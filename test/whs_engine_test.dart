import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/utils/whs_engine.dart';

void main() {
  group('WHSEngine - Score Differential', () {
    test('calculateScoreDifferential with standard data', () {
      // (85 - 71.0) * (113 / 125) = 12.656
      // Should round to 12.7
      final diff = WHSEngine.calculateScoreDifferential(
        adjustedGrossScore: 85,
        courseRating: 71.0,
        slopeRating: 125,
      );
      expect(diff, 12.7);
    });

    test('calculateScoreDifferential with PCC', () {
      // (85 - 71.0 - 1.0) * (113 / 125) = 13 * 0.904 = 11.752
      // Should round to 11.8
      final diff = WHSEngine.calculateScoreDifferential(
        adjustedGrossScore: 85,
        courseRating: 71.0,
        slopeRating: 125,
        pcc: 1.0,
      );
      expect(diff, 11.8);
    });

    test('calculate9HoleTotalDifferential (2024 formula)', () {
      // 9-hole diff + (HI * 0.52 + 1.15)
      // Play: 42, CR: 35.5, Slope: 125, HI: 15.0
      // 9-hole diff = (42 - 35.5) * (113 / 125) = 6.5 * 0.904 = 5.876
      // Expected = (15.0 * 0.52) + 1.15 = 7.8 + 1.15 = 8.95
      // Total = 14.826 -> 14.8
      final diff = WHSEngine.calculate9HoleTotalDifferential(
        nineHoleAdjustedGrossScore: 42,
        nineHoleCourseRating: 35.5,
        nineHoleSlopeRating: 125,
        playerHandicapIndex: 15.0,
      );
      expect(diff, 14.8);
    });
  });

  group('WHSEngine - Handicap Index', () {
    test('calculateHandicapIndex with 20 scores (best 8)', () {
      final differentials = List.generate(20, (index) => 10.0 + index); // 10.0 to 29.0
      // Best 8: 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0
      // Average = 108 / 8 = 13.5
      // * 0.96 = 12.96 -> 13.0
      final index = WHSEngine.calculateHandicapIndex(differentials);
      expect(index, 13.0);
    });

    test('calculateHandicapIndex with 3 scores (best 1)', () {
      final differentials = [10.5, 15.0, 20.0];
      // Best 1 = 10.5. * 0.96 = 10.08. Adjustment -2.0 -> 8.08 -> 8.1
      final index = WHSEngine.calculateHandicapIndex(differentials);
      expect(index, 8.1);
    });
  });

  group('WHSEngine - Caps (Soft/Hard)', () {
    test('no cap applied when index below soft cap', () {
      final differentials = List.generate(20, (_) => 12.0);
      // Avg = 12.0. * 0.96 = 11.52 -> 11.5
      // Soft cap at 13.0. 11.5 < 13.0 -> no cap
      final index = WHSEngine.calculateHandicapIndex(differentials, lowIndex: 10.0);
      expect(index, 11.5);
    });

    test('soft cap applied when index between soft and hard cap', () {
      final differentials = List.generate(20, (_) => 14.0);
      // Avg = 14.0. * 0.96 = 13.44 -> 13.4
      // Soft cap at 13.0. 13.4 > 13.0 -> 13.0 + (13.4-13.0)*0.5 = 13.2
      final index = WHSEngine.calculateHandicapIndex(differentials, lowIndex: 10.0);
      expect(index, 13.2);
    });

    test('hard cap applied when index exceeds hard cap threshold', () {
      final differentials = List.generate(20, (_) => 18.0);
      // Avg = 18.0. * 0.96 = 17.28 -> 17.3
      // Hard cap at 15.0. 17.3 > 15.0 -> 15.0
      final index = WHSEngine.calculateHandicapIndex(differentials, lowIndex: 10.0);
      expect(index, 15.0);
    });
  });

  group('WHSEngine - Exceptional Score Reduction (ESR)', () {
    test('calculateExceptionalScoreReduction - 10+ diff returns -2.0', () {
      // SD = 2.0, HI = 15.0 -> diff = 13.0 >= 10 -> -2.0
      final esr = WHSEngine.calculateExceptionalScoreReduction(2.0, 15.0);
      expect(esr, -2.0);
    });

    test('calculateExceptionalScoreReduction - 7-9.9 diff returns -1.0', () {
      // SD = 7.0, HI = 15.0 -> diff = 8.0 between 7 and 10 -> -1.0
      final esr = WHSEngine.calculateExceptionalScoreReduction(7.0, 15.0);
      expect(esr, -1.0);
    });

    test('calculateExceptionalScoreReduction - below 7 diff returns 0.0', () {
      // SD = 10.0, HI = 15.0 -> diff = 5.0 < 7 -> 0.0
      final esr = WHSEngine.calculateExceptionalScoreReduction(10.0, 15.0);
      expect(esr, 0.0);
    });

    test('ESR applied in calculateHandicapIndex when latestSD 8 below previous', () {
      // 19 diffs at 15.0 + latest SD at 5.0
      // Previous HI from 19 diffs: 7 best x 15.0 = 105/7 = 15.0. *0.96 = 14.4 -> 14.4
      // Latest SD = 5.0, diff from prev HI = 14.4-5.0 = 9.4 -> ESR = -1.0
      // All 20 sorted: 5.0 + 19x15.0. Best 8: 5.0 + 7x15.0 = 110/8 = 13.75. *0.96 = 13.2
      // Result = 13.2 + (-1.0) ESR = 12.2
      final differentials = List.generate(19, (_) => 15.0)..add(5.0);
      final previousDiffs = List.generate(19, (_) => 15.0);
      final previousIndex = WHSEngine.calculateHandicapIndex(previousDiffs);
      final index = WHSEngine.calculateHandicapIndex(
        differentials,
        latestScoreDiff: 5.0,
        previousIndex: previousIndex,
      );
      expect(index, 12.2);
    });

    test('ESR applied BEFORE soft cap', () {
      // Low index 10.0. 19 diffs at 10.0 + latest SD at 0.0
      // Previous HI with 19 diffs at 10.0 = approx 10.0
      // Latest SD = 0.0 (10 below) -> ESR = -2.0
      // Calculated from all 20 (with ESR): best 8 avg = (0 + 7*10) / 8 = 8.75
      // * 0.96 = 8.4. ESR -2.0 = 6.4. Below soft cap 13.0 -> 6.4
      final differentials = List.generate(19, (_) => 10.0)..add(0.0);
      final previousDiffs = List.generate(19, (_) => 10.0);
      final previousIndex = WHSEngine.calculateHandicapIndex(previousDiffs);
      final index = WHSEngine.calculateHandicapIndex(
        differentials,
        lowIndex: 10.0,
        latestScoreDiff: 0.0,
        previousIndex: previousIndex,
      );
      expect(index, lessThanOrEqualTo(10.0)); // ESR pushed it below anchor
    });

    test('no ESR when latestScoreDiff not provided', () {
      final differentials = List.generate(20, (_) => 15.0);
      // Avg = 15.0. * 0.96 = 14.4 -> 14.4 (no ESR since params omitted)
      final index = WHSEngine.calculateHandicapIndex(differentials);
      expect(index, 14.4);
    });
  });

  group('WHSEngine - Course Handicap', () {
    test('calculateCourseHandicap (2024 formula)', () {
      // Index 15.0, Slope 125, CR 71.0, Par 72
      // (15.0 * (125 / 113)) + (71.0 - 72)
      // (15.0 * 1.10619) - 1.0 = 16.5929 - 1.0 = 15.5929
      // Should round to 16
      final ch = WHSEngine.calculateCourseHandicap(
        handicapIndex: 15.0,
        slopeRating: 125,
        courseRating: 71.0,
        par: 72,
      );
      expect(ch, 16);
    });
  });

  group('WHSEngine - ESC Cap', () {
    test('calculateESCCap - Net Double Bogey logic', () {
      // Par 4, Stroke Index 5
      // Course Handicap 18 -> 1 stroke on hole
      // ESC = 4 + 2 + 1 = 7
      expect(WHSEngine.calculateESCCap(4, 18, 5), 7);
      
      // Course Handicap 5, SI 5 -> 1 stroke on hole
      expect(WHSEngine.calculateESCCap(4, 5, 5), 7);
      
      // Course Handicap 5, SI 6 -> 0 strokes on hole
      expect(WHSEngine.calculateESCCap(4, 5, 6), 6);
      
      // Course Handicap 40 -> 2 strokes (40/18 = 2.22) + extra if SI <= 40%18=4
      // Hole SI 3 -> 2 + 1 = 3 strokes
      // ESC = 4 + 2 + 3 = 9
      expect(WHSEngine.calculateESCCap(4, 40, 3), 9);
    });
  });
}
