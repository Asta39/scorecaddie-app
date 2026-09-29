import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../database/database.dart' as db;
import '../cloud/sync_service.dart';

class FriendService {
  final db.AppDatabase _database;
  // ignore: unused_field
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

  /// Turns what someone typed or scanned into a friend code: trims it,
  /// upper-cases it and restores the "SC-XXXX-XXXX" dashes if they were left
  /// out. Returns null when it can't be a friend code.
  static String? normalizeFriendCode(String input) {
    final raw = input.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    final body = raw.length == 10 && raw.startsWith('SC') ? raw.substring(2) : raw;
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(body)) return null;
    return 'SC-${body.substring(0, 4)}-${body.substring(4)}';
  }

  /// Sends a friend request, or completes the friendship when the other
  /// golfer already asked us. Friendships live in the Friend table as one row
  /// per request; either direction counts, so a pair is never stored twice.
  Future<FriendRequestResult> sendFriendRequest(String targetUid) async {
    if (_uid == null) return FriendRequestResult.failed;
    if (targetUid == _uid) return FriendRequestResult.self;

    // Already friends on this phone: nothing to ask.
    final local = await (_database.select(_database.friends)
          ..where((f) => f.userId.equals(_uid) & f.friendId.equals(targetUid)))
        .get();
    if (local.isNotEmpty) return FriendRequestResult.alreadyFriends;

    try {
      final rows = await _supabase
          .from('Friend')
          .select('id, userId, friendId, status')
          .or('and(userId.eq.$_uid,friendId.eq.$targetUid),and(userId.eq.$targetUid,friendId.eq.$_uid)');
      final pair = List<Map<String, dynamic>>.from(rows);

      if (pair.any((r) => r['status'] == 'ACCEPTED')) {
        await syncFriends();
        return FriendRequestResult.alreadyFriends;
      }

      // They asked us first: accepting that request makes us friends.
      final theirs = pair.where((r) => r['userId'] == targetUid).firstOrNull;
      if (theirs != null) {
        await _supabase
            .from('Friend')
            .update({'status': 'ACCEPTED', 'updatedAt': DateTime.now().toIso8601String()})
            .eq('id', theirs['id']);
        await syncFriends();
        return FriendRequestResult.nowFriends;
      }

      if (pair.any((r) => r['userId'] == _uid)) return FriendRequestResult.alreadySent;

      await _supabase.from('Friend').insert({
        'userId': _uid,
        'friendId': targetUid,
        'status': 'PENDING',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return FriendRequestResult.sent;
    } catch (e) {
      debugPrint('FriendService: sendFriendRequest failed: $e');
      return FriendRequestResult.failed;
    }
  }

  /// Makes the friends list on this phone match the server: every ACCEPTED
  /// row in either direction, once per golfer. Removes friends who were
  /// removed elsewhere and clears duplicates left by older versions.
  Future<void> syncFriends() async {
    if (_uid == null) return;
    try {
      final rows = await _supabase
          .from('Friend')
          .select('userId, friendId')
          .eq('status', 'ACCEPTED')
          .or('userId.eq.$_uid,friendId.eq.$_uid');
      final others = <String>{
        for (final r in List<Map<String, dynamic>>.from(rows)) (r['userId'] == _uid ? r['friendId'] : r['userId']) as String,
      }..remove(_uid);

      final profiles = <String, Map<String, dynamic>>{};
      if (others.isNotEmpty) {
        final data = await _supabase.from('User').select('id, name, avatarUrl').inFilter('id', others.toList());
        for (final p in List<Map<String, dynamic>>.from(data)) {
          profiles[p['id'] as String] = p;
        }
      }

      await _database.transaction(() async {
        final existing = await (_database.select(_database.friends)..where((f) => f.userId.equals(_uid))).get();
        final kept = <String>{};
        for (final f in existing) {
          // Drop anyone no longer a friend, and any second copy of a friend.
          if (!others.contains(f.friendId) || !kept.add(f.friendId)) {
            await (_database.delete(_database.friends)..where((x) => x.id.equals(f.id))).go();
          }
        }
        for (final id in others) {
          final p = profiles[id];
          final update = db.FriendsCompanion(
            friendName: drift.Value(p?['name'] as String? ?? 'Golfer'),
            friendAvatar: drift.Value(p?['avatarUrl'] as String?),
          );
          if (kept.contains(id)) {
            await (_database.update(_database.friends)..where((f) => f.userId.equals(_uid) & f.friendId.equals(id))).write(update);
          } else {
            await _database.into(_database.friends).insert(update.copyWith(userId: drift.Value(_uid), friendId: drift.Value(id)));
          }
        }
      });
    } catch (e) {
      debugPrint('FriendService: syncFriends failed: $e');
    }
  }

  /// Friend requests sent to me that are waiting for an answer.
  ///
  /// Realtime isn't enabled for the Friend table, so a realtime `.stream()`
  /// silently never delivered anything. This polls: now, every 20 seconds,
  /// and right after I answer one. Each poll also refreshes the friends list,
  /// which is how the sender learns their request was accepted.
  Stream<List<Map<String, dynamic>>> watchIncomingRequests() {
    if (_uid == null) return Stream.value([]);
    late final StreamController<List<Map<String, dynamic>>> c;
    Timer? timer;
    Future<void> load() async {
      try {
        final rows = await _supabase
            .from('Friend')
            .select('id, userId')
            .eq('friendId', _uid)
            .eq('status', 'PENDING')
            .order('updatedAt', ascending: false);
        final list = List<Map<String, dynamic>>.from(rows);
        final ids = list.map((r) => r['userId'] as String).toSet().toList();
        final profiles = <String, Map<String, dynamic>>{};
        if (ids.isNotEmpty) {
          final data = await _supabase.from('User').select('id, name, avatarUrl').inFilter('id', ids);
          for (final p in List<Map<String, dynamic>>.from(data)) {
            profiles[p['id'] as String] = p;
          }
        }
        final seen = <String>{};
        if (!c.isClosed) {
          c.add([
            for (final r in list)
              if (seen.add(r['userId'] as String))
                {
                  'id': r['id'],
                  'from': r['userId'],
                  'fromName': profiles[r['userId']]?['name'] ?? 'Golfer',
                  'fromAvatar': profiles[r['userId']]?['avatarUrl'],
                },
          ]);
        }
      } catch (e) {
        debugPrint('FriendService: loading requests failed: $e');
        if (!c.isClosed) c.add(const []);
      }
      await syncFriends();
    }

    void poke() => load();
    c = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        _pokes.add(poke);
        load();
        timer = Timer.periodic(const Duration(seconds: 20), (_) => load());
      },
      onCancel: () {
        _pokes.remove(poke);
        timer?.cancel();
      },
    );
    return c.stream;
  }

  final _pokes = <void Function()>{};
  void _refresh() {
    for (final p in _pokes.toList()) {
      p();
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    if (_uid == null) return;
    try {
      if (accept) {
        // Only the golfer the request was sent to can accept it.
        await _supabase
            .from('Friend')
            .update({'status': 'ACCEPTED', 'updatedAt': DateTime.now().toIso8601String()})
            .eq('id', requestId)
            .eq('friendId', _uid);
        await syncFriends();
      } else {
        await _supabase.from('Friend').delete().eq('id', requestId).eq('friendId', _uid);
      }
    } catch (e) {
      debugPrint('FriendService: respondToRequest failed: $e');
    } finally {
      _refresh();
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
      final localProfile = await _database.getProfile(_uid);
      final local = localProfile?.friendCode;

      // The code on the server is the one friends type and scan, so it wins.
      // This used to make a fresh code whenever the phone had none, which
      // replaced a golfer's code after a reinstall and broke codes they had
      // already shared.
      String? remote;
      try {
        final row = await _supabase.from('User').select('friendCode').eq('id', _uid).maybeSingle();
        remote = row?['friendCode'] as String?;
      } catch (_) {
        // Offline: keep whatever this phone has and try again next launch.
        if (local != null) return;
      }

      final code = remote ?? local ?? _generateFriendCode();
      if (code != local) {
        if (localProfile == null) {
          await _database.insertProfile(db.UserProfilesCompanion(uid: drift.Value(_uid), friendCode: drift.Value(code)));
        } else {
          await _database.updateProfile(_uid, db.UserProfilesCompanion(friendCode: drift.Value(code)));
        }
      }
      if (remote == null) {
        // Update, not upsert: a profile that isn't finished yet has no email,
        // which the User row requires.
        await _supabase.from('User').update({'friendCode': code}).eq('id', _uid);
      }
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
    identifier = identifier.trim();
    try {
      final code = normalizeFriendCode(identifier);

      if (code != null) {
        identifier = code;
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


  Future<void> removeFriend(String friendId) async {
    if (_uid == null) return;

    // 1. Delete from local DB
    await (_database.delete(_database.friends)..where((f) => f.friendId.equals(friendId))).go();

    // 2. Delete from Supabase Friend list (either direction)
    try {
      await _supabase.from('Friend').delete().eq('userId', _uid).eq('friendId', friendId);
      await _supabase.from('Friend').delete().eq('userId', friendId).eq('friendId', _uid);
    } catch (e) {
      debugPrint('FriendService: removeFriend failed: $e');
    }
  }
}

enum FriendRequestResult { sent, nowFriends, alreadySent, alreadyFriends, self, failed }
