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

    final now = DateTime.utc(2026, 9, 26, 17, 20);

    test('regression: an account from months ago that never set the flag goes home', () {
      // The real case: created 4 July, PLAYER, profileComplete false, no rounds.
      final row = {'role': 'PLAYER', 'profileComplete': false, 'createdAt': '2026-07-04T08:56:37.879'};
      expect(isServerProfileComplete(row, now: now), isTrue);
    });

    test('a brand-new sign-up still goes to role selection', () {
      final row = {'role': 'PLAYER', 'profileComplete': false, 'createdAt': '2026-09-26T17:18:00'};
      expect(isServerProfileComplete(row, now: now), isFalse);
    });

    test('createdAt without an offset is read as UTC, not local time', () {
      // 23h59m old in UTC: still new.
      final row = {'role': 'PLAYER', 'createdAt': '2026-09-25T17:21:00'};
      expect(isServerProfileComplete(row, now: now), isFalse);
      final older = {'role': 'PLAYER', 'createdAt': '2026-09-25T17:19:00+00:00'};
      expect(isServerProfileComplete(older, now: now), isTrue);
    });

    test('missing or malformed createdAt is not treated as old', () {
      expect(isServerProfileComplete({'role': 'PLAYER'}, now: now), isFalse);
      expect(isServerProfileComplete({'role': 'PLAYER', 'createdAt': 'nope'}, now: now), isFalse);
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
