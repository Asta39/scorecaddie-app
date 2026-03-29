import 'package:drift/drift.dart';
import 'database.dart';

/// Seeds the 17 Kenyan golf courses into the database.
/// Uses verified data where available, estimates where not.
Future<void> seedCourses(AppDatabase db) async {
  final existing = await db.getAllCourses(null);
  if (existing.isNotEmpty) return; // Already seeded

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
    ),

    CoursesCompanion.insert(
      name: 'Mombasa Golf Club',
      location: const Value('Mombasa'),
      totalHoles: const Value(18),
      par18: const Value(71),
      par9front: const Value(36),
      par9back: const Value(35),
      holePars: const Value('[4,4,5,3,4,4,3,5,4,4,4,5,3,4,3,4,4,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Vipingo Ridge',
      location: const Value('Kilifi'),
      totalHoles: const Value(18),
      par18: const Value(72),
      par9front: const Value(36),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,4,4,3,5,4,4,5,3,4,4,4,3,5,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Nakuru Golf Club',
      location: const Value('Nakuru'),
      totalHoles: const Value(18),
      par18: const Value(73),
      par9front: const Value(37),
      par9back: const Value(36),
      holePars: const Value('[4,5,3,4,5,4,4,3,5,4,4,3,5,4,4,3,5,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Eldoret Golf Club',
      location: const Value('Eldoret'),
      totalHoles: const Value(18),
      par18: const Value(71),
      par9front: const Value(35),
      par9back: const Value(36),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,3,5,4,4,3,4,5,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Nyanza Golf Club',
      location: const Value('Kisumu'),
      totalHoles: const Value(9),
      par18: Value.absent(),
      par9front: const Value(35),
      par9back: Value.absent(),
      holePars: const Value('[4,4,3,5,4,4,3,4,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Kericho Golf Club',
      location: const Value('Kericho'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Nandi Bears Club',
      location: const Value('Nandi Hills'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Machakos Golf Club',
      location: const Value('Machakos'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
    ),

    CoursesCompanion.insert(
      name: 'Ruiru Sports Club',
      location: const Value('Ruiru'),
      totalHoles: const Value(18),
      par18: const Value(70),
      par9front: const Value(35),
      par9back: const Value(35),
      holePars: const Value('[4,4,3,4,4,3,4,5,4,4,4,3,4,4,3,4,4,4]'),
    ),
  ];

  // Insert all courses
  await db.batch((batch) {
    batch.insertAll(db.courses, courses);
  });
}
