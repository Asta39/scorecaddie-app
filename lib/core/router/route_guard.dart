/// Pure routing rules for GoRouter's `redirect`.
///
/// Kept free of Flutter/Riverpod imports so every rule is unit-testable
/// (see test/route_guard_test.dart). app_router.dart gathers the live state
/// and delegates the decision here.
library;

const String splashRoute = '/splash';
const String holdingRoute = '/loading';
const String authRoute = '/auth';
const String homeRoute = '/';
const String roleSelectRoute = '/select-role';

/// Reachable while signed out.
const Set<String> publicRoutes = {authRoute, '/login-callback'};

/// Reachable only while signed in with an incomplete profile.
const Set<String> onboardingRoutes = {
  roleSelectRoute,
  '/player-onboarding',
  '/provider-onboarding',
};

/// Where the signed-in user's profile stands, from the router's point of view.
enum ProfileState {
  /// Not known yet: the startup profile check hasn't finished, or the local
  /// profile stream hasn't emitted a first value. Must never be read as
  /// "incomplete". Doing exactly that sent existing users to role select
  /// straight after login, before their profile had synced down.
  resolving,

  /// Signed in, profile resolved, onboarding not finished (or no profile).
  incomplete,

  /// Signed in and onboarded.
  complete,
}

/// Routes only a coach may open. `/coaching/...` is the player-facing view
/// of a coach's session and stays open to everyone signed in.
bool isCoachOnlyRoute(String location) => location.startsWith('/coach/');

/// Decides where to send the user, or null to stay put.
String? resolveRedirect({
  required String location,
  required bool authLoading,
  required bool isLoggedIn,
  required ProfileState profile,
  String? role,
}) {
  // Splash plays its animation, then navigates itself.
  if (location == splashRoute) return null;

  // Don't guess while the auth session is still being restored.
  if (authLoading) return null;

  // Signed out: only public routes. Everything else, including the holding
  // screen and onboarding, requires a session.
  if (!isLoggedIn) {
    return publicRoutes.contains(location) ? null : authRoute;
  }

  // Signed in, but we don't yet know whether they've onboarded. Park on the
  // holding screen instead of guessing.
  if (profile == ProfileState.resolving) {
    return location == holdingRoute ? null : holdingRoute;
  }

  if (profile == ProfileState.complete) {
    // Nothing to do on sign-in, holding or onboarding screens anymore.
    if (publicRoutes.contains(location) ||
        location == holdingRoute ||
        onboardingRoutes.contains(location)) {
      return homeRoute;
    }
    // Role gate. Supabase RLS still protects the data; this stops a player
    // landing on a half-broken coach screen via a deep link.
    if (isCoachOnlyRoute(location) && role?.toLowerCase() != 'coach') {
      return homeRoute;
    }
    return null;
  }

  // Incomplete: onboarding is the only place to be.
  return onboardingRoutes.contains(location) ? null : roleSelectRoute;
}

/// Derives [ProfileState] from plain inputs, so the account-switch rule below
/// is unit-testable without Riverpod.
///
/// On a reload (including switching accounts on the same device) Riverpod
/// keeps the previous value while the new one loads. Without the uid checks
/// the router could send a new user home on the previous user's completed
/// profile. Only route on state that belongs to [currentUid].
ProfileState deriveProfileState({
  required String? currentUid,
  required bool bootstrapFinished,
  String? bootstrapUid,
  required bool profileLoaded,
  String? profileUid,
  bool profileComplete = false,
}) {
  if (!bootstrapFinished || bootstrapUid != currentUid) return ProfileState.resolving;
  if (!profileLoaded) return ProfileState.resolving;
  if (profileUid != null && profileUid != currentUid) return ProfileState.resolving;
  return profileComplete ? ProfileState.complete : ProfileState.incomplete;
}
