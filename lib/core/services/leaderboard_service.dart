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
  /// Position from the server; ties share a rank.
  final int? rank;

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
    this.rank,
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
      rank: (json['rank'] as num?)?.toInt(),
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
      // Every client refetches on any round change platform-wide, so batch
      // bursts of changes into one refetch.
      debounceTimer = Timer(const Duration(seconds: 5), () async {
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

      // Ranking happens in the database (get_leaderboard): each golfer's
      // best round, top 50 plus the caller's own row. This used to download
      // every matching round with a User join and pick the best in Dart,
      // which grew with every round ever played.
      String? courseName;
      if (tab == LeaderboardTab.course && specificCourseId != null) {
        try {
          // Older rounds may only carry the course name, so match on both.
          final localCourse = await _database.getCourseBySupabaseId(specificCourseId);
          courseName = localCourse?.name.trim();
        } catch (_) {}
      }

      final response = await _supabase.rpc('get_leaderboard', params: {
        'p_scope': switch (tab) {
          LeaderboardTab.global => 'global',
          LeaderboardTab.friends => 'friends',
          LeaderboardTab.course => 'course',
        },
        'p_period': switch (period) {
          TimePeriod.allTime => 'all',
          TimePeriod.thisMonth => 'month',
          TimePeriod.thisWeek => 'week',
        },
        'p_scoring': scoring == ScoringType.net ? 'net' : 'gross',
        'p_course_id': tab == LeaderboardTab.course ? specificCourseId : null,
        'p_course_name': courseName,
        'p_limit': 50,
      });

      final rows = (response as List<dynamic>? ?? const []);
      debugPrint('LEADERBOARD: ${rows.length} ranked rows');
      return rows
          .map((row) => LeaderboardEntry.fromJson(row as Map<String, dynamic>))
          .toList();

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
