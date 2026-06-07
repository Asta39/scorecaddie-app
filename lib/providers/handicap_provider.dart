import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../core/database/database.dart' hide Provider;
import '../core/utils/whs_engine.dart';
import 'app_providers.dart';

/// Data model for the calculated handicap status
class HandicapStatus {
  final double? currentIndex;
  final double? lowIndex;
  final List<int> bestRoundIds; // Local DB IDs of the rounds used in the best 8
  final double? lastIndex; // Index from 30 days ago for trend
  final int roundsNeededForUpdate;
  
  // New fields for calculation breakdown
  final double? bestSum;
  final double? bestAverage;
  final double? bestAverageWithMultiplier;

  HandicapStatus({
    this.currentIndex,
    this.lowIndex,
    this.bestRoundIds = const [],
    this.lastIndex,
    this.roundsNeededForUpdate = 0,
    this.bestSum,
    this.bestAverage,
    this.bestAverageWithMultiplier,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HandicapStatus &&
          runtimeType == other.runtimeType &&
          currentIndex == other.currentIndex &&
          lowIndex == other.lowIndex &&
          roundsNeededForUpdate == other.roundsNeededForUpdate &&
          lastIndex == other.lastIndex &&
          bestSum == other.bestSum &&
          bestAverage == other.bestAverage;

  @override
  int get hashCode =>
      Object.hash(currentIndex, lowIndex, roundsNeededForUpdate, lastIndex, bestSum, bestAverage);

  double get trend => (currentIndex != null && lastIndex != null) 
      ? (currentIndex! - lastIndex!) 
      : 0.0;
}

final handicapProvider = StreamProvider<HandicapStatus>((ref) {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  
  if (user == null) return Stream.value(HandicapStatus());

  final lowIndexAnchor = profile?.anchorIndex;

  // Watch all rounds for this user to trigger updates live
  return db.watchAllRounds(user.uid).map((allRounds) {
    // Filter out rounds marked as not for analytics (e.g. partial rounds)
    final rounds = allRounds.where((r) => r.useForAnalytics).toList();

    if (rounds.isEmpty) return HandicapStatus(lowIndex: lowIndexAnchor);

    // 1. Extract valid differentials
    final allDiffs = rounds
        .where((r) => r.scoreDifferential != null)
        .map((r) => r.scoreDifferential!)
        .toList()
        .reversed // Oldest to newest
        .cast<double>()
        .toList();

    // 2. Calculate Current HI (Applying Caps based on Anchor, with ESR)
    final latestSD = allDiffs.isNotEmpty ? allDiffs.last : null;
    final previousIndex = allDiffs.length > 1
        ? WHSEngine.calculateHandicapIndex(allDiffs.sublist(0, allDiffs.length - 1), lowIndex: lowIndexAnchor)
        : null;
    final currentHI = WHSEngine.calculateHandicapIndex(
      allDiffs,
      lowIndex: lowIndexAnchor,
      latestScoreDiff: latestSD,
      previousIndex: previousIndex,
    );

    // 3. Low HI Handling
    // If the newly calculated index is lower than the stored anchor, it potentially becomes the new anchor.
    // For the UI, we prioritize the profile's anchorIndex.
    final lowHI = lowIndexAnchor ?? currentHI;

    // 4. Identify the "Best 8" local rounds
    // We take the last 20, sort them, and pick the top N.
    final last20 = rounds.length > 20 ? rounds.sublist(0, 20) : rounds;
    final validLast20 = last20.where((r) => r.scoreDifferential != null).toList();
    
    // Sort by differential ascending
    final sorted = List<Round>.from(validLast20)
        ..sort((a, b) => a.scoreDifferential!.compareTo(b.scoreDifferential!));
    
    final numToUse = _getDifferentialsToUse(validLast20.length);
    final bestIds = sorted.take(numToUse).map((r) => r.id).toList().cast<int>();

    // 5. Trend (compared to index 30 days ago)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final oldDiffs = rounds
        .where((r) => r.playedAt.isBefore(thirtyDaysAgo) && r.scoreDifferential != null)
        .map((r) => r.scoreDifferential!)
        .cast<double>()
        .toList();
    
    // For trend, we calculate the HI as it was 30 days ago (no cap applied for trend baseline usually)
    final oldHI = WHSEngine.calculateHandicapIndex(oldDiffs);

    // 6. Calculate breakdown stats
    final bestRoundsForSum = validLast20.where((r) => bestIds.contains(r.id)).toList();
    final sum = bestRoundsForSum.isEmpty ? 0.0 : bestRoundsForSum.fold<double>(0, (a, b) => a + (b.scoreDifferential ?? 0));
    final avg = bestRoundsForSum.isEmpty ? 0.0 : sum / bestRoundsForSum.length;
    final avgWithMultiplier = avg * 0.96;

    return HandicapStatus(
      currentIndex: currentHI,
      lowIndex: lowHI,
      bestRoundIds: bestIds,
      lastIndex: oldHI,
      roundsNeededForUpdate: rounds.length < 3 ? (3 - rounds.length) : 0,
      bestSum: sum,
      bestAverage: avg,
      bestAverageWithMultiplier: avgWithMultiplier,
    );
  });
});

class RoundWithTee {
  final Round round;
  final Tee? tee;
  RoundWithTee(this.round, this.tee);
}

final last20RoundsProvider = StreamProvider<List<RoundWithTee>>((ref) {
  final db = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  
  // Watch recent rounds and map them to include Tee info
  return db.watchRecentRounds(user.uid, limit: 20).asyncMap((rounds) async {
    final results = <RoundWithTee>[];
    for (final r in rounds) {
      Tee? tee;
      if (r.teeId != null) {
        tee = await db.getTeeById(r.teeId!);
      }
      results.add(RoundWithTee(r, tee));
    }
    return results;
  });
});

/// Provider that monitors handicap changes and persists them to the local database
/// and cloud to ensure the profile's anchorIndex and currentIndex are always robust.
/// This fulfills WHS 2024 compliance for Low Handicap Index tracking.
final handicapTrackerProvider = Provider<void>((ref) {
  ref.listen(handicapProvider, (previous, next) {
    final status = next.valueOrNull;
    if (status == null || status.currentIndex == null) return;
    
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;

    final currentAnchor = profile.anchorIndex;
    final calculatedHI = status.currentIndex!;
    
    // Check if current handicap or anchor needs update
    final bool handicapMismatch = profile.handicap != calculatedHI;
    final bool newAnchorFound = (currentAnchor == null || calculatedHI < currentAnchor);

    if (handicapMismatch || newAnchorFound) {
      debugPrint('WHS: Updating Handicap Index to $calculatedHI ${newAnchorFound ? '(New Low/Anchor)' : ''}');
      
      final profileService = ref.read(profileServiceProvider);
      profileService.updateProfile(
        profile.uid!, 
        UserProfilesCompanion(
          handicap: drift.Value(calculatedHI),
          anchorIndex: drift.Value(newAnchorFound ? calculatedHI : currentAnchor),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }
  });
});

int _getDifferentialsToUse(int count) {
  if (count < 1) return 0;
  if (count >= 1 && count <= 5) return 1;
  if (count == 6) return 2;
  if (count >= 7 && count <= 8) return 2;
  if (count >= 9 && count <= 11) return 3;
  if (count >= 12 && count <= 14) return 4;
  if (count >= 15 && count <= 16) return 5;
  if (count >= 17 && count <= 18) return 6;
  if (count == 19) return 7;
  return 8; 
}
