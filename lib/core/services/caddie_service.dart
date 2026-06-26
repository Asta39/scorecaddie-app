import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

class CaddieService {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. BOOKING CREATION FUNCTION
  Future<BookingModel> createBooking({
    required String providerId,
    required String initiatedVia,
    required String roundType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    debugPrint('CREATE: Current User: ${user.id}');

    final playerId = user.id;

    try {
      debugPrint('CREATE: Inserting booking for Player: $playerId, Provider: $providerId');
      
      final response = await _client.from('Booking').insert({
        'player_id': playerId,
        'provider_id': providerId,
        'status': 'CONFIRMED',
        'initiated_via': initiatedVia,
        'round_type': roundType,
        'booking_date': DateTime.now().toIso8601String(),
      }).select().single();

      debugPrint('CREATE: Booking inserted successfully with ID: ${response['id']}');

      // 2. Update provider status
      debugPrint('CREATE: Updating provider status to BOOKED');
      await _client.from('User').update({
        'providerStatus': 'BOOKED',
      }).eq('id', providerId);
      
      debugPrint('CREATE: Provider status updated successfully');

      return BookingModel.fromJson(response);
    } catch (e) {
      debugPrint('CREATE: Critical error during booking creation: $e');
      rethrow;
    }
  }

  // 2. PROVIDER DASHBOARD QUERY
  Future<List<BookingModel>> getUpcomingBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    
    final providerId = user.id;

    debugPrint('QUERY: Fetching upcoming bookings for Provider ID: $providerId');

    try {
      final response = await _client
          .from('Booking')
          .select()
          .eq('provider_id', providerId)
          .inFilter('status', ['confirmed', 'in_progress'])
          .gte('booking_date', DateTime.now().toIso8601String())
          .order('booking_date', ascending: true);

      final List<dynamic> data = response;
      debugPrint('QUERY: Found ${data.length} upcoming bookings');
      
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('QUERY: Error fetching upcoming bookings: $e');
      return [];
    }
  }

  // 3. SUPABASE REALTIME LISTENER
  Stream<List<BookingModel>> watchUpcomingBookings() async* {
    final user = _client.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }
    
    final providerId = user.id;

    debugPrint('STREAM: Starting realtime listener for Provider ID: $providerId');

    // Listen for changes
    yield* _client
        .from('Booking')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('booking_date', ascending: true)
        .map((data) {
          debugPrint('STREAM: Realtime update received with ${data.length} records');
          return data
              .map((json) => BookingModel.fromJson(json))
              .where((b) => b.status == 'confirmed' || b.status == 'pending' || b.status == 'in_progress')
              .toList();
        });
  }

  Stream<List<BookingModel>> watchAllBookings() async* {
    final user = _client.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }
    
    final providerId = user.id;

    yield* _client
        .from('Booking')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('booking_date', ascending: false)
        .map((data) {
          return data.map((json) => BookingModel.fromJson(json)).toList();
        });
  }
}
