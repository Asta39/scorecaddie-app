import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';
import '../cloud/sync_service.dart';
import 'package:flutter/foundation.dart';
import 'profile_completeness.dart';


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

    // 2. Our own row on the server. my_profile() is the only way to read
    // our private fields (email); it may also return an older row with the
    // same email, which we don't adopt automatically.
    final mine = await Supabase.instance.client.rpc('my_profile');
    Map<String, dynamic>? profileData =
        mine is Map && mine['id'] == uid ? Map<String, dynamic>.from(mine) : null;

    // 4. Decide completeness from the server row plus evidence only an
    // onboarded account has. The flag alone can't be trusted: provider syncs
    // used to wipe it (see isServerProfileComplete).
    if (!isServerProfileComplete(profileData)) {
      final roundsSnapshot = await Supabase.instance.client
          .from('Round')
          .select('id')
          .eq('userId', uid)
          .limit(1);
      if (isServerProfileComplete(profileData, hasRounds: (roundsSnapshot as List).isNotEmpty)) {
        profileData ??= {};
        profileData['role'] ??= 'player';
        profileData['profileComplete'] = true;
      }
    } else {
      profileData!['profileComplete'] = true;
    }

    if (profileData != null) {
      await _db.upsertProfile(db.UserProfilesCompanion(
        uid: drift.Value(uid),
        email: drift.Value(email ?? profileData['email'] as String?),
        name: drift.Value(profileData['name'] ?? displayName ?? 'Golfer'),
        avatarUrl: drift.Value(profileData['avatarUrl'] ?? photoUrl), // Use existing or provided (Google) photo
        handicap: drift.Value((profileData['handicapIndex'] ?? profileData['handicap'])?.toDouble()),
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
          .neq('id', user?.uid ?? '')
          .limit(1)
          .maybeSingle();

      return response == null;
    } catch (e) {
      debugPrint('PROFILE_SERVICE: Error checking username availability: $e');
      return false; // Fallback to unavailable if check fails
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
