
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

  /// Net Double Bogey for a hole in a nine-hole round (front or back nine).
  ///
  /// Strokes are spread over nine holes using the nine-hole stroke index
  /// (1-9, the small number printed on Kenyan cards). The nine-hole course
  /// handicap is half the 18-hole one.
  static int calculateESCCapNine(int holePar, int playerCourseHandicap, int nineHoleStrokeIndex) {
    final effectiveCH = playerCourseHandicap > 0 ? playerCourseHandicap : 36;
    final nineCH = (effectiveCH / 2).round();
    final baseStrokes = (nineCH / 9).floor();
    final extraStroke = (nineHoleStrokeIndex <= (nineCH % 9)) ? 1 : 0;
    return holePar + 2 + baseStrokes + extraStroke;
  }

  /// Nine-hole stroke indexes for the holes of one nine, in play order.
  ///
  /// Uses the card's nine-hole index where the club entered it. Otherwise
  /// ranks the holes by their 18-hole index (hardest = 1), which is how the
  /// nine-hole allocation is normally derived. Holes with no index at all
  /// fall back to play order.
  static List<int> nineHoleStrokeIndexes(List<int?> nineHoleIndexes, List<int?> strokeIndexes) {
    final n = nineHoleIndexes.length;
    final complete = nineHoleIndexes.every((v) => v != null) &&
        (nineHoleIndexes.cast<int>().toSet().length == n);
    if (complete) return nineHoleIndexes.cast<int>();

    final order = List<int>.generate(n, (i) => i)
      ..sort((a, b) {
        final sa = strokeIndexes[a] ?? 99 + a;
        final sb = strokeIndexes[b] ?? 99 + b;
        return sa.compareTo(sb);
      });
    final result = List<int>.filled(n, 0);
    for (var rank = 0; rank < n; rank++) {
      result[order[rank]] = rank + 1;
    }
    return result;
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
  /// Highest Handicap Index a player can have (Rule 5.2).
  static const double maxHandicapIndex = 54.0;

  /// Adjustment for scoring records shorter than 20 (Rule 5.2a table).
  static double fewerThan20Adjustment(int count) => switch (count) {
        3 => -2.0,
        4 => -1.0,
        6 => -1.0,
        _ => 0.0,
      };

  /// The Handicap Index from differentials in play order (oldest first).
  ///
  /// Rules of Handicapping 2024:
  /// - 5.2: average of the lowest 8 of the most recent 20 differentials,
  ///   with no multiplier (the old 0.96 "bonus for excellence" was dropped
  ///   in 2020); fewer than 20 use the 5.2a table, and at least 3 scores
  ///   (54 holes) are needed before there's an index at all; max 54.0.
  /// - 5.9: an exceptional score (7.0+ below the index before it) lowers
  ///   the most recent 20 differentials by 1 (or 2 at 10.0+), which keeps
  ///   applying until those rounds leave the window. The deprecated
  ///   [latestScoreDiff]/[previousIndex] parameters are ignored: the
  ///   reduction is worked out from the full history instead.
  /// - 5.8: soft cap above +3.0 and hard cap at +5.0 over [lowIndex].
  static double? calculateHandicapIndex(List<double> allDifferentials, {double? lowIndex, double? latestScoreDiff, double? previousIndex}) {
    final adjusted = <double>[];
    for (final d in allDifferentials) {
      final before = _indexOf(adjusted);
      adjusted.add(d);
      if (before == null) continue;
      final esr = calculateExceptionalScoreReduction(d, before);
      if (esr == 0) continue;
      final from = adjusted.length > 20 ? adjusted.length - 20 : 0;
      for (var i = from; i < adjusted.length; i++) {
        adjusted[i] += esr;
      }
    }
    var result = _indexOf(adjusted);
    if (result == null) return null;
    if (lowIndex != null) result = applyYearlyCap(result, lowIndex);
    return (result.clamp(-10.0, maxHandicapIndex) * 10).roundToDouble() / 10;
  }

  /// Index from the most recent 20 differentials, before caps. Null under 3.
  static double? _indexOf(List<double> diffs) {
    final recent = diffs.length > 20 ? diffs.sublist(diffs.length - 20) : diffs;
    final count = recent.length;
    if (count < 3) return null;
    final best = (List<double>.from(recent)..sort()).sublist(0, _getDifferentialsToUse(count));
    final average = best.reduce((a, b) => a + b) / best.length;
    return average + fewerThan20Adjustment(count);
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

  /// 9-hole Course Handicap (WHS 2024, Rule 6.1b)
  /// CH9 = (Handicap Index / 2) x (9-hole Slope / 113) + (9-hole Course Rating - 9-hole Par)
  /// Without 9-hole ratings, uses half the 18-hole rating and the 18-hole slope.
  static int calculateNineHoleCourseHandicap({
    required double handicapIndex,
    required int slopeRating,
    required double courseRating,
    required int par,
    int? nineSlopeRating,
    double? nineCourseRating,
    int? ninePar,
  }) {
    final slope = (nineSlopeRating ?? 0) > 0 ? nineSlopeRating! : slopeRating;
    final rating = (nineCourseRating ?? 0) > 0 ? nineCourseRating! : courseRating / 2;
    final p = ninePar ?? (par / 2).round();
    if (slope == 0) return (handicapIndex / 2).round();
    return ((handicapIndex / 2) * (slope / 113) + (rating - p)).round();
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

