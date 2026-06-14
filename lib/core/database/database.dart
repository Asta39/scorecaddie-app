
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/foundation.dart';

part 'database.g.dart';

// ─── Tables ────────────────────────────────────────────────────────────────

class UserProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get name => text().withDefault(const Constant('Golfer'))();
  TextColumn get avatarUrl => text().nullable()();
  RealColumn get handicap => real().nullable()();
  
  // Professional WHS tracking
  TextColumn get handicapOrigin => text().withDefault(const Constant('new_golfer'))(); // new_golfer, self_reported, kgu_verified
  RealColumn get importedIndex => real().nullable()();
  BoolColumn get isProvisional => boolean().withDefault(const Constant(true))();
  IntColumn get provisionalRounds => integer().withDefault(const Constant(0))();
  RealColumn get anchorIndex => real().nullable()();

  IntColumn get homeCourseId => integer().nullable()();
  TextColumn get homeCourseName => text().nullable()();
  TextColumn get skillLevel => text().nullable()(); 
  TextColumn get preferredTees => text().nullable()();
  TextColumn get playStyle => text().nullable()(); 
  TextColumn get units => text().withDefault(const Constant('Yards'))();
  TextColumn get themeMode => text().withDefault(const Constant('System'))();
  TextColumn get privacyLevel => text().withDefault(const Constant('Private'))();
  TextColumn get badgesJson => text().withDefault(const Constant('[]'))();
  TextColumn get role => text().nullable()(); 
  BoolColumn get profileComplete => boolean().withDefault(const Constant(false))();
  BoolColumn get pfpVerified => boolean().withDefault(const Constant(false))();
  
  // New Uber-model fields
  TextColumn get providerStatus => text().withDefault(const Constant('OFFLINE'))(); // AVAILABLE, ON_ROUND, OFFLINE
  TextColumn get currentBookingId => text().nullable()();
  TextColumn get passportPhotoUrl => text().nullable()();
  TextColumn get friendCode => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Clubs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); 
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  RealColumn get loft => real().nullable()();
  RealColumn get averageDistance => real().nullable()(); // NEW: Approximated distance
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()(); 
  TextColumn get supabaseId => text().nullable()(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Friends extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get friendId => text()();
  TextColumn get friendName => text().nullable()();
  TextColumn get friendAvatar => text().nullable()();
  TextColumn get supabaseId => text().nullable()();
  BoolColumn get isCoach => boolean().withDefault(const Constant(false))();
  BoolColumn get isStudent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, friendId}
  ];
}
class PracticeSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get locationName => text().nullable()();
  IntColumn get totalBalls => integer().withDefault(const Constant(0))();
  TextColumn get sessionType => text().withDefault(const Constant('FREE'))(); 
  IntColumn get drillId => integer().nullable().references(Drills, #id)(); 
  TextColumn get coachDrillId => text().nullable()(); // Supabase UUID
  IntColumn get targetDistance => integer().nullable()(); 
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  List<Set<Column>> get uniqueKeys => [{supabaseId}];
}

class Drills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().nullable()(); 
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get difficulty => text()(); 
  IntColumn get durationMinutes => integer()();
  TextColumn get icon => text().withDefault(const Constant('target'))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get supabaseId => text().nullable()();
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
  TextColumn get supabaseId => text().nullable()();
  IntColumn get clubId => integer().references(Clubs, #id)();
  RealColumn get distance => real().nullable()();
  TextColumn get quality => text().nullable()(); 
  TextColumn get shotShape => text().nullable()(); 
  TextColumn get ballFlightJson => text().nullable()(); 
  TextColumn get videoUrl => text().nullable()(); 
  TextColumn get poseMetricsJson => text().nullable()(); 
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()(); 
  TextColumn get userId => text().nullable()();    
  TextColumn get name => text()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get city => text().nullable()();
  TextColumn get region => text().nullable()(); 
  IntColumn get totalHoles => integer().withDefault(const Constant(18))();
  IntColumn get par => integer().nullable()(); 
  IntColumn get par18 => integer().nullable()();
  IntColumn get par9front => integer().nullable()();
  IntColumn get par9back => integer().nullable()();
  TextColumn get holePars => text().withDefault(const Constant('[]'))();  
  TextColumn get teeData => text().withDefault(const Constant('[]'))();   
  BoolColumn get isUserEdited => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();  
  RealColumn get caddieFee => real().nullable().withDefault(const Constant(1000.0))(); 
  RealColumn get latitude => real().nullable()(); // Added for location-based sorting
  RealColumn get longitude => real().nullable()(); // Added for location-based sorting
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [{supabaseId}, {name, location}];
}

