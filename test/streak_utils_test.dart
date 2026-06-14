import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/utils/streak_utils.dart';
import 'package:score_caddie/core/database/database.dart';

void main() {
  group('StreakUtils - calculateWeeklyStreak', () {
    test('returns 0 for empty rounds', () {
      expect(StreakUtils.calculateWeeklyStreak([]), 0);
    });

    test('returns 1 for single round this week', () {
      final now = DateTime.now();
      final round = Round(
        id: 1,
        userId: 'test',
        courseId: 1,
        totalScore: 85,
        holesPlayed: 18,
        playedAt: now,
        isSynced: true,
        useForAnalytics: true,
        courseName: 'Test Course',
        coursePar: 72,
        scoreVsPar: 13,
        tee: 'White',
        notes: '',
        createdAt: now,
        updatedAt: now,
        source: 'live',
      );
      expect(StreakUtils.calculateWeeklyStreak([round]), 1);
    });

    test('returns 1 for last week only (streak maintained)', () {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final round = Round(
        id: 1,
        userId: 'test',
        courseId: 1,
        totalScore: 85,
        holesPlayed: 18,
        playedAt: lastWeek,
        isSynced: true,
        useForAnalytics: true,
        courseName: 'Test Course',
        coursePar: 72,
        scoreVsPar: 13,
        tee: 'White',
        notes: '',
        createdAt: lastWeek,
        updatedAt: lastWeek,
        source: 'live',
      );
      expect(StreakUtils.calculateWeeklyStreak([round]), 1);
    });
  });

  group('StreakUtils - playedThisWeek', () {
    test('returns false for empty list', () {
      expect(StreakUtils.playedThisWeek([]), false);
    });

    test('returns true for round today', () {
      final now = DateTime.now();
      final round = Round(
        id: 1,
        userId: 'test',
        courseId: 1,
        totalScore: 85,
        holesPlayed: 18,
        playedAt: now,
        isSynced: true,
        useForAnalytics: true,
        courseName: 'Test Course',
        coursePar: 72,
        scoreVsPar: 13,
        tee: 'White',
        notes: '',
        createdAt: now,
        updatedAt: now,
        source: 'live',
      );
      expect(StreakUtils.playedThisWeek([round]), true);
    });

    test('returns false for round last month', () {
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final round = Round(
        id: 1,
        userId: 'test',
        courseId: 1,
        totalScore: 85,
        holesPlayed: 18,
        playedAt: lastMonth,
        isSynced: true,
        useForAnalytics: true,
        courseName: 'Test Course',
        coursePar: 72,
        scoreVsPar: 13,
        tee: 'White',
        notes: '',
        createdAt: lastMonth,
        updatedAt: lastMonth,
        source: 'live',
      );
      expect(StreakUtils.playedThisWeek([round]), false);
    });
  });
}