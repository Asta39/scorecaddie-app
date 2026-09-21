import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_completeness.dart';

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
      // withoutNulls: an upsert writes every key it's given, so passing null
      // for a field the caller didn't supply erased real server data. The
      // provider sync never passed profileComplete, which wiped it and sent
      // returning users back to role selection on their next fresh login.
      await _client.from('User').upsert(withoutNulls({
        'id': id,
        // Never overwrite a real email with the '' callers use as a fallback.
        'email': email.isEmpty ? null : email,
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
        // These four were accepted as parameters but never written, so a
        // coach's certification flag/name, specializations and target audience
        // silently vanished on every sync and came back empty after reinstall.
        'hasCertification': hasCertification,
        'certificationName': certificationName,
        'specializations': specializations,
        'targetAudience': targetAudience,
        // Completion is one-way. A device on a fresh install holds a local
        // profile that hasn't synced down yet (profileComplete false); it
        // must never downgrade a completed account on the server.
        'profileComplete': profileComplete == true ? true : null,
        'updatedAt': DateTime.now().toIso8601String(),
      }), onConflict: 'id');
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

      // Fallback to User table (for coaches). Goes through a narrow RPC:
      // writing another user's row directly only worked while the User
      // table had a wide-open policy, which also let anyone edit anyone.
      // The RPC increments views only, and never on your own profile.
      await _client.rpc('increment_profile_views', params: {'p_user_id': id});
    } catch (e) {
      debugPrint('API_INCREMENT_VIEWS ERROR: $e');
    }
  }
}
