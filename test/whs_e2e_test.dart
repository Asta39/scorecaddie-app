import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:score_caddie/core/database/database.dart';
import 'package:score_caddie/core/utils/whs_engine.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('End-to-End WHS Handicap Calculation with 20 dummy rounds', () async {
    final now = DateTime.now();
    final courseId = 1;
    
    // Create dummy course
    await db.into(db.courses).insert(CoursesCompanion.insert(
      id: Value(courseId),
      name: 'Test Course',
      par18: Value(72),
    ));

    // Insert 20 dummy rounds (mix of 18 and 9 holes)
    // To simulate realistic handicap progression, we'll insert differentials ranging from 10.0 to 29.0
    for (int i = 0; i < 20; i++) {
      final playedAt = now.subtract(Duration(days: 20 - i)); // Chronological order
      final scoreDiff = 10.0 + i; // 10.0, 11.0 ... 29.0
      
      await db.into(db.rounds).insert(RoundsCompanion.insert(
        id: Value(i + 1),
        courseId: courseId,
        playedAt: Value(playedAt),
        totalScore: 85 + i, // Arbitrary
        scoreVsPar: 13 + i,
        coursePar: 72,
        holesPlayed: Value(18),
        scoreDifferential: Value(scoreDiff), // Engine reads this directly or calculates it.
      ));
    }

    // Now, run the WHS calculation logic.
    // In a real app, this might be handled by HandicapProvider, but we can 
    // fetch the rounds from DB and pass them to WHSEngine.
    final rounds = await db.select(db.rounds).get();
    
    // Sort by date descending
    rounds.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    
    // The WHS engine takes a list of differentials
    final differentials = rounds.take(20).map((r) => r.scoreDifferential ?? 0.0).toList();
    
    // We inserted 10.0 to 29.0. Best 8 are 10, 11, 12, 13, 14, 15, 16, 17.
    // Average = 108 / 8 = 13.5
    // 13.5 * 0.96 = 12.96 -> rounded to 13.0
    
    final handicapIndex = WHSEngine.calculateHandicapIndex(differentials);
    
    expect(handicapIndex, 13.0);
  });
}
