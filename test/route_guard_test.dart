import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/core/router/route_guard.dart';

/// Shorthand for resolveRedirect with sensible defaults.
String? go(
  String location, {
  bool authLoading = false,
  bool loggedIn = true,
  ProfileState profile = ProfileState.complete,
  String? role = 'player',
}) =>
    resolveRedirect(
      location: location,
      authLoading: authLoading,
      isLoggedIn: loggedIn,
      profile: profile,
      role: role,
    );

/// Every route shape the guard cares about.
const allLocations = [
  '/splash',
  '/auth',
  '/login-callback',
  '/loading',
  '/select-role',
  '/player-onboarding',
  '/provider-onboarding',
  '/',
  '/practice',
  '/analytics',
  '/competitions',
  '/profile',
  '/coach/sessions',
  '/coach/students',
  '/coach/drills',
  '/coach/session/abc',
  '/coaching/session/abc',
  '/book-tee-time',
  '/restaurant',
];

void main() {
  group('regression: existing user sent to role select after login', () {
    test('signed-in user whose profile is still syncing is parked, not sent to onboarding', () {
      // The reported bug: straight after login the local profile didn't exist
      // yet and was read as "incomplete".
      expect(go('/auth', profile: ProfileState.resolving), holdingRoute);
      expect(go('/', profile: ProfileState.resolving), holdingRoute);
    });

    test('full login sequence for a returning user never touches /select-role', () {
      // 1. Just authenticated, still on the sign-in screen, profile resolving.
      final afterLogin = go('/auth', profile: ProfileState.resolving);
      expect(afterLogin, holdingRoute);

      // 2. Parked on the holding screen while the bootstrap runs.
      expect(go(afterLogin!, profile: ProfileState.resolving), isNull);

      // 3. Bootstrap finds the completed server profile.
      expect(go(afterLogin, profile: ProfileState.complete), homeRoute);
    });

    test('a genuinely new user still reaches role select once resolved', () {
      final afterLogin = go('/auth', profile: ProfileState.resolving);
      expect(go(afterLogin!, profile: ProfileState.incomplete), roleSelectRoute);
    });
  });

  group('splash and auth loading', () {
    test('splash is never redirected, whatever the state', () {
      for (final loggedIn in [true, false]) {
        for (final profile in ProfileState.values) {
          expect(go('/splash', loggedIn: loggedIn, profile: profile), isNull);
        }
      }
    });

    test('no redirect while the session is being restored', () {
      for (final location in allLocations) {
        expect(go(location, authLoading: true), isNull, reason: location);
      }
    });
  });

  group('signed out', () {
    test('public routes are reachable', () {
      expect(go('/auth', loggedIn: false), isNull);
      expect(go('/login-callback', loggedIn: false), isNull);
    });

    test('every non-public route sends to /auth', () {
      for (final location in allLocations) {
        if (location == '/splash' || publicRoutes.contains(location)) continue;
        for (final profile in ProfileState.values) {
          expect(go(location, loggedIn: false, profile: profile), authRoute,
              reason: '$location / $profile');
        }
      }
    });

    test('security: a signed-out user can only ever stay on a public route', () {
      for (final location in allLocations) {
        if (location == '/splash') continue;
        for (final profile in ProfileState.values) {
          final result = go(location, loggedIn: false, profile: profile, role: 'coach');
          final landsOn = result ?? location;
          expect(publicRoutes.contains(landsOn), isTrue, reason: '$location / $profile -> $landsOn');
        }
      }
    });
  });

  group('signed in, profile resolving', () {
    test('everything is parked on the holding screen', () {
      for (final location in allLocations) {
        if (location == '/splash') continue;
        final expected = location == holdingRoute ? isNull : equals(holdingRoute);
        expect(go(location, profile: ProfileState.resolving), expected, reason: location);
      }
    });
  });

  group('signed in, profile complete', () {
    test('sign-in, holding and onboarding screens go home', () {
      for (final location in [
        '/auth',
        '/login-callback',
        '/loading',
        '/select-role',
        '/player-onboarding',
        '/provider-onboarding',
      ]) {
        expect(go(location), homeRoute, reason: location);
      }
    });

    test('app routes are left alone', () {
      for (final location in ['/', '/practice', '/analytics', '/profile', '/restaurant', '/book-tee-time']) {
        expect(go(location), isNull, reason: location);
      }
    });

    test('coach routes are coach-only', () {
      expect(go('/coach/sessions', role: 'player'), homeRoute);
      expect(go('/coach/session/abc', role: 'caddie'), homeRoute);
      expect(go('/coach/drills', role: null), homeRoute);
      expect(go('/coach/sessions', role: 'coach'), isNull);
    });

    test('role check is case-insensitive (server stores COACH)', () {
      expect(go('/coach/students', role: 'COACH'), isNull);
    });

    test('player-facing /coaching/ session view stays open to players', () {
      expect(go('/coaching/session/abc', role: 'player'), isNull);
    });
  });

  group('signed in, profile incomplete', () {
    test('onboarding routes are reachable', () {
      for (final location in onboardingRoutes) {
        expect(go(location, profile: ProfileState.incomplete), isNull, reason: location);
      }
    });

    test('security: no app route can be deep-linked before onboarding', () {
      for (final location in allLocations) {
        if (location == '/splash' || onboardingRoutes.contains(location)) continue;
        expect(go(location, profile: ProfileState.incomplete, role: 'coach'), roleSelectRoute,
            reason: location);
      }
    });
  });

  group('deriveProfileState', () {
    test('resolving until the bootstrap has finished', () {
      expect(
        deriveProfileState(currentUid: 'a', bootstrapFinished: false, profileLoaded: true, profileUid: 'a', profileComplete: true),
        ProfileState.resolving,
      );
    });

    test('resolving until the profile stream has emitted', () {
      expect(
        deriveProfileState(currentUid: 'a', bootstrapFinished: true, bootstrapUid: 'a', profileLoaded: false),
        ProfileState.resolving,
      );
    });

    test('complete when both belong to the current user', () {
      expect(
        deriveProfileState(currentUid: 'a', bootstrapFinished: true, bootstrapUid: 'a', profileLoaded: true, profileUid: 'a', profileComplete: true),
        ProfileState.complete,
      );
    });

    test('incomplete when resolved and not onboarded', () {
      expect(
        deriveProfileState(currentUid: 'a', bootstrapFinished: true, bootstrapUid: 'a', profileLoaded: true, profileUid: 'a'),
        ProfileState.incomplete,
      );
    });

    test('resolved with no local profile at all counts as incomplete', () {
      expect(
        deriveProfileState(currentUid: 'a', bootstrapFinished: true, bootstrapUid: 'a', profileLoaded: true),
        ProfileState.incomplete,
      );
    });

    test('security: account switch never routes on the previous user\'s bootstrap', () {
      // Riverpod keeps the old value while reloading for the new user.
      expect(
        deriveProfileState(currentUid: 'new', bootstrapFinished: true, bootstrapUid: 'old', profileLoaded: true, profileUid: 'new', profileComplete: true),
        ProfileState.resolving,
      );
    });

    test('security: account switch never routes on the previous user\'s profile', () {
      expect(
        deriveProfileState(currentUid: 'new', bootstrapFinished: true, bootstrapUid: 'new', profileLoaded: true, profileUid: 'old', profileComplete: true),
        ProfileState.resolving,
      );
    });
  });

  test('isCoachOnlyRoute', () {
    expect(isCoachOnlyRoute('/coach/sessions'), isTrue);
    expect(isCoachOnlyRoute('/coach/session/1/edit'), isTrue);
    expect(isCoachOnlyRoute('/coaching/session/1'), isFalse);
    expect(isCoachOnlyRoute('/coach'), isFalse);
    expect(isCoachOnlyRoute('/'), isFalse);
  });
}
