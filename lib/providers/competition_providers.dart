import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/competition.dart';
import 'auth_providers.dart';

// ─── Supabase client shorthand ────────────────────────────────────────────────
final _supabase = Supabase.instance.client;

// ─── Club ID helper ───────────────────────────────────────────────────────────
// Reads the player's home club from the player_home_club view.
final playerHomeClubIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final row = await _supabase
      .from('player_home_club')
      .select('home_club_id')
      .eq('player_id', user.id)
      .maybeSingle();
  return row?['home_club_id'] as String?;
});

// ─── Competitions list for a club ─────────────────────────────────────────────
final competitionsForClubProvider =
    StreamProvider.family<List<Competition>, String>((ref, clubId) {
  return _supabase
      .from('competitions')
      .stream(primaryKey: ['id'])
      .eq('club_id', clubId)
      .order('start_date', ascending: false)
      .map((rows) => rows
          .map(Competition.fromJson)
          .where((c) => !c.isTemplate)
          .toList());
});

// ─── All competitions for the current user's home club ────────────────────────
// NOTE: This is a convenience alias — callers can also use
// competitionsForClubProvider(clubId) directly if they already have the clubId.
final myClubCompetitionsProvider =
    StreamProvider<List<Competition>>((ref) {
  final clubIdAsync = ref.watch(playerHomeClubIdProvider);
  return clubIdAsync.when(
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
    data: (clubId) {
      if (clubId == null) return Stream.value([]);
      return _supabase
          .from('competitions')
          .stream(primaryKey: ['id'])
          .eq('club_id', clubId)
          .order('start_date', ascending: false)
          .map((rows) => rows
              .map(Competition.fromJson)
              .where((c) => !c.isTemplate)
              .toList());
    },
  );
});

// ─── Single competition detail ────────────────────────────────────────────────
final competitionDetailProvider =
    FutureProvider.family<Competition?, String>((ref, competitionId) async {
  final row = await _supabase
      .from('competitions')
      .select()
      .eq('id', competitionId)
      .maybeSingle();
  if (row == null) return null;
  return Competition.fromJson(row);
});

// ─── Entries for a competition ────────────────────────────────────────────────
final competitionEntriesProvider =
    StreamProvider.family<List<CompetitionEntry>, String>((ref, competitionId) {
  return _supabase
      .from('competition_entries')
      .stream(primaryKey: ['id'])
      .eq('competition_id', competitionId)
      .order('created_at')
      .asyncMap((rows) async {
    // Enrich each entry with player profile data
    final enriched = <CompetitionEntry>[];
    for (final row in rows) {
      final playerId = row['player_id'] as String;
      final profile = await _supabase
          .from('User')
          .select('name, "handicapIndex", "avatarUrl"')
          .eq('id', playerId)
          .maybeSingle();
      enriched.add(CompetitionEntry.fromJson({
        ...row,
        'full_name': profile?['name'],
        'handicap_index': profile?['handicapIndex'],
        'avatar_url': profile?['avatarUrl'],
      }));
    }
    return enriched;
  });
});

// ─── Current user's entry for a competition ───────────────────────────────────
final myEntryProvider =
    FutureProvider.family<CompetitionEntry?, String>((ref, competitionId) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final row = await _supabase
      .from('competition_entries')
      .select()
      .eq('competition_id', competitionId)
      .eq('player_id', user.id)
      .maybeSingle();
  if (row == null) return null;
  return CompetitionEntry.fromJson(row);
});

// ─── Starting sheet (view — FutureProvider) ──────────────────────────────
final startingSheetProvider =
    FutureProvider.family<List<StartingSheetRow>, String>((ref, competitionId) async {
  final rows = await _supabase
      .from('competition_starting_sheet')
      .select()
      .eq('competition_id', competitionId)
      .order('tee_time');
  return rows.map(StartingSheetRow.fromJson).toList();
});

// ─── Leaderboard (view — FutureProvider) ────────────────────────────────
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardRow>, String>((ref, competitionId) async {
  final rows = await _supabase
      .from('competition_leaderboard')
      .select()
      .eq('competition_id', competitionId);
  return rows.map(LeaderboardRow.fromJson).toList();
});

