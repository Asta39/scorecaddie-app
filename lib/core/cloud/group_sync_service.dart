import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';
import 'dart:math';

final groupSyncServiceProvider = Provider<GroupSyncService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return GroupSyncService(user?.uid);
});

class GroupSyncService {
  final String? _uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GroupSyncService(this._uid);

  // Generate a random 6-character alphanumeric code
  String _generateRoundCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  Future<String?> createGroupRound({
    required int courseId,
    required String courseName,
    required String scoringMode,
  }) async {
    if (_uid == null) return null;

    final roundCode = _generateRoundCode();
    final docRef = _firestore.collection('group_rounds').doc();
    
    final roundData = {
      'roundId': docRef.id,
      'roundCode': roundCode,
      'captainId': _uid,
      'courseId': courseId,
      'courseName': courseName,
      'status': 'PENDING',
      'scoringMode': scoringMode,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'participants': [
        {
          'userId': _uid,
          'role': 'CAPTAIN',
          'status': 'JOINED',
        }
      ],
      'scores': {},
    };

    await docRef.set(roundData);
    return roundCode;
  }

  Future<bool> joinGroupRound(String roundCode) async {
    if (_uid == null) return false;

    final query = await _firestore
        .collection('group_rounds')
        .where('roundCode', isEqualTo: roundCode.toUpperCase())
        .where('status', isEqualTo: 'PENDING')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final doc = query.docs.first;
    final participants = List.from(doc.data()['participants'] as List);
    
    // Check if already in
    if (participants.any((p) => p['userId'] == _uid)) return true;

    participants.add({
      'userId': _uid,
      'role': 'PLAYER',
      'status': 'JOINED',
    });

    await doc.reference.update({
      'participants': participants,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Stream<DocumentSnapshot> watchGroupRound(String roundId) {
    return _firestore.collection('group_rounds').doc(roundId).snapshots();
  }

  Future<void> updateHoleScore({
    required String firestoreRoundId,
    required int holeNumber,
    required Map<String, dynamic> scoreData,
  }) async {
    if (_uid == null) return;

    await _firestore.collection('group_rounds').doc(firestoreRoundId).update({
      'scores.$_uid.hole$holeNumber': {
        ...scoreData,
        'timestamp': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> finalizeRound(String firestoreRoundId) async {
    if (_uid == null) return;
    await _firestore.collection('group_rounds').doc(firestoreRoundId).update({
      'status': 'COMPLETED',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
