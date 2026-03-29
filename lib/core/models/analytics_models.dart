import 'package:flutter/foundation.dart';

@immutable
class AdvancedStats {
  final int roundsPlayed;
  final double fairwayHitPercentage;
  final double greensInRegulationPercentage;
  final double puttsPerRound;
  final double penaltiesPerRound;
  final Map<int, double> parAverages; // Map of Par value (3, 4, 5) -> average score
  final double front9Avg;
  final double back9Avg;
  final int roundsPlayedToHandicap; // Progress out of 5
  final double? handicapIndex;
  final List<double> recentScores; // Last 20 rounds scoreVsPar
  final List<double> handicapHistory; // Last 20 rounds handicap trend
  final List<double> movingAverage;
  final List<double> front9Scores;
  final List<double> back9Scores;
  final double? scoreTrend;
  final double? puttsTrend;

  const AdvancedStats({
    required this.roundsPlayed,
    required this.fairwayHitPercentage,
    required this.greensInRegulationPercentage,
    required this.puttsPerRound,
    required this.penaltiesPerRound,
    required this.parAverages,
    required this.front9Avg,
    required this.back9Avg,
    required this.roundsPlayedToHandicap,
    this.handicapIndex,
    required this.recentScores,
    required this.handicapHistory,
    required this.movingAverage,
    required this.front9Scores,
    required this.back9Scores,
    this.scoreTrend,
    this.puttsTrend,
  });

  factory AdvancedStats.empty() => const AdvancedStats(
        roundsPlayed: 0,
        fairwayHitPercentage: 0,
        greensInRegulationPercentage: 0,
        puttsPerRound: 0,
        penaltiesPerRound: 0,
        parAverages: {3: 0, 4: 0, 5: 0},
        front9Avg: 0,
        back9Avg: 0,
        roundsPlayedToHandicap: 0,
        recentScores: [],
        handicapHistory: [],
        movingAverage: [],
        front9Scores: [],
        back9Scores: [],
        scoreTrend: null,
      );

  bool get isHandicapEligible => roundsPlayedToHandicap >= 5;

  String get bestScoreString {
    if (recentScores.isEmpty) return '—';
    final best = recentScores.reduce((a, b) => a < b ? a : b);
    return best <= 0 ? (best == 0 ? 'E' : best.toInt().toString()) : '+${best.toInt()}';
  }

  String get avgScoreString {
    if (recentScores.isEmpty) return '—';
    final avg = recentScores.reduce((a, b) => a + b) / recentScores.length;
    return avg <= 0 ? (avg == 0 ? 'E' : avg.toStringAsFixed(1)) : '+${avg.toStringAsFixed(1)}';
  }
}

@immutable
class PracticeStats {
  final int totalSessions;
  final Duration totalTime;
  final int totalBalls;
  final List<ClubPracticeStat> clubBreakdown;
  final List<double> accuracyTrend; // Last 10 sessions accuracy %
  final List<int> ballsHitTrend; // Last 10 sessions balls hit
  final String mostPracticedClub;
  final String bestAccuracyClub;
  final int totalBallsThisMonth;

  const PracticeStats({
    required this.totalSessions,
    required this.totalTime,
    required this.totalBalls,
    required this.clubBreakdown,
    required this.accuracyTrend,
    required this.ballsHitTrend,
    required this.mostPracticedClub,
    required this.bestAccuracyClub,
    required this.totalBallsThisMonth,
  });

  factory PracticeStats.empty() => const PracticeStats(
    totalSessions: 0,
    totalTime: Duration.zero,
    totalBalls: 0,
    clubBreakdown: [],
    accuracyTrend: [],
    ballsHitTrend: [],
    mostPracticedClub: '—',
    bestAccuracyClub: '—',
    totalBallsThisMonth: 0,
  );

  double get avgSessionMinutes => totalSessions > 0 ? totalTime.inMinutes / totalSessions : 0;
}

@immutable
class ClubPracticeStat {
  final String clubName;
  final int ballsHit;
  final double accuracy;
  final double avgDistance;

  const ClubPracticeStat({
    required this.clubName,
    required this.ballsHit,
    required this.accuracy,
    required this.avgDistance,
  });
}
