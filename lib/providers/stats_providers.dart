import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../core/database/database.dart' as db;
import '../core/models/analytics_models.dart';
import '../core/services/achievement_service.dart';
import '../core/utils/handicap.dart';
import 'auth_providers.dart';
import 'database_providers.dart';

final achievementServiceProvider = Provider<AchievementService>((ref) {
  final db = ref.watch(databaseProvider);
  return AchievementService(db: db, ref: ref);
});

final clubsProvider = StreamProvider<List<db.Club>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return (database.select(database.clubs)..where((c) => c.userId.equals(user.id))).watch();
});

final singleRoundProvider = StreamProvider.family<db.Round, int>((ref, roundId) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.rounds)..where((r) => r.id.equals(roundId))).watchSingle();
});

final holeScoresProvider = StreamProvider.family<List<db.HoleScore>, int>((ref, roundId) {
  final database = ref.watch(databaseProvider);
  return (database.select(database.holeScores)
        ..where((h) => h.roundId.equals(roundId))
        ..orderBy([(h) => drift.OrderingTerm.asc(h.holeNumber)]))
      .watch();
});

String _normalizeCourseName(String name) {
  return name
      .toLowerCase()
      .replaceAll('golf club', '')
      .replaceAll('country club', '')
      .replaceAll('sports club', '')
      .replaceAll('golf resort', '')
      .replaceAll('resort', '')
      .replaceAll('club', '')
      .replaceAll('(baobab course)', '')
      .replaceAll('&', '')
      .replaceAll('and', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final coursesProvider = StreamProvider<List<db.Course>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  return database.watchAllCourses(user?.id).map((courses) {
    final Map<String, db.Course> uniqueCourses = {};
    for (final c in courses) {
      final key = _normalizeCourseName(c.name) + '_' + _normalizeCourseName(c.location ?? '');
      if (!uniqueCourses.containsKey(key)) {
        uniqueCourses[key] = c;
      } else {
        final existing = uniqueCourses[key]!;
        final existingHasTees = existing.teeData != null && existing.teeData!.isNotEmpty && existing.teeData != '[]';
        final newHasTees = c.teeData != null && c.teeData!.isNotEmpty && c.teeData != '[]';
        
        if (newHasTees && !existingHasTees) {
          uniqueCourses[key] = c;
        } else if (!newHasTees && existingHasTees) {
          // Keep existing which has tees
        } else {
          // Both have or don't have tees, default to region check
          if ((existing.region == null || existing.region!.isEmpty) && 
              c.region != null && c.region!.isNotEmpty) {
            uniqueCourses[key] = c;
          }
        }
      }
    }
    final deduplicated = uniqueCourses.values.toList();
    deduplicated.sort((a, b) => a.name.compareTo(b.name));
    return deduplicated;
  });
});


final roundsProvider = StreamProvider<List<db.Round>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return database.watchAllRounds(user.id);
});

final courseTeesProvider = FutureProvider.family<List<db.Tee>, int>((ref, courseId) async {
  final database = ref.watch(databaseProvider);
  return await database.getTeesForCourse(courseId);
});

final recentRoundsProvider = StreamProvider<List<db.Round>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return database.watchRecentRounds(user.id, limit: 5);
});

final chartRoundsProvider = StreamProvider<List<db.Round>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return database.watchRecentRounds(user.id, limit: 10);
});

final totalRoundsProvider = StreamProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);
  return database.watchTotalRoundsCount(user.id, onlyForAnalytics: true);
});

final averageScoreProvider = StreamProvider<double?>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return database.watchAverageScore(user.id, onlyForAnalytics: true);
});

final bestScoreProvider = StreamProvider<int?>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return database.watchBestScore(user.id, onlyForAnalytics: true);
});

