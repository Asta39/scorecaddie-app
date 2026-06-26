import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Single source of truth for the current user's identity across the app.
///
/// The app previously mixed Supabase Auth UUIDs (format: `550e8400-...`) with
/// legacy Firebase UIDs (format: `JSuaD2Vam...`). Firebase has been fully
/// removed — all identity is now Supabase Auth.
///
/// Use [currentUid] everywhere instead of accessing `supabase.auth.currentUser?.id`
/// directly, so that any future identity changes are isolated to this class.
class IdentityResolver {
  static const _legacyFirebaseUidPattern = r'^[A-Za-z0-9_-]{20,40}$';

  /// Returns the current Supabase Auth UUID, or null if not signed in.
  static String? get currentUid {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Returns true if the app is currently authenticated.
  static bool get isAuthenticated => currentUid != null;

  /// Checks whether a stored user ID looks like a legacy Firebase UID
  /// rather than a Supabase UUID. Firebase UIDs are 20–40 alphanumeric
  /// chars without hyphens in a UUID-style pattern.
  ///
  /// Use this during data repair to identify rows that need re-mapping.
  static bool isLegacyFirebaseUid(String? uid) {
    if (uid == null) return false;
    // Supabase UUIDs are exactly 36 chars with 4 hyphens (e.g. 550e8400-...-...)
    final isUUID = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(uid);
    final looksLikeFirebase = RegExp(
      _legacyFirebaseUidPattern,
      caseSensitive: true,
    ).hasMatch(uid) && !isUUID;
    return looksLikeFirebase;
  }

  /// Logs a warning if a UID that should be a Supabase UUID looks like
  /// a legacy Firebase UID. Call this at auth-critical points during dev.
  static void assertSupabaseUid(String? uid, {String context = ''}) {
    if (kDebugMode && uid != null && isLegacyFirebaseUid(uid)) {
      debugPrint(
        '[IdentityResolver] ⚠️ WARNING: Detected possible legacy Firebase UID '
        '"$uid" in context: "$context". '
        'All UIDs should be Supabase Auth UUIDs since Firebase was removed.',
      );
    }
  }
}
