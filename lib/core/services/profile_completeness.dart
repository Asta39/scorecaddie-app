/// Pure helpers for deciding whether a server `User` row represents someone
/// who has already finished onboarding, and for building sync payloads that
/// don't erase server data. Unit-tested in test/profile_completeness_test.dart.
library;

/// Whether the server `User` row belongs to someone who already onboarded.
///
/// The `profileComplete` flag alone isn't trustworthy: until the fix that
/// shipped with this helper, every coach/caddie sync upserted
/// `profileComplete: null`, wiping it, and accounts from before onboarding
/// existed never had it set at all. So also accept evidence only an
/// established account can have:
/// - role coach or caddie, which is only ever set by provider onboarding
/// - at least one recorded round
/// - the account is older than [returningAfter]. Role selection is for
///   brand-new sign-ups; someone signing back into an account that has
///   existed for weeks goes home, even if they skipped onboarding back then.
bool isServerProfileComplete(
  Map<String, dynamic>? row, {
  bool hasRounds = false,
  DateTime? now,
  Duration returningAfter = const Duration(days: 1),
}) {
  if (hasRounds) return true;
  if (row == null) return false;
  if (row['profileComplete'] == true) return true;
  final role = (row['role'] as String?)?.toLowerCase();
  if (role == 'coach' || role == 'caddie') return true;

  final created = _parseUtc(row['createdAt']);
  if (created == null) return false;
  return (now ?? DateTime.now().toUtc()).difference(created) >= returningAfter;
}

/// `User.createdAt` is `timestamp without time zone` holding UTC, so it
/// arrives without an offset; read it as UTC rather than local time.
DateTime? _parseUtc(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  return DateTime.tryParse(hasZone ? value : '${value}Z')?.toUtc();
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
