import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/services/profile_completeness.dart';

void main() {
  group('isServerProfileComplete', () {
    test('explicit flag counts', () {
      expect(isServerProfileComplete({'profileComplete': true, 'role': 'PLAYER'}), isTrue);
    });

    test('no row and no rounds is a new user', () {
      expect(isServerProfileComplete(null), isFalse);
    });

    test('regression: coach whose flag was wiped to null is still complete', () {
      // Provider syncs upserted profileComplete: null. The role survived.
      expect(isServerProfileComplete({'profileComplete': null, 'role': 'COACH'}), isTrue);
    });

    test('caddie role counts, any case', () {
      expect(isServerProfileComplete({'role': 'caddie'}), isTrue);
      expect(isServerProfileComplete({'role': 'CADDIE'}), isTrue);
    });

    test('player with no flag and no rounds is incomplete', () {
      expect(isServerProfileComplete({'profileComplete': false, 'role': 'PLAYER'}), isFalse);
      expect(isServerProfileComplete({'role': 'PLAYER'}), isFalse);
    });

    test('recorded rounds count as evidence of onboarding', () {
      expect(isServerProfileComplete({'role': 'PLAYER'}, hasRounds: true), isTrue);
      expect(isServerProfileComplete(null, hasRounds: true), isTrue);
    });

    test('admin roles alone do not mark a player profile complete', () {
      expect(isServerProfileComplete({'role': 'club_admin'}), isFalse);
    });
  });

  group('withoutNulls', () {
    test('drops null values', () {
      expect(withoutNulls({'a': 1, 'b': null}), {'a': 1});
    });

    test('keeps falsy but real values', () {
      expect(
        withoutNulls({'flag': false, 'count': 0, 'text': ''}),
        {'flag': false, 'count': 0, 'text': ''},
      );
    });

    test('regression: an omitted profileComplete is not sent at all', () {
      final payload = withoutNulls({'id': 'u1', 'name': 'Tarly', 'profileComplete': null});
      expect(payload.containsKey('profileComplete'), isFalse);
      expect(payload, {'id': 'u1', 'name': 'Tarly'});
    });
  });
}
