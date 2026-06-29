import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:score_caddie/core/database/database.dart' as db;
import 'package:score_caddie/core/cloud/sync_service.dart';
import 'package:score_caddie/core/cloud/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockApiService extends Mock implements ApiService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockRef extends Mock implements Ref {}

void main() {
  late db.AppDatabase database;
  late MockApiService mockApi;
  late MockRef mockRef;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    mockApi = MockApiService();
    mockRef = MockRef();
    mockSupabase = MockSupabaseClient();
    
    // We don't mock the inner Supabase details here, just ensure the service 
    // initializes and handles early-exit conditions gracefully.
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncService - syncRound', () {
    test('returns early if _uid is null', () async {
      final syncService = SyncService(database, null, mockApi, mockRef);
      
      final round = db.Round(
        id: 1,
        courseId: 1,
        totalScore: 72,
        scoreVsPar: 0,
        coursePar: 72,
        holesPlayed: 18,
        courseName: 'Test',
        tee: 'Blue',
        source: 'live',
        isSynced: false,
        useForAnalytics: true,
        playedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '',
      );
      
      // Should not throw, and should exit early
      await syncService.syncRound(round, []);
      verifyZeroInteractions(mockApi);
    });

    test('skips if local course is not found in db', () async {
      final syncService = SyncService(database, 'test-uid', mockApi, mockRef);
      
      final round = db.Round(
        id: 1,
        courseId: 999, // Course doesn't exist in the memory DB
        totalScore: 72,
        scoreVsPar: 0,
        coursePar: 72,
        holesPlayed: 18,
        courseName: 'Test',
        tee: 'Blue',
        source: 'live',
        isSynced: false,
        useForAnalytics: true,
        playedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '',
      );

      // Should skip safely because courseId 999 isn't in DB
      await syncService.syncRound(round, []);
      verifyZeroInteractions(mockApi);
    });
  });
}
