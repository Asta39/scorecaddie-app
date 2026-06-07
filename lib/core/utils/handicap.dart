/// Handicap calculation utility.
///
/// This is a simplified calculator. For full WHS 2024 compliance with ESR,
/// soft/hard caps, and 9-hole support, use [WHSEngine.calculateHandicapIndex].
///
/// This calculator is kept for backward compatibility in 3 files:
/// - player_profile_screen.dart
/// - stats_providers.dart
/// - analytics_highlight_card_widget.dart
class HandicapCalculator {
  /// Calculate handicap index from a list of (score, coursePar) pairs.
  /// Returns null if no rounds are available.
  /// Uses simplified formula: (score - coursePar) as differential.
  static double? calculate(List<({int score, int coursePar})> rounds) {
    if (rounds.isEmpty) return null;

    final recent = rounds.length > 20 ? rounds.sublist(0, 20) : rounds;
    final differentials = recent
        .map((r) => (r.score - r.coursePar).toDouble())
        .toList()
      ..sort();

    final count = _getDiffCount(recent.length);
    if (count == 0) return null;

    final best = differentials.sublist(0, count);
    final avg = best.reduce((a, b) => a + b) / best.length;

    return double.parse(avg.toStringAsFixed(1));
  }

  static int _getDiffCount(int totalRounds) {
    if (totalRounds < 1) return 0;
    if (totalRounds <= 5) return 1;
    if (totalRounds == 6) return 2;
    if (totalRounds <= 8) return 2;
    if (totalRounds <= 11) return 3;
    if (totalRounds <= 14) return 4;
    if (totalRounds <= 16) return 5;
    if (totalRounds <= 18) return 6;
    if (totalRounds == 19) return 7;
    return 8;
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
