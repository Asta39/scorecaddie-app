import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';


class SyncService {
  final db.AppDatabase _database;
  final String? _uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  SyncService(this._database, this._uid);

  Future<String?> uploadShotVideo(File videoFile, String shotFirestoreId) async {
    if (_uid == null) return null;
    
    final ref = _storage.ref().child('users/$_uid/practice_videos/$shotFirestoreId.mp4');
    final uploadTask = await ref.putFile(videoFile, SettableMetadata(contentType: 'video/mp4'));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String?> uploadClubPhoto(File photoFile, String clubFirestoreId) async {
    if (_uid == null) return null;
    
    final ref = _storage.ref().child('users/$_uid/club_photos/$clubFirestoreId.jpg');
    final uploadTask = await ref.putFile(photoFile, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> syncRound(db.Round round, List<db.HoleScore> holes) async {
    if (_uid == null || round.firestoreId == null) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('rounds')
        .doc(round.firestoreId);
    
    final roundData = {
      'courseId': round.courseId,
      'courseName': round.courseName,
      'holesPlayed': round.holesPlayed,
      'totalScore': round.totalScore,
      'coursePar': round.coursePar,
      'scoreVsPar': round.scoreVsPar,
      'front9Score': round.front9Score,
      'back9Score': round.back9Score,
      'playedAt': round.playedAt.toIso8601String(),
      'syncedAt': FieldValue.serverTimestamp(),
      'holes': holes.map((h) => {
        'holeNumber': h.holeNumber,
        'par': h.par,
        'score': h.score,
        'yardage': h.yardage,
        'putts': h.putts,
        'fairwayHit': h.fairwayHit,
        'penalties': h.penalties,
      }).toList(),
    };
    
    await docRef.set(roundData, SetOptions(merge: true));
  }

  Future<void> pullRounds() async {
    if (_uid == null) return;
    
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('rounds')
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      
      final playedAt = DateTime.parse(data['playedAt'] as String);
      
      await _database.transaction(() async {
        await _database.upsertRound(
          db.RoundsCompanion.insert(
            firestoreId: drift.Value(firestoreId),
            courseId: data['courseId'] as int,
            courseName: drift.Value(data['courseName'] as String),
            holesPlayed: drift.Value(data['holesPlayed'] as int),
            tee: drift.Value(data['tee'] ?? ''),
            totalScore: data['totalScore'] as int,
            scoreVsPar: data['scoreVsPar'] as int,
            coursePar: data['coursePar'] as int,
            front9Score: drift.Value(data['front9Score'] as int?),
            back9Score: drift.Value(data['back9Score'] as int?),
            playedAt: drift.Value(playedAt),
            userId: drift.Value(_uid),
          )
        );
        
        final existingRound = await _database.getRoundByFirestoreId(firestoreId);
        if (existingRound == null) return;
        
        // Insert Hole Scores
        final holesData = data['holes'] as List<dynamic>;
        // Delete existing hole scores first to avoid orphans if the hole count changed
        await (_database.delete(_database.holeScores)..where((h) => h.roundId.equals(existingRound.id))).go();
        
        for (var hData in holesData) {
          await _database.into(_database.holeScores).insert(
            db.HoleScoresCompanion.insert(
              roundId: existingRound.id,
              holeNumber: hData['holeNumber'] as int,
              par: hData['par'] as int,
              score: hData['score'] as int,
              yardage: drift.Value(hData['yardage'] as int?),
              putts: drift.Value(hData['putts'] as int?),
              fairwayHit: drift.Value(hData['fairwayHit'] as String?),
              penalties: drift.Value(hData['penalties'] as int?),
            )
          );
        }
      });
    }
  }

  Future<void> syncCourse(db.Course course) async {
    if (_uid == null || course.firestoreId == null) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('custom_courses')
        .doc(course.firestoreId);
        
    final courseData = {
      'name': course.name,
      'location': course.location,
      'totalHoles': course.totalHoles,
      'par18': course.par18,
      'par9front': course.par9front,
      'par9back': course.par9back,
      'holePars': course.holePars,
      'teeData': course.teeData,
      'syncedAt': FieldValue.serverTimestamp(),
    };
    
    await docRef.set(courseData, SetOptions(merge: true));
  }

  Future<void> pullCourses() async {
    if (_uid == null) return;
    
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('custom_courses')
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      
      await _database.upsertCourse(
        db.CoursesCompanion.insert(
          firestoreId: drift.Value(firestoreId),
          name: data['name'] as String,
          location: drift.Value(data['location'] as String),
          totalHoles: drift.Value(data['totalHoles'] as int),
          par18: drift.Value(data['par18'] as int?),
          par9front: drift.Value(data['par9front'] as int?),
          par9back: drift.Value(data['par9back'] as int?),
          holePars: drift.Value(data['holePars'] as String? ?? '[]'),
          teeData: drift.Value(data['teeData'] as String? ?? '[]'),
          userId: drift.Value(_uid),
        )
      );
    }
  }

  Future<String?> uploadProfilePhoto(File photoFile) async {
    if (_uid == null) return null;
    final ref = _storage.ref().child('users/$_uid/profile_photo.jpg');
    final uploadTask = await ref.putFile(photoFile, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> syncProfile(db.UserProfile profile) async {
    if (_uid == null) return;
    
    String? avatarUrl = profile.avatarUrl;
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      final file = File(avatarUrl);
      if (await file.exists()) {
        final uploadedUrl = await uploadProfilePhoto(file);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
          // Update local DB so we don't re-upload
          await _database.updateProfile(_uid!, db.UserProfilesCompanion(avatarUrl: drift.Value(uploadedUrl)));
        }
      }
    }

    // Get best score from local DB to sync
    final bestScore = await _database.getBestScore(_uid!);

    final docRef = _firestore.collection('profiles').doc(_uid);
    await docRef.set({
      'email': profile.email,
      'name': profile.name,
      'avatarUrl': avatarUrl,
      'skillLevel': profile.skillLevel,
      'homeCourse': profile.homeCourseName,
      'privacyLevel': profile.privacyLevel,
      'units': profile.units,
      'themeMode': profile.themeMode,
      'role': profile.role,
      'profileComplete': profile.profileComplete,
      'handicap': profile.handicap,
      'bestScore': bestScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> pullProfile() async {
    if (_uid == null) return;
    final doc = await _firestore.collection('profiles').doc(_uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      await _database.upsertProfile(db.UserProfilesCompanion(
        firebaseUid: drift.Value(_uid!),
        email: drift.Value(data['email'] as String?),
        name: drift.Value(data['name'] as String? ?? 'Golfer'),
        avatarUrl: drift.Value(data['avatarUrl'] as String?),
        skillLevel: drift.Value(data['skillLevel'] as String?),
        homeCourseName: drift.Value(data['homeCourse'] as String?),
        privacyLevel: drift.Value(data['privacyLevel'] as String? ?? 'Private'),
        units: drift.Value(data['units'] as String? ?? 'Yards'),
        themeMode: drift.Value(data['themeMode'] as String? ?? 'System'),
        role: drift.Value(data['role'] as String?),
        profileComplete: drift.Value(data['profileComplete'] as bool? ?? false),
        updatedAt: drift.Value(DateTime.now()),
      ));
    }
  }

  Future<Map<String, dynamic>?> getPublicProfileData(String uid) async {
    final doc = await _firestore.collection('profiles').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<db.UserProfile?> getPublicProfile(String uid) async {
    final doc = await _firestore.collection('profiles').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final companion = db.UserProfilesCompanion(
        firebaseUid: drift.Value(uid),
        name: drift.Value(data['name'] as String? ?? ''),
        avatarUrl: drift.Value(data['avatarUrl'] as String?),
        skillLevel: drift.Value(data['skillLevel'] as String?),
        homeCourseName: drift.Value(data['homeCourse'] as String?),
        privacyLevel: drift.Value(data['privacyLevel'] as String? ?? 'Private'),
        units: drift.Value(data['units'] as String? ?? 'Yards'),
        themeMode: drift.Value(data['themeMode'] as String? ?? 'System'),
        updatedAt: drift.Value(DateTime.now()),
      );
      
      await _database.updateProfile(uid, companion);
      return await _database.getProfile(uid);
    }
    return await _database.getProfile(uid);
  }

  Future<DocumentSnapshot?> getProfileSnapshot(String uid) async {
    final doc = await _firestore.collection('profiles').doc(uid).get();
    return doc.exists ? doc : null;
  }

  Future<void> syncProvider(db.Provider provider) async {
    if (_uid == null) return;
    
    final docRef = _firestore.collection('providers').doc(_uid);
    await docRef.set({
      'role': provider.role,
      'name': provider.name,
      'phone': provider.phone,
      'whatsapp': provider.whatsapp,
      'experience': provider.experience,
      'courses': provider.coursesJson,
      'specializations': provider.specializationsJson,
      'availability': provider.availabilityJson,
      'price': provider.price,
      'rating': provider.rating,
      'totalReviews': provider.totalReviews,
      'totalBookings': provider.totalBookings,
      'totalCalls': provider.totalCalls,
      'profileComplete': provider.profileComplete,
      'certificationUrl': provider.certificationUrl,
      'bio': provider.bio,
      'personalityType': provider.personalityType,
      'coachingLocation': provider.coachingLocation,
      'coachingStyles': provider.coachingStylesJson,
      'sessionTypes': provider.sessionTypesJson,
      'hasCertification': provider.hasCertification,
      'certificationName': provider.certificationName,
      'views': provider.views,
      'streak': provider.streak,
      'isAvailable': provider.isAvailable, // Added real-time availability
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Pulls all public provider documents from the top-level `providers`
  /// collection and upserts them into the local SQLite `providers` table.
  Future<void> pullProviders() async {
    final snapshot = await _firestore.collection('providers').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final providerId = doc.id; // This is the provider's Firebase UID

      await _database.upsertProvider(db.ProvidersCompanion(
        userId: drift.Value(providerId),
        role: drift.Value(data['role'] as String? ?? ''),
        name: drift.Value(data['name'] as String? ?? ''),
        phone: drift.Value(data['phone'] as String? ?? ''),
        whatsapp: drift.Value(data['whatsapp'] as String?),
        experience: drift.Value(data['experience'] as int? ?? 0),
        coursesJson: drift.Value(data['courses'] as String? ?? '[]'),
        specializationsJson: drift.Value(data['specializations'] as String?),
        availabilityJson: drift.Value(data['availability'] as String? ?? '{}'),
        price: drift.Value((data['price'] as num?)?.toDouble()),
        rating: drift.Value((data['rating'] as num?)?.toDouble() ?? 0.0),
        totalReviews: drift.Value(data['totalReviews'] as int? ?? 0),
        totalBookings: drift.Value(data['totalBookings'] as int? ?? 0),
        totalCalls: drift.Value(data['totalCalls'] as int? ?? 0),
        profileComplete: drift.Value(data['profileComplete'] as bool? ?? false),
        certificationUrl: drift.Value(data['certificationUrl'] as String?),
        bio: drift.Value(data['bio'] as String?),
        personalityType: drift.Value(data['personalityType'] as String?),
        coachingLocation: drift.Value(data['coachingLocation'] as String?),
        coachingStylesJson: drift.Value(data['coachingStyles'] as String?),
        sessionTypesJson: drift.Value(data['sessionTypes'] as String?),
        hasCertification: drift.Value(data['hasCertification'] as bool? ?? false),
        certificationName: drift.Value(data['certificationName'] as String?),
        views: drift.Value(data['views'] as int? ?? 0),
        streak: drift.Value(data['streak'] as int? ?? 0),
        isAvailable: drift.Value(data['isAvailable'] as bool? ?? true),
      ));
    }
  }

  /// Writes a single interaction row to Firestore.
  Future<void> syncInteraction(db.Interaction interaction) async {
    if (_uid == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('interactions')
        .doc('${interaction.playerId}_${interaction.providerId}_${interaction.type}');

    await docRef.set({
      'playerId': interaction.playerId,
      'providerId': interaction.providerId,
      'type': interaction.type,
      'status': interaction.status,
      'timestamp': interaction.timestamp.toIso8601String(),
      'lastPromptedAt': interaction.lastPromptedAt?.toIso8601String(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Practice Sync ───

  Future<void> syncPracticeSession(db.PracticeSession session) async {
    if (_uid == null || session.firestoreId == null) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('practice_sessions')
        .doc(session.firestoreId);
        
    // Map drillId to firestoreId
    String? drillFirestoreId;
    if (session.drillId != null) {
      final drill = await (_database.select(_database.drills)..where((d) => d.id.equals(session.drillId!))).get().then((list) => list.firstOrNull);
      drillFirestoreId = drill?.firestoreId;
    }

    await docRef.set({
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'totalBalls': session.totalBalls,
      'sessionType': session.sessionType,
      'locationName': session.locationName,
      'drillId_v2': drillFirestoreId, // Use Firestore ID for cross-device reference
      'targetDistance': session.targetDistance,
      'notes': session.notes,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncPracticeShot(db.PracticeShot shot) async {
    if (_uid == null || shot.firestoreId == null) return;

    // Get session firestoreId first
    final session = await (_database.select(_database.practiceSessions)..where((s) => s.id.equals(shot.sessionId))).get().then((list) => list.firstOrNull);
    if (session == null || session.firestoreId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('practice_sessions')
        .doc(session.firestoreId)
        .collection('shots')
        .doc(shot.firestoreId);
        
    // Map clubId to firestoreId
    final club = await (_database.select(_database.clubs)..where((c) => c.id.equals(shot.clubId))).get().then((list) => list.firstOrNull);
    final clubFirestoreId = club?.firestoreId;

    await docRef.set({
      'clubId_v2': clubFirestoreId, // Use Firestore ID for cross-device reference
      'distance': shot.distance,
      'quality': shot.quality,
      'shotShape': shot.shotShape,
      'timestamp': shot.timestamp.toIso8601String(),
      'ballFlightJson': shot.ballFlightJson,
      'videoUrl': shot.videoUrl, // Added for AI Shot Analyzer
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncDrill(db.Drill drill) async {
    if (_uid == null || drill.firestoreId == null) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('drills')
        .doc(drill.firestoreId);
        
    await docRef.set({
      'name': drill.name,
      'description': drill.description,
      'difficulty': drill.difficulty,
      'durationMinutes': drill.durationMinutes,
      'category': drill.category,
      'icon': drill.icon,
      'isCustom': drill.isCustom,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncDrillStep(db.DrillStep step) async {
    if (_uid == null) return;
    
    final drill = await (_database.select(_database.drills)..where((d) => d.id.equals(step.drillId))).get().then((list) => list.firstOrNull);
    if (drill == null || drill.firestoreId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('drills')
        .doc(drill.firestoreId)
        .collection('steps')
        .doc(step.id.toString());
        
    await docRef.set({
      'stepOrder': step.stepOrder,
      'instruction': step.instruction,
      'targetDistance': step.targetDistance,
      'ballsRequired': step.ballsRequired,
      'clubType': step.clubType,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Club & Friend Sync ───

  Future<void> syncClub(db.Club club) async {
    if (_uid == null || club.firestoreId == null) return;
    
    // Handle photo upload if needed
    String? photoUrl = club.photoUrl;
    if (photoUrl != null && !photoUrl.startsWith('http')) {
      // It's a local file path, upload it
      final file = File(photoUrl);
      if (await file.exists()) {
        final uploadedUrl = await uploadClubPhoto(file, club.firestoreId!);
        if (uploadedUrl != null) {
          photoUrl = uploadedUrl;
          // Update local DB with the new URL to avoid re-uploading
          await (_database.update(_database.clubs)..where((c) => c.id.equals(club.id)))
              .write(db.ClubsCompanion(photoUrl: drift.Value(uploadedUrl)));
        }
      }
    }

    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('clubs')
        .doc(club.firestoreId);
        
    await docRef.set({
      'type': club.type,
      'brand': club.brand,
      'model': club.model,
      'loft': club.loft,
      'notes': club.notes,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncFriend(db.Friend friend) async {
    if (_uid == null || friend.friendId.isEmpty) return;
    
    final docRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .doc(friend.friendId);
        
    await docRef.set({
      'friendId': friend.friendId,
      'friendName': friend.friendName,
      'friendAvatar': friend.friendAvatar,
      'addedAt': friend.addedAt.toIso8601String(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> pullFriends() async {
    if (_uid == null) return;
    
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('friends')
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final friendId = data['friendId'] as String;
      
      final existing = await (_database.select(_database.friends)..where((f) => f.friendId.equals(friendId))).get().then((list) => list.firstOrNull);
      
      if (existing != null) {
        // Refresh existing friend info
        await (_database.update(_database.friends)..where((f) => f.id.equals(existing.id)))
            .write(db.FriendsCompanion(
              friendName: drift.Value(data['friendName'] as String?),
              friendAvatar: drift.Value(data['friendAvatar'] as String?),
            ));
        continue;
      }
      
      await _database.into(_database.friends).insert(
        db.FriendsCompanion.insert(
          userId: _uid!,
          friendId: friendId,
          friendName: drift.Value(data['friendName'] as String?),
          friendAvatar: drift.Value(data['friendAvatar'] as String?),
          addedAt: drift.Value(DateTime.parse(data['addedAt'] as String)),
        )
      );
    }
  }

  Future<void> pullClubs() async {
    if (_uid == null) return;
    
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('clubs')
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      
      await _database.upsertClub(db.ClubsCompanion.insert(
        userId: _uid!,
        type: data['type'] as String,
        brand: drift.Value(data['brand'] as String?),
        model: drift.Value(data['model'] as String?),
        loft: drift.Value((data['loft'] as num?)?.toDouble()),
        notes: drift.Value(data['notes'] as String?),
        photoUrl: drift.Value(data['photoUrl'] as String?),
        firestoreId: drift.Value(firestoreId),
      ));
    }
  }

  Future<void> pullPracticeSessions() async {
    if (_uid == null) return;
    
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('practice_sessions')
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      
      await _database.transaction(() async {
        // Resolve drillId from firestoreId
        int? localDrillId;
        final drillIdFirestore = data['drillId_v2'] as String?;
        if (drillIdFirestore != null) {
          final drill = await _database.getDrillByFirestoreId(drillIdFirestore);
          localDrillId = drill?.id;
        }

        await _database.upsertPracticeSession(db.PracticeSessionsCompanion.insert(
          userId: _uid!,
          firestoreId: drift.Value(firestoreId),
          startTime: drift.Value(DateTime.parse(data['startTime'] as String)),
          endTime: drift.Value(data['endTime'] != null ? DateTime.parse(data['endTime'] as String) : null),
          totalBalls: drift.Value(data['totalBalls'] as int),
          sessionType: drift.Value(data['sessionType'] as String),
          locationName: drift.Value(data['locationName'] as String?),
          drillId: drift.Value(localDrillId),
          targetDistance: drift.Value(data['targetDistance'] as int?),
          notes: drift.Value(data['notes'] as String?),
        ));

        // Get the local ID of the session we just upserted
        final localSession = await _database.getPracticeSessionByFirestoreId(firestoreId);
        if (localSession == null) return;

        // Pull shots for this session
        final shotsSnapshot = await doc.reference.collection('shots').get();
        for (var shotDoc in shotsSnapshot.docs) {
          final sData = shotDoc.data();
          final sFirestoreId = shotDoc.id;
          
          // Resolve clubId from firestoreId
          int localClubId = 0;
          final clubIdFirestore = sData['clubId_v2'] as String?;
          if (clubIdFirestore != null) {
            final club = await _database.getClubByFirestoreId(clubIdFirestore);
            localClubId = club?.id ?? 0;
          }
          
          if (localClubId == 0) continue; // Skip if club not found locally

          await _database.upsertPracticeShot(db.PracticeShotsCompanion.insert(
            sessionId: localSession.id,
            firestoreId: drift.Value(sFirestoreId),
            clubId: localClubId,
            distance: drift.Value((sData['distance'] as num?)?.toDouble()),
            quality: drift.Value(sData['quality'] as String?),
            shotShape: drift.Value(sData['shotShape'] as String?),
            timestamp: drift.Value(DateTime.parse(sData['timestamp'] as String)),
            ballFlightJson: drift.Value(sData['ballFlightJson'] as String?),
            videoUrl: drift.Value(sData['videoUrl'] as String?),
          ));
        }
      });
    }
  }

  Future<void> pullDrills() async {
    if (_uid == null) return;
    
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('drills')
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final firestoreId = doc.id;
      
      await _database.upsertDrill(db.DrillsCompanion.insert(
        userId: drift.Value(_uid),
        name: data['name'] as String,
        description: data['description'] as String,
        difficulty: data['difficulty'] as String,
        durationMinutes: data['durationMinutes'] as int,
        category: drift.Value(data['category'] as String? ?? 'General'),
        icon: drift.Value(data['icon'] as String? ?? 'target'),
        isCustom: drift.Value(data['isCustom'] as bool? ?? false),
        firestoreId: drift.Value(firestoreId),
      ));
    }
  }

  // ─── Catch-all Sync ───

  /// Scans all local tables for unsynced data (where firestoreId is null)
  /// and pushes them to Firestore. Addresses the "fix legacy sync" requirement.
  Future<void> syncAllPending() async {
    if (_uid == null) return;

    // 0. Pull Data from Firestore (Priority - Remote First)
    await pullProfile();
    await pullFriends();
    await pullProviders();
    await pullCourses();
    await pullClubs();
    await pullDrills();
    await pullPracticeSessions();
    await pullRounds();

    // 1. Sync Rounds (Local to Cloud)
    final unsyncedRounds = await (_database.select(_database.rounds)..where((r) => r.firestoreId.isNull())).get();
    for (var r in unsyncedRounds) {
      final firestoreId = const Uuid().v4();
      final updatedRound = r.copyWith(firestoreId: drift.Value(firestoreId));
      await _database.update(_database.rounds).replace(updatedRound);
      final holes = await _database.getHoleScoresForRound(r.id);
      await syncRound(updatedRound, holes);
    }

    // 2. Sync Clubs (Local to Cloud)
    final unsyncedClubs = await (_database.select(_database.clubs)..where((c) => c.firestoreId.isNull())).get();
    for (var c in unsyncedClubs) {
      final firestoreId = const Uuid().v4();
      final updatedClub = c.copyWith(firestoreId: drift.Value(firestoreId));
      await _database.update(_database.clubs).replace(updatedClub);
      await syncClub(updatedClub);
    }

    // 3. Sync Friends (Local to Cloud)
    final unsyncedFriends = await (_database.select(_database.friends)..where((f) => f.firestoreId.isNull())).get();
    for (var f in unsyncedFriends) {
      final firestoreId = const Uuid().v4();
      final updatedFriend = f.copyWith(firestoreId: drift.Value(firestoreId));
      await _database.update(_database.friends).replace(updatedFriend);
      await syncFriend(updatedFriend);
    }

    // 4. Sync Practice Sessions (Local to Cloud)
    final unsyncedSessions = await (_database.select(_database.practiceSessions)..where((s) => s.firestoreId.isNull())).get();
    for (var s in unsyncedSessions) {
      final firestoreId = const Uuid().v4();
      final updatedSession = s.copyWith(firestoreId: drift.Value(firestoreId));
      await _database.update(_database.practiceSessions).replace(updatedSession);
      await syncPracticeSession(updatedSession);
      
      // Sync shots for this session
      final unsyncedShots = await (_database.select(_database.practiceShots)
        ..where((sh) => sh.sessionId.equals(s.id) & sh.firestoreId.isNull())).get();
      for (var sh in unsyncedShots) {
        final shotId = const Uuid().v4();
        final updatedShot = sh.copyWith(firestoreId: drift.Value(shotId));
        await _database.update(_database.practiceShots).replace(updatedShot);
        await syncPracticeShot(updatedShot);
      }
    }

    // 5. Sync Drills (Local to Cloud - only custom ones)
    final unsyncedDrills = await (_database.select(_database.drills)..where((d) => d.firestoreId.isNull() & d.isCustom.equals(true))).get();
    for (var d in unsyncedDrills) {
      final firestoreId = const Uuid().v4();
      final updatedDrill = d.copyWith(firestoreId: drift.Value(firestoreId));
      await _database.update(_database.drills).replace(updatedDrill);
      await syncDrill(updatedDrill);
    }

    // 6. Sync Providers (own profile - Local to Cloud)
    final currentUid = _uid;
    if (currentUid != null) {
      final providerList = await (_database.select(_database.providers)..where((p) => p.userId.equals(currentUid))).get();
      if (providerList.isNotEmpty) {
        await syncProvider(providerList.first);
      }
    }

    // 7. Sync Interactions (Local to Cloud)
    if (_uid != null) {
      final allInteractions = await (_database.select(_database.interactions)
        ..where((i) => i.playerId.equals(_uid!))).get();
      for (final interaction in allInteractions) {
        await syncInteraction(interaction);
      }
    }
  }
}
