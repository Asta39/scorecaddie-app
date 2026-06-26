import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../database/database.dart' as db;

enum LeaderboardTab { global, friends, course }
enum TimePeriod { allTime, thisMonth, thisWeek }
enum ScoringType { gross, net }

class LeaderboardParams {
  final LeaderboardTab tab;
  final TimePeriod period;
  final ScoringType scoring;
  final String? courseId;

  LeaderboardParams({
    required this.tab,
    required this.period,
    required this.scoring,
    this.courseId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardParams &&
          runtimeType == other.runtimeType &&
          tab == other.tab &&
          period == other.period &&
          scoring == other.scoring &&
          courseId == other.courseId;

  @override
  int get hashCode => tab.hashCode ^ period.hashCode ^ scoring.hashCode ^ courseId.hashCode;
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double handicap;
  final double score;
  final int roundsPlayed;
  final String? courseId;
  final DateTime roundDate;
  final String? handicapOrigin;
  final bool isProvisional;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.handicap,
    required this.score,
    required this.roundsPlayed,
    this.courseId,
    required this.roundDate,
    this.handicapOrigin,
    required this.isProvisional,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final user = json['User'] as Map<String, dynamic>? ?? {};
    final score = (json['totalScore'] as num? ?? 
                  json['totalNet'] as num? ?? 
                  json['score'] as num? ?? 
                  json['total_score'] as num? ?? 
                  json['total_net'] as num? ?? 0.0).toDouble();
    
    final userId = json['userId'] as String? ?? json['user_id'] as String? ?? 'unknown';

    return LeaderboardEntry(
      userId: userId,
      displayName: user['name'] as String? ?? 'Golfer',
      avatarUrl: user['avatarUrl'] as String? ?? user['avatar_url'] as String?,
      handicap: (user['handicapIndex'] as num? ?? user['handicap_index'] as num? ?? 0.0).toDouble(),
      score: score,
      roundsPlayed: 1,
      courseId: json['courseId'] as String? ?? json['course_id'] as String?,
      roundDate: DateTime.tryParse(json['playedAt'] as String? ?? json['played_at'] as String? ?? '') ?? DateTime.now(),
      handicapOrigin: user['handicapOrigin'] as String? ?? user['handicap_origin'] as String?,
      isProvisional: user['isProvisional'] as bool? ?? user['is_provisional'] as bool? ?? true,
    );
  }
}

class LeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final db.AppDatabase _database;

  LeaderboardService(this._database);

