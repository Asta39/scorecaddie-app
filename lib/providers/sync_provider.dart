import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'app_providers.dart';

class SyncController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  Timer? _timer;

  SyncController(this.ref) : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    // Watch auth state to start/stop timer
    ref.listen(authStateProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null) {
        debugPrint('SYNC: User authenticated, starting sync timer.');
        _startSyncTimer();
        // Initial immediate sync on login
        syncNow();
      } else {
        debugPrint('SYNC: No user, stopping sync timer.');
        _stopSyncTimer();
      }
    });

    // If already logged in on init
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      debugPrint('SYNC: Found existing user on init, starting sync.');
      _startSyncTimer();
      syncNow();
    }
  }

  void _startSyncTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => syncNow());
  }

  void _stopSyncTimer() {
    _timer?.cancel();
    _timer = null;
  }

  bool _isSyncing = false;

  Future<void> syncNow() async {
    if (_isSyncing) {
      debugPrint('SYNC: Already syncing, skipping this tick.');
      return;
    }
    _isSyncing = true;
    final syncService = ref.read(syncServiceProvider);
    state = const AsyncValue.loading();
    try {
      debugPrint('SYNC: Starting priority pull and push...');
      await syncService.syncAllPending();
      state = const AsyncValue.data(null);
      debugPrint('SYNC: Completed successfully.');
    } catch (e, st) {
      debugPrint('SYNC ERROR: $e');
      state = AsyncValue.error(e, st);
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final syncControllerProvider = StateNotifierProvider<SyncController, AsyncValue<void>>((ref) {
  return SyncController(ref);
});
