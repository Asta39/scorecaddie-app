import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart' as db;
import '../../providers/app_providers.dart';
import 'api_service.dart';
import 'supabase_storage_service.dart';
import '../utils/whs_engine.dart';

class SyncService {
  final db.AppDatabase _database;
  final String? _uid;
  final ApiService _api;
  final Ref _ref;
  bool _isSyncing = false;
  final _uuid = const Uuid();

  SyncService(this._database, this._uid, this._api, this._ref);
  
  // Stable namespace for deterministic UUIDs
  static const _namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // Random UUID as namespace

  String _generateStableId(String type, List<String> parts) {
    final input = '$type:${parts.join(':')}';
    return _uuid.v5(_namespace, input);
  }

  SupabaseStorageService get _storage => _ref.read(supabaseStorageServiceProvider);

  Future<String?> uploadShotVideo(File videoFile, String shotId) async {
    if (_uid == null) return null;
    final path = 'users/$_uid/practice_videos/$shotId.mp4';
    return await _storage.uploadFile(bucket: 'user_assets', path: path, file: videoFile);
  }

  Future<String?> uploadClubPhoto(File photoFile, String clubId) async {
    if (_uid == null) return null;
    final path = 'users/$_uid/club_photos/$clubId.jpg';
    return await _storage.uploadFile(bucket: 'user_assets', path: path, file: photoFile);
  }

