
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// ─── Tables ────────────────────────────────────────────────────────────────

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firebaseUid => text().unique().nullable()();
  TextColumn get email => text().nullable()(); // Added for email-based lookup
  TextColumn get name => text().withDefault(const Constant('Golfer'))();
  TextColumn get avatarUrl => text().nullable()();
  RealColumn get handicap => real().nullable()();
  IntColumn get homeCourseId => integer().nullable()();
  TextColumn get homeCourseName => text().nullable()();
  TextColumn get skillLevel => text().nullable()(); // Beginner, Weekend Warrior, Avid, Competitive
  TextColumn get preferredTees => text().nullable()();
  TextColumn get playStyle => text().nullable()(); // Cart, Walking, Mixed
  TextColumn get units => text().withDefault(const Constant('Yards'))();
  TextColumn get themeMode => text().withDefault(const Constant('System'))();
  TextColumn get privacyLevel => text().withDefault(const Constant('Private'))();
  TextColumn get badgesJson => text().withDefault(const Constant('[]'))();
  TextColumn get role => text().nullable()(); // player, caddie, coach
  BoolColumn get profileComplete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Clubs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // Driver, 3-Wood, 7-Iron, etc.
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  RealColumn get loft => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()(); // Mandatory for identification
  TextColumn get firestoreId => text().nullable()(); // Added for cloud sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Friends extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()(); // The current user
  TextColumn get friendId => text()(); // The friend's Firebase UID
  TextColumn get friendName => text().nullable()();
  TextColumn get friendAvatar => text().nullable()();
  TextColumn get firestoreId => text().nullable()(); // Added for cloud sync
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

class PracticeSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get firestoreId => text().nullable()();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get locationName => text().nullable()();
  IntColumn get totalBalls => integer().withDefault(const Constant(0))();
  TextColumn get sessionType => text().withDefault(const Constant('FREE'))(); // FREE, TARGET, DRILL, CHALLENGE
  IntColumn get drillId => integer().nullable().references(Drills, #id)(); // Linked to structured drill
  IntColumn get targetDistance => integer().nullable()(); // Added for Target Practice
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Drills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().nullable()(); // Added for custom drills
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get difficulty => text()(); // Beginner, Intermediate, Advanced, Expert
  IntColumn get durationMinutes => integer()();
  TextColumn get icon => text().withDefault(const Constant('target'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get firestoreId => text().nullable()();
}

class DrillSteps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get drillId => integer().references(Drills, #id)();
  IntColumn get stepOrder => integer()();
  TextColumn get instruction => text()();
  IntColumn get targetDistance => integer().nullable()();
  IntColumn get ballsRequired => integer()();
  TextColumn get clubType => text().nullable()();
}

class PracticeShots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(PracticeSessions, #id)();
  TextColumn get firestoreId => text().nullable()();
  IntColumn get clubId => integer().references(Clubs, #id)();
  RealColumn get distance => real().nullable()();
  TextColumn get quality => text().nullable()(); // GREAT, GOOD, OKAY, MISS
  TextColumn get shotShape => text().nullable()(); 
  TextColumn get ballFlightJson => text().nullable()(); // For AI analytics
  TextColumn get videoUrl => text().nullable()(); // Added for AI Shot Analyzer
  TextColumn get poseMetricsJson => text().nullable()(); // Added for biomechanical data
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firestoreId => text().nullable()(); // Added for cloud sync
  TextColumn get userId => text().nullable()();    // Added for multi-user isolation
  TextColumn get name => text()();
  TextColumn get location => text().withDefault(const Constant(''))();
  IntColumn get totalHoles => integer().withDefault(const Constant(18))();
  IntColumn get par18 => integer().nullable()();
  IntColumn get par9front => integer().nullable()();
  IntColumn get par9back => integer().nullable()();
  TextColumn get holePars => text().withDefault(const Constant('[]'))();  // JSON array of 18 ints
  TextColumn get teeData => text().withDefault(const Constant('[]'))();   // JSON array of tee objects
  BoolColumn get isUserEdited => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();  // For Firestore sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Rounds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firestoreId => text().nullable()(); // Added for cloud sync
  TextColumn get userId => text().nullable()();    // Added for multi-user isolation
  IntColumn get courseId => integer().references(Courses, #id)();
  TextColumn get courseName => text().withDefault(const Constant(''))();
  IntColumn get holesPlayed => integer().withDefault(const Constant(18))();
  TextColumn get tee => text().withDefault(const Constant(''))();
  IntColumn get totalScore => integer()();
  IntColumn get coursePar => integer()();
  IntColumn get scoreVsPar => integer()();
  IntColumn get front9Score => integer().nullable()();
  IntColumn get back9Score => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get syncId => text().nullable()();
  DateTimeColumn get playedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class HoleScores extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roundId => integer().references(Rounds, #id)();
  IntColumn get holeNumber => integer()();
  IntColumn get par => integer()();
  IntColumn get score => integer()();
  IntColumn get yardage => integer().nullable()();
  
  // Advanced Scoring Stats
  IntColumn get putts => integer().nullable()();
  TextColumn get fairwayHit => text().nullable()(); // 'Hit', 'Left', 'Right', 'Short', 'Long'
  IntColumn get penalties => integer().nullable()();
  IntColumn get groupRoundId => integer().nullable().references(GroupRounds, #id)();
}

class GroupRounds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get roundCode => text().unique()(); // e.g. "GRD-7X9K2"
  TextColumn get captainId => text()();
  IntColumn get courseId => integer().references(Courses, #id)();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, IN_PROGRESS, COMPLETED
  TextColumn get scoringMode => text().withDefault(const Constant('INDIVIDUAL_DEVICES'))(); // INDIVIDUAL_DEVICES, SINGLE_DEVICE
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class GroupRoundParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupRoundId => integer().references(GroupRounds, #id)();
  TextColumn get userId => text()();
  TextColumn get status => text().withDefault(const Constant('JOINED'))(); // INVITED, JOINED
  TextColumn get role => text().withDefault(const Constant('PLAYER'))();   // CAPTAIN, PLAYER
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
}

class Providers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get role => text()(); // caddie or coach
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get whatsapp => text().nullable()();
  IntColumn get experience => integer().withDefault(const Constant(0))();
  TextColumn get coursesJson => text().withDefault(const Constant('[]'))();
  TextColumn get specializationsJson => text().nullable()();
  TextColumn get availabilityJson => text().withDefault(const Constant('{}'))();
  RealColumn get price => real().nullable()();
  RealColumn get rating => real().withDefault(const Constant(0))();
  IntColumn get totalReviews => integer().withDefault(const Constant(0))();
  IntColumn get totalBookings => integer().withDefault(const Constant(0))();
  IntColumn get totalCalls => integer().withDefault(const Constant(0))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  BoolColumn get profileComplete => boolean().withDefault(const Constant(false))();
  TextColumn get certificationUrl => text().nullable()(); // Added for security
  TextColumn get bio => text().nullable()();
  TextColumn get personalityType => text().nullable()();
  TextColumn get coachingLocation => text().nullable()();
  TextColumn get coachingStylesJson => text().nullable()();
  TextColumn get sessionTypesJson => text().nullable()();
  BoolColumn get hasCertification => boolean().withDefault(const Constant(false))();
  TextColumn get certificationName => text().nullable()();
  IntColumn get views => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Interactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playerId => text()();
  TextColumn get providerId => text()();
  TextColumn get type => text()(); // call, whatsapp
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, booked, ignored
  DateTimeColumn get lastPromptedAt => dateTime().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get providerId => text()();
  TextColumn get playerId => text()();
  TextColumn get playerName => text()();
  TextColumn get playerAvatar => text().nullable()();
  IntColumn get rating => integer()();
  TextColumn get comment => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database Definition ───────────────────────────────────────────────────


@DriftDatabase(tables: [
  UserProfiles, Courses, Rounds, HoleScores, Clubs, Friends, 
  GroupRounds, GroupRoundParticipants, PracticeSessions, 
  PracticeShots, Drills, DrillSteps, Providers, Interactions, Reviews
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this when schema changes
  @override
  int get schemaVersion => 24;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await syncPrimaryDrills();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(holeScores, holeScores.putts);
          await m.addColumn(holeScores, holeScores.fairwayHit);
          await m.addColumn(holeScores, holeScores.penalties);
        }
        if (from < 3) {
          await m.addColumn(rounds, rounds.firestoreId);
        }
        if (from < 4) {
          await m.addColumn(courses, courses.firestoreId);
        }
        if (from < 5) {
          // Logic for previous migrations if needed
        }
        if (from < 6) {
          // Add UserProfile personalization columns
          await m.addColumn(userProfiles, userProfiles.homeCourseId);
          await m.addColumn(userProfiles, userProfiles.homeCourseName);
          await m.addColumn(userProfiles, userProfiles.skillLevel);
          await m.addColumn(userProfiles, userProfiles.preferredTees);
          await m.addColumn(userProfiles, userProfiles.playStyle);
          await m.addColumn(userProfiles, userProfiles.units);
          await m.addColumn(userProfiles, userProfiles.themeMode);
          await m.addColumn(userProfiles, userProfiles.privacyLevel);
          await m.addColumn(userProfiles, userProfiles.badgesJson);
          
          // Create new Clubs table
          await m.createTable(clubs);
        }
        if (from < 7) {
          await m.createTable(friends);
        }
        if (from < 8) {
          // Recreate UserProfiles to apply unique constraint safely
          final allProfiles = await (select(userProfiles)).get();
          final uniqueProfiles = <String, UserProfile>{};
          for (var p in allProfiles) {
            if (p.firebaseUid != null) {
              uniqueProfiles.putIfAbsent(p.firebaseUid!, () => p);
            }
          }
          
          await m.deleteTable(userProfiles.actualTableName);
          await m.createTable(userProfiles);
          
          for (var p in uniqueProfiles.values) {
            await into(userProfiles).insert(p);
          }
        }
        if (from < 9) {
          // Add groupRoundId to holeScores (for individual tracking in shared rounds)
          await m.addColumn(holeScores, holeScores.groupRoundId);
          // Create group round tables
          await m.createTable(groupRounds);
          await m.createTable(groupRoundParticipants);
        }
        if (from < 10) {
          // Add firestoreId to Clubs and Friends
          await m.addColumn(clubs, clubs.firestoreId);
          await m.addColumn(friends, friends.firestoreId);
          // Create Practice tables
          await m.createTable(practiceSessions);
          await m.createTable(practiceShots);
        }
        if (from < 11) {
          // Add drillId and targetDistance to PracticeSessions
          await m.addColumn(practiceSessions, practiceSessions.drillId);
          await m.addColumn(practiceSessions, practiceSessions.targetDistance);
          // Create new Drill tables
          await m.createTable(drills);
          await m.createTable(drillSteps);
          await syncPrimaryDrills();
        }
        if (from < 13) {
          // Add userId, category, and icon to Drills
          await m.addColumn(this.drills, this.drills.userId);
          await m.addColumn(this.drills, this.drills.category);
          await m.addColumn(this.drills, this.drills.icon);
        }
        if (from < 14) {
          await m.addColumn(practiceShots, practiceShots.poseMetricsJson);
          await syncPrimaryDrills();
        }
        if (from < 15) {
          await m.addColumn(clubs, clubs.photoUrl);
        }
        if (from < 16) {
          await m.addColumn(userProfiles, userProfiles.role);
          await m.createTable(providers);
          await m.createTable(interactions);
        }
        if (from < 17) {
          await m.addColumn(this.providers, this.providers.certificationUrl);
        }
        if (from < 18) {
          await m.addColumn(this.userProfiles, this.userProfiles.profileComplete);
        }
        if (from < 19) {
          await m.addColumn(this.providers, this.providers.bio);
          await m.addColumn(this.providers, this.providers.personalityType);
          await m.addColumn(this.providers, this.providers.coachingLocation);
          await m.addColumn(this.providers, this.providers.coachingStylesJson);
          await m.addColumn(this.providers, this.providers.sessionTypesJson);
          await m.addColumn(this.providers, this.providers.hasCertification);
          await m.addColumn(this.providers, this.providers.certificationName);
        }
        if (from < 20) {
          await m.addColumn(this.providers, this.providers.views);
          await m.addColumn(this.providers, this.providers.streak);
          // Just in case it was missed, though normally createdAt is always there
          try {
            await m.addColumn(this.providers, this.providers.createdAt);
          } catch (_) {}
        }
        if (from < 21) {
          await m.createTable(reviews);
        }
        if (from < 22) {
          await m.addColumn(interactions, interactions.lastPromptedAt);
        }
        if (from < 23) {
          await m.addColumn(userProfiles, userProfiles.email);
        }
        if (from < 24) {
          await m.addColumn(providers, providers.isAvailable);
        }
      },
    );
  }

  // ─── Course Queries ───

  Future<List<Course>> getAllCourses(String? userId) => 
      (select(courses)..where((c) => c.userId.isNull() | c.userId.equals(userId ?? ''))).get();

  Future<Course> getCourse(int id) =>
      (select(courses)..where((c) => c.id.equals(id))).getSingle();

  Stream<List<Course>> watchAllCourses(String? userId) => 
      (select(courses)..where((c) => c.userId.isNull() | c.userId.equals(userId ?? ''))).watch();

  Future<Course?> getCourseByFirestoreId(String firestoreId) async {
    final list = await (select(courses)..where((c) => c.firestoreId.equals(firestoreId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<int> insertCourse(CoursesCompanion course) =>
      into(courses).insert(course);

  Future<bool> updateCourse(Course course) =>
      update(courses).replace(course);

  Future<void> upsertCourse(CoursesCompanion course) async {
    final existing = await getCourseByFirestoreId(course.firestoreId.value!);
    if (existing != null) {
      await (update(courses)..where((c) => c.id.equals(existing.id))).write(course);
    } else {
      await into(courses).insert(course);
    }
  }

  Future<void> upsertRound(RoundsCompanion round) async {
    final existing = await getRoundByFirestoreId(round.firestoreId.value!);
    if (existing != null) {
      await (update(rounds)..where((r) => r.id.equals(existing.id))).write(round);
    } else {
      await into(rounds).insert(round);
    }
  }

  // ─── Club Queries ────────────────────────────────────────────────────────

  Future<Club?> getClubByFirestoreId(String firestoreId) async {
    final list = await (select(clubs)..where((c) => c.firestoreId.equals(firestoreId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<Club?> getClubByAttributes(String type, String? brand, String? model, String userId) async {
    final list = await (select(clubs)
      ..where((c) => c.userId.equals(userId) & 
                     c.firestoreId.isNull() & 
                     c.type.equals(type) & 
                     (brand != null ? c.brand.equals(brand) : c.brand.isNull()) &
                     (model != null ? c.model.equals(model) : c.model.isNull())
      )).get();
    return list.isEmpty ? null : list.first;
  }

  Future<void> upsertClub(ClubsCompanion club) async {
    Club? existing = await getClubByFirestoreId(club.firestoreId.value!);
    
    // Fallback: match by attributes if not found by ID to prevent duplication
    if (existing == null && club.firestoreId.value != null) {
      existing = await getClubByAttributes(
        club.type.value,
        club.brand.value,
        club.model.value,
        club.userId.value,
      );
    }

    if (existing != null) {
      await (update(clubs)..where((c) => c.id.equals(existing!.id))).write(club);
    } else {
      await into(clubs).insert(club);
    }
  }

  // ─── Round Queries ───

  Future<List<Round>> getAllRounds(String userId) =>
      (select(rounds)
        ..where((r) => r.userId.equals(userId))
        ..orderBy([(r) => OrderingTerm.desc(r.playedAt)]))
          .get();

  Stream<List<Round>> watchAllRounds(String userId) =>
      (select(rounds)
        ..where((r) => r.userId.equals(userId))
        ..orderBy([(r) => OrderingTerm.desc(r.playedAt)]))
          .watch();

  Future<Round> getRound(int id) =>
      (select(rounds)..where((r) => r.id.equals(id))).getSingle();

  Future<Round?> getRoundByFirestoreId(String firestoreId) async {
    final list = await (select(rounds)..where((r) => r.firestoreId.equals(firestoreId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<int> insertRound(RoundsCompanion round) =>
      into(rounds).insert(round);

  Future<bool> updateRound(Round round) =>
      update(rounds).replace(round);

  Future<int> deleteRound(int id) =>
      (delete(rounds)..where((r) => r.id.equals(id))).go();

  Future<List<Round>> getRecentRounds(String userId, {int limit = 5}) =>
      (select(rounds)
        ..where((r) => r.userId.equals(userId))
        ..orderBy([(r) => OrderingTerm.desc(r.playedAt)])
        ..limit(limit))
          .get();

  // ─── Hole Score Queries ───

  Future<List<HoleScore>> getHoleScoresForRound(int roundId) =>
      (select(holeScores)
        ..where((h) => h.roundId.equals(roundId))
        ..orderBy([(h) => OrderingTerm.asc(h.holeNumber)]))
          .get();

  Future<void> insertHoleScores(List<HoleScoresCompanion> scores) async {
    await batch((b) {
      b.insertAll(holeScores, scores);
    });
  }

  Future<void> deleteHoleScoresForRound(int roundId) =>
      (delete(holeScores)..where((h) => h.roundId.equals(roundId))).go();

  Future<List<HoleScore>> getUserHoleScores(String userId) {
    final query = select(holeScores).join([
      innerJoin(rounds, rounds.id.equalsExp(holeScores.roundId)),
    ])..where(rounds.userId.equals(userId));
    
    return query.map((row) => row.readTable(holeScores)).get();
  }

  // ─── Friend Queries ───

  Future<List<Friend>> getFriends(String userId) =>
      (select(friends)..where((f) => f.userId.equals(userId))).get();

  Stream<List<Friend>> watchFriends(String userId) =>
      (select(friends)..where((f) => f.userId.equals(userId))).watch();

  // ─── Leaderboard Queries ───

  Future<List<Round>> getCourseRounds(int courseId) =>
      (select(rounds)..where((r) => r.courseId.equals(courseId))..orderBy([(u) => OrderingTerm.asc(u.totalScore)])).get();

  // ─── User Profile ───

  Future<UserProfile?> getProfile(String uid) async {
    final list = await (select(userProfiles)..where((u) => u.firebaseUid.equals(uid))).get();
    return list.isEmpty ? null : list.first;
  }

  Stream<UserProfile?> watchProfile(String uid) =>
      (select(userProfiles)..where((u) => u.firebaseUid.equals(uid)))
          .watch()
          .map((list) => list.isEmpty ? null : list.first);
  Future<int> insertProfile(UserProfilesCompanion profile) =>
      into(userProfiles).insert(profile);

  Future<void> updateProfile(String uid, UserProfilesCompanion profile) =>
      (update(userProfiles)..where((u) => u.firebaseUid.equals(uid))).write(profile);

  Future<void> upsertProfile(UserProfilesCompanion profile) =>
      into(userProfiles).insert(
        profile,
        onConflict: DoUpdate(
          (old) => profile,
          target: [userProfiles.firebaseUid],
        ),
      );

  // ─── Provider Queries ───

  Future<Provider?> getProvider(String userId) async {
    final list = await (select(providers)..where((p) => p.userId.equals(userId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<void> upsertProvider(ProvidersCompanion provider) =>
      into(providers).insert(
        provider,
        onConflict: DoUpdate(
          (old) => provider,
          target: [providers.userId],
        ),
      );

  /// Recalculates average rating + review count from the Reviews table
  /// and writes the result to the matching Provider row.
  Future<void> updateProviderRating(String providerId) async {
    final allReviews = await (select(reviews)
      ..where((r) => r.providerId.equals(providerId)))
        .get();

    final count = allReviews.length;
    final avg = count == 0
        ? 0.0
        : allReviews.map((r) => r.rating).reduce((a, b) => a + b) / count;

    await (update(providers)..where((p) => p.userId.equals(providerId)))
        .write(ProvidersCompanion(
      rating: Value(avg),
      totalReviews: Value(count),
    ));
  }

  // ─── Practice Queries ──────────────────────────────────────────────────────

  Future<PracticeSession?> getPracticeSessionByFirestoreId(String firestoreId) async {
    final list = await (select(practiceSessions)..where((s) => s.firestoreId.equals(firestoreId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<void> upsertPracticeSession(PracticeSessionsCompanion session) async {
    final existing = await getPracticeSessionByFirestoreId(session.firestoreId.value!);
    if (existing != null) {
      await (update(practiceSessions)..where((s) => s.id.equals(existing.id))).write(session);
    } else {
      await into(practiceSessions).insert(session);
    }
  }

  Future<PracticeShot?> getPracticeShotByFirestoreId(String firestoreId) async {
    final list = await (select(practiceShots)..where((s) => s.firestoreId.equals(firestoreId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<void> upsertPracticeShot(PracticeShotsCompanion shot) async {
    final existing = await getPracticeShotByFirestoreId(shot.firestoreId.value!);
    if (existing != null) {
      await (update(practiceShots)..where((s) => s.id.equals(existing.id))).write(shot);
    } else {
      await into(practiceShots).insert(shot);
    }
  }

  Future<Drill?> getDrillByFirestoreId(String firestoreId) async {
    final list = await (select(drills)..where((d) => d.firestoreId.equals(firestoreId))).get();
    return list.isEmpty ? null : list.first;
  }

  Future<void> upsertDrill(DrillsCompanion drill) async {
    final existing = await getDrillByFirestoreId(drill.firestoreId.value!);
    if (existing != null) {
      await (update(drills)..where((d) => d.id.equals(existing.id))).write(drill);
    } else {
      await into(drills).insert(drill);
    }
  }

  // ─── Stats ───

  Future<int> getTotalRoundsCount(String userId) async {
    final count = countAll();
    final query = selectOnly(rounds)
      ..where(rounds.userId.equals(userId))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<double?> getAverageScore(String userId) async {
    final avg = rounds.totalScore.avg();
    final query = selectOnly(rounds)
      ..where(rounds.userId.equals(userId))
      ..addColumns([avg]);
    final result = await query.get().then((list) => list.firstOrNull);
    return result?.read(avg);
  }

  Future<int?> getBestScore(String userId) async {
    final min = rounds.totalScore.min();
    final query = selectOnly(rounds)
      ..where(rounds.userId.equals(userId))
      ..addColumns([min]);
    final result = await query.get().then((list) => list.firstOrNull);
    return result?.read(min);
  }

  // ─── Seeding ───

  Future<void> syncPrimaryDrills() async {

    await transaction(() async {
      // 1. Clock Face Drill
      final existingClock = await (select(drills)..where((d) => d.name.equals('Clock Face Drill'))).get().then((list) => list.firstOrNull);
      int clockId;
      if (existingClock == null) {
        clockId = await into(drills).insert(DrillsCompanion.insert(
          name: 'Clock Face Drill',
          description: 'Improve direction control by hitting to specific "clock" positions.',
          difficulty: 'Intermediate',
          durationMinutes: 20,
        ));
      } else {
        clockId = existingClock.id;
      }
      
      final clockSteps = await (select(drillSteps)..where((s) => s.drillId.equals(clockId))).get();
      if (clockSteps.isEmpty) {
        await batch((b) {
          b.insertAll(drillSteps, [
            DrillStepsCompanion.insert(drillId: clockId, stepOrder: 1, instruction: 'Hit 5 balls to 12 o\'clock position', ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: clockId, stepOrder: 2, instruction: 'Hit 5 balls to 3 o\'clock position', ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: clockId, stepOrder: 3, instruction: 'Hit 5 balls to 6 o\'clock position', ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: clockId, stepOrder: 4, instruction: 'Hit 5 balls to 9 o\'clock position', ballsRequired: 5),
          ]);
        });
      }

      // 2. Ladder Drill
      final existingLadder = await (select(drills)..where((d) => d.name.equals('Ladder Drill'))).get().then((list) => list.firstOrNull);
      int ladderId;
      if (existingLadder == null) {
        ladderId = await into(drills).insert(DrillsCompanion.insert(
          name: 'Ladder Drill',
          description: 'Progressive distance control across different yardages.',
          difficulty: 'Advanced',
          durationMinutes: 15,
        ));
      } else {
        ladderId = existingLadder.id;
      }

      final ladderSteps = await (select(drillSteps)..where((s) => s.drillId.equals(ladderId))).get();
      if (ladderSteps.isEmpty) {
        await batch((b) {
          b.insertAll(drillSteps, [
            DrillStepsCompanion.insert(drillId: ladderId, stepOrder: 1, instruction: 'Hit 5 balls to 100 yards', targetDistance: Value(100), ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: ladderId, stepOrder: 2, instruction: 'Hit 5 balls to 125 yards', targetDistance: Value(125), ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: ladderId, stepOrder: 3, instruction: 'Hit 5 balls to 150 yards', targetDistance: Value(150), ballsRequired: 5),
          ]);
        });
      }

      // 3. 9-Club Challenge
      final existingNineClub = await (select(drills)..where((d) => d.name.equals('9-Club Challenge'))).get().then((list) => list.firstOrNull);
      int nineClubId;
      if (existingNineClub == null) {
        nineClubId = await into(drills).insert(DrillsCompanion.insert(
          name: '9-Club Challenge',
          description: 'Hit one ball with each of 9 different clubs to different targets.',
          difficulty: 'Expert',
          durationMinutes: 30,
        ));
      } else {
        nineClubId = existingNineClub.id;
      }

      final nineClubSteps = await (select(drillSteps)..where((s) => s.drillId.equals(nineClubId))).get();
      if (nineClubSteps.isEmpty) {
        await batch((b) {
          b.insertAll(drillSteps, [
            DrillStepsCompanion.insert(drillId: nineClubId, stepOrder: 1, instruction: 'Hit 1 ball with 9 different clubs', ballsRequired: 9),
          ]);
        });
      }

      // 4. Pre-Round Warmup
      final existingWarmup = await (select(drills)..where((d) => d.name.equals('Pre-Round Warmup'))).get().then((list) => list.firstOrNull);
      int warmupId;
      if (existingWarmup == null) {
        warmupId = await into(drills).insert(DrillsCompanion.insert(
          name: 'Pre-Round Warmup',
          description: 'Systematic routine to get you ready for the first tee.',
          difficulty: 'Beginner',
          durationMinutes: 10,
        ));
      } else {
        warmupId = existingWarmup.id;
      }

      final warmupSteps = await (select(drillSteps)..where((s) => s.drillId.equals(warmupId))).get();
      if (warmupSteps.isEmpty) {
        await batch((b) {
          b.insertAll(drillSteps, [
            DrillStepsCompanion.insert(drillId: warmupId, stepOrder: 1, instruction: '5 Wedges: Half-swings to find tempo', ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: warmupId, stepOrder: 2, instruction: '5 Mid Irons: Focus on solid contact', ballsRequired: 5),
            DrillStepsCompanion.insert(drillId: warmupId, stepOrder: 3, instruction: '3 Long Irons/Woods: High launches', ballsRequired: 3),
            DrillStepsCompanion.insert(drillId: warmupId, stepOrder: 4, instruction: '2 Drivers: Pick a target fairway', ballsRequired: 2),
          ]);
        });
      }
    });
  }
}

// ─── Open Connection ───────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'score_caddie.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
