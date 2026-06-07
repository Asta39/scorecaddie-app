import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';
import 'package:drift/drift.dart' as drift;
import 'api_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref);
});

class SupabaseService {
  final Ref _ref;
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseService(this._ref);

  db.AppDatabase get _db => _ref.read(databaseProvider);

  RealtimeChannel? _bookingChannel;
  RealtimeChannel? _messageChannel;

  Future<void> init() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    debugPrint('SUPABASE: Initializing real-time listeners for ${user.id}');

    // SELF-HEALING: Ensure user profile exists in Supabase User table
    try {
      debugPrint('SUPABASE: Checking profile for user ${user.id}...');
      
      // Check if there's already a profile in the DB
      final dbProfile = await _client.from('User').select('name, role, bio, experience').eq('id', user.id).maybeSingle();
      
      if (dbProfile == null) {
        // Create new minimal profile ONLY if it doesn't exist
        final localProfile = await _db.getProfile(user.id);
        final currentRole = (localProfile?.role ?? 'PLAYER').toUpperCase();
        
        await _client.from('User').insert({
          'id': user.id,
          'email': user.email ?? '',
          'name': user.metadata?['full_name'] ?? 'Golfer',
          'role': currentRole,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('SUPABASE: Created new minimal user profile');
      } else {
        // Profile exists. If name is 'Golfer' but metadata has a real name, update it ONLY.
        if (dbProfile['name'] == 'Golfer' && user.metadata?['full_name'] != null) {
          await _client.from('User').update({
            'name': user.metadata?['full_name'],
            'updatedAt': DateTime.now().toIso8601String(),
          }).eq('id', user.id);
          debugPrint('SUPABASE: Updated Golfer name from metadata');
        }
        debugPrint('SUPABASE: Profile already exists and is healthy');
      }
    } catch (profileError) {
      debugPrint('SUPABASE ERROR: Profile self-healing failed: $profileError');
    }

    // 1. Listen for Bookings (both as player and provider)
    _bookingChannel = _client
        .channel('public:Booking')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Booking',
          callback: (payload) async {
            debugPrint('SUPABASE: Booking change detected: ${payload.eventType}');
            final data = payload.newRecord;
            
            final playerId = data['player_id'] ?? data['playerId'];
            final providerId = data['provider_id'] ?? data['providerId'];
            
            if (playerId == user.id || providerId == user.id) {
              await _db.upsertBooking(db.BookingsCompanion.insert(
                serverId: drift.Value(data['id'].toString()),
                playerId: playerId,
                providerId: providerId,
                status: drift.Value(data['status'] ?? 'PENDING'),
                initiatedVia: drift.Value(data['initiated_via'] ?? data['initiatedVia'] ?? 'CHAT'),
                roundType: drift.Value(data['round_type'] ?? data['roundType'] ?? 'EIGHTEEN_HOLES'),
                startTime: drift.Value((data['start_time'] ?? data['startTime']) != null ? DateTime.parse(data['start_time'] ?? data['startTime']) : null),
                endTime: drift.Value((data['end_time'] ?? data['endTime']) != null ? DateTime.parse(data['end_time'] ?? data['endTime']) : null),
                amountPaid: drift.Value((data['amount_paid'] ?? data['amountPaid'] as num?)?.toDouble()),
              ));
            }
          },
        )
        .subscribe();

    // 2. Listen for Messages
    _messageChannel = _client
        .channel('public:Message')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'Message',
          callback: (payload) async {
            final data = payload.newRecord;
            if (data['receiverId'] == user.id || data['senderId'] == user.id) {
              debugPrint('SUPABASE: New message received: ${data['content']}');
              await _db.upsertMessage(db.MessagesCompanion.insert(
                serverId: drift.Value(data['id'].toString()),
                bookingId: drift.Value(data['bookingId']?.toString()),
                senderId: data['senderId'],
                receiverId: data['receiverId'],
                content: data['content'],
                createdAt: drift.Value(data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now()),
              ));
            }
          },
        )
        .subscribe();
  }

  void dispose() {
    _bookingChannel?.unsubscribe();
    _messageChannel?.unsubscribe();
  }

  /// Updates provider availability status in both Supabase and local DB
  Future<void> updateStatus(String status) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    debugPrint('SUPABASE: Updating status to $status');

    // 1. Sync to Supabase User table
    await _client
        .from('User')
        .update({'providerStatus': status})
        .eq('id', user.id);

    // 2. Sync to local DB (UserProfiles)
    await _db.updateProfile(user.id, db.UserProfilesCompanion(
      providerStatus: drift.Value(status),
    ));

    // 3. Sync to local DB (Providers)
    final bool isAvailable = status == 'AVAILABLE';
    await (_db.update(_db.providers)..where((p) => p.userId.equals(user.id)))
        .write(db.ProvidersCompanion(isAvailable: drift.Value(isAvailable)));

    // 4. Sync to PostgreSQL Backend via API
    final provider = await _db.getProvider(user.id);
    if (provider != null) {
      await _ref.read(syncServiceProvider).syncProvider(provider);
    } else {
      // Fallback for players
      final profile = await _db.getProfile(user.id);
      if (profile != null) {
        await _ref.read(apiServiceProvider).syncProfile(
          id: user.id,
          email: profile.email ?? '',
          name: profile.name,
          role: (profile.role ?? 'PLAYER').toUpperCase(),
          avatarUrl: profile.avatarUrl,
          handicapIndex: profile.handicap,
          providerStatus: status,
        );
      }
    }
  }

  /// Initiates a booking from a player to a caddie
  Future<void> createBooking({
    required String caddieId,
    required String initiatedVia, // CALL or CHAT
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final response = await _client.from('Booking').insert({
      'player_id': user.id,
      'provider_id': caddieId,
      'status': 'CONFIRMED',
      'initiated_via': initiatedVia,
      'booking_date': DateTime.now().toIso8601String(),
    }).select().single();

    // Store in local DB
    await _db.upsertBooking(db.BookingsCompanion.insert(
      serverId: drift.Value(response['id'].toString()),
      playerId: user.id,
      providerId: caddieId,
      status: const drift.Value('CONFIRMED'),
      initiatedVia: drift.Value(initiatedVia),
    ));
  }

  /// Creates an inquiry when a player indicates they didn't book
  Future<void> createInquiry({
    required String providerId,
    required String initiatedVia,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final response = await _client.from('Inquiry').insert({
      'playerId': user.id,
      'providerId': providerId,
      'initiatedVia': initiatedVia,
      'status': 'PENDING',
    }).select().single();

    await _db.insertInquiry(db.InquiriesCompanion.insert(
      serverId: drift.Value(response['id'].toString()),
      playerId: user.id,
      providerId: providerId,
      initiatedVia: initiatedVia,
      status: const drift.Value('PENDING'),
    ));
  }

  /// Confirms a booking (usually by the player via the chat bar)
  Future<void> confirmBooking(String bookingServerId) async {
    await _client
        .from('Booking')
        .update({'status': 'CONFIRMED'})
        .eq('id', bookingServerId);

    // Update local DB
    final localBooking = await (_db.select(_db.bookings)..where((b) => b.serverId.equals(bookingServerId))).getSingleOrNull();
    if (localBooking != null) {
      await _db.updateBookingStatus(localBooking.id, 'CONFIRMED');
    }
  }

  /// Starts a round (by the caddie)
  Future<void> startRound(String bookingServerId, String roundType) async {
    final now = DateTime.now().toIso8601String();
    
    await _client.from('Booking').update({
      'status': 'IN_PROGRESS',
      'start_time': now,
      'round_type': roundType,
    }).eq('id', bookingServerId);

    // Set caddie status to ON_ROUND
    await updateStatus('ON_ROUND');

    // Update local DB
    final localBooking = await (_db.select(_db.bookings)..where((b) => b.serverId.equals(bookingServerId))).getSingleOrNull();
    if (localBooking != null) {
      await (_db.update(_db.bookings)..where((b) => b.id.equals(localBooking.id))).write(db.BookingsCompanion(
        status: const drift.Value('IN_PROGRESS'),
        startTime: drift.Value(DateTime.parse(now)),
        roundType: drift.Value(roundType),
      ));
      
      // Update remote User currentBookingId
      final user = _ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        await _client.from('User').update({'currentBookingId': bookingServerId}).eq('id', user.id);
        
        // Update local UserProfile - Store the server ID here so currentBookingProvider can find it
        await _db.updateProfile(user.id, db.UserProfilesCompanion(
          currentBookingId: drift.Value(bookingServerId),
        ));
      }
    }
  }

  /// Ends a round (by the caddie)
  Future<void> endRound({
    required String bookingServerId,
    required double amount,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();
    
    // 1. Get start time to calculate duration
    final bookingData = await _client.from('Booking').select('start_time').eq('id', bookingServerId).single();
    final startTimeStr = bookingData['start_time'] ?? bookingData['startTime'];
    final startTime = DateTime.parse(startTimeStr);
    final duration = now.difference(startTime).inMinutes;

    // 2. Update booking
    await _client.from('Booking').update({
      'status': 'COMPLETED',
      'end_time': now.toIso8601String(),
      'duration_minutes': duration,
      'amount_paid': amount,
      'payment_method': paymentMethod,
    }).eq('id', bookingServerId);

    // 3. Set caddie status back to AVAILABLE or OFFLINE
    await updateStatus('AVAILABLE');

    // 4. Update local DB
    final localBooking = await (_db.select(_db.bookings)..where((b) => b.serverId.equals(bookingServerId))).getSingleOrNull();
    if (localBooking != null) {
      await (_db.update(_db.bookings)..where((b) => b.id.equals(localBooking.id))).write(db.BookingsCompanion(
        status: const drift.Value('COMPLETED'),
        endTime: drift.Value(now),
        durationMinutes: drift.Value(duration),
        amountPaid: drift.Value(amount),
        paymentMethod: drift.Value(paymentMethod),
      ));
      
      // Clear remote User currentBookingId
      final user = _ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        await _client.from('User').update({'currentBookingId': null}).eq('id', user.id);
        
        // Clear local currentBookingId
        await _db.updateProfile(user.id, const db.UserProfilesCompanion(
          currentBookingId: drift.Value(null),
        ));
      }
    }
  }

  /// Sends a message in a booking context
  Future<void> sendMessage({
    String? bookingId,
    required String receiverId,
    required String content,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final response = await _client.from('Message').insert({
      'bookingId': bookingId,
      'senderId': user.id,
      'receiverId': receiverId,
      'content': content,
    }).select().single();

    await _db.into(_db.messages).insert(db.MessagesCompanion.insert(
      serverId: drift.Value(response['id'].toString()),
      bookingId: drift.Value(bookingId),
      senderId: user.id,
      receiverId: receiverId,
      content: content,
      createdAt: drift.Value(DateTime.now()),
    ));
  }
}
