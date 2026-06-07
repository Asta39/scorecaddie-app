import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/utils/handicap.dart';

void main() {
  group('HandicapCalculator - calculate', () {
    test('returns null for empty rounds', () {
      expect(HandicapCalculator.calculate([]), null);
    });

    test('calculates from single round', () {
      final rounds = [(score: 85, coursePar: 72)];
      final result = HandicapCalculator.calculate(rounds);
      expect(result, 13.0); // 85 - 72 = 13
    });

    test('calculates best of 1 for 1-3 rounds', () {
      final rounds = [
        (score: 100, coursePar: 72),
        (score: 90, coursePar: 72),
        (score: 95, coursePar: 72),
      ];
      // Best: 90 - 72 = 18
      final result = HandicapCalculator.calculate(rounds);
      expect(result, 18.0);
    });

    test('calculates best of 2 for 6 rounds', () {
      final rounds = List.generate(6, (i) => (score: 80 + i, coursePar: 72));
      // Best 2: 80, 81 -> differentials 8, 9 -> avg = 8.5
      final result = HandicapCalculator.calculate(rounds);
      expect(result, 8.5);
    });

    test('calculates best of 8 for 20+ rounds', () {
      final rounds = List.generate(20, (i) => (score: 70 + i, coursePar: 72));
      // Best 8: 70-77 -> differentials -2 to 5 -> avg = 1.5
      final result = HandicapCalculator.calculate(rounds);
      expect(result, 1.5);
    });

    test('uses only last 20 rounds', () {
      // Put newer 20 rounds with higher scores (85), and older 5 rounds with lower scores (72).
      // Since index 0 is newest, first 20 elements (indices 0-19) are used.
      final rounds = List.generate(25, (i) => i < 20 ? (score: 85, coursePar: 72) : (score: 72, coursePar: 72));
      final result = HandicapCalculator.calculate(rounds);
      // Best 8 of first 20: all 85 -> differential 13.0
      expect(result, 13.0);
    });
  });

  group('HandicapCalculator - format', () {
    test('returns dash for null', () {
      expect(HandicapCalculator.format(null), '—');
    });

    test('formats negative as plus', () {
      expect(HandicapCalculator.format(-2.5), '+2.5');
    });

    test('formats positive normally', () {
      expect(HandicapCalculator.format(15.3), '15.3');
    });

    test('formats zero', () {
      expect(HandicapCalculator.format(0.0), '0.0');
    });
  });

  group('HandicapCalculator - holeScoreLabel', () {
    test('returns Eagle for -2', () {
      expect(HandicapCalculator.holeScoreLabel(2, 4), 'Eagle');
    });

    test('returns Birdie for -1', () {
      expect(HandicapCalculator.holeScoreLabel(3, 4), 'Birdie');
    });

    test('returns Par for 0', () {
      expect(HandicapCalculator.holeScoreLabel(4, 4), 'Par');
    });

    test('returns Bogey for +1', () {
      expect(HandicapCalculator.holeScoreLabel(5, 4), 'Bogey');
    });

    test('returns Double for +2', () {
      expect(HandicapCalculator.holeScoreLabel(6, 4), 'Double');
    });

    test('returns +N for +3 and above', () {
      expect(HandicapCalculator.holeScoreLabel(8, 4), '+4');
    });
  });
}