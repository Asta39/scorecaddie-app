import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/cloud/sync_service.dart';
import '../core/cloud/api_service.dart';
import '../core/cloud/supabase_service.dart';
import '../core/cloud/supabase_storage_service.dart';
import 'database_providers.dart';
import 'auth_providers.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(databaseProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final api = ref.watch(apiServiceProvider);
  return SyncService(database, user?.id, api, ref);
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref);
});

final supabaseStorageServiceProvider = Provider<SupabaseStorageService>((ref) {
  return SupabaseStorageService();
});