final advancedStatsProvider = FutureProvider<AdvancedStats>((ref) async {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return AdvancedStats.empty();

  final allRounds = ref.watch(roundsProvider).valueOrNull ?? [];
  // Filter for analytics-eligible rounds
  final rounds = allRounds.where((r) => r.useForAnalytics).toList();
  
  if (rounds.isEmpty) return AdvancedStats.empty();

  final holeScores = await database.getUserHoleScores(user.id);
  
  final scoresByRound = <int, List<db.HoleScore>>{};
  for (var score in holeScores) {
    scoresByRound.putIfAbsent(score.roundId, () => []).add(score);
  }

  int totalFairwaysHit = 0;
  int totalFairwaysTracked = 0;
  int totalGIR = 0;
  int totalHolesWithDetailedStats = 0;
  int totalPutts = 0;
  int totalPenalties = 0;
  
  final parScores = <int, List<int>>{3: [], 4: [], 5: []};
  double front9Sum = 0;
  int front9Count = 0;
  double back9Sum = 0;
  int back9Count = 0;

  int nineHoleRoundsPlayed = 0;
  int eighteenHoleRoundsPlayed = 0;
  double nineHoleTotalVsPar = 0;
  double eighteenHoleTotalVsPar = 0;
  final Map<String, List<int>> courseScores = {};

  for (var round in rounds) {
    final rScores = scoresByRound[round.id] ?? [];

    if (round.holesPlayed == 9) {
      nineHoleRoundsPlayed++;
      nineHoleTotalVsPar += round.scoreVsPar;
    } else {
      eighteenHoleRoundsPlayed++;
      eighteenHoleTotalVsPar += round.scoreVsPar;
    }

    courseScores.putIfAbsent(round.courseName, () => []).add(round.totalScore);

    for (var s in rScores) {
      if (s.score <= 0) continue;

      if (s.fairwayHit != null && s.par > 3) {
        totalFairwaysTracked++;
        if (s.fairwayHit == 'Hit') totalFairwaysHit++;
      }

      if (s.putts != null) {
        totalHolesWithDetailedStats++;
        totalPutts += s.putts!;
        
        if (s.gir != null) {
          if (s.gir!) totalGIR++;
        } else {
          if (s.score - s.putts! <= s.par - 2) {
            totalGIR++;
          }
        }
      } else if (s.gir != null) {
        totalHolesWithDetailedStats++;
        if (s.gir!) totalGIR++;
      }
      
      if (s.penalties != null) totalPenalties += s.penalties!;

      if (parScores.containsKey(s.par)) {
        parScores[s.par]!.add(s.score);
      }

      if (s.holeNumber <= 9) {
        front9Sum += s.score;
        front9Count++;
      } else {
        back9Sum += s.score;
        back9Count++;
      }
    }
  }

  final fairwayHitPercentage = totalFairwaysTracked > 0 ? (totalFairwaysHit / totalFairwaysTracked) * 100 : 0.0;
  final girPercentage = totalHolesWithDetailedStats > 0 ? (totalGIR / totalHolesWithDetailedStats) * 100 : 0.0;
  
  final puttsPerHole = totalHolesWithDetailedStats > 0 ? totalPutts / totalHolesWithDetailedStats : 0.0;
  final penaltiesPerHole = totalHolesWithDetailedStats > 0 ? totalPenalties / totalHolesWithDetailedStats : 0.0;
  
  final parAvgs = parScores.map((par, scores) => MapEntry(par, scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length));

  final recentRounds = rounds.take(20).toList().reversed.toList();
  final recentScoresVsPar = recentRounds.map((r) => (r.totalScore - r.coursePar).toDouble()).toList();
  final front9Scores = recentRounds.map((r) => (r.front9Score ?? 0).toDouble()).toList();
  final back9Scores = recentRounds.map((r) => (r.back9Score ?? 0).toDouble()).toList();
  
  List<double> movingAvg = [];
  for (int i = 0; i < recentScoresVsPar.length; i++) {
    int start = i - 2 >= 0 ? i - 2 : 0;
    final sub = recentScoresVsPar.sublist(start, i + 1);
    movingAvg.add(sub.reduce((a, b) => a + b) / sub.length);
  }

  double? scoreTrend;
  if (recentScoresVsPar.length > 1) {
    final latest = recentScoresVsPar.last;
    final prevAvg = recentScoresVsPar.sublist(0, recentScoresVsPar.length - 1).reduce((a, b) => a + b) / (recentScoresVsPar.length - 1);
    scoreTrend = latest - prevAvg;
  }

  List<double> handicapHistory = [];
  if (rounds.length >= 3) {
    final historyRounds = rounds.take(20).toList().reversed.toList();
    for (int i = 0; i < historyRounds.length; i++) {
        final window = historyRounds.sublist(0, i + 1).reversed.toList();
        final hcp = HandicapCalculator.calculate(window.map((r) => (score: r.totalScore, coursePar: r.coursePar)).toList());
        if (hcp != null) handicapHistory.add(hcp);
    }
  }

  final courseStats = courseScores.entries.map((e) {
    final scores = e.value;
    final avg = scores.fold(0, (sum, s) => sum + s) / scores.length;
    final best = scores.reduce((a, b) => a < b ? a : b);
    final round = rounds.where((r) => r.courseName == e.key).first;
    final bestVsPar = best - round.coursePar;
    return CourseStat(
      courseName: e.key,
      roundsPlayed: scores.length,
      avgScore: avg,
      avgVsPar: avg - round.coursePar,
      bestScore: best,
      bestVsPar: bestVsPar,
    );
  }).toList()
    ..sort((a, b) => b.roundsPlayed.compareTo(a.roundsPlayed));

  return AdvancedStats(
    roundsPlayed: rounds.length,
    fairwayHitPercentage: fairwayHitPercentage,
    greensInRegulationPercentage: girPercentage,
    puttsPerRound: puttsPerHole * 18,
    penaltiesPerRound: penaltiesPerHole * 18,
    parAverages: parAvgs,
    front9Avg: front9Count > 0 ? (front9Sum / front9Count * 9) : 0,
    back9Avg: back9Count > 0 ? (back9Sum / back9Count * 9) : 0,
    roundsPlayedToHandicap: rounds.length,
    handicapIndex: handicapHistory.isNotEmpty ? handicapHistory.last : null,
    recentScores: recentScoresVsPar,
    handicapHistory: handicapHistory,
    movingAverage: movingAvg,
    front9Scores: front9Scores,
    back9Scores: back9Scores,
    scoreTrend: scoreTrend,
    nineHoleRoundsPlayed: nineHoleRoundsPlayed,
    eighteenHoleRoundsPlayed: eighteenHoleRoundsPlayed,
    nineHoleAvgVsPar: nineHoleRoundsPlayed > 0 ? nineHoleTotalVsPar / nineHoleRoundsPlayed : 0,
    eighteenHoleAvgVsPar: eighteenHoleRoundsPlayed > 0 ? eighteenHoleTotalVsPar / eighteenHoleRoundsPlayed : 0,
    courseStats: courseStats,
  );
});

