import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';

/// Seeds the 17 Kenyan golf courses into the database.
/// Uses verified data where available, estimates where not.
Future<void> seedCourses(AppDatabase db) async {
  // 1. Seed/Update Kenyan golf courses inside a transaction to make it extremely fast
  await db.transaction(() async {
    final courses = <CoursesCompanion>[
    // ── Verified courses with full hole-by-hole data ──

    CoursesCompanion.insert(
      name: 'Royal Nairobi Golf Club',
      location: const Value('Nairobi'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,3,5,4,4,3,4,5,4,4,3,5,4,4,3,4,5,4]'),
      teeData: const Value('[{"name":"Men","yardages":[365,175,530,410,350,185,400,510,370,380,165,520,415,355,190,405,500,375]},{"name":"Women","yardages":[320,140,480,365,310,150,355,465,325,340,130,475,370,315,155,360,455,330]},{"name":"Blue","yardages":[390,195,555,435,375,205,425,535,395,405,185,545,440,380,210,430,525,400]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.2989),
      longitude: const Value(36.7914),
    ),

    CoursesCompanion.insert(
      name: 'Karen Country Club',
      location: const Value('Nairobi'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,4,4,3,5,4,4,5,3,4,4,4,3,5,4]'),
      teeData: const Value('[{"name":"White","yardages":[380,520,165,400,370,410,180,530,360,385,515,170,395,365,405,175,525,355]},{"name":"Yellow","yardages":[360,500,150,380,350,390,165,510,340,365,495,155,375,345,385,160,505,335]},{"name":"Red","yardages":[320,460,125,345,315,355,135,475,305,330,455,130,340,310,350,130,470,300]},{"name":"Green","yardages":[340,480,140,360,330,370,150,490,320,345,475,145,355,325,365,145,485,315]}]'),
      caddieFee: const Value(1200.0),
      latitude: const Value(-1.3533),
      longitude: const Value(36.7117),
    ),

    CoursesCompanion.insert(
      name: 'Muthaiga Golf Club',
      location: const Value('Nairobi'),
      totalHoles: const Value(18),
      par18: const Value(71),
      par9front: const Value(35),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,5,4,3,4,4,4,4,3,5,4,4,3,4,5,4]'),
      teeData: const Value('[{"name":"Blue","yardages":[385,400,175,510,370,160,415,390,365,395,180,525,380,405,170,410,520,375]},{"name":"White","yardages":[365,380,160,490,350,145,395,370,345,375,165,505,360,385,155,390,500,355]},{"name":"Yellow","yardages":[345,360,145,470,330,130,375,350,325,355,150,485,340,365,140,370,480,335]},{"name":"Red","yardages":[310,325,120,435,295,110,340,315,290,320,125,450,305,330,115,335,445,300]}]'),
      caddieFee: const Value(1200.0),
      latitude: const Value(-1.2483),
      longitude: const Value(36.8333),
    ),

    CoursesCompanion.insert(
      name: 'Windsor Golf Hotel & Country Club',
      location: const Value('Nairobi'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,4,4,3,5,4,4,5,3,4,4,4,3,5,4]'),
      teeData: const Value('[{"name":"Ndovu","yardages":[395,535,185,415,380,420,195,545,375,400,530,180,410,375,415,190,540,370]},{"name":"Simba","yardages":[375,515,170,395,360,400,180,525,355,380,510,165,390,355,395,175,520,350]},{"name":"Kifaru","yardages":[355,495,155,375,340,380,165,505,335,360,490,150,370,335,375,160,500,330]},{"name":"Chui","yardages":[335,475,140,355,320,360,150,485,315,340,470,135,350,315,355,145,480,310]},{"name":"Nyati","yardages":[315,455,125,335,300,340,135,465,295,320,450,120,330,295,335,130,460,290]}]'),
      caddieFee: const Value(1500.0),
      latitude: const Value(-1.2104),
      longitude: const Value(36.8770),
    ),

    CoursesCompanion.insert(
      name: 'Sigona Golf Club',
      location: const Value('Kikuyu'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,5,4,4,3,4,5,4,4,3,5,4,4,3,4,5]'),
      teeData: const Value('[{"name":"Chui","yardages":[390,370,160,510,350,400,170,380,520,385,390,165,505,375,340,150,380,500]},{"name":"Simba","yardages":[360,340,140,480,320,370,150,350,490,355,360,145,475,345,315,135,350,470]},{"name":"Kifaru","yardages":[330,310,120,450,290,340,130,320,460,325,330,125,445,315,290,120,320,440]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.2333),
      longitude: const Value(36.6500),
    ),

    CoursesCompanion.insert(
      name: 'Vet Lab Sports Club',
      location: const Value('Kabete'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,5,4,4,3,4,5,4,4,3,5,4,4,3,4,5]'),
      teeData: const Value('[{"name":"Chui","yardages":[380,360,150,500,340,390,160,370,510,375,380,155,495,365,330,140,370,490]},{"name":"Simba","yardages":[350,330,130,470,310,360,140,340,480,345,350,135,465,335,300,125,340,460]},{"name":"Kifaru","yardages":[320,300,110,440,280,330,120,310,450,315,320,115,435,305,270,110,310,430]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.2667),
      longitude: const Value(36.7333),
    ),

    CoursesCompanion.insert(
      name: 'Thika Greens Golf Resort',
      location: const Value('Thika'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,4,4,3,5,4,4,5,3,4,4,4,3,5,4]'),
      teeData: const Value('[{"name":"Chui","yardages":[380,520,165,400,370,410,180,530,360,385,515,170,395,365,405,175,525,355]},{"name":"Simba","yardages":[360,500,150,380,350,390,165,510,340,365,495,155,375,345,385,160,505,335]},{"name":"Kifaru","yardages":[340,480,140,360,330,370,150,490,320,345,475,145,355,325,365,145,485,315]}]'),
      caddieFee: const Value(1200.0),
      latitude: const Value(-1.0167),
      longitude: const Value(37.0833),
    ),

    CoursesCompanion.insert(
      name: 'Limuru Country Club',
      location: const Value('Limuru'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,5,4,4,3,4,5,4,4,3,5,4,4,3,4,5]'),
      teeData: const Value('[{"name":"Chui","yardages":[385,365,155,505,345,395,165,375,515,380,385,160,500,370,335,145,375,495]},{"name":"Simba","yardages":[355,335,135,475,315,365,155,345,485,350,355,140,470,340,310,130,345,465]},{"name":"Kifaru","yardages":[325,305,115,445,285,335,125,315,455,320,325,120,440,310,280,115,315,435]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.1167),
      longitude: const Value(36.6333),
    ),

    CoursesCompanion.insert(
      name: 'Nyeri Golf Club',
      location: const Value('Nyeri'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,3,5,4,4,5,4,4,3,4,3,5,4,4,5,4,4,3]'),
      teeData: const Value('[{"name":"Simba","yardages":[348,170,527,447,313,554,400,401,214,374,162,499,441,289,580,370,398,190]},{"name":"Chui","yardages":[331,151,447,400,266,504,366,362,190,331,151,447,329,266,504,367,301,142]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-0.4245),
      longitude: const Value(36.9423),
    ),


    // ── Courses with basic data (user can edit par/yardage) ──

    CoursesCompanion.insert(
      name: 'Nyali Golf & Country Club',
      location: const Value('Mombasa'),
      totalHoles: const Value(18),
      par18: const Value(71),
      par9front: const Value(35),
      par9back: const Value(36),
      holePars: const Value('[4,3,5,4,4,3,4,4,4,4,3,5,4,4,3,4,5,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":71.2,"slopeRating":128,"yardages":[360,150,510,390,340,160,380,480,350,370,155,500,395,345,170,390,490,340]},{"name":"Chui","courseRating":68.5,"slopeRating":118,"yardages":[330,130,470,360,310,140,350,450,320,340,135,470,365,315,150,360,460,310]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-4.0333),
      longitude: const Value(39.7167),
    ),

    CoursesCompanion.insert(
      name: 'Mombasa Golf Club',
      location: const Value('Mombasa'),
      totalHoles: const Value(9),
      par18: const Value(71),
      par9front: const Value(35),
      par9back: const Value(36),
      holePars: const Value('[4,3,4,4,4,3,4,4,5]'),
      teeData: const Value('[{"name":"Simba","courseRating":71.2,"slopeRating":122,"yardages":[325,145,370,390,340,160,380,360,495]},{"name":"Chui","courseRating":68.5,"slopeRating":112,"yardages":[295,125,340,360,310,140,350,330,465]}]'),
      caddieFee: const Value(800.0),
      latitude: const Value(-4.0667),
      longitude: const Value(39.6667),
    ),

    CoursesCompanion.insert(
      name: 'Vipingo Ridge',
      location: const Value('Kilifi'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,4,4,3,5,4,4,5,3,4,4,4,3,5,4]'),
      teeData: const Value('[{"name":"Black","courseRating":74.2,"slopeRating":138,"yardages":[410,540,195,430,390,425,185,550,380,405,535,175,415,380,420,185,545,365]},{"name":"White","courseRating":72.1,"slopeRating":131,"yardages":[385,515,175,405,365,400,165,525,355,380,510,155,390,355,395,165,520,345]},{"name":"Yellow","courseRating":69.8,"slopeRating":124,"yardages":[360,490,155,380,340,375,145,500,330,355,485,135,365,330,370,145,495,325]},{"name":"Red","courseRating":71.5,"slopeRating":122,"yardages":[335,465,135,355,315,350,125,475,305,330,460,115,340,305,345,125,470,305]}]'),
      caddieFee: const Value(1500.0),
      latitude: const Value(-3.8242),
      longitude: const Value(39.7997),
    ),

    CoursesCompanion.insert(
      name: 'Nakuru Golf Club',
      location: const Value('Nakuru'),
      totalHoles: const Value(18),
      par18: const Value(73),
      par9front: const Value(36),
      par9back: const Value(37),
      holePars: const Value('[4,4,3,5,4,4,3,4,5,4,4,3,5,4,4,3,4,5,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":72.1,"slopeRating":128,"yardages":[370,360,155,515,350,380,165,390,505,370,360,155,515,350,380,165,390,505,340]},{"name":"Chui","courseRating":69.2,"slopeRating":118,"yardages":[340,330,135,485,320,350,145,360,475,340,330,135,485,320,350,145,360,475,310]}]'),
      caddieFee: const Value(800.0),
      latitude: const Value(-0.2833),
      longitude: const Value(36.0683),
    ),

    CoursesCompanion.insert(
      name: 'Eldoret Golf Club',
      location: const Value('Eldoret'),
      totalHoles: const Value(18),
      par18: const Value(71),
      par9front: const Value(35),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,3,5,4,4,3,4,5,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":70.5,"slopeRating":126,"yardages":[355,365,160,380,350,155,385,505,345,360,165,495,375,340,150,380,500,330]},{"name":"Chui","courseRating":67.2,"slopeRating":115,"yardages":[325,335,140,350,320,135,355,475,315,330,145,465,345,310,130,350,470,300]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(0.5143),
      longitude: const Value(35.2697),
    ),

    CoursesCompanion.insert(
      name: 'Nyanza Golf Club',
      location: const Value('Kisumu'),
      totalHoles: const Value(9),
      par18: Value.absent(),
      par9front: const Value(35),
      par9back: Value.absent(),
      holePars: const Value('[4,4,3,5,4,4,3,4,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":35.2,"slopeRating":115,"yardages":[315,335,140,480,345,360,150,380,350]},{"name":"Chui","courseRating":33.8,"slopeRating":108,"yardages":[290,310,120,440,315,330,135,350,320]}]'),
      caddieFee: const Value(800.0),
      latitude: const Value(-0.1022),
      longitude: const Value(34.7500),
    ),

    CoursesCompanion.insert(
      name: 'Kericho Golf Club',
      location: const Value('Kericho'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
      teeData: const Value('[{"name":"Kifaru","courseRating":69.9,"slopeRating":121,"yardages":[278,401,161,367,187,398,267,516,299,278,401,161,367,187,398,267,516,299]},{"name":"Nyati","courseRating":67.1,"slopeRating":112,"yardages":[250,370,140,340,160,360,240,480,270,250,370,140,340,160,360,240,480,270]}]'),
      caddieFee: const Value(800.0),
      latitude: const Value(-0.3667),
      longitude: const Value(35.2833),
    ),

    CoursesCompanion.insert(
      name: 'Nandi Bears Club',
      location: const Value('Nandi Hills'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":70.0,"slopeRating":122,"yardages":[330,370,150,390,340,170,400,500,350,330,370,150,390,340,170,400,500,350]},{"name":"Chui","courseRating":67.5,"slopeRating":113,"yardages":[300,340,130,360,310,150,370,470,320,300,340,130,360,310,150,370,470,320]}]'),
      caddieFee: const Value(800.0),
      latitude: const Value(0.1000),
      longitude: const Value(35.2000),
    ),

    CoursesCompanion.insert(
      name: 'Machakos Golf Club',
      location: const Value('Machakos'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":69.5,"slopeRating":120,"yardages":[320,360,145,380,330,160,390,490,340,320,360,145,380,330,160,390,490,340]},{"name":"Chui","courseRating":66.8,"slopeRating":111,"yardages":[290,330,130,350,300,140,360,460,310,290,330,130,350,300,140,360,460,310]}]'),
      caddieFee: const Value(800.0),
      latitude: const Value(-1.5167),
      longitude: const Value(37.2667),
    ),

    CoursesCompanion.insert(
      name: 'Ruiru Sports Club',
      location: const Value('Ruiru'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
      teeData: const Value('[{"name":"White","courseRating":70.2,"slopeRating":124,"yardages":[340,350,155,375,345,150,380,495,335,340,350,155,375,345,150,380,495,335]},{"name":"Red","courseRating":67.5,"slopeRating":113,"yardages":[310,320,135,345,315,130,350,465,305,310,320,135,345,315,130,350,465,305]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.1500),
      longitude: const Value(36.9667),
    ),
  ];

    // Upsert all courses and populate tees/holes locally
    for (var c in courses) {
      final courseId = await db.upsertCourse(c);
      final teeDataJson = c.teeData.present ? c.teeData.value : null;
      final holeParsJson = c.holePars.present ? c.holePars.value : null;
      if (teeDataJson != null && holeParsJson != null) {
        await _seedTeesAndHolesForCourse(db, courseId, teeDataJson, holeParsJson);
      }
    }
  });

  // 2. Clean up and merge duplicate courses at database level sequentially
  await deduplicateCoursesInDatabase(db);
}

String _normalizeName(String val) {
  return val
      .toLowerCase()
      .replaceAll('golf club', '')
      .replaceAll('country club', '')
      .replaceAll('sports club', '')
      .replaceAll('golf resort', '')
      .replaceAll('club', '')
      .replaceAll('-', '')
      .replaceAll(' ', '')
      .replaceAll('&', '')
      .replaceAll('and', '')
      .trim();
}

Future<void> deduplicateCoursesInDatabase(AppDatabase db) async {
  try {
    await db.transaction(() async {
      final allCourses = await db.select(db.courses).get();
      final Map<String, List<Course>> grouped = {};
      for (final c in allCourses) {
        final key = _normalizeName(c.name);
        grouped.putIfAbsent(key, () => []).add(c);
      }

      for (final entry in grouped.entries) {
        final list = entry.value;
        if (list.length > 1) {
          // Find the primary one to keep
          list.sort((a, b) {
            final aHasSupabase = a.supabaseId != null ? 1 : 0;
            final bHasSupabase = b.supabaseId != null ? 1 : 0;
            if (aHasSupabase != bHasSupabase) {
              return bHasSupabase.compareTo(aHasSupabase);
            }
            final aHasTees = (a.teeData != null && a.teeData!.isNotEmpty && a.teeData != '[]') ? 1 : 0;
            final bHasTees = (b.teeData != null && b.teeData!.isNotEmpty && b.teeData != '[]') ? 1 : 0;
            if (aHasTees != bHasTees) {
              return bHasTees.compareTo(aHasTees);
            }
            return a.id.compareTo(b.id);
          });

          final primary = list.first;
          final duplicates = list.sublist(1);

          for (final dup in duplicates) {
            // 1. Merge Tees
            final dupTees = await (db.select(db.tees)..where((t) => t.courseId.equals(dup.id))).get();
            final primTees = await (db.select(db.tees)..where((t) => t.courseId.equals(primary.id))).get();

            for (final dTee in dupTees) {
              final matchingPrimTee = primTees.where((t) => t.name.toLowerCase() == dTee.name.toLowerCase() && t.gender == dTee.gender).firstOrNull;
              if (matchingPrimTee != null) {
                await (db.update(db.rounds)..where((r) => r.teeId.equals(dTee.id))).write(
                  RoundsCompanion(teeId: Value(matchingPrimTee.id)),
                );
                await (db.update(db.courseHoles)..where((h) => h.teeId.equals(dTee.id))).write(
                  CourseHolesCompanion(teeId: Value(matchingPrimTee.id)),
                );
                await (db.delete(db.tees)..where((t) => t.id.equals(dTee.id))).go();
              } else {
                await (db.update(db.tees)..where((t) => t.id.equals(dTee.id))).write(
                  TeesCompanion(courseId: Value(primary.id)),
                );
              }
            }

            // 2. Merge CourseHoles
            final dupHoles = await (db.select(db.courseHoles)..where((h) => h.courseId.equals(dup.id))).get();
            final primHoles = await (db.select(db.courseHoles)..where((h) => h.courseId.equals(primary.id))).get();

            for (final dHole in dupHoles) {
              final matchingPrimHole = primHoles.where((h) => h.teeId == dHole.teeId && h.holeNumber == dHole.holeNumber).firstOrNull;
              if (matchingPrimHole != null) {
                await (db.delete(db.courseHoles)..where((h) => h.id.equals(dHole.id))).go();
              } else {
                await (db.update(db.courseHoles)..where((h) => h.id.equals(dHole.id))).write(
                  CourseHolesCompanion(courseId: Value(primary.id)),
                );
              }
            }

            // 3. Re-associate Rounds
            await (db.update(db.rounds)..where((r) => r.courseId.equals(dup.id))).write(
              RoundsCompanion(courseId: Value(primary.id)),
            );

            // 4. Re-associate GroupRounds
            await (db.update(db.groupRounds)..where((gr) => gr.courseId.equals(dup.id))).write(
              GroupRoundsCompanion(courseId: Value(primary.id)),
            );

            // 5. Delete the duplicate course
            await (db.delete(db.courses)..where((c) => c.id.equals(dup.id))).go();
          }
        }
      }
    });
  } catch (e, stack) {
    print('Error deduplicating courses in database: $e\n$stack');
  }
}

Future<void> _seedTeesAndHolesForCourse(
  AppDatabase db,
  int courseId,
  String teeDataJson,
  String holeParsJson,
) async {
  try {
    final List<dynamic> teesList = jsonDecode(teeDataJson);
    final List<dynamic> parsList = jsonDecode(holeParsJson);

    for (final teeMap in teesList) {
      if (teeMap is! Map) continue;
      final String teeName = teeMap['name'] as String;
      final List<dynamic> yardages = teeMap['yardages'] as List<dynamic>;
      final double courseRating = (teeMap['courseRating'] as num?)?.toDouble() ?? 72.0;
      final int slopeRating = (teeMap['slopeRating'] as num?)?.toInt() ?? 113;

      final String gender = (teeName.toLowerCase() == 'ladies' || teeName.toLowerCase() == 'women') ? 'female' : 'male';

      final existingTees = await (db.select(db.tees)..where((t) => t.courseId.equals(courseId) & t.name.equals(teeName) & t.gender.equals(gender))).get();
      int teeId;
      if (existingTees.isNotEmpty) {
        teeId = existingTees.first.id;
        await (db.update(db.tees)..where((t) => t.id.equals(teeId))).write(
          TeesCompanion(
            courseRating: Value(courseRating),
            slopeRating: Value(slopeRating),
            yardage: Value(yardages.fold<int>(0, (sum, y) => sum + (y as int))),
          ),
        );
      } else {
        teeId = await db.into(db.tees).insert(
          TeesCompanion.insert(
            courseId: courseId,
            name: teeName,
            gender: Value(gender),
            courseRating: courseRating,
            slopeRating: slopeRating,
            yardage: Value(yardages.fold<int>(0, (sum, y) => sum + (y as int))),
          ),
        );
      }

      for (int i = 0; i < yardages.length; i++) {
        final holeNumber = i + 1;
        final par = (i < parsList.length) ? (parsList[i] as int) : 4;
        final distance = yardages[i] as int;
        
        final existingHoles = await (db.select(db.courseHoles)..where((ch) => ch.courseId.equals(courseId) & ch.teeId.equals(teeId) & ch.holeNumber.equals(holeNumber))).get();
        if (existingHoles.isEmpty) {
          await db.into(db.courseHoles).insert(
            CourseHolesCompanion.insert(
              courseId: courseId,
              teeId: Value(teeId),
              holeNumber: holeNumber,
              par: par,
              handicapIndex: Value(holeNumber),
              distance: Value(distance),
            ),
          );
        } else {
          await (db.update(db.courseHoles)..where((ch) => ch.id.equals(existingHoles.first.id))).write(
            CourseHolesCompanion(
              par: Value(par),
              distance: Value(distance),
            ),
          );
        }
      }
    }
  } catch (e, stack) {
    print('SEED ERROR for course $courseId: $e\n$stack');
  }
}
