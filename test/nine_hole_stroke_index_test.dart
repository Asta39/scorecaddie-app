import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/utils/whs_engine.dart';

void main() {
  group('nineHoleStrokeIndexes', () {
    test('uses the card nine-hole index when complete', () {
      // Nyeri Course 1, front nine: large SI and small SI from the card.
      final si18 = [9, 17, 5, 1, 11, 15, 13, 3, 7];
      final si9 = [3, 9, 5, 1, 7, 8, 6, 2, 4];
      expect(WHSEngine.nineHoleStrokeIndexes(si9, si18), si9);
    });

    test('derives by ranking the 18-hole index when missing', () {
      final si18 = [9, 17, 5, 1, 11, 15, 13, 3, 7];
      expect(
        WHSEngine.nineHoleStrokeIndexes(List.filled(9, null), si18),
        [5, 9, 3, 1, 6, 8, 7, 2, 4],
      );
    });

    test('ignores a partial or duplicated nine-hole index', () {
      final si18 = [2, 4, 6, 8, 10, 12, 14, 16, 18];
      final partial = [1, null, 3, 4, 5, 6, 7, 8, 9];
      final dupes = [1, 1, 3, 4, 5, 6, 7, 8, 9];
      final ranked = [1, 2, 3, 4, 5, 6, 7, 8, 9];
      expect(WHSEngine.nineHoleStrokeIndexes(partial, si18), ranked);
      expect(WHSEngine.nineHoleStrokeIndexes(dupes, si18), ranked);
    });
  });

  group('calculateESCCapNine', () {
    test('CH 22 gives 11 strokes over nine: 2 on SI 1-2, 1 elsewhere', () {
      expect(WHSEngine.calculateESCCapNine(4, 22, 1), 4 + 2 + 2);
      expect(WHSEngine.calculateESCCapNine(4, 22, 2), 4 + 2 + 2);
      expect(WHSEngine.calculateESCCapNine(4, 22, 3), 4 + 2 + 1);
    });

    test('CH 10 gives 5 strokes on nine-hole SI 1-5', () {
      expect(WHSEngine.calculateESCCapNine(3, 10, 5), 3 + 2 + 1);
      expect(WHSEngine.calculateESCCapNine(3, 10, 6), 3 + 2);
    });
  });
}