final practiceAnalyticsProvider = FutureProvider<PracticeStats>((ref) async {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return PracticeStats.empty();

  final allSessions = await (database.select(database.practiceSessions)
        ..where((s) => s.userId.equals(user.id) & s.endTime.isNotNull())
        ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime, mode: drift.OrderingMode.desc)]))
      .get();

  if (allSessions.isEmpty) return PracticeStats.empty();

  final allShots = await database.select(database.practiceShots).get();

  final clubs = await (database.select(database.clubs)..where((c) => c.userId.equals(user.id))).get();

  int totalBalls = 0;
  Duration totalTime = Duration.zero;
  for (var s in allSessions) {
    totalBalls += s.totalBalls.toInt();
    if (s.endTime != null) {
      totalTime += s.endTime!.difference(s.startTime);
    }
  }

  final Map<int, List<db.PracticeShot>> shotsByClub = {};
  for (var shot in allShots) {
    if (allSessions.any((s) => s.id == shot.sessionId)) {
      shotsByClub.putIfAbsent(shot.clubId, () => []).add(shot);
    }
  }

  final List<ClubPracticeStat> clubBreakdown = [];
  String mostPracticedClub = '—';
  int maxBalls = 0;
  String bestAccuracyClub = '—';
  double maxAccuracy = -1.0;

  for (var clubId in shotsByClub.keys) {
    final club = clubs.firstWhere(
      (c) => c.id == clubId, 
      orElse: () => db.Club(
        id: 0, 
        userId: '', 
        type: 'Unknown', 
        createdAt: DateTime.now(),
      ),
    );
    if (club.id == 0) continue;

    final shots = shotsByClub[clubId] ?? [];
    double accuracySum = 0;
    for (var s in shots) {
      switch (s.quality) {
        case 'GREAT': accuracySum += 1.0; break;
        case 'GOOD': accuracySum += 0.8; break;
        case 'OKAY': accuracySum += 0.5; break;
        default: accuracySum += 0.0;
      }
    }
    final accuracy = shots.isNotEmpty ? (accuracySum / shots.length) * 100 : 0.0;
    final avgDist = shots.isNotEmpty ? shots.fold(0.0, (sum, s) => sum + (s.distance ?? 0)) / shots.length : 0.0;

    clubBreakdown.add(ClubPracticeStat(
      clubName: club.type,
      ballsHit: shots.length,
      accuracy: accuracy,
      avgDistance: avgDist,
    ));

    if (shots.length > maxBalls) {
      maxBalls = shots.length;
      mostPracticedClub = club.type;
    }
    if (accuracy > maxAccuracy && shots.length >= 5) {
      maxAccuracy = accuracy;
      bestAccuracyClub = club.type;
    }
  }

  final List<double> accuracyTrend = [];
  final List<int> ballsHitTrend = [];
  final recentSessions = allSessions.take(10).toList().reversed;
  for (var session in recentSessions) {
    final sShots = allShots.where((s) => s.sessionId == session.id).toList();
    ballsHitTrend.add(session.totalBalls);
    if (sShots.isEmpty) {
      accuracyTrend.add(0.0);
      continue;
    }
    double sAccSum = 0;
    for (var s in sShots) {
       switch (s.quality) {
        case 'GREAT': sAccSum += 1.0; break;
        case 'GOOD': sAccSum += 0.8; break;
        case 'OKAY': sAccSum += 0.5; break;
        default: sAccSum += 0.0;
      }
    }
    accuracyTrend.add((sAccSum / sShots.length) * 100);
  }

  final now = DateTime.now();
  final firstOfMonth = DateTime(now.year, now.month, 1);
  final totalBallsThisMonth = allSessions
      .where((s) => s.startTime.isAfter(firstOfMonth))
      .fold(0, (sum, s) => sum + s.totalBalls);

  return PracticeStats(
    totalSessions: allSessions.length,
    totalTime: totalTime,
    totalBalls: totalBalls,
    clubBreakdown: clubBreakdown..sort((a, b) => b.ballsHit.compareTo(a.ballsHit)),
    accuracyTrend: accuracyTrend,
    ballsHitTrend: ballsHitTrend,
    mostPracticedClub: mostPracticedClub,
    bestAccuracyClub: bestAccuracyClub,
    totalBallsThisMonth: totalBallsThisMonth,
  );
});
