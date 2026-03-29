import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart' as db;
import '../models/achievement_model.dart';
import '../../providers/app_providers.dart';

import '../../providers/app_providers.dart';

class AchievementService {
  final db.AppDatabase _db;
  final Ref _ref;

  AchievementService({required db.AppDatabase db, required Ref ref})
      : _db = db,
        _ref = ref;

  Future<void> checkAllAchievements(String userId) async {
    try {
      // 1. Get current earned badges
      final profile = await _db.getProfile(userId);
      if (profile == null) return;

      final Set<String> earnedIds = _parseBadges(profile.badgesJson);
      final Set<String> newEarnedIds = Set.from(earnedIds);

      // 2. Load necessary data
      final rounds = await _db.getAllRounds(userId);
      if (rounds.isEmpty && earnedIds.isEmpty) return; // Optimization

      final allHoleScores = await _db.getUserHoleScores(userId);
      final friends = await _db.getFriends(userId);
      final clubs = await (_db.select(_db.clubs)..where((c) => c.userId.equals(userId))).get();
      final practiceSessions = await (_db.select(_db.practiceSessions)..where((ps) => ps.userId.equals(userId))).get();

      // 3. Check each achievement
      for (final achievement in Achievement.allAchievements) {
        if (newEarnedIds.contains(achievement.id)) continue;

        bool isEarned = false;
        switch (achievement.id) {
          // --- Scoring ---
          case 'score_100':
            isEarned = rounds.any((r) => r.totalScore < 100 && r.holesPlayed >= 18);
            break;
          case 'score_90':
            isEarned = rounds.any((r) => r.totalScore < 90 && r.holesPlayed >= 18);
            break;
          case 'score_80':
            isEarned = rounds.any((r) => r.totalScore < 80 && r.holesPlayed >= 18);
            break;
          case 'birdie_first':
            isEarned = allHoleScores.any((h) => h.score == h.par - 1);
            break;
          case 'eagle_first':
            isEarned = allHoleScores.any((h) => h.score <= h.par - 2);
            break;
          case 'par_master':
            for (final r in rounds) {
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              if (scores.where((h) => h.score == h.par).length >= 9) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'hole_in_one':
            isEarned = allHoleScores.any((h) => h.score == 1 && h.par >= 3);
            break;
          case 'bogey_free':
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              if (scores.isNotEmpty && scores.every((h) => h.score <= h.par)) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'sub_par_9':
            isEarned = rounds.any((r) => (r.front9Score != null && r.front9Score! < 36) || (r.back9Score != null && r.back9Score! < 36));
            break;

          // --- Consistency ---
          case 'streak_par_3':
            isEarned = _checkScoreStreak(allHoleScores, (h) => h.score == h.par, 3);
            break;
          case 'streak_birdie_2':
            isEarned = _checkScoreStreak(allHoleScores, (h) => h.score == h.par - 1, 2);
            break;
          case 'fairway_king':
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final scores = allHoleScores.where((h) => h.roundId == r.id && h.par > 3);
              if (scores.isNotEmpty && scores.every((h) => h.fairwayHit == 'Hit')) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'gir_master':
            for (final r in rounds) {
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              int gir = 0;
              for (var s in scores) {
                // GIR = score - putts <= par - 2
                if (s.putts != null && (s.score - s.putts!) <= (s.par - 2)) gir++;
              }
              if (gir >= 12) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'no_penalties':
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              if (scores.isNotEmpty && scores.every((h) => (h.penalties ?? 0) == 0)) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'putt_pro':
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              int totalPutts = scores.fold(0, (sum, h) => sum + (h.putts ?? 0));
              if (scores.length >= 18 && totalPutts > 0 && totalPutts < 30) {
                isEarned = true;
                break;
              }
            }
            break;

          // --- Activity ---
          case 'round_1':
            isEarned = rounds.length >= 1;
            break;
          case 'round_10':
            isEarned = rounds.length >= 10;
            break;
          case 'round_50':
            isEarned = rounds.length >= 50;
            break;
          case 'round_100':
            isEarned = rounds.length >= 100;
            break;
          case 'weekend_warrior':
            final sats = rounds.where((r) => r.playedAt.weekday == DateTime.saturday);
            final suns = rounds.where((r) => r.playedAt.weekday == DateTime.sunday);
            if (sats.isNotEmpty && suns.isNotEmpty) {
              for (var sat in sats) {
                for (var sun in suns) {
                  if (sun.playedAt.difference(sat.playedAt).inDays.abs() <= 1) {
                    isEarned = true;
                    break;
                  }
                }
                if (isEarned) break;
              }
            }
            break;
          case 'early_bird':
            isEarned = rounds.any((r) => r.playedAt.hour < 7);
            break;
          case 'night_owl':
            isEarned = rounds.any((r) => r.playedAt.hour >= 18 && r.playedAt.minute >= 30);
            break;
          case 'marathon':
            final Map<String, int> dailyRounds = {};
            for (var r in rounds) {
              final dateStr = r.playedAt.toIso8601String().substring(0, 10);
              dailyRounds[dateStr] = (dailyRounds[dateStr] ?? 0) + 1;
            }
            isEarned = dailyRounds.values.any((count) => count >= 2);
            break;

          // --- Explorer ---
          case 'course_5':
            isEarned = rounds.map((r) => r.courseId).toSet().length >= 5;
            break;
          case 'course_10':
            isEarned = rounds.map((r) => r.courseId).toSet().length >= 10;
            break;

          // --- Social ---
          case 'friend_first':
            isEarned = friends.isNotEmpty;
            break;
          case 'friend_round':
            // Logic would require checking if other participants are friends
            // For now, assume if groupRoundId is not null, it might be with a friend
            isEarned = allHoleScores.any((h) => h.groupRoundId != null);
            break;

          // --- Fun/Misc ---
          case 'new_bag':
            isEarned = clubs.length >= 14;
            break;
          case 'comeback':
            isEarned = rounds.any((r) => r.front9Score != null && r.back9Score != null && (r.front9Score! - r.back9Score!) >= 10);
            break;
          case 'lucky_7':
            isEarned = _checkScoreStreak(allHoleScores, (h) => h.score == h.par, 7);
            break;
          case 'albatross':
            isEarned = allHoleScores.any((h) => h.score == h.par - 3);
            break;
          case 'streak_birdie_3':
            isEarned = _checkScoreStreak(allHoleScores, (h) => h.score == h.par - 1, 3);
            break;
          case 'par_4_eagle':
            isEarned = allHoleScores.any((h) => h.par == 4 && h.score == 2);
            break;
          case 'sub_30_putts':
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              int totalPutts = scores.fold(0, (sum, h) => sum + (h.putts ?? 0));
              if (scores.length >= 18 && totalPutts > 0 && totalPutts <= 25) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'caddie_helper':
            // Activity streak could be checked here
            break;
        }

        if (isEarned) {
          newEarnedIds.add(achievement.id);
        }
      }

      // 4. Save if changed
      if (newEarnedIds.length > earnedIds.length) {
        await _db.updateProfile(userId, db.UserProfilesCompanion(
          badgesJson: drift.Value(jsonEncode(newEarnedIds.toList())),
        ));
        _ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      debugPrint('ACHIEVEMENT_SERVICE: Error checking achievements: $e');
    }
  }

  bool _checkScoreStreak(List<db.HoleScore> allScores, bool Function(db.HoleScore) condition, int length) {
    // Group by round
    final Map<int, List<db.HoleScore>> roundScores = {};
    for (var s in allScores) {
      roundScores.putIfAbsent(s.roundId, () => []).add(s);
    }

    for (var roundId in roundScores.keys) {
      final scores = roundScores[roundId]!..sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
      int currentStreak = 0;
      for (var s in scores) {
        if (condition(s)) {
          currentStreak++;
          if (currentStreak >= length) return true;
        } else {
          currentStreak = 0;
        }
      }
    }
    return false;
  }

  Set<String> _parseBadges(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>().toSet();
    } catch (e) {
      debugPrint('Error parsing badges: $e');
    }
    return {};
  }
}