class Tees extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer().references(Courses, #id)();
  TextColumn get name => text()(); // "White", "Simba", etc
  TextColumn get gender => text().withDefault(const Constant('male'))();
  RealColumn get courseRating => real()();
  IntColumn get slopeRating => integer()();
  IntColumn get par => integer().nullable()();
  IntColumn get yardage => integer().nullable()();
  
  // WHS 2024: Specific 9-hole ratings for accurate 9-hole handicapping
  RealColumn get courseRatingFront => real().nullable()();
  IntColumn get slopeRatingFront => integer().nullable()();
  RealColumn get courseRatingBack => real().nullable()();
  IntColumn get slopeRatingBack => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {courseId, name, gender}
  ];
}

class Rounds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get supabaseId => text().nullable()(); 
  TextColumn get userId => text().nullable()();    
  IntColumn get courseId => integer().references(Courses, #id)();
  IntColumn get teeId => integer().nullable().references(Tees, #id)(); // NEW
  TextColumn get courseName => text().withDefault(const Constant(''))();
  IntColumn get holesPlayed => integer().withDefault(const Constant(18))();
  TextColumn get tee => text().withDefault(const Constant(''))();
  IntColumn get totalScore => integer()();
  IntColumn get adjustedGrossScore => integer().nullable()(); // NEW: ESC capped
  IntColumn get totalNet => integer().nullable()();
  IntColumn get coursePar => integer()();
  IntColumn get scoreVsPar => integer()();
  RealColumn get scoreDifferential => real().nullable()(); // NEW
  RealColumn get handicapBefore => real().nullable()(); // NEW
  RealColumn get handicapAfter => real().nullable()(); // NEW
  IntColumn get front9Score => integer().nullable()();
  IntColumn get back9Score => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get syncId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // NEW
  BoolColumn get useForAnalytics => boolean().withDefault(const Constant(true))(); // NEW
  
  // Scanned round additions
  TextColumn get source => text().withDefault(const Constant('live'))(); // 'live', 'scanned', 'manual'
  TextColumn get scorecardImageUrl => text().nullable()();
  RealColumn get scannerConfidence => real().nullable()();
  TextColumn get scannerPlayerSlot => text().nullable()();

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
  IntColumn get putts => integer().nullable()();
  TextColumn get fairwayHit => text().nullable()(); 
  IntColumn get penalties => integer().nullable()();
  IntColumn get groupRoundId => integer().nullable().references(GroupRounds, #id)();
  TextColumn get participantId => text().nullable()(); // NEW: Link to GroupRoundParticipant
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get gir => boolean().nullable()();
}

class CourseHoles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer().references(Courses, #id)();
  IntColumn get teeId => integer().nullable().references(Tees, #id)(); // NEW
  IntColumn get holeNumber => integer()();
  IntColumn get par => integer()();
  IntColumn get handicapIndex => integer().nullable()();
  IntColumn get distance => integer().nullable()();
  
  @override
  List<Set<Column>> get uniqueKeys => [{courseId, teeId, holeNumber}];
}

class GroupRounds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get roundCode => text().unique()(); 
  TextColumn get captainId => text()();
  IntColumn get courseId => integer().references(Courses, #id)();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); 
  TextColumn get scoringMode => text().withDefault(const Constant('INDIVIDUAL_DEVICES'))(); 
  BoolColumn get useForAnalytics => boolean().withDefault(const Constant(true))(); // NEW: Support early round finish
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class GroupRoundParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupRoundId => integer().references(GroupRounds, #id)();
  TextColumn get userId => text()();
  TextColumn get status => text().withDefault(const Constant('JOINED'))(); 
  TextColumn get role => text().withDefault(const Constant('player'))();   
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();
}

class Providers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get role => text()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get phone => text()();
  TextColumn get whatsapp => text().nullable()();
  IntColumn get experience => integer().withDefault(const Constant(0))();
  TextColumn get coursesJson => text().withDefault(const Constant('[]'))();
  TextColumn get specializationsJson => text().nullable()();
  TextColumn get availabilityJson => text().withDefault(const Constant('{}'))();
  RealColumn get price => real().nullable()();
  RealColumn get rating => real().withDefault(const Constant(5.0))();
  IntColumn get totalReviews => integer().withDefault(const Constant(0))();
  IntColumn get totalBookings => integer().withDefault(const Constant(0))();
  IntColumn get totalCalls => integer().withDefault(const Constant(0))();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();
  BoolColumn get profileComplete => boolean().withDefault(const Constant(false))();
  TextColumn get certificationUrl => text().nullable()(); 
  TextColumn get certificatesJson => text().withDefault(const Constant('[]'))(); 
  TextColumn get bio => text().nullable()();
  TextColumn get personalityType => text().nullable()();
  TextColumn get coachingLocation => text().nullable()();
  TextColumn get coachingStylesJson => text().nullable()();
  TextColumn get sessionTypesJson => text().nullable()();
  BoolColumn get hasCertification => boolean().withDefault(const Constant(false))();
  TextColumn get certificationName => text().nullable()();
  TextColumn get targetAudienceJson => text().nullable()();
  IntColumn get views => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Interactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playerId => text()();
  TextColumn get providerId => text()();
  TextColumn get type => text()(); 
  TextColumn get status => text().withDefault(const Constant('pending'))(); 
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

// ─── Uber-model New Tables ───────────────────────────────────────────────────

class Bookings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique().nullable()(); // PostgreSQL ID
  TextColumn get playerId => text()();
  TextColumn get providerId => text()();
  
  TextColumn get roundType => text().withDefault(const Constant('EIGHTEEN_HOLES'))(); // EIGHTEEN_HOLES, FRONT_NINE, BACK_NINE
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED
  TextColumn get initiatedVia => text().withDefault(const Constant('CHAT'))(); // CALL, CHAT
  
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  
  RealColumn get amountPaid => real().nullable()();
  TextColumn get currency => text().withDefault(const Constant('KES'))();
  TextColumn get paymentMethod => text().nullable()(); // CASH, MPESA, CARD
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique().nullable()();
  TextColumn get bookingId => text().nullable()();
  TextColumn get senderId => text()();
  TextColumn get receiverId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();
}

class Inquiries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().unique().nullable()();
  TextColumn get playerId => text()();
  TextColumn get providerId => text()();
  TextColumn get initiatedVia => text()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, RESOLVED
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TeeTimeReminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  DateTimeColumn get reminderDate => dateTime()();
  IntColumn get notifyBeforeMinutes => integer().withDefault(const Constant(30))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database Definition ───────────────────────────────────────────────────


@DriftDatabase(tables: [
  UserProfiles, Courses, CourseHoles, Tees, Rounds, HoleScores, Clubs, Friends, 
  GroupRounds, GroupRoundParticipants, PracticeSessions, 
  PracticeShots, Drills, DrillSteps, Providers, Interactions, Reviews,
  Bookings, Messages, Inquiries, TeeTimeReminders
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 54;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await syncPrimaryDrills();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle all previous migrations (simplified for development recovery)
        if (from < 46) {
           try { await m.addColumn(holeScores, holeScores.gir); } catch (_) {}
        }
        
        if (from < 47) {
          try { await m.addColumn(clubs, clubs.averageDistance); } catch (_) {}
          try { await m.deleteTable('courses'); await m.createTable(courses); } catch (_) {}
        }

        if (from < 48) {
          // RENAME firestoreId to supabaseId for all tables using Raw SQL for reliability
          final tables = ['clubs', 'friends', 'courses', 'rounds', 'practice_sessions', 'practice_shots', 'drills'];
          for (var table in tables) {
            try {
              await customStatement('ALTER TABLE $table RENAME COLUMN firestore_id TO supabase_id;');
            } catch (e) {
              debugPrint('MIGRATION: Column already renamed or table missing in $table');
            }
          }
        }

        if (from < 49) {
          // ENSURE hole_scores has all required columns for group rounds
          try { await m.addColumn(holeScores, holeScores.participantId); } catch (_) {}
          try { await m.addColumn(holeScores, holeScores.groupRoundId); } catch (_) {}
          
          try {
            await customStatement('ALTER TABLE rounds RENAME COLUMN firestore_id TO supabase_id;');
          } catch (_) {}
        }

        if (from < 50) {
          try { await m.addColumn(rounds, rounds.useForAnalytics); } catch (_) {}
        }

        if (from < 51) {
          try { await m.addColumn(groupRounds, groupRounds.useForAnalytics); } catch (_) {}
        }

        if (from < 52) {
          try { await m.createTable(teeTimeReminders); } catch (_) {}
        }

        if (from < 53) {
          try { await m.addColumn(userProfiles, userProfiles.friendCode); } catch (_) {}
        }

        if (from < 54) {
          try { await m.addColumn(rounds, rounds.source); } catch (_) {}
          try { await m.addColumn(rounds, rounds.scorecardImageUrl); } catch (_) {}
          try { await m.addColumn(rounds, rounds.scannerConfidence); } catch (_) {}
          try { await m.addColumn(rounds, rounds.scannerPlayerSlot); } catch (_) {}
        }
      },
      // Safety net: if the v52→v53→v54 migration was silently swallowed (try/catch
      // ate the error but version was already stamped), run the ALTER TABLE
      // unconditionally on every open. SQLite ignores "duplicate column" errors.
      beforeOpen: (details) async {
        try {
          // SQLite does NOT allow UNIQUE in ADD COLUMN — just add the column.
          // Uniqueness is enforced by Drift's schema on fresh installs.
          await customStatement(
            'ALTER TABLE user_profiles ADD COLUMN friend_code TEXT;',
          );
        } catch (_) {}
        
        try {
          await customStatement(
            'ALTER TABLE rounds ADD COLUMN source TEXT DEFAULT \'live\';',
          );
        } catch (_) {}

        try {
          await customStatement(
            'ALTER TABLE rounds ADD COLUMN scorecard_image_url TEXT;',
          );
        } catch (_) {}

        try {
          await customStatement(
            'ALTER TABLE rounds ADD COLUMN scanner_confidence REAL;',
          );
        } catch (_) {}

        try {
          await customStatement(
            'ALTER TABLE rounds ADD COLUMN scanner_player_slot TEXT;',
          );
        } catch (_) {}
      },
    );
  }

  // ─── Existing Queries (truncated) ───
  Future<List<Course>> getAllCourses(String? userId) => (select(courses)..where((c) => c.userId.isNull() | c.userId.equals(userId ?? ''))).get();
  Future<Course> getCourse(int id) => (select(courses)..where((c) => c.id.equals(id))).getSingle();
  Stream<List<Course>> watchAllCourses(String? userId) {
    return (select(courses)
      ..where((c) => c.userId.isNull() | c.userId.equals(userId ?? ''))
    ).watch();
  }
  Future<Course?> getCourseBySupabaseId(String supabaseId) async { final list = await (select(courses)..where((c) => c.supabaseId.equals(supabaseId))).get(); return list.isEmpty ? null : list.first; }
  Future<int> insertCourse(CoursesCompanion course) => into(courses).insert(course);
  Future<bool> updateCourse(Course course) => update(courses).replace(course);
  Future<int> upsertCourse(CoursesCompanion course) async {
    // Check if course exists by supabaseId or name+location to avoid constraint violations
    Course? existing;
    if (course.supabaseId.present && course.supabaseId.value != null) {
      existing = await (select(courses)..where((c) => c.supabaseId.equals(course.supabaseId.value!))).getSingleOrNull();
    }

    existing ??= await (select(courses)..where((c) => c.name.equals(course.name.value) & c.location.equals(course.location.value))).getSingleOrNull();

    if (existing != null) {
      await (update(courses)..where((c) => c.id.equals(existing!.id))).write(course);
      return existing.id;
    } else {
      return await into(courses).insert(course);
    }
  }  Future<List<CourseHole>> getHolesForCourse(int courseId, {int? teeId, bool deduplicate = true}) async {
    if (!deduplicate) {
      return await (select(courseHoles)..where((h) => h.courseId.equals(courseId))..orderBy([(h) => OrderingTerm.asc(h.holeNumber)])).get();
    }

    // 1. Try specific tee holes first
    List<CourseHole> results = [];
    if (teeId != null) {
      results = await (select(courseHoles)..where((h) => h.courseId.equals(courseId) & h.teeId.equals(teeId))..orderBy([(h) => OrderingTerm.asc(h.holeNumber)])).get();
      return results; // No deduplication needed for a specific tee
    }
    
    // 2. Fallback to general holes (where teeId is null) if no specific tee holes
    if (results.isEmpty) {
      results = await (select(courseHoles)..where((h) => h.courseId.equals(courseId) & h.teeId.isNull())..orderBy([(h) => OrderingTerm.asc(h.holeNumber)])).get();
    }

    // 2.5 Fallback to any holes for this course if still empty (e.g. locally seeded specific tees)
    if (results.isEmpty) {
      results = await (select(courseHoles)..where((h) => h.courseId.equals(courseId))..orderBy([(h) => OrderingTerm.asc(h.holeNumber)])).get();
    }

    if (!deduplicate) {
      return results;
    }

    // 3. Robust Deduplication by holeNumber
    final Map<int, CourseHole> uniqueMap = {};
    for (final h in results) {
      if (!uniqueMap.containsKey(h.holeNumber)) {
        uniqueMap[h.holeNumber] = h;
      }
    }
    
    final sortedHoles = uniqueMap.values.toList();
    sortedHoles.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
    return sortedHoles;
  }
  Future<void> upsertCourseHoles(List<CourseHolesCompanion> holes) async { await batch((b) { b.insertAll(courseHoles, holes, mode: InsertMode.insertOrReplace); }); }

  Future<List<Tee>> getTeesForCourse(int courseId) => (select(tees)..where((t) => t.courseId.equals(courseId))).get();
  Future<Tee?> getTeeByName(int courseId, String name) => (select(tees)..where((t) => t.courseId.equals(courseId) & t.name.equals(name))).getSingleOrNull();
  Future<void> upsertTees(List<TeesCompanion> teeList) async { await batch((b) { b.insertAll(tees, teeList, mode: InsertMode.insertOrReplace); }); }
  Future<Tee?> getTeeById(int id) => (select(tees)..where((t) => t.id.equals(id))).getSingleOrNull();
  
  Future<void> upsertRound(RoundsCompanion round) async { final existing = await getRoundBySupabaseId(round.supabaseId.value!); if (existing != null) { await (update(rounds)..where((r) => r.id.equals(existing.id))).write(round); } else { await into(rounds).insert(round); } }
  Future<Club?> getClubBySupabaseId(String supabaseId) async { final list = await (select(clubs)..where((c) => c.supabaseId.equals(supabaseId))).get(); return list.isEmpty ? null : list.first; }
  Future<void> upsertClub(ClubsCompanion club) async { Club? existing = await getClubBySupabaseId(club.supabaseId.value!); if (existing == null && club.supabaseId.value != null) { existing = await getClubByAttributes(club.type.value, club.brand.value, club.model.value, club.userId.value); } if (existing != null) { await (update(clubs)..where((c) => c.id.equals(existing!.id))).write(club); } else { await into(clubs).insert(club); } }
  Future<Club?> getClubByAttributes(String type, String? brand, String? model, String userId) async { final list = await (select(clubs)..where((c) => c.userId.equals(userId) & c.supabaseId.isNull() & c.type.equals(type) & (brand != null ? c.brand.equals(brand) : c.brand.isNull()) & (model != null ? c.model.equals(model) : c.model.isNull()) )).get(); return list.isEmpty ? null : list.first; }
  Future<List<Round>> getAllRounds(String userId) => (select(rounds)..where((r) => r.userId.equals(userId))..orderBy([(r) => OrderingTerm.desc(r.playedAt)])).get();
  Stream<List<Round>> watchAllRounds(String userId, {bool onlyForAnalytics = false}) {
    final query = select(rounds)..where((r) => r.userId.equals(userId));
    if (onlyForAnalytics) {
      query.where((r) => r.useForAnalytics.equals(true));
    }
    query.orderBy([(r) => OrderingTerm.desc(r.playedAt)]);
    return query.watch();
  }
  Future<Round> getRound(int id) => (select(rounds)..where((r) => r.id.equals(id))).getSingle();
  Future<Round?> getRoundBySupabaseId(String supabaseId) async { final list = await (select(rounds)..where((r) => r.supabaseId.equals(supabaseId))).get(); return list.isEmpty ? null : list.first; }
  Future<int> insertRound(RoundsCompanion round) => into(rounds).insert(round);
  Future<bool> updateRound(Round round) => update(rounds).replace(round);
  Future<int> deleteRound(int id) => (delete(rounds)..where((r) => r.id.equals(id))).go();
  Future<List<Round>> getRecentRounds(String userId, {int limit = 5}) => (select(rounds)..where((r) => r.userId.equals(userId))..orderBy([(r) => OrderingTerm.desc(r.playedAt)])..limit(limit)).get();
  Stream<List<Round>> watchRecentRounds(String userId, {int limit = 5, bool onlyForAnalytics = false}) {
    final query = select(rounds)..where((r) => r.userId.equals(userId));
    if (onlyForAnalytics) {
      query.where((r) => r.useForAnalytics.equals(true));
    }
    query..orderBy([(r) => OrderingTerm.desc(r.playedAt)])..limit(limit);
    return query.watch();
  }

  Stream<int> watchTotalRoundsCount(String userId, {bool onlyForAnalytics = false}) {
    final count = rounds.id.count();
    final query = selectOnly(rounds)
      ..addColumns([count])
      ..where(rounds.userId.equals(userId));
    if (onlyForAnalytics) {
      query.where(rounds.useForAnalytics.equals(true));
    }
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<int> getTotalRoundsCount(String userId) {
    final count = rounds.id.count();
    final query = selectOnly(rounds)
      ..addColumns([count])
      ..where(rounds.userId.equals(userId));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Stream<double?> watchAverageScore(String userId, {bool onlyForAnalytics = false}) {
    final avg = rounds.totalScore.avg();
    final query = selectOnly(rounds)
      ..addColumns([avg])
      ..where(rounds.userId.equals(userId));
    if (onlyForAnalytics) {
      query.where(rounds.useForAnalytics.equals(true));
    }
    return query.map((row) => row.read(avg)).watchSingle();
  }

  Future<double?> getAverageScore(String userId) {
    final avg = rounds.totalScore.avg();
    final query = selectOnly(rounds)
      ..addColumns([avg])
      ..where(rounds.userId.equals(userId));
    return query.map((row) => row.read(avg)).getSingle();
  }

  Stream<int?> watchBestScore(String userId, {bool onlyForAnalytics = false}) {
    final min = rounds.totalScore.min();
    final query = selectOnly(rounds)
      ..addColumns([min])
      ..where(rounds.userId.equals(userId));
    if (onlyForAnalytics) {
      query.where(rounds.useForAnalytics.equals(true));
    }
    return query.map((row) => row.read(min)).watchSingle();
  }

  Future<int?> getBestScore(String userId) {
    final min = rounds.totalScore.min();
    final query = selectOnly(rounds)
      ..addColumns([min])
      ..where(rounds.userId.equals(userId));
    return query.map((row) => row.read(min)).getSingle();
  }
  Future<List<HoleScore>> getHoleScoresForRound(int roundId) => (select(holeScores)..where((h) => h.roundId.equals(roundId))..orderBy([(h) => OrderingTerm.asc(h.holeNumber)])).get();
  Future<void> insertHoleScores(List<HoleScoresCompanion> scores) async { await batch((b) { b.insertAll(holeScores, scores); }); }
  Future<void> deleteHoleScoresForRound(int roundId) => (delete(holeScores)..where((h) => h.roundId.equals(roundId))).go();
  Future<List<HoleScore>> getUserHoleScores(String userId) { final query = select(holeScores).join([ innerJoin(rounds, rounds.id.equalsExp(holeScores.roundId)), ])..where(rounds.userId.equals(userId)); return query.map((row) => row.readTable(holeScores)).get(); }
  Future<List<Friend>> getFriends(String userId) => (select(friends)..where((f) => f.userId.equals(userId))).get();
  Stream<List<Friend>> watchFriends(String userId) => (select(friends)..where((f) => f.userId.equals(userId))).watch();
  Future<List<Round>> getCourseRounds(int courseId) => (select(rounds)..where((r) => r.courseId.equals(courseId))..orderBy([(u) => OrderingTerm.asc(u.totalScore)])).get();

  Future<UserProfile?> getProfile(String uid) async { final list = await (select(userProfiles)..where((u) => u.uid.equals(uid))).get(); return list.isEmpty ? null : list.first; }
  Stream<UserProfile?> watchProfile(String uid) => (select(userProfiles)..where((u) => u.uid.equals(uid))).watch().map((list) => list.isEmpty ? null : list.first);
  Stream<List<Provider>> watchAllProviders() => select(providers).watch();
  Stream<Provider?> watchProvider(String uid) => (select(providers)..where((p) => p.userId.equals(uid))).watch().map((list) => list.isEmpty ? null : list.first);
  Future<int> insertProfile(UserProfilesCompanion profile) => into(userProfiles).insert(profile);
  Future<void> updateProfile(String uid, UserProfilesCompanion profile) => (update(userProfiles)..where((u) => u.uid.equals(uid))).write(profile);
  Future<void> upsertProfile(UserProfilesCompanion profile) => into(userProfiles).insert(profile, onConflict: DoUpdate((old) => profile, target: [userProfiles.uid], ), );
  Future<Provider?> getProvider(String userId) async { final list = await (select(providers)..where((p) => p.userId.equals(userId))).get(); return list.isEmpty ? null : list.first; }
  Future<void> upsertProvider(ProvidersCompanion provider) => into(providers).insert(provider, onConflict: DoUpdate((old) => provider, target: [providers.userId], ), );
  Future<void> updateProviderRating(String providerId) async { final allReviews = await (select(reviews)..where((r) => r.providerId.equals(providerId))).get(); final count = allReviews.length; final avg = count == 0 ? 0.0 : allReviews.map((r) => r.rating).reduce((a, b) => a + b) / count; await (update(providers)..where((p) => p.userId.equals(providerId))).write(ProvidersCompanion(rating: Value(avg), totalReviews: Value(count), )); }
  Future<void> incrementProviderViews(String providerId) async { final p = await (select(providers)..where((p) => p.userId.equals(providerId))).getSingleOrNull(); if (p != null) { await (update(providers)..where((p) => p.userId.equals(providerId))).write(ProvidersCompanion(views: Value(p.views + 1), )); } }
  Future<PracticeSession?> getPracticeSessionBySupabaseId(String supabaseId) async { final list = await (select(practiceSessions)..where((s) => s.supabaseId.equals(supabaseId))).get(); return list.isEmpty ? null : list.first; }
  Future<void> upsertPracticeSession(PracticeSessionsCompanion session) async { final existing = await getPracticeSessionBySupabaseId(session.supabaseId.value!); if (existing != null) { await (update(practiceSessions)..where((s) => s.id.equals(existing.id))).write(session); } else { await into(practiceSessions).insert(session); } }
  Future<PracticeShot?> getPracticeShotBySupabaseId(String supabaseId) async { final list = await (select(practiceShots)..where((s) => s.supabaseId.equals(supabaseId))).get(); return list.isEmpty ? null : list.first; }
  Future<void> upsertPracticeShot(PracticeShotsCompanion shot) async { final existing = await getPracticeShotBySupabaseId(shot.supabaseId.value!); if (existing != null) { await (update(practiceShots)..where((s) => s.id.equals(existing.id))).write(shot); } else { await into(practiceShots).insert(shot); } }
  Future<Drill?> getDrillBySupabaseId(String supabaseId) async { final list = await (select(drills)..where((d) => d.supabaseId.equals(supabaseId))).get(); return list.isEmpty ? null : list.first; }
  Future<void> upsertDrill(DrillsCompanion drill) async { final existing = await getDrillBySupabaseId(drill.supabaseId.value!); if (existing != null) { await (update(drills)..where((d) => d.id.equals(existing.id))).write(drill); } else { await into(drills).insert(drill); } }

  // ─── Uber-model Queries ───

  Future<int> insertBooking(BookingsCompanion booking) => into(bookings).insert(booking);
  Future<void> upsertBooking(BookingsCompanion booking) => into(bookings).insert(booking, onConflict: DoUpdate((old) => booking, target: [bookings.serverId], ), );
  Stream<List<Booking>> watchPlayerBookings(String playerId) => (select(bookings)..where((b) => b.playerId.equals(playerId))..orderBy([(b) => OrderingTerm.desc(b.createdAt)])).watch();
  Stream<List<Booking>> watchProviderBookings(String providerId) => (select(bookings)..where((b) => b.providerId.equals(providerId))..orderBy([(b) => OrderingTerm.desc(b.createdAt)])).watch();
  Future<Booking?> getBookingById(int id) => (select(bookings)..where((b) => b.id.equals(id))).getSingleOrNull();
  Future<void> updateBookingStatus(int id, String status) => (update(bookings)..where((b) => b.id.equals(id))).write(BookingsCompanion(status: Value(status)));

  Future<int> insertMessage(MessagesCompanion message) => into(messages).insert(message);
  Future<void> upsertMessage(MessagesCompanion message) => into(messages).insert(message, onConflict: DoUpdate((old) => message, target: [messages.serverId]));
  Stream<List<Message>> watchConversation(String uid1, String uid2) => (select(messages)..where((m) => (m.senderId.equals(uid1) & m.receiverId.equals(uid2)) | (m.senderId.equals(uid2) & m.receiverId.equals(uid1)))..orderBy([(m) => OrderingTerm.asc(m.createdAt)])).watch();

  Future<int> insertInquiry(InquiriesCompanion inquiry) => into(inquiries).insert(inquiry);

  Future<void> syncPrimaryDrills() async {
    await transaction(() async {
      // 1. Clock Face Drill
      final d1Id = await _upsertDrillLocal('Clock Face Drill', 'Improve direction control by hitting to specific "clock" positions.', 'Intermediate', 20);
      await _upsertDrillSteps(d1Id, [
        'Hit 5 balls to 12 o\'clock position',
        'Hit 5 balls to 3 o\'clock position',
        'Hit 5 balls to 6 o\'clock position',
        'Hit 5 balls to 9 o\'clock position',
      ]);

      // 2. Lag Putting 10-20-30
      final d2Id = await _upsertDrillLocal('Lag Putting 10-20-30', 'Master distance control on the greens.', 'Beginner', 15);
      await _upsertDrillSteps(d2Id, [
        'Place markers at 10ft, 20ft, and 30ft',
        'Hit 3 balls to each distance',
        'Focus on getting every ball within a 3ft circle',
      ]);

      // 3. Gate Drill (Alignment)
      final d3Id = await _upsertDrillLocal('Alignment Gate Drill', 'Ensure your ball starts on the correct line.', 'Advanced', 25);
      await _upsertDrillSteps(d3Id, [
        'Place two alignment sticks 1 foot in front of ball',
        'Create a "gate" just wider than your ball',
        'Hit 10 balls through the gate without touching sticks',
      ]);

      // 4. Par 18 Chipping
      final d4Id = await _upsertDrillLocal('Par 18 Chipping', 'Test your short game pressure.', 'Intermediate', 30);
      await _upsertDrillSteps(d4Id, [
        'Pick 9 different chipping spots around the green',
        'Chip and putt out for every spot (Par 2 per spot)',
        'Try to score 18 or better total',
      ]);

      // 5. Bunker Blast
      final d5Id = await _upsertDrillLocal('Bunker Blast', 'Build confidence in the sand.', 'Intermediate', 20);
      await _upsertDrillSteps(d5Id, [
        'Draw a line 2 inches behind the ball in sand',
        'Hit the line, not the ball',
        'Complete 10 successful sand explosions',
      ]);
    });
  }

  Future<int> _upsertDrillLocal(String name, String desc, String diff, int dur) async {
    final existing = await (select(drills)..where((d) => d.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    return await into(drills).insert(DrillsCompanion.insert(
      name: name,
      description: desc,
      difficulty: diff,
      durationMinutes: dur,
      category: const Value('General'),
    ));
  }

  Future<void> _upsertDrillSteps(int drillId, List<String> instructions) async {
    final existing = await (select(drillSteps)..where((s) => s.drillId.equals(drillId))).get();
    if (existing.isNotEmpty) return;
    await batch((b) {
      for (int i = 0; i < instructions.length; i++) {
        b.insert(drillSteps, DrillStepsCompanion.insert(
          drillId: drillId,
          stepOrder: i + 1,
          instruction: instructions[i],
          ballsRequired: 5,
        ));
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'score_caddie.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
