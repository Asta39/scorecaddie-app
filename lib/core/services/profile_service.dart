import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';
import '../cloud/sync_service.dart';
import 'package:flutter/foundation.dart';


class ProfileService {
  final Ref _ref;

  ProfileService(this._ref);

  db.AppDatabase get _db => _ref.read(databaseProvider);
  SyncService get _sync => _ref.read(syncServiceProvider);

  /// Ensures a profile exists for the given UID.
  /// First checks local DB, then Supabase by UID, then fallback to Email lookup.
  Future<void> ensureProfile(String uid, {String? displayName, String? photoUrl, String? email}) async {
    // 1. Check local DB
    final existing = await _db.getProfile(uid);
    if (existing != null) {
      if (existing.email == null && email != null) {
        await _db.updateProfile(uid, db.UserProfilesCompanion(email: drift.Value(email)));
      }
      if (existing.profileComplete) return;
    }

    // 2. Check Supabase (via SyncService) by ID
    final supabaseProfile = await Supabase.instance.client.from('User').select().eq('id', uid).maybeSingle();
    Map<String, dynamic>? profileData = supabaseProfile;

    // 3. Email-based lookup fallback (Requirement: check if email already exists in DB)
    if (profileData == null && email != null) {
      final emailQuery = await Supabase.instance.client
          .from('User')
          .select()
          .eq('email', email)
          .limit(1)
          .maybeSingle();
      
      if (emailQuery != null) {
        if (emailQuery['id'] == uid) {
          profileData = emailQuery;
          debugPrint('PROFILE_SERVICE: Restored existing profile by email match: $email');
        } else {
          debugPrint('PROFILE_SERVICE: Found profile with same email but different UID. Skipping auto-restoration.');
        }
      }
    }

    // 4. Check if they have any rounds (legacy players) if profile not marked complete
    if (profileData == null || profileData['profileComplete'] != true) {
      final roundsSnapshot = await Supabase.instance.client
          .from('Round')
          .select('id')
          .or('userId.eq.$uid') // Assume userId could be the fetched user ID
          .limit(1);
          
      if ((roundsSnapshot as List).isNotEmpty) {
        profileData ??= {};
        profileData['role'] ??= 'player';
        profileData['profileComplete'] = true;
      }
    }

    if (profileData != null) {
      await _db.upsertProfile(db.UserProfilesCompanion(
        uid: drift.Value(uid),
        email: drift.Value(email ?? profileData['email'] as String?),
        name: drift.Value(profileData['name'] ?? displayName ?? 'Golfer'),
        avatarUrl: drift.Value(profileData['avatarUrl'] ?? photoUrl), // Use existing or provided (Google) photo
        handicap: drift.Value(profileData['handicap']?.toDouble()),
        role: drift.Value(profileData['role']?.toString().toLowerCase()),
        profileComplete: drift.Value(profileData['profileComplete'] ?? false),
        updatedAt: drift.Value(DateTime.now()),
      ));
      
      // If we found they were complete, trigger a full pull of their data
      if (profileData['profileComplete'] == true) {
         _sync.syncAllPending(); // Run in background to populate rounds/courses
      }
      return;
    }

    // 5. Create fresh local profile if truly new and doesn't exist locally
    if (existing == null) {
      await _db.insertProfile(db.UserProfilesCompanion.insert(
        uid: drift.Value(uid),
        email: drift.Value(email),
        name: drift.Value(displayName ?? 'Golfer'),
        avatarUrl: drift.Value(photoUrl), // Store Google PFP here
        profileComplete: const drift.Value(false),
      ));
    } else if (existing.avatarUrl == null && photoUrl != null) {
      // Update existing incomplete local profile with Google PFP if it was missing
      await _db.updateProfile(uid, db.UserProfilesCompanion(
        avatarUrl: drift.Value(photoUrl),
      ));
    }
  }

  Future<bool> isUsernameAvailable(String name) async {
    try {
      final supabase = Supabase.instance.client;
      final user = _ref.read(authStateProvider).valueOrNull;
      
      // Check for any user with the same name, excluding the current user
      final response = await supabase
          .from('User')
          .select('id')
          .ilike('name', name)
          .not('id', 'eq', user?.uid ?? '')
          .maybeSingle();

      return response == null;
    } catch (e) {
      debugPrint('PROFILE_SERVICE: Error checking username availability: $e');
      return true; // Fallback to available if check fails
    }
  }

  Future<void> updateProfile(String uid, db.UserProfilesCompanion companion) async {
    // 1. Update local DB first with whatever we have (might be local path)
    await _db.updateProfile(uid, companion);
    
    // 2. Fetch the updated profile to sync
    final profile = await _db.getProfile(uid);
    if (profile != null) {
      // 3. Sync will handle the upload if it's a local file
      await _sync.syncProfile(profile);

      // 4. FORCE sync to Supabase User table to override Google names/PFPs
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('User').update({
          'name': profile.name,
          'avatarUrl': profile.avatarUrl,
        }).eq('id', uid);
        debugPrint('PROFILE_SERVICE: Forced Supabase user sync success');
      } catch (e) {
        debugPrint('PROFILE_SERVICE: Forced Supabase sync failed: $e');
      }
    }
  }
}
