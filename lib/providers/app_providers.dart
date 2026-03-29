import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/database/database.dart' as db;
import '../core/firebase/firebase_service.dart';
import '../core/models/analytics_models.dart';
import '../core/services/ai_analyzer_service.dart';
import 'package:drift/drift.dart' as drift;
import '../core/services/profile_service.dart';
import '../core/services/friend_service.dart';
import '../core/cloud/sync_service.dart';
import '../core/utils/handicap.dart';
import '../core/services/achievement_service.dart';
export '../core/services/achievement_service.dart';

// ─── Database Provider ─────────────────────────────────────────────────────

final databaseProvider = Provider<db.AppDatabase>((ref) {
  final database = db.AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

// ─── Firebase Auth Provider ────────────────────────────────────────────────

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

// ─── Courses Provider ──────────────────────────────────────────────────────

final coursesProvider = StreamProvider<List<db.Course>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  return database.watchAllCourses(user?.uid);
});

// ─── Rounds Provider ───────────────────────────────────────────────────────

final roundsProvider = StreamProvider<List<db.Round>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return database.watchAllRounds(user.uid);
});

final recentRoundsProvider = FutureProvider<List<db.Round>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return database.getRecentRounds(user.uid, limit: 5);
});

final chartRoundsProvider = FutureProvider<List<db.Round>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];
  return database.getRecentRounds(user.uid, limit: 10);
});

// ─── Stats Providers ───────────────────────────────────────────────────────

final totalRoundsProvider = FutureProvider<int>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;
  return database.getTotalRoundsCount(user.uid);
});

final averageScoreProvider = FutureProvider<double?>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return database.getAverageScore(user.uid);
});

final bestScoreProvider = FutureProvider<int?>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return database.getBestScore(user.uid);
});

// ─── Navigation Index Provider ─────────────────────────────────────────────

final navIndexProvider = StateProvider<int>((ref) => 0);

final singleRoundProvider = FutureProvider.family<db.Round, int>((ref, id) {
  final database = ref.watch(databaseProvider);
  return database.getRound(id);
});

final holeScoresProvider = FutureProvider.family<List<db.HoleScore>, int>((ref, roundId) {
  final database = ref.watch(databaseProvider);
  return database.getHoleScoresForRound(roundId);
});

// ─── Service Providers ───────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  return SyncService(database, user?.uid);
});

final friendServiceProvider = Provider<FriendService>((ref) {
  final database = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  return FriendService(database, sync, user?.uid);
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref);
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(
    db: ref.watch(databaseProvider),
    ref: ref,
  );
});

// ─── User Profile & Settings ───────────────────────────────────────────────

final userProfileProvider = StreamProvider<db.UserProfile?>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  
  // Combine Firestore and Local DB for best resilience
  return FirebaseFirestore.instance
      .collection('profiles')
      .doc(user.uid)
      .snapshots()
      .asyncMap((doc) async {
        if (doc.exists) {
          final data = doc.data()!;
          // Sync firestore data to local DB
          await database.upsertProfile(db.UserProfilesCompanion(
            firebaseUid: drift.Value(user.uid),
            email: drift.Value(data['email'] as String?),
            name: drift.Value(data['name'] as String? ?? 'Golfer'),
            avatarUrl: drift.Value(data['avatarUrl'] as String?),
            skillLevel: drift.Value(data['skillLevel'] as String?),
            homeCourseName: drift.Value(data['homeCourse'] as String?),
            privacyLevel: drift.Value(data['privacyLevel'] as String? ?? 'Private'),
            units: drift.Value(data['units'] as String? ?? 'Yards'),
            themeMode: drift.Value(data['themeMode'] as String? ?? 'System'),
            role: drift.Value(data['role'] as String?),
            profileComplete: drift.Value(data['profileComplete'] as bool? ?? false),
            handicap: drift.Value((data['handicap'] as num?)?.toDouble()),
            updatedAt: drift.Value(DateTime.now()),
          ));
          return database.getProfile(user.uid);
        } else {
          return database.getProfile(user.uid);
        }
      });
});

final specificUserProfileProvider = StreamProvider.family<db.UserProfile?, String>((ref, userId) {
  final database = ref.watch(databaseProvider);
  return database.watchProfile(userId);
});


final clubsProvider = StreamProvider<List<db.Club>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return (database.select(database.clubs)..where((c) => c.userId.equals(user.uid))).watch();
});

final friendsProvider = StreamProvider<List<db.Friend>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return (database.select(database.friends)..where((f) => f.userId.equals(user.uid))).watch();
});

final friendRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamIncomingRequests();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final mode = profile?.themeMode ?? 'Light'; // Default to Light as requested
  
  switch (mode) {
    // Note: The user explicitly said "default should be light mode"
    // and "then if the user wants they can change it to system".
    case 'Dark': return ThemeMode.dark;
    case 'Light': return ThemeMode.light;
    case 'System': return ThemeMode.system;
    default: return ThemeMode.light;
  }
});

