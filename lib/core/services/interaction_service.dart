import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';
import 'package:drift/drift.dart' as drift;

final interactionServiceProvider = Provider((ref) => InteractionService(ref));

class InteractionService {
  final Ref _ref;
  InteractionService(this._ref);

  db.AppDatabase get _database => _ref.read(databaseProvider);

  /// Logs a contact attempt (Call or WhatsApp).
  /// Guards against duplicates using the (playerId, providerId, type) triple
  /// so the same player can contact via both WhatsApp and phone call.
  Future<void> logInteraction({
    required String providerId,
    required String type, // 'call' or 'whatsapp'
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Contacting the same pro again restarts the "did you book?" check
    // instead of being ignored, so the question is about the latest contact.
    final existing = await (_database.select(_database.interactions)
          ..where((i) => i.playerId.equals(user.uid) & i.providerId.equals(providerId) & i.status.equals('pending')))
        .get();
    if (existing.isNotEmpty) {
      await (_database.update(_database.interactions)..where((i) => i.id.isIn(existing.map((e) => e.id))))
          .write(db.InteractionsCompanion(type: drift.Value(type), timestamp: drift.Value(DateTime.now()), lastPromptedAt: const drift.Value(null)));
      return;
    }

    final interaction = db.Interaction(
      id: 0,
      playerId: user.uid,
      providerId: providerId,
      type: type,
      status: 'pending',
      timestamp: DateTime.now(),
    );

    await _database.into(_database.interactions).insert(db.InteractionsCompanion.insert(
      playerId: user.uid,
      providerId: providerId,
      type: type,
      status: const drift.Value('pending'),
    ));

    // Push to Supabase
    await _ref.read(syncServiceProvider).syncInteraction(interaction);

    // Also update provider total calls if it is a call-type interaction
    if (type == 'call') {
      final provider = await _getProvider(providerId);
      if (provider != null) {
        await (_database.update(_database.providers)..where((p) => p.userId.equals(providerId)))
            .write(db.ProvidersCompanion(
              totalCalls: drift.Value(provider.totalCalls + 1),
            ));
      }
    }
  }

  /// Confirms whether a booking actually happened
  Future<void> confirmBooking(int interactionId, bool booked) async {
    final interaction = await (_database.select(_database.interactions)
          ..where((i) => i.id.equals(interactionId)))
        .get()
        .then((rows) => rows.firstOrNull);

    if (interaction == null) return; // Already deleted or never existed

    final updated = interaction.copyWith(
      status: booked ? 'booked' : 'ignored',
    );

    await (_database.update(_database.interactions)..where((i) => i.id.equals(interactionId)))
        .write(db.InteractionsCompanion(
          status: drift.Value(booked ? 'booked' : 'ignored'),
        ));

    // Update in Supabase
    await _ref.read(syncServiceProvider).syncInteraction(updated);

    if (booked) {
      final provider = await _getProvider(interaction.providerId);
      if (provider != null) {
        await (_database.update(_database.providers)..where((p) => p.userId.equals(interaction.providerId)))
            .write(db.ProvidersCompanion(
              totalBookings: drift.Value(provider.totalBookings + 1),
            ));
      }
    }
  }

  Future<db.Provider?> _getProvider(String userId) async {
    return (_database.select(_database.providers)..where((p) => p.userId.equals(userId)))
        .get()
        .then((rows) => rows.firstOrNull);
  }

  Future<List<db.Interaction>> getPendingInteractions() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return [];

    return await (_database.select(_database.interactions)
          ..where((i) => i.playerId.equals(user.uid) & i.status.equals('pending')))
        .get();
  }

  /// The contact to ask about now, if any: the latest pending one, at least
  /// [minAway] old (so the player actually left to call or message), at most
  /// [window] old, and not asked about in the last [snooze]. Contacts older
  /// than the window are dropped so they never come back.
  Future<db.Interaction?> dueForPrompt({
    Duration minAway = const Duration(seconds: 20),
    Duration window = const Duration(hours: 3),
    Duration snooze = const Duration(minutes: 45),
  }) async {
    final now = DateTime.now();
    final pending = await getPendingInteractions();
    pending.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (final i in pending) {
      if (now.difference(i.timestamp) > window) await ignoreInteraction(i.id);
    }
    for (final i in pending) {
      final age = now.difference(i.timestamp);
      if (age < minAway || age > window) continue;
      if (i.lastPromptedAt != null && now.difference(i.lastPromptedAt!) < snooze) continue;
      return i;
    }
    return null;
  }

  /// Sets status to 'ignored' so it won't prompt again.
  Future<void> ignoreInteraction(int id) async {
    await (_database.update(_database.interactions)..where((i) => i.id.equals(id)))
        .write(const db.InteractionsCompanion(
          status: drift.Value('ignored'),
        ));
  }

  /// Sets lastPromptedAt to now: "not yet" asks again after the snooze.
  Future<void> dismissInteraction(int id) async {
    await (_database.update(_database.interactions)..where((i) => i.id.equals(id)))
        .write(db.InteractionsCompanion(
          lastPromptedAt: drift.Value(DateTime.now()),
        ));
  }

  /// Fetches unique providers from 'booked' interactions for the current user.
  Future<List<db.Provider>> getRecentPros() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return [];

    final interactions = await (_database.select(_database.interactions)
          ..where((i) => i.playerId.equals(user.uid) & i.status.equals('booked')))
        .get();

    if (interactions.isEmpty) return [];

    final providerIds = interactions.map((i) => i.providerId).toSet().toList();
    
    return await (_database.select(_database.providers)
          ..where((p) => p.userId.isIn(providerIds)))
        .get();
  }
}
