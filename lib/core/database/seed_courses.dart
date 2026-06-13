import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';

/// Seeds the 17 Kenyan golf courses into the database.
/// Uses verified data where available, estimates where not.
Future<void> seedCourses(AppDatabase db) async {
  // Seed/Update Kenyan golf courses

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
      holePars: const Value('[4,4,5,3,4,4,3,5,4,4,4,5,3,4,4,3,5,4]'),
      teeData: const Value('[{"name":"White","yardages":[370,390,520,170,405,380,175,535,365,375,395,525,165,400,375,180,530,360]},{"name":"Yellow","yardages":[350,370,500,155,385,360,160,515,345,355,375,505,150,380,355,165,510,340]},{"name":"Ladies","yardages":[310,330,460,125,345,320,130,475,305,315,335,465,120,340,315,135,470,300]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.2185),
      longitude: const Value(36.6534),
    ),

    CoursesCompanion.insert(
      name: 'Vet Lab Sports Club',
      location: const Value('Nairobi'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,3,5,4,4,3,4,5,4,4,3,5,4,4,3,4,5,4]'),
      teeData: const Value('[{"name":"Blue","yardages":[380,170,525,405,375,180,410,530,365,385,175,520,400,370,185,415,535,360]},{"name":"White","yardages":[360,155,505,385,355,165,390,510,345,365,160,500,380,350,170,395,515,340]},{"name":"Red","yardages":[320,125,465,345,315,135,350,470,305,325,130,460,340,310,140,355,475,300]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.2589),
      longitude: const Value(36.7156),
    ),

    CoursesCompanion.insert(
      name: 'Thika Greens Golf Resort',
      location: const Value('Thika'),
      totalHoles: const Value(18),
      par18: const Value(73),
      par9front: const Value(37),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,5,4,3,4,5,4,4,3,5,4,4,3,5,4]'),
      teeData: const Value('[{"name":"Twiga","yardages":[400,540,190,420,535,385,175,415,545,395,410,180,530,405,390,185,540,370]},{"name":"Ndovu","yardages":[380,520,175,400,515,365,160,395,525,375,390,165,510,385,370,170,520,350]},{"name":"Kifaru","yardages":[360,500,160,380,495,345,145,375,505,355,370,150,490,365,350,155,500,330]},{"name":"Nyati","yardages":[330,470,135,350,465,315,125,345,475,325,340,130,460,335,320,135,470,300]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-0.8464),
      longitude: const Value(37.0736),
    ),

    CoursesCompanion.insert(
      name: 'Limuru Country Club',
      location: const Value('Limuru'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,5,4,4,3,5,4,4,4,3,5,4,4,3,5,4]'),
      teeData: const Value('[{"name":"Course 1","yardages":[370,385,165,520,400,375,170,530,360,380,390,160,515,395,370,175,525,355]},{"name":"Course 2","yardages":[350,365,150,500,380,355,155,510,340,360,370,145,495,375,350,160,505,335]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-1.0967),
      longitude: const Value(36.6433),
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
      totalHoles: const Value(18),
      par18: const Value(71),
      par9front: const Value(36),
      par9back: const Value(35),
      holePars: const Value('[4,4,5,3,4,4,3,5,4,4,4,5,3,4,3,4,4,4]'),
      teeData: const Value('[{"name":"Chui","courseRating":68.7,"slopeRating":122,"yardages":[285,290,120,300,425,350,165,455,390,285,290,120,300,425,350,165,455,390]},{"name":"Nyati","courseRating":66.6,"slopeRating":111,"yardages":[260,270,110,280,400,330,150,430,360,260,270,110,280,400,330,150,430,360]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-4.0733),
      longitude: const Value(39.6733),
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
      par9front: const Value(37),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,5,4,4,3,5,4,4,3,5,4,4,3,5,4]'),
      teeData: const Value('[{"name":"Simba","courseRating":71.6,"slopeRating":129,"yardages":[376,365,438,216,361,343,357,449,518,383,393,325,516,371,145,517,181,548]},{"name":"Chui","courseRating":67.8,"slopeRating":118,"yardages":[350,340,390,190,330,310,330,410,480,350,360,290,480,340,130,480,160,500]}]'),
      caddieFee: const Value(1000.0),
      latitude: const Value(-0.2450),
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
  } catch (_) {}
}