// ─── Actions notifier ─────────────────────────────────────────────────────────
@immutable
class CompetitionActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const CompetitionActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  CompetitionActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return CompetitionActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class CompetitionActionsNotifier
    extends StateNotifier<CompetitionActionState> {
  final Ref ref;

  CompetitionActionsNotifier(this.ref)
      : super(const CompetitionActionState());

  void clearMessages() {
    state = const CompetitionActionState();
  }

  /// Player enters a competition.
  Future<bool> enterCompetition({
    required String competitionId,
    required double playingHandicap,
    required num entryFee,
    String? mpesaPhone,
    String? teeColor,
    String? flightName,
  }) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      if (entryFee > 0) {
        if (mpesaPhone == null || mpesaPhone.isEmpty) {
          state = state.copyWith(isLoading: false, errorMessage: 'M-Pesa phone number is required.');
          return false;
        }

        // Simulate successful payment directly inserting to DB
        await _supabase.from('competition_entries').insert({
          'competition_id': competitionId,
          'player_id': user.id,
          'playing_handicap': playingHandicap,
          'tee_color': teeColor,
          'flight_name': flightName,
          'entry_status': 'confirmed',
          'payment_status': 'paid',
          'mpesa_phone_number': mpesaPhone,
          'paystack_reference': 'SIMULATED-${DateTime.now().millisecondsSinceEpoch}',
        });
        state = state.copyWith(
            isLoading: false, successMessage: 'M-Pesa payment simulated successfully! Entry confirmed.');
        return true;
      } else {
        // Free entry
        await _supabase.from('competition_entries').insert({
          'competition_id': competitionId,
          'player_id': user.id,
          'playing_handicap': playingHandicap,
          'tee_color': teeColor,
          'flight_name': flightName,
          'entry_status': 'confirmed',
          'payment_status': 'paid',
        });
        state = state.copyWith(
            isLoading: false, successMessage: 'Entry submitted and confirmed successfully!');
        return true;
      }
    } catch (e) {
      debugPrint('CompetitionActions: enterCompetition error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to enter competition: $e');
      return false;
    }
  }

  /// Player withdraws from a competition.
  Future<bool> withdrawFromCompetition(String entryId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase
          .from('competition_entries')
          .update({'entry_status': 'withdrawn'})
          .eq('id', entryId);
      state = state.copyWith(
          isLoading: false, successMessage: 'Withdrawn from competition.');
      return true;
    } catch (e) {
      debugPrint('CompetitionActions: withdrawFromCompetition error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to withdraw: $e');
      return false;
    }
  }

  /// Admin confirms a pending entry.
  Future<bool> confirmEntry({
    required String entryId,
    required String confirmedBy,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.from('competition_entries').update({
        'entry_status': 'confirmed',
        'confirmed_by': confirmedBy,
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('id', entryId);
      state = state.copyWith(isLoading: false, successMessage: 'Entry confirmed.');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to confirm: $e');
      return false;
    }
  }

  /// Admin submits/updates a scanned scorecard result.
  Future<bool> submitResult({
    required String competitionId,
    required String entryId,
    required String playerId,
    required int grossScore,
    required double netScore,
    int? stablefordPoints,
    required List<Map<String, dynamic>> scorecard,
    required bool certified,
    String? certifiedBy,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.from('competition_results').upsert({
        'competition_id': competitionId,
        'entry_id': entryId,
        'player_id': playerId,
        'gross_score': grossScore,
        'net_score': netScore,
        'stableford_points': stablefordPoints,
        'scorecard': scorecard,
        'result_status': 'active',
        'certified': certified,
        'certified_by': certifiedBy,
        'certified_at': certified ? DateTime.now().toIso8601String() : null,
      }, onConflict: 'competition_id,player_id');

      if (certified) {
        try {
          // Fetch competition details to map courseId and courseName
          final compRow = await _supabase
              .from('competitions')
              .select()
              .eq('id', competitionId)
              .maybeSingle();

          final courseId = compRow?['club_id'] as String? ?? competitionId;
          final compName = compRow?['name'] as String? ?? 'Competition Round';

          // Look up the golf course name from the Course table
          final courseRow = await _supabase
              .from('Course')
              .select('name')
              .eq('id', courseId)
              .maybeSingle();
          final courseName = courseRow?['name'] as String? ?? compName;

          // Calculate total course par from scorecard
          final coursePar = scorecard.fold<int>(
              0, (sum, item) => sum + ((item['par'] ?? item['strokes'] ?? 4) as num).toInt());

          final playedAt = compRow?['start_date'] != null
              ? '${compRow?['start_date']}T12:00:00Z'
              : DateTime.now().toIso8601String();

          final roundId = 'comp_${competitionId}_$playerId';

          // 1. Save to the main Round table in Supabase
          await _supabase.from('Round').upsert({
            'id': roundId,
            'userId': playerId,
            'courseId': courseId,
            'courseName': courseName,
            'coursePar': coursePar,
            'playedAt': playedAt,
            'totalScore': grossScore,
            'totalNet': netScore.round(),
            'scoreVsPar': grossScore - coursePar,
            'holesPlayed': scorecard.length,
            'source': 'COMPETITION_SCANNED',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }, onConflict: 'id');

          // 2. Save individual hole scores to the HoleScore table
          final List<Map<String, dynamic>> holeScoreInserts = scorecard.map((s) {
            final hNum = (s['hole'] as num).toInt();
            return {
              'id': 'hs_${roundId}_$hNum',
              'roundId': roundId,
              'holeNumber': hNum,
              'par': (s['par'] ?? 4) as int,
              'score': (s['strokes'] ?? 4) as int,
              'putts': 0,
            };
          }).toList();

          await _supabase.from('HoleScore').upsert(holeScoreInserts, onConflict: 'id');
        } catch (e) {
          debugPrint('submitResult: Failed to save personal Round/HoleScore: $e');
        }
      }

      state = state.copyWith(
          isLoading: false,
          successMessage: certified ? 'Result certified!' : 'Draft saved.');
      return true;
    } catch (e) {
      debugPrint('CompetitionActions: submitResult error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to submit result: $e');
      return false;
    }
  }

  /// Admin updates competition status (e.g. upcoming → open_for_entry).
  Future<bool> updateCompetitionStatus({
    required String competitionId,
    required String newStatus,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase
          .from('competitions')
          .update({'status': newStatus})
          .eq('id', competitionId);
      state = state.copyWith(
          isLoading: false,
          successMessage: 'Competition status updated to "$newStatus".');
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to update status: $e');
      return false;
    }
  }

  /// Admin creates a new competition.
  Future<String?> createCompetition({
    required String clubId,
    required String name,
    String? description,
    required String competitionType,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? entryDeadline,
    double entryFee = 0,
    Map<String, dynamic>? rulesConfig,
    required String createdBy,
    bool isTemplate = false,
    String? posterUrl,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _supabase.from('competitions').insert({
        'club_id': clubId,
        'name': name,
        'description': description,
        'competition_type': competitionType,
        'status': 'upcoming',
        'start_date': isTemplate ? '1970-01-01' : startDate.toIso8601String().substring(0, 10),
        'end_date': isTemplate ? null : endDate?.toIso8601String().substring(0, 10),
        'entry_deadline': isTemplate ? null : entryDeadline?.toIso8601String(),
        'entry_fee': entryFee,
        'rules_config': rulesConfig ?? {
          'handicap_allowance_pct': 100,
          'max_handicap': 36,
          'flights': [],
          'tiebreaker': 'countback',
        },
        'created_by': createdBy,
        'is_template': isTemplate,
        'poster_url': posterUrl,
      }).select('id').single();

      state = state.copyWith(
          isLoading: false, successMessage: 'Competition created!');
      return result['id'] as String;
    } catch (e) {
      debugPrint('CompetitionActions: createCompetition error: $e');
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to create competition: $e');
      return null;
    }
  }
}

final competitionActionsProvider =
    StateNotifierProvider<CompetitionActionsNotifier, CompetitionActionState>(
        (ref) => CompetitionActionsNotifier(ref));