  Future<void> syncProfile(db.UserProfile profile) async {
    if (_uid == null) return;
    
    String? avatarUrl = profile.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      final file = File(avatarUrl);
      if (await file.exists()) {
        final uploadedUrl = await _storage.uploadProfilePhoto(_uid, file);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
          await (_database.update(_database.userProfiles)..where((u) => u.uid.equals(_uid)))
              .write(db.UserProfilesCompanion(avatarUrl: drift.Value(uploadedUrl)));
        }
      }
    }

    String pfpType = 'INITIALS';
    if (avatarUrl != null) {
      if (avatarUrl.contains('googleusercontent.com')) {
        pfpType = 'GOOGLE';
      } else if (profile.pfpVerified) {
        pfpType = 'VERIFIED_FACE';
      }
    }

    List<String> badges = [];
    try {
      if (profile.badgesJson.isNotEmpty) {
        final decoded = jsonDecode(profile.badgesJson);
        if (decoded is List) {
          badges = decoded.cast<String>();
        }
      }
    } catch (_) {}

    // PostgreSQL Sync
    await _api.syncProfile(
      id: profile.uid!,
      email: profile.email ?? '',
      name: profile.name,
      role: (profile.role ?? 'PLAYER').toUpperCase(),
      avatarUrl: avatarUrl,
      pfpType: pfpType,
      pfpVerified: profile.pfpVerified,
      providerStatus: profile.providerStatus,
      handicapIndex: profile.handicap,
      anchorIndex: profile.anchorIndex,
      badges: badges,
      profileComplete: profile.profileComplete,
    );
  }

  Future<void> syncAllPending() async {
    if (_uid == null) return;

    await pullProfile();
    await pullProviders();
    // 1.5 NEW: Pull Official KGU Course Intel
    await pullKguData();
    // Restore rounds from cloud for cross-device continuity
    await pullRounds();

    // 2. Migrate to PostgreSQL
    final profile = await _database.getProfile(_uid);
    if (profile != null) await syncProfile(profile);

    await _migrateCourses();
    await _migrateRoundsAndStats();
  }

  Future<void> _migrateCourses() async {
    // 1. CLEANUP DUPLICATES: Find all courses with same name and location
    try {
      final allCourses = await _database.select(_database.courses).get();
      final Map<String, db.Course> uniqueCourses = {};
      final List<int> idsToDelete = [];

      for (var c in allCourses) {
        final key = '${c.name.trim().toLowerCase()}_${c.location.trim().toLowerCase()}';
        if (uniqueCourses.containsKey(key)) {
          // If the one we already have doesn't have a supabaseId but this one does, swap them
          if (uniqueCourses[key]!.supabaseId == null && c.supabaseId != null) {
            idsToDelete.add(uniqueCourses[key]!.id);
            uniqueCourses[key] = c;
          } else {
            idsToDelete.add(c.id);
          }
        } else {
          uniqueCourses[key] = c;
        }
      }

      if (idsToDelete.isNotEmpty) {
        debugPrint('CLEANUP: Deleting ${idsToDelete.length} duplicate course entries.');
        await (_database.delete(_database.courses)..where((c) => c.id.isIn(idsToDelete))).go();
      }
    } catch (e) {
      debugPrint('CLEANUP ERROR: Course deduplication failed: $e');
    }

    // 2. PROCEED WITH NORMAL MIGRATION
    final coursesList = await (_database.select(_database.courses)..where((c) => c.userId.equals(_uid!) & c.supabaseId.isNull())).get();
    final supabase = Supabase.instance.client;
    
    for (final course in coursesList) {
      try {
        final holes = await _database.getHolesForCourse(course.id);
        
        // 1. Resolve or Generate Supabase ID for Course
        String supabaseCourseId = course.supabaseId ?? _uuid.v4();
        
        // Update local DB with the new supabaseId if it was missing
        if (course.supabaseId == null) {
          await _database.updateCourse(course.copyWith(supabaseId: drift.Value(supabaseCourseId)));
        }

        // 2. Direct Supabase Course Sync (onConflict:'id' prevents duplicates)
        await supabase.from('Course').upsert({
          'id': supabaseCourseId,
          // 'uid': course.userId, // Link to user if custom course
          'name': course.name,
          'location': course.location,
          'city': course.city,
          'region': course.region,
          'holesCount': course.totalHoles,
          'par18': course.par18,
          // 'latitude': course.latitude,
          // 'longitude': course.longitude,
          'updatedAt': DateTime.now().toIso8601String(),
        }, onConflict: 'id');

        // 3. Migrate Tees
        final tees = await _database.getTeesForCourse(course.id);
        if (tees.isNotEmpty) {
          final List<Map<String, dynamic>> teeData = [];
          for (final t in tees) {
            // Use deterministic ID to avoid duplication without complex unique constraints
            final teeId = _generateStableId('tee', [supabaseCourseId, t.name, t.gender]);
            teeData.add({
              'id': teeId,
              'courseId': supabaseCourseId,
              'name': t.name,
              'gender': t.gender,
              'courseRating': t.courseRating,
              'slopeRating': t.slopeRating,
              'par': t.par,
              'yardage': t.yardage,
            });
          }
          await supabase.from('Tee').upsert(teeData, onConflict: 'id');
        }

        // 4. Migrate Holes (including Tee mapping)
        if (holes.isNotEmpty) {
          final List<Map<String, dynamic>> holeData = [];
          
          // Fetch the tees we just upserted to get their Supabase IDs
          final supabaseTees = await supabase.from('Tee').select('id, name').eq('courseId', supabaseCourseId);
          final Map<String, String> teeNameToSupabaseId = {
            for (var t in supabaseTees) t['name'] as String: t['id'] as String
          };

          for (final h in holes) {
            String? mappedTeeId;
            if (h.teeId != null) {
              final localTee = tees.firstWhere((t) => t.id == h.teeId);
              mappedTeeId = teeNameToSupabaseId[localTee.name];
            }

            // Stable ID for CourseHole
            final holeId = _generateStableId('coursehole', [
              supabaseCourseId, 
              mappedTeeId ?? 'default', 
              h.holeNumber.toString()
            ]);

            holeData.add({
              'id': holeId, 
              'courseId': supabaseCourseId,
              'teeId': mappedTeeId, 
              'holeNumber': h.holeNumber,
              'par': h.par,
              'handicapIndex': h.handicapIndex,
              'distance': h.distance,
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
          await supabase.from('CourseHole').upsert(holeData, onConflict: 'id');
        }
      } catch (e) {
        debugPrint('SYNC ERROR: Failed to migrate course ${course.id}: $e');
      }
    }
  }

  Future<void> _migrateRoundsAndStats() async {
    // REPAIR STEP: Ensure rounds are linked to the correct Supabase Course UUID
    try {
      final allLocalRounds = await _database.select(_database.rounds).get();
      final allLocalCourses = await _database.select(_database.courses).get();
      
      for (var r in allLocalRounds) {
        final localCourse = allLocalCourses.where((c) => c.id == r.courseId).firstOrNull;
        if (localCourse != null && localCourse.supabaseId != null) {
          // If the round is marked synced but might be using an old ID, we force re-sync
          // Or if it's unsynced, we ensure it uses the correct course UUID
        }
      }
    } catch (e) {
      debugPrint('REPAIR: Data repair failed: $e');
    }

    final roundsList = await (_database.select(_database.rounds)..where((r) => r.userId.equals(_uid!) & r.isSynced.equals(false))).get();
    if (roundsList.isNotEmpty) {
      final roundIds = roundsList.map((r) => r.id).toList();
      final allHoleScores = await (_database.select(_database.holeScores)..where((h) => h.roundId.isIn(roundIds))).get();
      final holesByRound = <int, List<db.HoleScore>>{};
      for (var hs in allHoleScores) {
        holesByRound.putIfAbsent(hs.roundId, () => []).add(hs);
      }
      for (final round in roundsList) {
        final holes = holesByRound[round.id] ?? [];
        await syncRound(round, holes);
      }
    }

    final localProfile = await _database.getProfile(_uid!);
    if (localProfile != null) {
      try {
        final supabase = Supabase.instance.client;

        // Calculate comprehensive stats from all synced hole scores
        final allRounds = await _database.getAllRounds(_uid);
        if (allRounds.isNotEmpty) {
          final allRoundIds = allRounds.map((r) => r.id).toList();
          final allHoleScores = await (_database.select(_database.holeScores)..where((h) => h.roundId.isIn(allRoundIds))).get();
          final holesByRound = <int, List<db.HoleScore>>{};
          for (var hs in allHoleScores) {
            holesByRound.putIfAbsent(hs.roundId, () => []).add(hs);
          }

          double totalFairwaysHit = 0;
          double totalFairwaysTracked = 0;
          double totalPutts = 0;
          double totalHolesWithPutts = 0;
          double totalGIR = 0;
          double totalHolesWithStats = 0;
          double totalScore = 0;

          for (final round in allRounds) {
            totalScore += round.totalScore;
            final holes = holesByRound[round.id] ?? [];
            for (final h in holes) {
              if (h.fairwayHit != null && h.par > 3) {
                totalFairwaysTracked++;
                if (h.fairwayHit == 'Hit') totalFairwaysHit++;
              }
              if (h.putts != null) {
                totalPutts += h.putts!;
                totalHolesWithPutts++;
                totalHolesWithStats++;
                // GIR: reached the green in regulation if (score - putts) <= (par - 2)
                if (h.score - h.putts! <= h.par - 2) totalGIR++;
              }
            }
          }

        final double? fairwayPct = totalFairwaysTracked > 0
            ? (totalFairwaysHit / totalFairwaysTracked) * 100
            : null;
        final double? girPct = totalHolesWithStats > 0
            ? (totalGIR / totalHolesWithStats) * 100
            : null;
        final double? avgPutts = totalHolesWithPutts > 0
            ? (totalPutts / totalHolesWithPutts) * 18
            : null;
        final double? avgScore = allRounds.isNotEmpty
            ? totalScore / allRounds.length
            : null;

        await supabase.from('PlayerStat').upsert({
          'id': _uuid.v4(), 
          'userId': _uid,
          'handicapIndex': localProfile.handicap,
          'avgScore': avgScore,
          'fairwayHitPct': fairwayPct,
          'girPct': girPct,
          'avgPutts': avgPutts,
          'recordedAt': DateTime.now().toIso8601String(),
        }, onConflict: 'userId');
        }
      } catch (e) {
        debugPrint('SYNC ERROR: Failed to migrate stats: $e');
      }
    }
  }

  Future<void> pullFriends() async {
    // Friends list is handled via realtime streams in SupabaseFriendService
    return;
  }

  Future<void> pullProfile() async {
    if (_uid == null) return;
    try {
      final existingLocal = await _database.getProfile(_uid);
      final data = await _api.getProfile(_uid);

      if (data != null) {
        // CRITICAL GUARD: Once a profile is complete locally, don't let a sync operation revert it.
        bool localWasComplete = existingLocal?.profileComplete ?? false;
        bool mergedComplete = (data['profileComplete'] as bool? ?? false) || localWasComplete;

        // ROLE PROTECTION: Never downgrade a role during sync.
        // Standardize both to lowercase for safe comparison.
        String? remoteRole = (data['role'] as String?)?.toLowerCase();
        String? localRole = existingLocal?.role?.toLowerCase();
        
        String? finalRole = remoteRole;
        if (localRole != null && (localRole == 'coach' || localRole == 'caddie') && remoteRole == 'player') {
          finalRole = localRole;
        } else {
          finalRole = remoteRole ?? localRole ?? 'player';
        }

        // ── PROFESSIONAL DATA MERGING ──
        // Only overwrite if remote data is not null/empty, or if local is currently default.
        String? mergedName = data['name'] as String?;
        if (mergedName == null || mergedName == 'Golfer') mergedName = existingLocal?.name ?? 'Golfer';

        await _database.upsertProfile(db.UserProfilesCompanion(
          uid: drift.Value(_uid),
          email: drift.Value(data['email'] as String? ?? existingLocal?.email),
          name: drift.Value(mergedName),
          avatarUrl: drift.Value(data['avatarUrl'] as String? ?? existingLocal?.avatarUrl),
          role: drift.Value(finalRole),
          profileComplete: drift.Value(mergedComplete),
          handicap: drift.Value((data['handicapIndex'] as num?)?.toDouble() ?? existingLocal?.handicap),
          pfpVerified: drift.Value(data['pfpVerified'] as bool? ?? existingLocal?.pfpVerified ?? false),
          providerStatus: drift.Value(data['providerStatus'] as String? ?? existingLocal?.providerStatus ?? 'OFFLINE'),
          updatedAt: drift.Value(DateTime.now()),
        ));

        // If it's a provider, update provider table too with merging
        if (finalRole == 'coach' || finalRole == 'caddie') {
          final localProv = await _database.getProvider(_uid);
          
          await _database.upsertProvider(db.ProvidersCompanion(
            userId: drift.Value(_uid),
            role: drift.Value(finalRole),
            name: drift.Value(mergedName),
            phone: drift.Value(data['phone'] as String? ?? localProv?.phone ?? ''),
            whatsapp: drift.Value(data['whatsapp'] as String? ?? localProv?.whatsapp),
            bio: drift.Value(data['bio'] as String? ?? localProv?.bio),
            experience: drift.Value(data['experience'] as int? ?? localProv?.experience ?? 0),
            price: drift.Value((data['price'] as num?)?.toDouble() ?? localProv?.price ?? 0.0),
            personalityType: drift.Value(data['personalityType'] as String? ?? localProv?.personalityType),
            coursesJson: drift.Value(data['coursesJson'] as String? ?? localProv?.coursesJson ?? '[]'),
            hasCertification: drift.Value(data['hasCertification'] as bool? ?? localProv?.hasCertification ?? false),
            certificationName: drift.Value(data['certificationName'] as String? ?? localProv?.certificationName),
            certificationUrl: drift.Value(data['certificationUrl'] as String? ?? localProv?.certificationUrl),
            coachingLocation: drift.Value(data['coachingLocation'] as String? ?? localProv?.coachingLocation),
            specializationsJson: drift.Value(data['specializations'] as String? ?? localProv?.specializationsJson),
            targetAudienceJson: drift.Value(data['targetAudience'] as String? ?? localProv?.targetAudienceJson),
            profileComplete: drift.Value(mergedComplete),
          ));
        }
      }
    } catch (e) {
      debugPrint('PULL_PROFILE_ERROR: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchFirestoreProfile(String uid) async {
    // Removed Firestore call. Return null or rewrite if needed.
    return null;
  }

  Future<void> syncCourse(db.Course course) async {
    if (_uid == null || course.supabaseId == null) return;
    // We already migrate courses to Supabase in _migrateCourses
  }

  Future<void> syncGroupRoundForPlayer({
    required String firestoreRoundId,
    required int courseId,
    required String courseName,
    required List<int> holePars,
    required Map<String, dynamic> myScoresData,
    int? teeId,
    double? handicapBefore,
  }) async {
    if (_uid == null) return;

    // 1. Get Tee data for WHS calculations
    db.Tee? tee;
    if (teeId != null) {
      tee = await (_database.select(_database.tees)..where((t) => t.id.equals(teeId))).getSingleOrNull();
    } else {
      // Fallback to first tee if none selected (better than failing)
      final tees = await _database.getTeesForCourse(courseId);
      if (tees.isNotEmpty) tee = tees.first;
    }

    // 2. Calculate scores and adjusted gross (ESC)
    int totalScore = 0;
    int adjustedGrossScore = 0;
    int front9Score = 0;
    int back9Score = 0;
    int coursePar = holePars.reduce((a, b) => a + b);

    // Get current handicap for ESC calculation if not provided
    double hIndex = handicapBefore ?? 0.0;
    if (handicapBefore == null) {
      final profile = await _database.getProfile(_uid);
      hIndex = profile?.handicap ?? 0.0;
    }

    // Course Handicap for ESC: (HI * (Slope / 113)) + (CR - Par)
    int courseHandicap = 0;
    if (tee != null) {
      courseHandicap = ((hIndex * (tee.slopeRating / 113)) + (tee.courseRating - coursePar)).round();
    }

    for (int i = 0; i < holePars.length; i++) {
      final hVal = (myScoresData['hole${i + 1}'] as Map<String, dynamic>? ?? {})['score'] as int? ?? holePars[i];
      totalScore += hVal;
      
      if (i < 9) {
        front9Score += hVal;
      } else {
        back9Score += hVal;
      }

      // ESC: Net Double Bogey check
      final escCap = WHSEngine.calculateESCCap(holePars[i], courseHandicap, i + 1);
      adjustedGrossScore += (hVal > escCap) ? escCap : hVal;
    }

    // 3. Calculate Differential
    double differential = 0.0;
    if (tee != null) {
      differential = WHSEngine.calculateScoreDifferential(
        adjustedGrossScore: adjustedGrossScore,
        courseRating: tee.courseRating,
        slopeRating: tee.slopeRating,
      );
    }

    // 4. Save to Local DB
    await _database.transaction(() async {
      final roundId = await _database.into(_database.rounds).insert(
        db.RoundsCompanion.insert(
          supabaseId: drift.Value(firestoreRoundId),
          courseId: courseId,
          courseName: drift.Value(courseName),
          holesPlayed: drift.Value(holePars.length),
          totalScore: totalScore,
          adjustedGrossScore: drift.Value(adjustedGrossScore),
          scoreVsPar: totalScore - coursePar,
          coursePar: coursePar,
          scoreDifferential: drift.Value(differential),
          handicapBefore: drift.Value(hIndex),
          front9Score: drift.Value(front9Score),
          back9Score: drift.Value(back9Score),
          playedAt: drift.Value(DateTime.now()),
          userId: drift.Value(_uid),
        ),
      );

      for (int i = 0; i < holePars.length; i++) {
        final hData = myScoresData['hole${i + 1}'] as Map<String, dynamic>? ?? {};
        final hScore = hData['score'] as int? ?? holePars[i];
        
        await _database.into(_database.holeScores).insert(db.HoleScoresCompanion.insert(
          roundId: roundId,
          holeNumber: i + 1,
          par: holePars[i],
          score: hScore,
          putts: drift.Value(hData['putts'] as int?),
          gir: drift.Value(hData['gir'] as bool?),
          fairwayHit: drift.Value(hData['fairwayHit'] as String?),
        ));
      }
    });

    // 5. Final Step: Sync this official round record back to Supabase "Round" table 
    // so it appears in History and is counted by cloud HI engine
    final savedRound = await (_database.select(_database.rounds)..where((r) => r.supabaseId.equals(firestoreRoundId))).getSingle();
    final savedHoles = await (_database.select(_database.holeScores)..where((h) => h.roundId.equals(savedRound.id))).get();
    
    await syncRound(savedRound, savedHoles);
  }

  Future<void> syncPracticeSession(db.PracticeSession session) async {
    if (_uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('PracticeSession').upsert({
        if (session.supabaseId != null) 'id': session.supabaseId,
        'userId': _uid,
        'startTime': session.startTime.toIso8601String(),
        'endTime': session.endTime?.toIso8601String(),
        'locationName': session.locationName,
        'totalBalls': session.totalBalls,
        'sessionType': session.sessionType,
        'drillId': session.drillId,
        'targetDistance': session.targetDistance,
        'notes': session.notes,
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('SYNC: syncPracticeSession failed');
    }
  }

  Future<void> syncPracticeShot(db.PracticeShot shot) async {
    if (_uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('PracticeShot').upsert({
        if (shot.supabaseId != null) 'id': shot.supabaseId,
        'sessionId': shot.sessionId,
        'clubId': shot.clubId,
        'distance': shot.distance,
        'quality': shot.quality,
        'shotShape': shot.shotShape,
        'ballFlightJson': shot.ballFlightJson,
        'videoUrl': shot.videoUrl,
        'poseMetricsJson': shot.poseMetricsJson,
        'timestamp': shot.timestamp.toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('SYNC: syncPracticeShot failed');
    }
  }

  Future<void> pullProviders() async {
    // Removed Firestore pull
  }

  Future<String?> uploadProfilePhoto(File photoFile) async {
    if (_uid == null) return null;
    return await _storage.uploadProfilePhoto(_uid, photoFile);
  }

  Future<String?> uploadCertificatePhoto(File photoFile, String fileName) async {
    if (_uid == null) return null;
    return await _storage.uploadCertification(_uid, photoFile, fileName);
  }

  Future<void> syncProvider(db.Provider provider) async {
    if (_uid == null) return;

    String? certUrl = provider.certificationUrl;
    if (certUrl != null && certUrl.isNotEmpty && !certUrl.startsWith('http')) {
      final file = File(certUrl);
      if (await file.exists()) {
        final uploadedUrl = await _storage.uploadCertification(_uid, file, 'primary_cert');
        if (uploadedUrl != null) {
          certUrl = uploadedUrl;
          await (_database.update(_database.providers)..where((p) => p.userId.equals(_uid)))
              .write(db.ProvidersCompanion(certificationUrl: drift.Value(uploadedUrl)));
        }
      }
    }

    // Postgres Sync (via Profile Sync which now handles all fields)
    final profile = await _database.getProfile(_uid);
    if (profile != null) {
      await _api.syncProfile(
        id: profile.uid!,
        email: profile.email ?? '',
        name: profile.name,
        role: (profile.role ?? 'PLAYER').toUpperCase(),
        avatarUrl: profile.avatarUrl,
        pfpVerified: profile.pfpVerified,
        providerStatus: profile.providerStatus,
        phone: provider.phone,
        whatsapp: provider.whatsapp,
        bio: provider.bio,
        experience: provider.experience,
        price: provider.price,
        personalityType: provider.personalityType,
        coursesJson: provider.coursesJson,
        hasCertification: provider.hasCertification,
        certificationName: provider.certificationName,
        certificationUrl: certUrl,
        coachingLocation: provider.coachingLocation,
        specializations: provider.specializationsJson,
        targetAudience: provider.targetAudienceJson,
      );
    }
  }

  Future<void> syncInteraction(db.Interaction interaction) async {
    if (_uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('interactions').upsert({
        'player_id': interaction.playerId,
        'provider_id': interaction.providerId,
        'type': interaction.type,
        'status': interaction.status,
        'lastPromptedAt': interaction.lastPromptedAt?.toIso8601String(),
        'timestamp': interaction.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('SYNC_INTERACTION_ERROR: $e');
    }
  }

  Future<void> syncReview(db.Review review) async {
    if (_uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('Review').insert({
        'provider_id': review.providerId,
        'player_id': review.playerId,
        'player_name': review.playerName,
        'player_avatar': review.playerAvatar,
        'rating': review.rating,
        'comment': review.comment,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('SYNC_REVIEW_ERROR: $e');
    }
  }

  // ── Official KGU Intel Sync ──────────────────────────────
  Future<void> pullKguData() async {
    if (_isSyncing) {
      debugPrint('SYNC: KGU pull already in progress, skipping.');
      return;
    }
    _isSyncing = true;
    try {
      final supabase = Supabase.instance.client;
      debugPrint('SYNC: Pulling official KGU data with optimized caching...');

      // 0. Cache Course IDs to avoid 18,000 individual DB lookups
      final allLocalCourses = await _database.select(_database.courses).get();
      final Map<String, int> fidToLocalId = {
        for (var c in allLocalCourses) if (c.supabaseId != null) c.supabaseId!: c.id
      };

      // 1. Pull Courses (Paginated)
      int courseOffset = 0;
      int totalCourses = 0;
      bool hasMoreCourses = true;
      while (hasMoreCourses) {
        final List<dynamic> courseData = await supabase.from('Course').select().range(courseOffset, courseOffset + 999);
        if (courseData.isEmpty) {
          hasMoreCourses = false;
        } else {
          for (final c in courseData) {
            try {
              final fid = c['id'] as String;
              final localId = await _database.upsertCourse(db.CoursesCompanion.insert(
                supabaseId: drift.Value(fid),
                name: c['name'] as String,
                location: drift.Value(c['location'] as String? ?? ''),
                city: drift.Value(c['city'] as String?),
                region: drift.Value(c['region'] as String?),
                totalHoles: drift.Value(c['holesCount'] as int? ?? 18),
                par18: drift.Value(c['par18'] as int?),
              ));
              // Update cache with the confirmed local ID
              fidToLocalId[fid] = localId;
              if (c['name'].toString().contains('Sigona')) {
                debugPrint('SYNC_DIAGNOSTIC: Sigona mapped to SupabaseID: $fid');
              }
            } catch (e) {
              debugPrint('SYNC: Error upserting course ${c['name']}: $e');
            }
          }
          totalCourses += courseData.length;
          courseOffset += 1000;
          if (courseData.length < 1000) hasMoreCourses = false;
        }
      }

      // 2. Pull All Tees (Paginated)
      final Map<String, int> supabaseTeeIdToLocalId = {};
      int teeOffset = 0;
      int totalTees = 0;
      bool hasMoreTees = true;
      while (hasMoreTees) {
        final List<dynamic> teeData = await supabase.from('Tee').select().range(teeOffset, teeOffset + 999);
        if (teeData.isEmpty) {
          hasMoreTees = false;
        } else {
          for (final t in teeData) {
            try {
              final fid = t['courseId'] as String;
              final localId = fidToLocalId[fid];
              if (localId != null) {
                final insertedId = await _database.into(_database.tees).insert(db.TeesCompanion.insert(
                  courseId: localId,
                  name: t['name'] as String,
                  gender: drift.Value(t['gender'] as String),
                  courseRating: (t['courseRating'] as num).toDouble(),
                  slopeRating: t['slopeRating'] as int,
                  par: drift.Value(t['par'] as int?),
                  yardage: drift.Value(t['yardage'] as int?),
                ), mode: drift.InsertMode.insertOrReplace);
                supabaseTeeIdToLocalId[t['id'].toString()] = insertedId;
              }
            } catch (e) {
              debugPrint('SYNC: Error upserting tee ${t['name']}: $e');
            }
          }
          totalTees += teeData.length;
          teeOffset += 1000;
          if (teeData.length < 1000) hasMoreTees = false;
        }
      }

      // 3. Pull All Holes (Paginated)
      int holeOffset = 0;
      int totalHoles = 0;
      bool hasMoreHoles = true;
      while (hasMoreHoles) {
        final List<dynamic> holeData = await supabase
            .from('CourseHole')
            .select('courseId, holeNumber, par, handicapIndex, distance') 
            .range(holeOffset, holeOffset + 999);
            
        if (holeData.isEmpty) {
          hasMoreHoles = false;
        } else {
          final List<db.CourseHolesCompanion> holeCompanions = [];
          for (final h in holeData) {
            try {
              final fid = h['courseId'] as String;
              final localId = fidToLocalId[fid];
              if (localId != null) {
                holeCompanions.add(db.CourseHolesCompanion.insert(
                  courseId: localId,
                  teeId: const drift.Value(null), 
                  holeNumber: h['holeNumber'] as int,
                  par: h['par'] as int? ?? 4,
                  handicapIndex: drift.Value(h['handicapIndex'] as int?),
                  distance: drift.Value(h['distance'] as int?),
                ));
              }
            } catch (_) {}
          }
          if (holeCompanions.isNotEmpty) {
            try {
              await _database.upsertCourseHoles(holeCompanions);
            } catch (e) {
              debugPrint('SYNC: Error upserting hole batch: $e');
            }
          }
          totalHoles += holeData.length;
          holeOffset += 1000;
          if (holeData.length < 1000) hasMoreHoles = false;
        }
      }
      
      debugPrint('SYNC: KGU pull complete. Courses: $totalCourses, Tees: $totalTees, Holes: $totalHoles');
    } catch (e) {
      debugPrint('SYNC ERROR: Official KGU pull failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ── Cross-Device Round Restore ──────────────────────────────
  Future<void> pullRounds() async {
    if (_uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      debugPrint('SYNC: Pulling rounds from Supabase for user $_uid...');

      final List<dynamic> roundData = await supabase
          .from('Round')
          .select()
          .eq('userId', _uid)
          .order('playedAt', ascending: false);

      if (roundData.isEmpty) {
        debugPrint('SYNC: No rounds found in Supabase.');
        return;
      }

      int restoredCount = 0;

      for (final r in roundData) {
        final String supabaseRoundId = r['id'] as String;

        // Skip if already in local DB
        final existing = await _database.getRoundBySupabaseId(supabaseRoundId);
        if (existing != null) continue;

        // Resolve courseId: find local course by supabase courseId
        final String supabaseCourseId = r['courseId'] as String;
        final localCourse = await _database.getCourseBySupabaseId(supabaseCourseId);
        if (localCourse == null) {
          debugPrint('SYNC: Skipping round $supabaseRoundId — course not found locally');
          continue;
        }

        // Insert the round
        final localRoundId = await _database.into(_database.rounds).insert(
          db.RoundsCompanion.insert(
            supabaseId: drift.Value(supabaseRoundId),
            courseId: localCourse.id,
            courseName: drift.Value(r['courseName'] as String? ?? localCourse.name),
            holesPlayed: drift.Value(r['holesPlayed'] as int? ?? 18),
            totalScore: r['totalScore'] as int,
            totalNet: drift.Value(r['totalNet'] as int?),
            adjustedGrossScore: drift.Value(r['adjustedGrossScore'] as int?),
            coursePar: r['coursePar'] as int? ?? 72,
            scoreVsPar: r['scoreVsPar'] as int? ?? 0,
            scoreDifferential: drift.Value((r['scoreDifferential'] as num?)?.toDouble()),
            handicapBefore: drift.Value((r['handicapBefore'] as num?)?.toDouble()),
            handicapAfter: drift.Value((r['handicapAfter'] as num?)?.toDouble()),
            front9Score: drift.Value(r['front9Score'] as int?),
            back9Score: drift.Value(r['back9Score'] as int?),
            playedAt: drift.Value(DateTime.tryParse(r['playedAt'] ?? '') ?? DateTime.now()),
            userId: drift.Value(_uid),
            isSynced: drift.Value(true),
          ),
        );

        // Pull hole scores for this round
        final List<dynamic> holeData = await supabase
            .from('HoleScore')
            .select()
            .eq('roundId', supabaseRoundId)
            .order('holeNumber');

        if (holeData.isNotEmpty) {
          final List<db.HoleScoresCompanion> holeCompanions = holeData.map((h) =>
            db.HoleScoresCompanion.insert(
              roundId: localRoundId,
              holeNumber: h['holeNumber'] as int,
              par: h['par'] as int,
              score: h['score'] as int,
              putts: drift.Value(h['putts'] as int?),
              fairwayHit: drift.Value(h['fairwayHit'] as String?),
              penalties: drift.Value(h['penalties'] as int?),
              isSynced: drift.Value(true),
            ),
          ).toList();
          await _database.insertHoleScores(holeCompanions);
        }

        restoredCount++;
      }

      debugPrint('SYNC: Round pull complete. Restored $restoredCount new rounds from ${roundData.length} total.');
    } catch (e) {
      debugPrint('SYNC ERROR: Round pull failed: $e');
    }
  }

  Future<void> syncRound(db.Round round, List<db.HoleScore> holes) async {
    if (_uid == null) return;
    try {
      final supabase = Supabase.instance.client;
      
      final allCourses = await _database.select(_database.courses).get();
      final localCourse = allCourses.where((c) => c.id == round.courseId).firstOrNull;
      
      if (localCourse == null) {
        debugPrint('SYNC WARNING: Skipping round ${round.id} - local course data missing.');
        return;
      }
      
      String? supabaseCourseId = localCourse.supabaseId;
      
      // AUTO-RESOLUTION: If this round is linked to a local-only course, try to find an official match by name
      if (supabaseCourseId == null) {
        debugPrint('SYNC: Attempting to resolve official course for ${localCourse.name}');
        final officialMatch = allCourses.firstWhere(
          (c) => c.name.trim().toLowerCase() == localCourse.name.trim().toLowerCase() && c.supabaseId != null,
          orElse: () => localCourse,
        );
        supabaseCourseId = officialMatch.supabaseId;
      }
      
      if (supabaseCourseId == null) {
        debugPrint('SYNC ERROR: Skipping round sync - course "${localCourse.name}" not in Supabase');
        return;
      }

      // FIX: Assign a stable round ID and persist it back to local DB
      // so repeated syncs hit the same row via onConflict instead of duplicating.
      final uuid = Uuid();
      final serverRoundId = round.supabaseId ?? uuid.v4();

      // Persist the server ID locally if it was just minted
      if (round.supabaseId == null) {
        await (_database.update(_database.rounds)..where((r) => r.id.equals(round.id)))
            .write(db.RoundsCompanion(supabaseId: drift.Value(serverRoundId)));
      }

      final roundData = {
        'id': serverRoundId,
        'userId': _uid,
        'courseId': supabaseCourseId,
        'playedAt': round.playedAt.toIso8601String(),
        'totalScore': round.totalScore,
        'totalNet': round.totalNet,
        'scoreVsPar': round.scoreVsPar,
        'holesPlayed': round.holesPlayed,
        'scoreDifferential': round.scoreDifferential,
        'handicapBefore': round.handicapBefore,
        'handicapAfter': round.handicapAfter,
        'adjustedGrossScore': round.adjustedGrossScore,
        'coursePar': round.coursePar,
        'courseName': round.courseName,
        'front9Score': round.front9Score,
        'back9Score': round.back9Score,
        'source': round.source,
        'scorecardImageUrl': round.scorecardImageUrl,
        'scannerConfidence': round.scannerConfidence,
        'scannerPlayerSlot': round.scannerPlayerSlot,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await supabase.from('Round').upsert(roundData, onConflict: 'id');

      // FIX: Use proper map literal syntax (=> <String, dynamic>{...})
      // The old code used => { } which Dart interprets as a function body
      // returning void, causing holeRows to be List<void> and the upsert to
      // silently produce no data.
      if (holes.isNotEmpty) {
        final holeRows = holes.map((h) {
          // Use deterministic ID for hole scores to prevent duplication on re-sync
          final holeScoreId = _generateStableId('holescore', [serverRoundId, h.holeNumber.toString()]);
          return <String, dynamic>{
            'id': holeScoreId,
            'roundId': serverRoundId,
            'holeNumber': h.holeNumber,
            'par': h.par,
            'score': h.score,
            'putts': h.putts ?? 0,
            'fairwayHit': h.fairwayHit,
            'penalties': h.penalties ?? 0,
            'gir': h.gir,
          };
        }).toList();
        await supabase.from('HoleScore').upsert(holeRows, onConflict: 'id');
      }

      // Mark as synced locally
      await _database.transaction(() async {
        await (_database.update(_database.rounds)..where((r) => r.id.equals(round.id)))
            .write(db.RoundsCompanion(isSynced: drift.Value(true)));
        
        await (_database.update(_database.holeScores)..where((h) => h.roundId.equals(round.id)))
            .write(db.HoleScoresCompanion(isSynced: drift.Value(true)));
      });

    } catch (e) {
      debugPrint('SYNC ERROR: Round sync failed: $e');
    }
  }
}
