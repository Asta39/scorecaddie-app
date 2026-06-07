import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:score_caddie/core/database/database.dart';
import 'package:score_caddie/core/database/seed_courses.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Course seeding works and contains full data', () async {
    await seedCourses(db);

    final allCourses = await db.getAllCourses(null);
    expect(allCourses.length, greaterThanOrEqualTo(17), reason: 'Should have at least 17 seeded courses');

    // Verify Royal Nairobi (first one in seed)
    final royal = allCourses.firstWhere((c) => c.name == 'Royal Nairobi Golf Club');
    expect(royal.par18, 72);
    expect(royal.latitude, -1.2989);
    expect(royal.longitude, 36.7914);
    expect(royal.teeData, isNotNull);
    expect(royal.teeData, isNot('[]'));
  });

  test('Course seeding doesn\'t duplicate (if id or firestoreId handled)', () async {
    await seedCourses(db);
    final firstCount = (await db.getAllCourses(null)).length;
    
    await seedCourses(db);
    final secondCount = (await db.getAllCourses(null)).length;
    
    // If this fails, we know we have a duplication issue
    expect(secondCount, firstCount, reason: 'Seeding twice should not double the courses');
  });
}

// Extension to AppDatabase for testing if needed, but AppDatabase already takes a QueryExecutor
// Wait, I need to check how AppDatabase is defined. 
// It uses _openConnection() in the constructor. I should add a constructor for testing.
