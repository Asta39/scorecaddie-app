import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart' as db;
import '../core/services/friend_service.dart';
import '../core/services/leaderboard_service.dart';
import 'database_providers.dart';
import 'auth_providers.dart';
import 'sync_providers.dart';

final friendServiceProvider = Provider<FriendService>((ref) {
  final database = ref.watch(databaseProvider);
  final sync = ref.watch(syncServiceProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final supabaseClient = ref.watch(supabaseClientProvider);

  final service = FriendService(database, sync, user?.id, supabaseClient);

  // Auto-generate a Friend Code in the background the moment a user logs in.
  // This is intentionally fire-and-forget — no await, non-fatal if it fails.
  if (user != null) {
    service.ensureFriendCode();
  }

  return service;
});


final friendsProvider = StreamProvider<List<db.Friend>>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return (database.select(database.friends)..where((f) => f.userId.equals(user.id))).watch();
});

final friendRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamIncomingRequests();
});

final acceptedSentRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(friendServiceProvider);
  return service.streamAcceptedSentRequests();
});

final leaderboardStreamProvider = StreamProvider.family<List<LeaderboardEntry>, LeaderboardParams>((ref, params) {
  final service = ref.watch(leaderboardServiceProvider);
  final auth = ref.watch(authStateProvider);
  final user = auth.valueOrNull;

  return service.streamLeaderboard(
    tab: params.tab,
    period: params.period,
    scoring: params.scoring,
    currentUserId: user?.id,
    specificCourseId: params.courseId,
  );
});
