
/// The "Math Brain" of Score Caddie.
/// Implements official 2024 World Handicap System (WHS) formulas.
class WHSEngine {

  // ── Step 1: ESC Cap per hole ──────────────────────────────
  /// Net Double Bogey = par + 2 + player's handicap strokes on that hole
  static int calculateESCCap(int holePar, int playerCourseHandicap, int holeStrokeIndex) {
    // If no course handicap yet, use 36 (default max) to allow initial data entry
    final effectiveCH = playerCourseHandicap > 0 ? playerCourseHandicap : 36;
    
    // Strokes received on this hole:
    // (effectiveCH / 18) is the base number of strokes for every hole.
    // (effectiveCH % 18) are the extra strokes distributed to hardest holes.
    final baseStrokes = (effectiveCH / 18).floor();
    final extraStroke = (holeStrokeIndex <= (effectiveCH % 18)) ? 1 : 0;
    
    final strokesOnHole = baseStrokes + extraStroke;
    
    return holePar + 2 + strokesOnHole; 
  }

  // ── Step 2: Score Differential ───────────────────────────
  /// Standard 18-hole Score Differential formula.
  static double calculateScoreDifferential({
    required int adjustedGrossScore,
    required double courseRating,
    required int slopeRating,
    double pcc = 0.0,
  }) {
    if (slopeRating == 0) return 0.0;
    final diff = (adjustedGrossScore - courseRating - pcc) * (113 / slopeRating);
    return (diff * 10).roundToDouble() / 10;
  }

  /// 2024 WHS 9-hole to 18-hole transformation.
  /// scales a 9-hole score up using the "Expected Score" method.
  static double calculate9HoleTotalDifferential({
    required int nineHoleAdjustedGrossScore,
    required double nineHoleCourseRating,
    required int nineHoleSlopeRating,
    required double playerHandicapIndex,
    double pcc = 0.0,
  }) {
    if (nineHoleSlopeRating == 0) return playerHandicapIndex;

    // 1. Calculate 9-hole differential for the played holes
    final nineHoleDiff = (nineHoleAdjustedGrossScore - nineHoleCourseRating - (0.5 * pcc)) * (113 / nineHoleSlopeRating);
    
    // 2. Add Expected Score Differential for the other 9 holes
    // WHS 2024 standardized formula approximation: (HI * 0.52) + 1.15
    final expectedDiffForOther9 = (playerHandicapIndex * 0.52) + 1.15;
    
    final totalDiff = nineHoleDiff + expectedDiffForOther9;
    return (totalDiff * 10).roundToDouble() / 10;
  }

  // ── Step 3: Handicap Index ───────────────────────────────
  /// Calculates the Handicap Index from a list of differentials.
  /// Applies 20th score window, the "Best 8" logic, and WHS Caps if [lowIndex] is provided.
  /// If [latestScoreDiff] and [previousIndex] are provided, applies Exceptional Score Reduction (ESR)
  /// before the soft/hard cap check per WHS 2024 rules.
  static double? calculateHandicapIndex(List<double> allDifferentials, {double? lowIndex, double? latestScoreDiff, double? previousIndex}) {
    if (allDifferentials.isEmpty) return null;
    
    // Only use the 20 most recent scores
    final recent = allDifferentials.length > 20
        ? allDifferentials.sublist(allDifferentials.length - 20)
        : allDifferentials;

    final count = recent.length;
    final numToUse = _getDifferentialsToUse(count);
    if (numToUse == 0) return null;

    final sorted = List<double>.from(recent)..sort();
    final best = sorted.sublist(0, numToUse);
    final average = best.reduce((a, b) => a + b) / best.length;
    
    // Apply 0.96 multiplier (as per user design requirement)
    // Note: Official WHS 2024 usually uses 1.0, but we follow the design spec here.
    double result = average * 0.96;

    // Apply WHS adjustments for fewer than 20 scores
    double adjustment = 0.0;
    if (count == 3) {
      adjustment = -2.0;
    } else if (count == 4) {
      adjustment = -1.0;
    } else if (count == 6) {
      adjustment = -1.0;
    }

    result = result + adjustment;

    // Apply Exceptional Score Reduction (ESR) before cap check
    // WHS 2024: if latest SD is 7.0+ below previous HI, reduce index by -1.0 or -2.0
    if (latestScoreDiff != null && previousIndex != null) {
      result += calculateExceptionalScoreReduction(latestScoreDiff, previousIndex);
    }

    // Apply WHS Caps (Soft/Hard) if a Low Index (Anchor) is available
    if (lowIndex != null) {
      result = applyYearlyCap(result, lowIndex);
    }

    return (result * 10).roundToDouble() / 10;
  }

  // ── Step 4: Caps & Anchoring ─────────────────────────────
  
  /// WHS Soft & Hard Cap logic based on the lowest index in the past year.
  static double applyYearlyCap(double newIndex, double lowestIndexPastYear) {
    final softCap = lowestIndexPastYear + 3.0;
    final hardCap = lowestIndexPastYear + 5.0;

    if (newIndex <= softCap) return newIndex;
    
    if (newIndex >= hardCap) return hardCap;

    // Soft cap: Reduces any increase above 3.0 by 50%
    final result = softCap + (newIndex - softCap) * 0.5;
    return (result * 10).roundToDouble() / 10;
  }

  /// Exceptional Score Reduction (ESR)
  /// Applies a bonus reduction if a score is significantly better than current index.
  static double calculateExceptionalScoreReduction(double scoreDiff, double currentIndex) {
    final difference = currentIndex - scoreDiff;
    if (difference >= 10.0) {
      return -2.0;
    }
    if (difference >= 7.0) {
      return -1.0;
    }
    return 0.0;
  }

  // ── Step 5: Course & Playing Handicap ─────────────────────

  /// Course Handicap (2024 formula)
  /// CH = (Handicap Index x (Slope Rating / 113)) + (Course Rating - Par)
  static int calculateCourseHandicap({
    required double handicapIndex,
    required int slopeRating,
    required double courseRating,
    required int par,
  }) {
    if (slopeRating == 0) {
      return handicapIndex.round();
    }
    final ch = (handicapIndex * (slopeRating / 113)) + (courseRating - par);
    return ch.round();
  }

  /// Playing Handicap
  /// PH = Course Handicap x Handicap Allowance
  /// Common allowance: 0.95 for Individual Stroke Play, 0.85 for 4-ball.
  static int calculatePlayingHandicap(int courseHandicap, double allowance) {
    return (courseHandicap * allowance).round();
  }

  static int _getDifferentialsToUse(int count) {
    if (count < 1) {
      return 0;
    }
    if (count >= 1 && count <= 5) {
      return 1;
    }
    if (count == 6) {
      return 2;
    }
    if (count >= 7 && count <= 8) {
      return 2;
    }
    if (count >= 9 && count <= 11) {
      return 3;
    }
    if (count >= 12 && count <= 14) {
      return 4;
    }
    if (count >= 15 && count <= 16) {
      return 5;
    }
    if (count >= 17 && count <= 18) {
      return 6;
    }
    if (count == 19) {
      return 7;
    }
    return 8; 
  }
}

