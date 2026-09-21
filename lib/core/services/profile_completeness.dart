/// Pure helpers for deciding whether a server `User` row represents someone
/// who has already finished onboarding, and for building sync payloads that
/// don't erase server data. Unit-tested in test/profile_completeness_test.dart.
library;

/// Whether the server `User` row belongs to someone who already onboarded.
///
/// The `profileComplete` flag alone isn't trustworthy: until the fix that
/// shipped with this helper, every coach/caddie sync upserted
/// `profileComplete: null`, wiping it. So also accept evidence only an
/// onboarded account can have:
/// - role coach or caddie, which is only ever set by provider onboarding
/// - at least one recorded round
bool isServerProfileComplete(Map<String, dynamic>? row, {bool hasRounds = false}) {
  if (hasRounds) return true;
  if (row == null) return false;
  if (row['profileComplete'] == true) return true;
  final role = (row['role'] as String?)?.toLowerCase();
  return role == 'coach' || role == 'caddie';
}

/// Drops null values so an upsert only writes fields we actually have.
///
/// PostgREST upserts write every key they're given. Sending `null` for a
/// field the caller simply didn't supply erased real server data. That is
/// how `profileComplete` kept getting wiped.
Map<String, dynamic> withoutNulls(Map<String, dynamic> payload) => {
      for (final entry in payload.entries)
        if (entry.value != null) entry.key: entry.value,
    };