final advancedStatsProvider = FutureProvider<AdvancedStats>((ref) async {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return AdvancedStats.empty();

  // Watch roundsProvider to make this provider reactive to new rounds
  final rounds = ref.watch(roundsProvider).valueOrNull ?? [];
  if (rounds.isEmpty) return AdvancedStats.empty();

  final holeScores = await database.getUserHoleScores(user.uid);
  
  // Group hole scores by round for easier calculation
  final scoresByRound = <int, List<db.HoleScore>>{};
  for (var score in holeScores) {
    scoresByRound.putIfAbsent(score.roundId, () => []).add(score);
  }

  // Calculate Metrics
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

  for (var round in rounds) {
    final rScores = scoresByRound[round.id] ?? [];
    for (var s in rScores) {
      // Fairway Hit (only if par > 3)
      if (s.par > 3) {
        if (s.fairwayHit != null) {
          totalFairwaysTracked++;
          if (s.fairwayHit == 'Hit') totalFairwaysHit++;
        }
      }
      
      // GIR (Greens in Regulation)
      // Standard logic: par - 2 shots to reach green.
      // If score - putts <= par - 2, it's a GIR.
      if (s.putts != null) {
        totalHolesWithDetailedStats++;
        totalPutts += s.putts!;
        if (s.score - s.putts! <= s.par - 2) {
          totalGIR++;
        }
      }
      
      if (s.penalties != null) totalPenalties += s.penalties!;

      // Par Averages
      if (parScores.containsKey(s.par)) {
        parScores[s.par]!.add(s.score);
      }

      // Front vs Back 9
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
  
  // Stats per hole
  final puttsPerHole = totalHolesWithDetailedStats > 0 ? totalPutts / totalHolesWithDetailedStats : 0.0;
  final penaltiesPerHole = totalHolesWithDetailedStats > 0 ? totalPenalties / totalHolesWithDetailedStats : 0.0;
  
  final parAvgs = parScores.map((par, scores) => MapEntry(par, scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length));

  // Recent Scores (Last 20) - Chronological order for chart
  final recentRounds = rounds.take(20).toList().reversed.toList();
  final recentScoresVsPar = recentRounds.map((r) => (r.totalScore - r.coursePar).toDouble()).toList();
  final front9Scores = recentRounds.map((r) => (r.front9Score ?? 0).toDouble()).toList();
  final back9Scores = recentRounds.map((r) => (r.back9Score ?? 0).toDouble()).toList();
  
  // Moving Average (Period 3)
  List<double> movingAvg = [];
  for (int i = 0; i < recentScoresVsPar.length; i++) {
    int start = i - 2 >= 0 ? i - 2 : 0;
    final sub = recentScoresVsPar.sublist(start, i + 1);
    movingAvg.add(sub.reduce((a, b) => a + b) / sub.length);
  }

  // Trend (Latest round vs average of the rest of the recent rounds)
  double? scoreTrend;
  if (recentScoresVsPar.length > 1) {
    final latest = recentScoresVsPar.last;
    final prevAvg = recentScoresVsPar.sublist(0, recentScoresVsPar.length - 1).reduce((a, b) => a + b) / (recentScoresVsPar.length - 1);
    scoreTrend = latest - prevAvg;
  }

  // Handicap History (Calculate sliding window handicap for last 20 rounds)
  List<double> handicapHistory = [];
  if (rounds.length >= 3) {
    // We need at least a few rounds to show a trend
    final historyRounds = rounds.take(20).toList().reversed.toList();
    for (int i = 0; i < historyRounds.length; i++) {
        final window = historyRounds.sublist(0, i + 1).reversed.toList();
        final hcp = HandicapCalculator.calculate(window.map((r) => (score: r.totalScore, coursePar: r.coursePar)).toList());
        if (hcp != null) handicapHistory.add(hcp);
    }
  }

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
  );
});

final practiceAnalyticsProvider = FutureProvider<PracticeStats>((ref) async {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return PracticeStats.empty();

  // Watch sessions to be reactive
  final allSessions = await (database.select(database.practiceSessions)
        ..where((s) => s.userId.equals(user.uid) & s.endTime.isNotNull())
        ..orderBy([(t) => drift.OrderingTerm(expression: t.startTime, mode: drift.OrderingMode.desc)]))
      .get();

  if (allSessions.isEmpty) return PracticeStats.empty();

  final allShots = await database.select(database.practiceShots).get();

  final clubs = await (database.select(database.clubs)..where((c) => c.userId.equals(user.uid))).get();

  // Basic stats
  int totalBalls = 0;
  Duration totalTime = Duration.zero;
  for (var s in allSessions) {
    totalBalls += s.totalBalls.toInt();
    if (s.endTime != null) {
      totalTime += s.endTime!.difference(s.startTime);
    }
  }

  // Club breakdown
  final Map<int, List<db.PracticeShot>> shotsByClub = {};
  for (var shot in allShots) {
    // Only include shots that belong to a completed session
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

  // Accuracy & Balls Trend (per session)
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

  // Monthly stats
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

final aiAnalyzerServiceProvider = Provider<AIAnalyzerService>((ref) {
  final svc = AIAnalyzerService();
  ref.onDispose(svc.dispose);
  return svc;
});

// ─── Marketplace Providers ──────────────────────────────────────────────────

final allProvidersProvider = StreamProvider<List<db.Provider>>((ref) {
  return FirebaseFirestore.instance
      .collection('providers')
      .where('profileComplete', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return db.Provider(
              id: 0, // Not used from firestore
              userId: doc.id,
              role: data['role'] ?? '',
              name: data['name'] ?? '',
              phone: data['phone'] ?? '',
              whatsapp: data['whatsapp'],
              experience: data['experience'] ?? 0,
              coursesJson: data['courses'] ?? '[]',
              specializationsJson: data['specializations'],
              availabilityJson: data['availability'] ?? '{}',
              price: (data['price'] as num?)?.toDouble(),
              rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
              totalReviews: data['totalReviews'] ?? 0,
              totalBookings: data['totalBookings'] ?? 0,
              totalCalls: data['totalCalls'] ?? 0,
              profileComplete: data['profileComplete'] ?? false,
              certificationUrl: data['certificationUrl'],
              bio: data['bio'],
              personalityType: data['personalityType'],
              coachingLocation: data['coachingLocation'],
              coachingStylesJson: data['coachingStyles'],
              sessionTypesJson: data['sessionTypes'],
              hasCertification: data['hasCertification'] ?? false,
              certificationName: data['certificationName'],
              views: data['views'] ?? 0,
              streak: data['streak'] ?? 0,
              isAvailable: data['isAvailable'] ?? true,
              createdAt: DateTime.now(), // Placeholder
            );
          }).toList());
});

final interactionsProvider = StreamProvider<List<db.Interaction>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return (database.select(database.interactions)
        ..where((i) => i.playerId.equals(user.uid))
        ..orderBy([(t) => drift.OrderingTerm(expression: t.timestamp, mode: drift.OrderingMode.asc)]))
      .watch();
});