  Stream<List<LeaderboardEntry>> streamLeaderboard({
    required LeaderboardTab tab,
    required TimePeriod period,
    required ScoringType scoring,
    String? currentUserId,
    String? specificCourseId,
  }) {
    final controller = StreamController<List<LeaderboardEntry>>();
    
    Timer? debounceTimer;

    void update() async {
      if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        try {
          final entries = await fetchLeaderboard(
            tab: tab,
            period: period,
            scoring: scoring,
            currentUserId: currentUserId,
            specificCourseId: specificCourseId,
          );
          if (!controller.isClosed) controller.add(entries);
        } catch (e) {
          if (!controller.isClosed) controller.addError(e);
        }
      });
    }

    update();

    final channel = _supabase.channel('public:Round:leaderboard_updates');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'Round',
      callback: (payload) => update(),
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'User',
      callback: (payload) => update(),
    ).subscribe();

    controller.onCancel = () {
      debounceTimer?.cancel();
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required LeaderboardTab tab,
    required TimePeriod period,
    required ScoringType scoring,
    String? currentUserId,
    String? specificCourseId,
  }) async {
    try {
      debugPrint('LEADERBOARD: Fetching for tab=$tab, period=$period, scoring=$scoring, specificCourseId=$specificCourseId');

      final String scoreColumn = scoring == ScoringType.net ? 'totalNet' : 'totalScore';
      
      var query = _supabase.from('Round').select('''
        userId, courseId, courseName, playedAt, $scoreColumn,
        User(id, name, avatarUrl, handicapIndex, isProvisional, handicapOrigin)
      ''');

      if (tab == LeaderboardTab.friends) {
        final friendsRes = await _supabase.from('Friend').select('friendId').eq('userId', currentUserId!);
        final ids = (friendsRes as List).map((f) => f['friendId'] as String).toList();
        ids.add(currentUserId);
        query = query.inFilter('userId', ids);
      }

      if (period == TimePeriod.thisWeek) {
        final start = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        query = query.gte('playedAt', start);
      } else if (period == TimePeriod.thisMonth) {
        final start = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
        query = query.gte('playedAt', start);
      }

if (tab == LeaderboardTab.course && specificCourseId != null) {
        debugPrint('LEADERBOARD: Merging rankings for Course ID: $specificCourseId');
        
        try {
          final localCourse = await _database.getCourseBySupabaseId(specificCourseId);
          
          if (localCourse != null) {
            final String cName = localCourse.name.trim().replaceAll('"', '""');
            debugPrint('LEADERBOARD: Fetching ALL rounds matching name: $cName');
            query = query.or('courseName.eq."$cName",courseId.eq.$specificCourseId');
          } else {
             query = query.eq('courseId', specificCourseId);
           }
        } catch (e) {
          query = query.eq('courseId', specificCourseId);
        }
      }

      final response = await query.order(scoreColumn, ascending: true);
      final List<dynamic> rows = response as List<dynamic>;
      debugPrint('LEADERBOARD: Fetched ${rows.length} rows from Supabase.');
      
      final Map<String, LeaderboardEntry> bestRounds = {};
      for (var row in rows) {
        final entry = LeaderboardEntry.fromJson(row as Map<String, dynamic>);
        if (entry.score <= 0) continue; 
        if (!bestRounds.containsKey(entry.userId)) {
          bestRounds[entry.userId] = entry;
        }
      }

      final sorted = bestRounds.values.toList();
      sorted.sort((a, b) => a.score.compareTo(b.score));
      return sorted;

    } catch (e) {
      debugPrint('LEADERBOARD_ERROR: $e');
      return [];
    }
  }

  Future<Map<String, LeaderboardEntry?>> fetchCourseRecords(String courseId, String courseName) async {
    try {
      final String cName = courseName.trim().replaceAll('"', '""');
      debugPrint('FETCH_RECORDS: Merging name="$cName" or ID=$courseId');

      final gross = await _supabase.from('Round').select('userId, courseId, courseName, playedAt, totalScore, User(id, name, avatarUrl, handicapIndex, isProvisional, handicapOrigin)').or('courseName.eq."$cName",courseId.eq.$courseId').order('totalScore', ascending: true).limit(1).maybeSingle();
      final net = await _supabase.from('Round').select('userId, courseId, courseName, playedAt, totalNet, User(id, name, avatarUrl, handicapIndex, isProvisional, handicapOrigin)').or('courseName.eq."$cName",courseId.eq.$courseId').order('totalNet', ascending: true).limit(1).maybeSingle();
      
      return {
        'gross': gross != null ? LeaderboardEntry.fromJson(gross) : null,
        'net': net != null ? LeaderboardEntry.fromJson(net) : null,
      };
    } catch (e) {
      debugPrint('COURSE_RECORDS_ERROR: $e');
      return {'gross': null, 'net': null};
    }
  }

  Future<Map<String, LeaderboardEntry?>> fetchPersonalBest(String userId, String courseId, String courseName) async {
    try {
      final String cName = courseName.trim().replaceAll('"', '""');
      debugPrint('FETCH_PB: Merging user=$userId, name="$cName" or ID=$courseId');

      final gross = await _supabase.from('Round').select('userId, courseId, courseName, playedAt, totalScore, User(id, name, avatarUrl, handicapIndex, isProvisional, handicapOrigin)').eq('userId', userId).or('courseName.eq."$cName",courseId.eq.$courseId').order('totalScore', ascending: true).limit(1).maybeSingle();
      final net = await _supabase.from('Round').select('userId, courseId, courseName, playedAt, totalNet, User(id, name, avatarUrl, handicapIndex, isProvisional, handicapOrigin)').eq('userId', userId).or('courseName.eq."$cName",courseId.eq.$courseId').order('totalNet', ascending: true).limit(1).maybeSingle();
      
      return {
        'gross': gross != null ? LeaderboardEntry.fromJson(gross) : null,
        'net': net != null ? LeaderboardEntry.fromJson(net) : null,
      };
    } catch (e) {
      debugPrint('PERSONAL_PB_ERROR: $e');
      return {'gross': null, 'net': null};
    }
  }
}

final leaderboardServiceProvider = Provider((ref) => LeaderboardService(ref.watch(databaseProvider)));
