import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../providers/app_providers.dart';
import 'dart:math';

final groupSyncServiceProvider = Provider<GroupSyncService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return GroupSyncService(user?.id);
});

class GroupSyncService {
  final String? _uid;
  final SupabaseClient _supabase = Supabase.instance.client;

  GroupSyncService(this._uid);

  // Generate a random 6-character alphanumeric code
  String _generateRoundCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<String?> createGroupRound({
    required int courseId,
    required String courseName,
    required int coursePar,
    required String scoringMode,
    required int holesPlayed,
    required int teeId,
    required double? handicapBefore,
  }) async {
    if (_uid == null) return null;

    final roundCode = _generateRoundCode();
    
    // Insert GroupRound
    final roundData = await _supabase.from('GroupRound').insert({
      'roundCode': roundCode,
      'captainId': _uid,
      'courseId': courseId.toString(),
      'courseName': courseName,
      'coursePar': coursePar,
      'holesPlayed': holesPlayed,
      'status': 'PENDING',
      'scoringMode': scoringMode,
    }).select('id').single();

    final roundId = roundData['id'];

    // Insert Participant
    await _supabase.from('GroupRoundParticipant').insert({
      'groupRoundId': roundId,
      'userId': _uid,
      'role': 'CAPTAIN',
      'status': 'JOINED',
      'teeId': teeId,
      'handicapBefore': handicapBefore,
    });

    return roundCode;
  }

  Future<bool> joinGroupRound(String roundCode, {int? teeId, double? handicapBefore}) async {
    if (_uid == null) return false;

    final query = await _supabase
        .from('GroupRound')
        .select('id, status')
        .eq('roundCode', roundCode.toUpperCase())
        .eq('status', 'PENDING')
        .limit(1);

    if (query.isEmpty) return false;

    final roundId = query.first['id'];

    // Check if already in
    final participantQuery = await _supabase
        .from('GroupRoundParticipant')
        .select('id')
        .eq('groupRoundId', roundId)
        .eq('userId', _uid)
        .limit(1);
    
    if (participantQuery.isNotEmpty) {
      // Update existing participant info
      await _supabase.from('GroupRoundParticipant').update({
        'teeId': teeId,
        'handicapBefore': handicapBefore,
        'status': 'JOINED',
      }).eq('id', participantQuery.first['id']);
      return true;
    }

    await _supabase.from('GroupRoundParticipant').insert({
      'groupRoundId': roundId,
      'userId': _uid,
      'role': 'PLAYER',
      'status': 'JOINED',
      'teeId': teeId,
      'handicapBefore': handicapBefore,
    });

    return true;
  }

  Stream<List<Map<String, dynamic>>> watchParticipants(String roundId) {
    return _supabase
        .from('GroupRoundParticipant')
        .stream(primaryKey: ['id'])
        .eq('groupRoundId', roundId)
        .asyncMap((participants) async {
          final List<Map<String, dynamic>> enriched = [];
          for (var p in participants) {
            final userData = await _supabase.from('User').select('name, avatarUrl').eq('id', p['userId']).maybeSingle();
            enriched.add({
              ...p,
              'user': userData,
            });
          }
          return enriched;
        });
  }

  Stream<Map<String, dynamic>> watchGroupRound(String roundId) {
    return _supabase
        .from('GroupRound')
        .stream(primaryKey: ['id'])
        .eq('id', roundId)
        .map((list) => list.first);
  }

  Stream<List<Map<String, dynamic>>> watchAllScores(String roundId) {
    return _supabase
        .from('GroupRoundScore')
        .stream(primaryKey: ['id'])
        .eq('groupRoundId', roundId);
  }

  Stream<List<Map<String, dynamic>>> watchHoleScores(String roundId, int holeNumber) {
    return _supabase
        .from('GroupRoundScore')
        .stream(primaryKey: ['id'])
        .eq('groupRoundId', roundId)
        .map((data) => data.where((row) => row['holeNumber'] == holeNumber).toList());
  }

