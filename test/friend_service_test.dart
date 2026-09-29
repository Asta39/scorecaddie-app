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
    test('refuses your own account', () async {
      final result = await friendService.sendFriendRequest('current-user-uid');
      expect(result, FriendRequestResult.self);
    });

    test('says already friends when they are on this phone', () async {
      // Insert a friend locally
      await db.into(db.friends).insert(FriendsCompanion.insert(
        userId: 'current-user-uid',
        friendId: 'target-friend-uid',
      ));

      final result = await friendService.sendFriendRequest('target-friend-uid');
      
      expect(result, FriendRequestResult.alreadyFriends);
    });

    test('fails when signed out', () async {
      final unauthService = FriendService(db, mockSync, null, mockSupabase);
      final result = await unauthService.sendFriendRequest('target-uid');
      expect(result, FriendRequestResult.failed);
    });
  });

  group('FriendService.normalizeFriendCode', () {
    test('accepts the code as shown', () {
      expect(FriendService.normalizeFriendCode('SC-A3B9-X7K2'), 'SC-A3B9-X7K2');
    });
    test('accepts lower case, spaces and missing dashes', () {
      expect(FriendService.normalizeFriendCode(' sc a3b9 x7k2 '), 'SC-A3B9-X7K2');
      expect(FriendService.normalizeFriendCode('a3b9x7k2'), 'SC-A3B9-X7K2');
      expect(FriendService.normalizeFriendCode('scab12cd'), 'SC-SCAB-12CD');
    });
    test('rejects anything that is not a friend code', () {
      expect(FriendService.normalizeFriendCode('hello'), isNull);
      expect(FriendService.normalizeFriendCode('SC-A3B9-X7K'), isNull);
      expect(FriendService.normalizeFriendCode('3f2b1c9e-8d7a-4b6c-9e1f-2a3b4c5d6e7f'), isNull);
    });
  });
}