final pendingInteractionsProvider = Provider<AsyncValue<List<db.Interaction>>>((ref) {
  final interactions = ref.watch(interactionsProvider);
  return interactions.whenData((list) => list.where((i) => i.status == 'pending').toList());
});

final recentProsProvider = StreamProvider<List<db.Provider>>((ref) {
  final interactions = ref.watch(interactionsProvider).valueOrNull ?? [];
  final bookedProviderIds = interactions
      .where((i) => i.status == 'booked')
      .map((i) => i.providerId)
      .toSet()
      .toList();
  
  if (bookedProviderIds.isEmpty) return Stream.value([]);
  
  final database = ref.watch(databaseProvider);
  return (database.select(database.providers)
        ..where((p) => p.userId.isIn(bookedProviderIds)))
      .watch();
});

final providerInteractionsProvider = StreamProvider<List<db.Interaction>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('interactions')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return db.Interaction(
              id: 0,
              playerId: data['playerId'],
              providerId: data['providerId'],
              type: data['type'],
              status: data['status'],
              timestamp: DateTime.parse(data['timestamp']),
              lastPromptedAt: data['lastPromptedAt'] != null ? DateTime.parse(data['lastPromptedAt']) : null,
            );
          }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
});

final providerReviewsProvider = StreamProvider.family<List<db.Review>, String>((ref, providerId) {
  // Pull reviews from firestore for real-time
  return FirebaseFirestore.instance
      .collection('reviews')
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return db.Review(
              id: 0,
              providerId: data['providerId'],
              playerId: data['playerId'],
              playerName: data['playerName'],
              playerAvatar: data['playerAvatar'],
              rating: data['rating'],
              comment: data['comment'],
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
});

final currentProviderProvider = StreamProvider<db.Provider?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  
  return FirebaseFirestore.instance
      .collection('providers')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        return db.Provider(
          id: 0,
          userId: doc.id,
          role: data['role'] ?? '',
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          whatsapp: data['whatsapp'],
          experience: data['experience'] ?? 0,
          coursesJson: data['courses'] ?? '[]',
          specializationsJson: data['specializations'],
          availabilityJson: data['availability'] ?? '{}',
          price: (data['price'] as num?)?.toDouble(),
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          totalReviews: data['totalReviews'] ?? 0,
          totalBookings: data['totalBookings'] ?? 0,
          totalCalls: data['totalCalls'] ?? 0,
          profileComplete: data['profileComplete'] ?? false,
          certificationUrl: data['certificationUrl'],
          bio: data['bio'],
          personalityType: data['personalityType'],
          coachingLocation: data['coachingLocation'],
          coachingStylesJson: data['coachingStyles'],
          sessionTypesJson: data['sessionTypes'],
          hasCertification: data['hasCertification'] ?? false,
          certificationName: data['certificationName'],
          views: data['views'] ?? 0,
          streak: data['streak'] ?? 0,
          isAvailable: data['isAvailable'] ?? true,
          createdAt: DateTime.now(),
        );
      });
});
