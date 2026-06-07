import '../database/database.dart' as db;

class StreakUtils {
  /// Calculates the current weekly streak (Monday-Sunday) based on a list of rounds.
  /// A streak is maintained if there's at least one round per week.
  static int calculateWeeklyStreak(List<db.Round> rounds) {
    if (rounds.isEmpty) return 0;
    
    // Ensure rounds are sorted by date descending
    final sortedRounds = List<db.Round>.from(rounds)..sort((a, b) => b.playedAt.compareTo(a.playedAt));
    
    final Set<DateTime> activeWeeks = {};
    for (var r in sortedRounds) {
      final date = r.playedAt;
      // Start of week (Monday)
      final startOfWeek = DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
      activeWeeks.add(startOfWeek);
    }
    
    final sortedWeeks = activeWeeks.toList()..sort((a, b) => b.compareTo(a));
    
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    
    // If most recent round was before last week, streak is broken
    if (sortedWeeks.first.isBefore(lastWeekStart)) return 0;
    
    int streak = 0;
    DateTime expectedWeek = sortedWeeks.first;
    
    for (var week in sortedWeeks) {
      if (week == expectedWeek) {
        streak++;
        expectedWeek = expectedWeek.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Determines if a round was played in the current week (Monday-Sunday).
  static bool playedThisWeek(List<db.Round> rounds) {
    if (rounds.isEmpty) return false;
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return rounds.any((r) => r.playedAt.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))));
  }
}
