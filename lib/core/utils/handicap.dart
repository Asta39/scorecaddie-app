/// Handicap calculation utility.
///
/// Uses simplified WHS-inspired formula:
/// 1. Take last 20 rounds (or all if fewer than 20)
/// 2. Calculate score differential for each: (score - course par) × (113 / slope rating)
///    (Using slope = 113 as default when not available, simplifying to score - par)
/// 3. Select best 8 differentials (or proportional number if fewer than 20 rounds)
/// 4. Average them → handicap index
class HandicapCalculator {
  /// Number of differentials to use based on total rounds available.
  static int _diffCount(int totalRounds) {
    if (totalRounds <= 3) return 1;
    if (totalRounds <= 4) return 1;
    if (totalRounds <= 5) return 1;
    if (totalRounds <= 6) return 2;
    if (totalRounds <= 8) return 2;
    if (totalRounds <= 11) return 3;
    if (totalRounds <= 14) return 4;
    if (totalRounds <= 16) return 5;
    if (totalRounds <= 18) return 6;
    if (totalRounds <= 19) return 7;
    return 8; // 20+
  }

  /// Calculate handicap index from a list of (score, coursePar) pairs.
  /// Returns null if no rounds are available.
  /// [rounds] should be ordered most recent first.
  static double? calculate(List<({int score, int coursePar})> rounds) {
    if (rounds.isEmpty) return null;

    // Take last 20 rounds
    final recent = rounds.length > 20 ? rounds.sublist(0, 20) : rounds;

    // Calculate differentials (score - par, simplified when no slope data)
    final differentials = recent
        .map((r) => (r.score - r.coursePar).toDouble())
        .toList()
      ..sort(); // Sort ascending — best (lowest) first

    // Pick best N differentials
    final count = _diffCount(recent.length);
    final best = differentials.sublist(0, count);

    // Average
    final avg = best.reduce((a, b) => a + b) / best.length;

    // Round to 1 decimal
    return double.parse(avg.toStringAsFixed(1));
  }

  /// Format handicap for display, e.g. "+2.3" or "14.7".
  static String format(double? handicap) {
    if (handicap == null) return '—';
    if (handicap < 0) return '+${handicap.abs().toStringAsFixed(1)}';
    if (handicap > 0) return handicap.toStringAsFixed(1);
    return '0.0';
  }

  /// Get score label for a hole relative to par.
  static String holeScoreLabel(int score, int par) {
    final diff = score - par;
    if (diff <= -2) return 'Eagle';
    if (diff == -1) return 'Birdie';
    if (diff == 0) return 'Par';
    if (diff == 1) return 'Bogey';
    if (diff == 2) return 'Double';
    return '+$diff';
  }
}
