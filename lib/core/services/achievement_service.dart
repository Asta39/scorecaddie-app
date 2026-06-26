import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart' as db;
import '../models/achievement_model.dart';
import '../../providers/app_providers.dart';
import '../utils/streak_utils.dart';


class AchievementService {
  final db.AppDatabase _db;
  final Ref _ref;

  AchievementService({required db.AppDatabase db, required Ref ref})
      : _db = db,
        _ref = ref;

  Future<List<Achievement>> checkAllAchievements(String userId) async {
    final List<Achievement> newlyEarned = [];
    try {
      // 1. Get current earned badges
      final profile = await _db.getProfile(userId);
      if (profile == null) return [];

      final Set<String> earnedIds = _parseBadges(profile.badgesJson);
      final Set<String> newEarnedIds = Set.from(earnedIds);

      // 2. Load necessary data
      final rounds = await _db.getAllRounds(userId);
      if (rounds.isEmpty && earnedIds.isEmpty) return []; // Optimization

      final rawHoleScores = await _db.getUserHoleScores(userId);
      final friends = await _db.getFriends(userId);
      final clubs = await (_db.select(_db.clubs)..where((c) => c.userId.equals(userId))).get();

      // CRITICAL: Filter out unplayed holes (score <= 0).
      // When a user finishes early, unplayed holes are stored with score=0.
      // These must be excluded from ALL achievement checks to prevent
      // false positives (e.g., score=0 on a par-4 would be a "double eagle").
      final allHoleScores = rawHoleScores.where((h) => h.score > 0).toList();

      // Build a lookup of actually-played hole counts per round.
      // This is used for achievements that require a "complete" round
      // (e.g., bogey-free round needs all holes played, not just the
      // ones the user entered before finishing early).
      final Map<int, int> playedCountByRound = {};
      for (var h in allHoleScores) {
        playedCountByRound[h.roundId] = (playedCountByRound[h.roundId] ?? 0) + 1;
      }

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
            // Must be a full 18-hole round where ALL 18 holes were actually
            // played (not a partial finish) and every played hole is <= par.
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final played = playedCountByRound[r.id] ?? 0;
              if (played < 18) continue; // Partial round — skip
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
            // Must be a full 18-hole round with all 18 holes played
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final played = playedCountByRound[r.id] ?? 0;
              if (played < 18) continue;
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
            // Must be a full 18-hole round with all 18 holes played
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final played = playedCountByRound[r.id] ?? 0;
              if (played < 18) continue;
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              if (scores.isNotEmpty && scores.every((h) => (h.penalties ?? 0) == 0)) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'putt_pro':
            // Must be a full 18-hole round with all 18 holes played and putts tracked
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final played = playedCountByRound[r.id] ?? 0;
              if (played < 18) continue;
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              final trackedPutts = scores.where((h) => h.putts != null);
              if (trackedPutts.length < 18) continue; // Need putts for all holes
              int totalPutts = trackedPutts.fold(0, (sum, h) => sum + h.putts!);
              if (totalPutts > 0 && totalPutts < 30) {
                isEarned = true;
                break;
              }
            }
            break;

          // --- Activity ---
          case 'round_1':
            isEarned = rounds.isNotEmpty;
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
            // Check if any played hole is linked to a group round
            isEarned = allHoleScores.any((h) => h.groupRoundId != null);
            break;

          // --- Fun/Misc ---
          case 'new_bag':
            isEarned = clubs.length >= 14;
            break;
          case 'comeback':
            // Only valid for full 18-hole rounds where both nines were completed
            isEarned = rounds.any((r) {
              if (r.front9Score == null || r.back9Score == null) return false;
              if (r.holesPlayed < 18) return false;
              final played = playedCountByRound[r.id] ?? 0;
              if (played < 18) return false;
              return (r.front9Score! - r.back9Score!) >= 10;
            });
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
            // Must be a full 18-hole round with all 18 putts tracked
            for (final r in rounds.where((r) => r.holesPlayed >= 18)) {
              final played = playedCountByRound[r.id] ?? 0;
              if (played < 18) continue;
              final scores = allHoleScores.where((h) => h.roundId == r.id);
              final trackedPutts = scores.where((h) => h.putts != null);
              if (trackedPutts.length < 18) continue;
              int totalPutts = trackedPutts.fold(0, (sum, h) => sum + h.putts!);
              if (totalPutts > 0 && totalPutts <= 25) {
                isEarned = true;
                break;
              }
            }
            break;
          case 'caddie_helper':
            // Activity streak could be checked here
            break;
            
          // --- Streak Milestones ---
          case 'streak_week_1':
            isEarned = _calculateWeeklyStreak(rounds) >= 1;
            break;
          case 'streak_week_4':
            isEarned = _calculateWeeklyStreak(rounds) >= 4;
            break;
          case 'streak_week_12':
            isEarned = _calculateWeeklyStreak(rounds) >= 12;
            break;
          case 'streak_week_26':
            isEarned = _calculateWeeklyStreak(rounds) >= 26;
            break;
          case 'streak_week_52':
            isEarned = _calculateWeeklyStreak(rounds) >= 52;
            break;
        }

        if (isEarned) {
          newEarnedIds.add(achievement.id);
          newlyEarned.add(achievement);
        }
      }

      // 4. Save if changed
      if (newEarnedIds.length > earnedIds.length) {
        await _db.updateProfile(userId, db.UserProfilesCompanion(
          badgesJson: drift.Value(jsonEncode(newEarnedIds.toList())),
        ));
        _ref.invalidate(userProfileProvider);
      }
      return newlyEarned;
    } catch (e) {
      debugPrint('ACHIEVEMENT_SERVICE: Error checking achievements: $e');
      return [];
    }
  }

  bool _checkScoreStreak(List<db.HoleScore> allScores, bool Function(db.HoleScore) condition, int length) {
    // Group by round (allScores already filtered for score > 0)
    final Map<int, List<db.HoleScore>> roundScores = {};
    for (var s in allScores) {
      roundScores.putIfAbsent(s.roundId, () => []).add(s);
    }

    for (var roundId in roundScores.keys) {
      final scores = roundScores[roundId]!..sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
      int currentStreak = 0;

      // Track hole number gaps to break streaks across unplayed holes.
      // e.g., if holes 1-5 are played but 6-9 are unplayed, a streak
      // should not carry from hole 5 to hole 10.
      int? lastHoleNumber;

      for (var s in scores) {
        final isConsecutive = lastHoleNumber == null || s.holeNumber == lastHoleNumber + 1;
        lastHoleNumber = s.holeNumber;

        if (!isConsecutive) {
          // Gap in hole numbers means unplayed holes in between — break streak
          currentStreak = 0;
        }

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

  int _calculateWeeklyStreak(List<db.Round> rounds) {
    return StreakUtils.calculateWeeklyStreak(rounds);
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
