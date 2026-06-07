import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../database/database.dart' as db;
import '../cloud/sync_service.dart';

class FriendService {
  final db.AppDatabase _database;
  final SyncService _sync;
  final String? _uid;
  final supabase.SupabaseClient _supabase;

  FriendService(this._database, this._sync, this._uid, this._supabase);

  /// Generates a random, human-readable friend code (e.g. SC-A3B9-X7K1).
  /// Excludes look-alike characters: 0, O, 1, I, L.
  static String _generateFriendCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final part1 = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'SC-$part1-$part2';
  }

  Future<bool> sendFriendRequest(String targetUid) async {
    if (_uid == null || targetUid == _uid) return false;

    // 1. Check if already friends locally
    final existing = await (_database.select(_database.friends)..where((f) => f.friendId.equals(targetUid))).get().then((rows) => rows.firstOrNull);
    if (existing != null) return false;

    // 2. Fetch target profile from Supabase to confirm exists
    final targetProfile = await fetchProfile(targetUid);
    if (targetProfile == null) return false;

    // 3. Create request in Supabase Friend table
    try {
      await _supabase.from('Friend').upsert({
        'userId': _uid,
        'friendId': targetUid,
        'status': 'PENDING',
        'updatedAt': DateTime.now().toIso8601String()
      }, onConflict: 'userId,friendId');
      return true;
    } catch (e) {
      debugPrint('FriendService ERROR: Failed to send friend request');
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> streamIncomingRequests() {
    if (_uid == null) return Stream.value([]);
    debugPrint('FriendService: Starting stream for incoming requests');
    try {
      return _supabase
          .from('Friend')
          .stream(primaryKey: ['id'])
          .eq('friendId', _uid)
          .asyncMap((data) async {
            List<Map<String, dynamic>> requests = [];
            final pendingData = data.where((row) => row['status'] == 'PENDING');
            for (var row in pendingData) {
              final fromUid = row['userId'] as String;
              final profile = await fetchProfile(fromUid);
              requests.add({
                'id': row['id'], // Supabase UUID
                'from': fromUid,
                'to': _uid,
                'fromName': profile?['name'] ?? 'Golfer',
                'fromAvatar': profile?['avatarUrl'],
                'status': 'pending',
              });
            }
            return requests;
          })
          .handleError((error) {
            debugPrint('Supabase STREAM ERROR (Friend)');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('Error setting up friend requests stream');
      return Stream.value([]);
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    if (_uid == null) return;
    try {
      if (accept) {
        // Fetch the request record first to know who sent it
        final request = await _supabase.from('Friend').select().eq('id', requestId).maybeSingle();
        if (request == null) return;
        
        final fromUid = request['userId'] as String;

        // Mark as accepted in Supabase
        await _supabase.from('Friend').update({
          'status': 'ACCEPTED',
          'updatedAt': DateTime.now().toIso8601String()
        }).eq('id', requestId);

        // Fetch profile to save locally
        final fromProfile = await fetchProfile(fromUid);
        final fromName = fromProfile?['name'] ?? 'Golfer';
        final fromAvatar = fromProfile?['avatarUrl'];

        // Add to local DB
        await _database.into(_database.friends).insert(db.FriendsCompanion.insert(
          userId: _uid,
          friendId: fromUid,
          friendName: drift.Value(fromName),
          friendAvatar: drift.Value(fromAvatar),
        ), mode: drift.InsertMode.insertOrReplace);

        _sync.pullFriends();
      } else {
        // Decline = delete row or mark DECLINED
        await _supabase.from('Friend').delete().eq('id', requestId);
      }
    } catch (e) {
      debugPrint('FriendService ERROR: respondToRequest failed');
    }
  }

  /// Listens for requests I SENT that have been accepted
  Stream<List<Map<String, dynamic>>> streamAcceptedSentRequests() {
    if (_uid == null) return Stream.value([]);
    return _supabase
        .from('Friend')
        .stream(primaryKey: ['id'])
        .eq('userId', _uid)
        .asyncMap((data) async {
          List<Map<String, dynamic>> accepted = [];
          final acceptedData = data.where((row) => row['status'] == 'ACCEPTED');
          for (var row in acceptedData) {
            final toUid = row['friendId'] as String;
            final profile = await fetchProfile(toUid);
            accepted.add({
              'id': row['id'],
              'from': _uid,
              'to': toUid,
              'toName': profile?['name'] ?? 'Golfer',
              'toAvatar': profile?['avatarUrl'],
              'status': 'accepted',
            });
          }
          return accepted;
        });
  }

  Future<void> finalizeHandshake(String requestId) async {
    if (_uid == null) return;
    try {
      final request = await _supabase.from('Friend').select().eq('id', requestId).maybeSingle();
      if (request == null) return;

      final toUid = request['friendId'] as String;

      // 1. Fetch latest profile of the person who accepted
      final friendProfile = await fetchProfile(toUid);
      final name = friendProfile?['name'] ?? 'Golfer';
      final avatar = friendProfile?['avatarUrl'];

      // 2. Add to MY local DB
      await _database.into(_database.friends).insert(db.FriendsCompanion.insert(
        userId: _uid,
        friendId: toUid,
        friendName: drift.Value(name),
        friendAvatar: drift.Value(avatar),
      ), mode: drift.InsertMode.insertOrReplace);

      // We DON'T delete the row here because it's our ongoing record of friendship (status='ACCEPTED').
      // Alternatively, we leave it in the DB to sync friends automatically in pullFriends().
      
      _sync.pullFriends();
      debugPrint('FriendService: Handshake finalized');
    } catch (e) {
      debugPrint('FriendService ERROR: finalizeHandshake failed');
    }
  }

  /// Real-time stream of a user's profile
  Stream<Map<String, dynamic>?> streamProfile(String uid) {
    return _supabase
        .from('User')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((data) => data.isEmpty ? null : {
          'uid': data.first['id'],
          'name': data.first['name'],
          'avatarUrl': data.first['avatarUrl'],
          'handicapIndex': data.first['handicapIndex'],
          'skillLevel': data.first['skillLevel'],
          'playStyle': data.first['playStyle'],
        });
  }

  /// Real-time stream of a user's career stats
  Stream<Map<String, dynamic>?> streamPlayerStats(String uid) {
    // Watch the Round table for this user
    return _supabase
        .from('Round')
        .stream(primaryKey: ['id'])
        .eq('userId', uid)
        .asyncMap((rounds) async {
          if (rounds.isEmpty) {
            return {
              'totalRounds': 0,
              'avgScore': 0.0,
              'bestScore': null,
              'recentScore': null,
              'homeCourse': 'None',
              'achievements': [],
            };
          }

          final totalRounds = rounds.length;
          final totalScore = rounds.fold<int>(0, (sum, r) => sum + (r['totalScore'] as int));
          final avgScore = totalScore / totalRounds;
          
          // Best score
          final bestScore = rounds.map((r) => r['totalScore'] as int).reduce((a, b) => a < b ? a : b);
          
          // Sort by playedAt for recent round
          final sortedRounds = List<Map<String, dynamic>>.from(rounds);
          sortedRounds.sort((a, b) => DateTime.parse(b['playedAt']).compareTo(DateTime.parse(a['playedAt'])));
          final recentRound = sortedRounds.first;

          // Fetch course name if needed (Wait, stream data might not include joined tables)
          // In real-time streams, Joins are tricky. We might need a separate fetch or use the data already in the stream.
          String courseName = recentRound['courseName'] ?? 'Unknown Course';

          final achievements = [];
          if (bestScore < 80) achievements.add({'id': 'breaking_80', 'title': 'Breaking 80', 'icon': 'trophy'});
          if (totalRounds >= 10) achievements.add({'id': 'veteran', 'title': 'Veteran', 'icon': 'medal'});

          return {
            'totalRounds': totalRounds,
            'avgScore': double.parse(avgScore.toStringAsFixed(1)),
            'bestScore': bestScore,
            'recentScore': {
              'score': recentRound['totalScore'],
              'date': recentRound['playedAt'],
              'course': courseName,
            },
            'homeCourse': courseName,
            'achievements': achievements
          };
        });
  }

  /// Called automatically on login. Ensures every user has a Friend Code
  /// without requiring them to manually trigger a profile sync.
  ///
  /// Designed to be instant: writes locally first so the QR dialog
  /// updates in < 1 second, then pushes to Supabase in the background.
  Future<void> ensureFriendCode() async {
    if (_uid == null) return;
    try {
      // 1. Already have one locally? Nothing to do — fast path.
      final localProfile = await _database.getProfile(_uid);
      if (localProfile?.friendCode != null) return;

      // 2. Generate a brand-new code immediately (no network wait).
      //    We'll reconcile with any existing remote code afterwards.
      final friendCode = _generateFriendCode();

      // 3. Write locally FIRST — this is what makes the QR dialog update instantly.
      if (localProfile == null) {
        await _database.insertProfile(
          db.UserProfilesCompanion(
            uid: drift.Value(_uid),
            friendCode: drift.Value(friendCode),
          ),
        );
      } else {
        await _database.updateProfile(
          _uid,
          db.UserProfilesCompanion(friendCode: drift.Value(friendCode)),
        );
      }
      debugPrint('FriendService: Friend code saved locally → $friendCode');

      // 4. Patch just the friendCode on the existing Supabase row (background).
      //    Use update() not upsert() — avoids the not-null email constraint
      //    on accounts that haven't completed their profile yet.
      //    syncMyProfileToCloud() will write the full row when they do.
      _supabase
          .from('User')
          .update({'friendCode': friendCode})
          .eq('id', _uid)
          .then((_) {
        debugPrint('FriendService: Friend code synced to Supabase → $friendCode');
      }).catchError((e) {
        debugPrint('FriendService: Friend code Supabase sync failed (non-fatal): $e');
      });

    } catch (e) {
      debugPrint('FriendService: ensureFriendCode failed: $e');
    }
  }

  // Debounce guard — prevents runaway calls when listener fires on every rebuild
  DateTime? _lastProfileSync;

  Future<void> syncMyProfileToCloud({
    required String name,
    required String email,
    String? avatarUrl,
    double? handicapIndex,
  }) async {
    if (_uid == null) return;
    // Rate-limit to once every 30 seconds
    final now = DateTime.now();
    if (_lastProfileSync != null && now.difference(_lastProfileSync!).inSeconds < 30) return;
    _lastProfileSync = now;
    try {
      // Check if we already have a friend code locally
      final localProfile = await _database.getProfile(_uid);
      String? friendCode = localProfile?.friendCode;

      // If not, check if one exists remotely (avoids overwriting on multi-device)
      if (friendCode == null) {
        final remoteData = await _supabase
            .from('User')
            .select('friendCode')
            .eq('id', _uid)
            .maybeSingle();
        friendCode = remoteData?['friendCode'] as String?;
      }

      // Still null — generate a fresh one
      friendCode ??= _generateFriendCode();

      // Persist locally
      await _database.updateProfile(
        _uid,
        db.UserProfilesCompanion(friendCode: drift.Value(friendCode)),
      );

      await _supabase.from('User').upsert({
        'id': _uid,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'handicapIndex': handicapIndex ?? 0.0,
        'friendCode': friendCode,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('FriendService: Profile synced to cloud (friendCode: $friendCode)');
    } catch (e) {
      debugPrint('FriendService ERROR: Profile sync failed: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String identifier) async {
    try {
      final isFriendCode = identifier.toUpperCase().startsWith('SC-');

      if (isFriendCode) {
        // --- Friend Code Lookup ---
        debugPrint('FriendService: Looking up by friendCode: $identifier');
        final response = await _supabase
            .from('User')
            .select('id, name, avatarUrl, handicapIndex, skillLevel, playStyle, friendCode')
            .eq('friendCode', identifier.toUpperCase())
            .limit(1);
        if ((response as List).isNotEmpty) {
          final data = response.first;
          debugPrint('FriendService: Found profile by friendCode');
          return _mapProfileData(data);
        }
        debugPrint('FriendService: No profile found for friendCode $identifier');
        return null;
      }

      // --- Primary: lookup by Supabase UUID 'id' ---
      debugPrint('FriendService: Looking up by id: $identifier');
      final response = await _supabase
          .from('User')
          .select('id, name, avatarUrl, handicapIndex, skillLevel, playStyle, friendCode')
          .eq('id', identifier)
          .limit(1);

      if ((response as List).isNotEmpty) {
        debugPrint('FriendService: Found profile by id');
        return _mapProfileData(response.first);
      }

      // --- Fallback: legacy firebaseUid ---
      debugPrint('FriendService: id lookup failed, trying firebaseUid');
      final fallback = await _supabase
          .from('User')
          .select('id, name, avatarUrl, handicapIndex, skillLevel, playStyle, friendCode')
          .eq('firebaseUid', identifier)
          .limit(1);

      if ((fallback as List).isNotEmpty) {
        debugPrint('FriendService: Found profile by firebaseUid');
        return _mapProfileData(fallback.first);
      }

      debugPrint('FriendService: No profile found in User table for: $identifier');
      return null;
    } catch (e, stack) {
      debugPrint('FriendService: Critical Error fetching profile: $e\n$stack');
      return null;
    }
  }

  Map<String, dynamic> _mapProfileData(Map<String, dynamic> data) {
    return {
      'uid': data['id'],
      'name': data['name'],
      'avatarUrl': data['avatarUrl'],
      'handicapIndex': data['handicapIndex'],
      'skillLevel': data['skillLevel'],
      'playStyle': data['playStyle'],
      'friendCode': data['friendCode'],
    };
  }

  Future<bool> addFriend(String friendUid) async {
    return sendFriendRequest(friendUid);
  }

  Future<void> removeFriend(String friendId) async {
    if (_uid == null) return;

    // 1. Delete from local DB
    await (_database.delete(_database.friends)..where((f) => f.friendId.equals(friendId))).go();

    // 2. Delete from Supabase Friend list (either direction)
    await _supabase.from('Friend').delete().eq('userId', _uid).eq('friendId', friendId);
    await _supabase.from('Friend').delete().eq('userId', friendId).eq('friendId', _uid);
  }
}
