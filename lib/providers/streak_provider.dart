import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/streak_utils.dart';
import 'app_providers.dart';

enum StreakStatus {
  noRounds,
  broken,
  active,
  safe,
  atRisk,
}

class StreakInfo {
  final int count;
  final StreakStatus status;
  final DateTime? lastPlayed;
  final bool playedThisWeek;
  final List<DateTime> playedDatesThisWeek;

  StreakInfo({
    required this.count,
    required this.status,
    this.lastPlayed,
    required this.playedThisWeek,
    this.playedDatesThisWeek = const [],
  });

  factory StreakInfo.empty() => StreakInfo(
        count: 0,
        status: StreakStatus.noRounds,
        playedThisWeek: false,
        playedDatesThisWeek: [],
      );
}

final streakProvider = StreamProvider<StreakInfo>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(StreakInfo.empty());

  final database = ref.watch(databaseProvider);

  return database.watchAllRounds(user.id).map((rounds) {
    if (rounds.isEmpty) {
      return StreakInfo(
        count: 0,
        status: StreakStatus.noRounds,
        playedThisWeek: false,
        playedDatesThisWeek: [],
      );
    }

    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    // Check if played this week and get the specific dates
    final roundsThisWeek = rounds.where((r) => 
      r.playedAt.isAfter(currentWeekStart.subtract(const Duration(seconds: 1)))
    ).toList();
    
    final playedThisWeek = roundsThisWeek.isNotEmpty;
    final playedDatesThisWeek = roundsThisWeek.map((r) => r.playedAt).toList();
    
    final streakCount = StreakUtils.calculateWeeklyStreak(rounds);
    final lastPlayed = rounds.first.playedAt; 

    StreakStatus status;
    if (streakCount == 0) {
      status = StreakStatus.broken;
    } else if (playedThisWeek) {
      status = StreakStatus.safe;
    } else if (now.weekday >= 5) {
      status = StreakStatus.atRisk;
    } else {
      status = StreakStatus.active;
    }

    return StreakInfo(
      count: streakCount,
      status: status,
      lastPlayed: lastPlayed,
      playedThisWeek: playedThisWeek,
      playedDatesThisWeek: playedDatesThisWeek,
    );
  });
});
