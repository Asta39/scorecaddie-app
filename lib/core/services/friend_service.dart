import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart' as db;
import '../cloud/sync_service.dart';
import '../../providers/app_providers.dart';


class FriendService {
  final db.AppDatabase _database;
  final SyncService _sync;
  final String? _uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FriendService(this._database, this._sync, this._uid);

  Future<bool> sendFriendRequest(String targetUid) async {
    if (_uid == null || targetUid == _uid) return false;

    // 1. Check if already friends
    final existing = await (_database.select(_database.friends)..where((f) => f.friendId.equals(targetUid))).get().then((rows) => rows.firstOrNull);
    if (existing != null) return false;

    // 2. Fetch target profile for validation and display data
    final targetDoc = await _sync.getProfileSnapshot(targetUid);
    if (targetDoc == null) return false;
    final targetData = targetDoc.data() as Map<String, dynamic>;

    // 3. Fetch sender profile
    final myDoc = await _sync.getProfileSnapshot(_uid!);
    final myData = myDoc?.data() as Map<String, dynamic>? ?? {};

    // 4. Create request in Firestore
    final requestId = _uid! + '_' + targetUid;
    await _firestore.collection('friend_requests').doc(requestId).set({
      'from': _uid,
      'to': targetUid,
      'fromName': myData['name'] ?? 'Golfer',
      'fromAvatar': myData['avatarUrl'],
      'toName': targetData['name'] ?? 'Golfer',
      'toAvatar': targetData['avatarUrl'],
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Stream<List<Map<String, dynamic>>> streamIncomingRequests() {
    if (_uid == null) return Stream.value([]);
    return _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    if (_uid == null) return;

    final docRef = _firestore.collection('friend_requests').doc(requestId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final fromUid = data['from'] as String;

    if (accept) {
      // 1. Add to local DB (both sides will sync via SyncService eventually, but let's do local now)
      await _database.into(_database.friends).insert(db.FriendsCompanion.insert(
        userId: _uid!,
        friendId: fromUid,
        friendName: drift.Value(data['fromName'] as String? ?? 'Golfer'),
        friendAvatar: drift.Value(data['fromAvatar'] as String?),
      ));

      // 2. Mark as accepted
      await docRef.update({'status': 'accepted'});
      
      // 3. Also add reciprocal friend in Firestore (so the sender sees it on their next pull)
      await _firestore.collection('users').doc(_uid).collection('friends').doc(fromUid).set({
        'friendId': fromUid,
        'friendName': data['fromName'],
        'friendAvatar': data['fromAvatar'],
        'addedAt': DateTime.now().toIso8601String(),
      });
      
      await _firestore.collection('users').doc(fromUid).collection('friends').doc(_uid).set({
        'friendId': _uid,
        'friendName': data['toName'],
        'friendAvatar': data['toAvatar'],
        'addedAt': DateTime.now().toIso8601String(),
      });
    } else {
      // Mark as declined
      await docRef.update({'status': 'declined'});
    }
  }

  Future<Map<String, dynamic>?> fetchProfile(String uid) async {
    final doc = await _sync.getProfileSnapshot(uid);
    return doc?.data() as Map<String, dynamic>?;
  }

  Future<bool> addFriend(String friendUid) async {
    // Legacy direct add - keep for QR code if we want it instant, but maybe better to use request
    return sendFriendRequest(friendUid);
  }
}
