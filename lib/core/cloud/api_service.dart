import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  // All cloud operations go directly to Supabase.
  // Legacy Node.js backend has been decommissioned.

  SupabaseClient get _client => Supabase.instance.client;

  /// Upserts the user's profile directly into the Supabase User table.
  Future<void> syncProfile({
    required String id,
    required String email,
    required String name,
    required String role,
    String? avatarUrl,
    String? passportPhotoUrl,
    String? pfpType,
    bool? pfpVerified,
    String? providerStatus,
    double? handicapIndex,
    String? phone,
    String? whatsapp,
    String? bio,
    int? experience,
    double? price,
    String? personalityType,
    String? coursesJson,
    bool? hasCertification,
    String? certificationName,
    String? certificationUrl,
    String? coachingLocation,
    String? specializations,
    String? targetAudience,
    List<String>? badges,
    bool? profileComplete,
    double? anchorIndex,
  }) async {
    try {
      final cleanRole = role.trim().toLowerCase();
      final dbRole = (cleanRole == 'club_admin' || cleanRole == 'super_admin') ? cleanRole : cleanRole.toUpperCase();
      await _client.from('User').upsert({
        'id': id,
        'email': email,
        'name': name,
        'role': dbRole,
        'avatarUrl': avatarUrl,
        'pfpType': pfpType,
        'pfpVerified': pfpVerified,
        'providerStatus': providerStatus,
        'handicapIndex': handicapIndex,
        'phone': phone,
        'whatsapp': whatsapp,
        'bio': bio,
        'experience': experience,
        'price': price,
        'personalityType': personalityType,
        'coursesJson': coursesJson,
        'certificationUrl': certificationUrl,
        'coachingLocation': coachingLocation,
        'profileComplete': profileComplete,
        'updatedAt': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('API_SYNC_PROFILE ERROR: $e');
    }
  }

  /// Fetches the user profile directly from the Supabase User table.
  /// This fixes the "Zero Data" dashboard after a fresh install.
  Future<Map<String, dynamic>?> getProfile(String id) async {
    try {
      final response = await _client
          .from('User')
          .select()
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('API_GET_PROFILE ERROR: $e');
      return null;
    }
  }

  Future<void> incrementViews(String id) async {
    try {
      // First try caddies table
      final caddie = await _client.from('caddies').select('views').eq('id', id).maybeSingle();
      if (caddie != null) {
        final currentViews = caddie['views'] as int? ?? 0;
        await _client.from('caddies').update({'views': currentViews + 1}).eq('id', id);
        return;
      }

      // Fallback to User table (for coaches)
      final profile = await _client.from('User').select('views').eq('id', id).maybeSingle();
      if (profile != null) {
        final currentViews = profile['views'] as int? ?? 0;
        await _client.from('User').update({'views': currentViews + 1}).eq('id', id);
      }
    } catch (e) {
      debugPrint('API_INCREMENT_VIEWS ERROR: $e');
    }
  }
}
