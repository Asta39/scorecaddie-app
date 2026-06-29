import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score_caddie/core/database/database.dart';
import 'package:score_caddie/core/services/friend_service.dart';
import 'package:score_caddie/core/cloud/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSyncService extends Mock implements SyncService {}
class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late AppDatabase db;
  late MockSyncService mockSync;
  late MockSupabaseClient mockSupabase;
  late FriendService friendService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockSync = MockSyncService();
    mockSupabase = MockSupabaseClient();
    
    friendService = FriendService(db, mockSync, 'current-user-uid', mockSupabase);
  });

  tearDown(() async {
    await db.close();
  });

  group('FriendService - sendFriendRequest', () {
    test('returns false if targetUid is same as current user', () async {
      final result = await friendService.sendFriendRequest('current-user-uid');
      expect(result, isFalse);
    });

    test('returns false if already friends locally', () async {
      // Insert a friend locally
      await db.into(db.friends).insert(FriendsCompanion.insert(
        userId: 'current-user-uid',
        friendId: 'target-friend-uid',
      ));

      final result = await friendService.sendFriendRequest('target-friend-uid');
      
      // Should return false because they are already friends locally
      expect(result, isFalse);
    });

    test('returns false if unauthenticated', () async {
      final unauthService = FriendService(db, mockSync, null, mockSupabase);
      final result = await unauthService.sendFriendRequest('target-uid');
      expect(result, isFalse);
    });
  });
}