  Future<void> updatePlayerScore({
    required String groupRoundId,
    required String participantId,
    required String userId,
    required int holeNumber,
    required int strokes,
    int? putts,
    String? fairwayHit,
    int? penalties,
    bool? gir,
  }) async {
    try {
      debugPrint('GROUP_SYNC: Upserting score to GroupRoundScore for $userId');
      
      // Use a stable, composite ID for the score row
      final scoreId = 'grs_${participantId}_$holeNumber';

      await _supabase.from('GroupRoundScore').upsert({
        'id': scoreId,
        'groupRoundId': groupRoundId,
        'participantId': participantId,
        'userId': userId,
        'holeNumber': holeNumber,
        'strokes': strokes,
        'putts': putts ?? 0,
        'fairwayHit': fairwayHit,
        'penalties': penalties ?? 0,
        'gir': gir,
        'updatedAt': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      
      debugPrint('GROUP_SYNC: Score updated successfully');
    } catch (e) {
      debugPrint('GROUP_SYNC ERROR: Failed to update GroupRoundScore: $e');
    }
  }

  Future<void> finalizeRound(String groupRoundId, {int? actualHolesPlayed, bool useForAnalytics = true}) async {
    try {
      debugPrint('GROUP_SYNC: Finalizing round $groupRoundId (analytics: $useForAnalytics)');
      final Map<String, dynamic> updates = {
        'status': 'COMPLETED',
        'useForAnalytics': useForAnalytics,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (actualHolesPlayed != null) {
        updates['holesPlayed'] = actualHolesPlayed;
      }
      
      await _supabase.from('GroupRound').update(updates).eq('id', groupRoundId);
      debugPrint('GROUP_SYNC: Round $groupRoundId finalized successfully');
    } catch (e) {
      debugPrint('GROUP_SYNC ERROR: Failed to finalize round: $e');
      rethrow;
    }
  }

  Future<void> certifyParticipant(String participantId, {bool dispute = false, String? note}) async {
    // 1. Mark as certified in GroupRoundParticipant
    await _supabase.from('GroupRoundParticipant').update({
      'certifiedAt': DateTime.now().toIso8601String(),
      'disputed': dispute,
      'disputeNote': dispute ? note : null,
    }).eq('id', participantId);

    if (dispute) return;

    try {
      // 2. Fetch all data needed to push to global Round table
      final pData = await _supabase.from('GroupRoundParticipant').select('*, GroupRound(*)').eq('id', participantId).single();
      final round = pData['GroupRound'];
      final userId = pData['userId'];
      
      // Fetch all scores for this participant
      final scores = await _supabase.from('GroupRoundScore').select('*').eq('participantId', participantId).order('holeNumber');
      if (scores.isEmpty) return;

      final totalStrokes = scores.fold<int>(0, (sum, row) => sum + (row['strokes'] as int));
      final courseId = round['courseId'];
      final courseName = round['courseName'];
      final coursePar = round['coursePar'] ?? 72;
      final hIndex = (pData['handicapBefore'] as num?)?.toDouble() ?? 0.0;
      
      // Calculate actual holes played based on entries
      final actualHolesPlayed = scores.length;


      // 3. Push to global Round table
      final roundInsert = await _supabase.from('Round').insert({
        'userId': userId,
        'courseId': courseId, 
        'courseName': courseName,
        'coursePar': coursePar,
        'playedAt': round['updatedAt'] ?? DateTime.now().toIso8601String(),
        'totalScore': totalStrokes,
        'holesPlayed': actualHolesPlayed,
        'totalNet': totalStrokes - hIndex,
        'scoringMode': 'GROUP_CERTIFIED',
        'groupRoundId': round['id'],
        'useForAnalytics': round['useForAnalytics'] ?? (actualHolesPlayed >= (round['holesPlayed'] ?? 9)), 
      }).select('id').single();

      final roundId = roundInsert['id'];

      // 4. Migrate hole scores to global HoleScore table
      // We need pars. Since we don't have them in GroupRoundScore, we'll fetch from CourseHole
      final courseHoles = await _supabase.from('CourseHole').select('holeNumber, par').eq('courseId', courseId);
      final Map<int, int> parMap = {
        for (var h in courseHoles) (h['holeNumber'] as int): (h['par'] as int)
      };

      final List<Map<String, dynamic>> holeScoreInserts = scores.map((s) {
        final hNum = s['holeNumber'] as int;
        return {
          'id': 'hs_${roundId}_$hNum', // Stable ID
          'roundId': roundId,
          'holeNumber': hNum,
          'par': parMap[hNum] ?? 4, // Fallback to 4 if not found
          'score': s['strokes'],
          'putts': s['putts'] ?? 0,
          'fairwayHit': s['fairwayHit'],
          'penalties': s['penalties'] ?? 0,
          'gir': s['gir'],
        };
      }).toList();

      await _supabase.from('HoleScore').upsert(holeScoreInserts, onConflict: 'id');

    } catch (e) {
      debugPrint('Error pushing to leaderboard and migrating scores: $e');
    }
  }
}
