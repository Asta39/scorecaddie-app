import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart' as db;
import 'auth_providers.dart';
import 'database_providers.dart';

final userBookingsProvider = StreamProvider<List<db.Booking>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(supabaseClientProvider)
      .from('Booking')
      .stream(primaryKey: ['id'])
      .eq('playerId', user.id)
      .order('createdAt', ascending: false)
      .map((list) {
        return list.map((data) => db.Booking(
          id: 0,
          serverId: data['id'],
          playerId: data['playerId'],
          providerId: data['providerId'],
          roundType: data['roundType'] ?? 'EIGHTEEN_HOLES',
          status: data['status'] ?? 'PENDING',
          initiatedVia: data['initiatedVia'] ?? 'CHAT',
          startTime: data['startTime'] != null ? DateTime.tryParse(data['startTime']) : null,
          endTime: data['endTime'] != null ? DateTime.tryParse(data['endTime']) : null,
          durationMinutes: data['durationMinutes'],
          amountPaid: data['amountPaid'] != null ? (data['amountPaid'] is int ? (data['amountPaid'] as int).toDouble() : data['amountPaid']) : null,
          currency: data['currency'] ?? 'KES',
          paymentMethod: data['paymentMethod'],
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
          updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt']) ?? DateTime.now() : DateTime.now(),
        )).toList();
      });
});

final providerBookingsProvider = StreamProvider<List<db.Booking>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(supabaseClientProvider)
      .from('Booking')
      .stream(primaryKey: ['id'])
      .eq('providerId', user.id)
      .order('createdAt', ascending: false)
      .map((list) {
        return list.map((data) => db.Booking(
          id: 0,
          serverId: data['id'],
          playerId: data['playerId'],
          providerId: data['providerId'],
          roundType: data['roundType'] ?? 'EIGHTEEN_HOLES',
          status: data['status'] ?? 'PENDING',
          initiatedVia: data['initiatedVia'] ?? 'CHAT',
          startTime: data['startTime'] != null ? DateTime.tryParse(data['startTime']) : null,
          endTime: data['endTime'] != null ? DateTime.tryParse(data['endTime']) : null,
          durationMinutes: data['durationMinutes'],
          amountPaid: data['amountPaid'] != null ? (data['amountPaid'] is int ? (data['amountPaid'] as int).toDouble() : data['amountPaid']) : null,
          currency: data['currency'] ?? 'KES',
          paymentMethod: data['paymentMethod'],
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
          updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt']) ?? DateTime.now() : DateTime.now(),
        )).toList();
      });
});

final currentBookingProvider = StreamProvider<db.Booking?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile?.currentBookingId == null) return Stream.value(null);
  
  final database = ref.watch(databaseProvider);
  return database.watchProviderBookings(profile!.uid!).map((list) {
    return list.where((b) => b.serverId == profile.currentBookingId).firstOrNull;
  });
});

final pendingInteractionProvider = StreamProvider.family<db.Interaction?, String>((ref, providerId) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);

  return ref.watch(supabaseClientProvider)
      .from('interactions')
      .stream(primaryKey: ['id'])
      .eq('playerId', user.id)
      .map((list) {
        list = list.where((data) => data['providerId'] == providerId && data['status'] == 'pending').toList();
        if (list.isEmpty) return null;
        final data = list.first;
        return db.Interaction(
          id: data['id'] ?? 0,
          playerId: data['playerId'],
          providerId: data['providerId'],
          type: data['type'],
          status: data['status'] ?? 'pending',
          lastPromptedAt: data['lastPromptedAt'] != null ? DateTime.tryParse(data['lastPromptedAt']) : null,
          timestamp: data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) ?? DateTime.now() : DateTime.now(),
        );
      });
});

final inquiriesProvider = StreamProvider<List<db.Inquiry>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  
  return ref.watch(supabaseClientProvider)
      .from('Inquiry')
      .stream(primaryKey: ['id'])
      .eq('providerId', user.id)
      .order('createdAt', ascending: false)
      .map((list) {
        return list.map((data) => db.Inquiry(
          id: 0,
          serverId: data['id'],
          playerId: data['playerId'],
          providerId: data['providerId'],
          initiatedVia: data['initiatedVia'],
          status: data['status'] ?? 'PENDING',
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
        )).toList();
      });
});
