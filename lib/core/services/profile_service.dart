import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
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
  /// First checks local DB, then Firestore by UID, then fallback to Email lookup.
  Future<void> ensureProfile(String uid, {String? displayName, String? photoUrl, String? email}) async {
    // 1. Check local DB
    final existing = await _db.getProfile(uid);
    if (existing != null && existing.profileComplete) return;

    // 2. Check Firestore (via SyncService) by UID
    final firestoreProfile = await _sync.getProfileSnapshot(uid);
    Map<String, dynamic>? profileData;
    if (firestoreProfile != null && firestoreProfile.exists) {
      profileData = firestoreProfile.data() as Map<String, dynamic>;
    }

    // 3. Email-based lookup fallback (Requirement: check if email already exists in DB)
    if (profileData == null && email != null) {
      final emailQuery = await FirebaseFirestore.instance
          .collection('profiles')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (emailQuery.docs.isNotEmpty) {
        profileData = emailQuery.docs.first.data();
        debugPrint('PROFILE_SERVICE: Found existing profile by email: $email');
      }
    }

    // 4. If profile incomplete or missing, check providers collection AND rounds
    if (profileData == null || !(profileData['profileComplete'] ?? false)) {
      // Check providers collection
      final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(uid).get();
      if (providerDoc.exists) {
        final providerData = providerDoc.data()!;
        profileData ??= {};
        profileData['role'] = providerData['role'];
        profileData['profileComplete'] = providerData['profileComplete'] ?? true;
        profileData['name'] ??= providerData['name'];
      } else {
        // If not a provider, check if they have any rounds (legacy players)
        final roundsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('rounds')
            .limit(1)
            .get();
            
        if (roundsSnapshot.docs.isNotEmpty) {
          profileData ??= {};
          profileData['role'] ??= 'player';
          profileData['profileComplete'] = true;
        }
      }
    }

    if (profileData != null) {
      await _db.upsertProfile(db.UserProfilesCompanion(
        firebaseUid: drift.Value(uid),
        email: drift.Value(email ?? profileData['email'] as String?),
        name: drift.Value(profileData['name'] ?? displayName ?? 'Golfer'),
        avatarUrl: drift.Value(profileData['avatarUrl'] ?? photoUrl), // Use existing or provided (Google) photo
        handicap: drift.Value(profileData['handicap']?.toDouble()),
        role: drift.Value(profileData['role']),
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
        firebaseUid: drift.Value(uid),
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

  Future<void> updateProfile(String uid, db.UserProfilesCompanion companion) async {
    // 1. If photo is a local file, upload it first
    if (companion.avatarUrl.present) {
      final path = companion.avatarUrl.value;
      if (path != null && !path.startsWith('http')) {
        final file = File(path);
        if (await file.exists()) {
          final uploadedUrl = await _sync.uploadProfilePhoto(file);
          if (uploadedUrl != null) {
            // Replace local path with remote URL in companion
            companion = companion.copyWith(avatarUrl: drift.Value(uploadedUrl));
          }
        }
      }
    }

    // 2. Update local DB
    await _db.updateProfile(uid, companion);
    
    // 3. Sync full profile to Firestore
    final profile = await _db.getProfile(uid);
    if (profile != null) {
      await _sync.syncProfile(profile);
    }
  }
}
