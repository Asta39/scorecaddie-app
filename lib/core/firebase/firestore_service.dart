import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/database.dart'; // Using Drift models

/// Service for handling cloud data synchronization with Firestore.
/// Employs a local-first architecture where Drift is the source of truth,
/// and this service pushes/pulls data to the cloud.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Collection References ---
  
  /// Global courses collection (shared across all users)
  CollectionReference<Map<String, dynamic>> get _coursesRef => 
      _db.collection('courses');

  /// User documents (profiles, settings)
  CollectionReference<Map<String, dynamic>> get _usersRef => 
      _db.collection('users');

  /// User's private rounds subcollection
  CollectionReference<Map<String, dynamic>>? get _userRoundsRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _usersRef.doc(uid).collection('rounds');
  }

  // --- User Profiles ---

  /// Sync local user profile to Firestore
  Future<void> syncUserProfile(UserProfile profile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return; // User must be signed in to sync

    await _usersRef.doc(uid).set({
      'name': profile.name,
      'avatarUrl': profile.avatarUrl,
      'handicap': profile.handicap,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- Rounds & Hole Scores ---

  /// Push a round (and its hole scores) to Firestore
  Future<String?> pushRound(Round round, List<HoleScore> holeScores) async {
    final roundsRef = _userRoundsRef;
    if (roundsRef == null) return null;

    final docRef = round.syncId != null && round.syncId!.isNotEmpty
        ? roundsRef.doc(round.syncId)
        : roundsRef.doc(); // Create new ID if not synced yet

    // Convert hole scores to a nested list of maps
    final scoresData = holeScores.map((h) => {
      'holeNumber': h.holeNumber,
      'par': h.par,
      'score': h.score,
      'yardage': h.yardage,
    }).toList();

    await docRef.set({
      'courseId': round.courseId,
      'courseName': round.courseName,
      'holesPlayed': round.holesPlayed,
      'tee': round.tee,
      'totalScore': round.totalScore,
      'coursePar': round.coursePar,
      'scoreVsPar': round.scoreVsPar,
      'front9Score': round.front9Score,
      'back9Score': round.back9Score,
      'notes': round.notes,
      'playedAt': round.playedAt.toIso8601String(),
      'scores': scoresData, // Embedded sub-array for fast reading
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return docRef.id; // Return the firestore ID to save back to local syncId
  }

  /// Delete a round from Firestore
  Future<void> deleteRound(String syncId) async {
    final roundsRef = _userRoundsRef;
    if (roundsRef == null) return;
    
    await roundsRef.doc(syncId).delete();
  }

  // --- Courses ---

  /// Fetch all global courses from Firestore
  Future<List<Map<String, dynamic>>> fetchGlobalCourses() async {
    final snapshot = await _coursesRef.get();
    return snapshot.docs.map((doc) => {'syncId': doc.id, ...doc.data()}).toList();
  }
}
