import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../core/database/database.dart' as db;
import '../core/services/supabase_auth_service.dart';
import '../core/services/profile_service.dart';
import '../core/models/auth_user.dart';
import 'database_providers.dart';

final supabaseClientProvider = Provider<supabase.SupabaseClient>((ref) {
  return supabase.Supabase.instance.client;
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref);
});

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return authService.authStateChanges.map((state) {
    final user = state.session?.user;
    
    if (user != null) {
      OneSignal.login(user.id);
    } else {
      OneSignal.logout();
    }

    return user != null ? AuthUser.fromSupabase(user) : null;
  });
});

final userProfileProvider = StreamProvider<db.UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    return Stream.value(null);
  }
  return ref.watch(databaseProvider).watchProfile(user.id);
});

final specificUserProfileProvider = StreamProvider.family<db.UserProfile?, String>((ref, userId) {
  return ref.watch(supabaseClientProvider)
      .from('User')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((list) {
        if (list.isEmpty) return null;
        final data = list.first;
        return db.UserProfile(
          id: 0,
          uid: data['id'],
          email: data['email'],
          name: data['name'] ?? 'Golfer',
          role: data['role'],
          themeMode: data['themeMode'] ?? 'System',
          avatarUrl: data['avatarUrl'],
          privacyLevel: data['privacyLevel'] ?? 'Private',
          homeCourseId: data['homeCourseId'],
          homeCourseName: data['homeCourseName'],
          skillLevel: data['skillLevel'],
          preferredTees: data['preferredTees'],
          playStyle: data['playStyle'],
          units: data['units'] ?? 'Yards',
          badgesJson: data['badgesJson'] ?? '[]',
          profileComplete: data['profileComplete'] ?? false,
          pfpVerified: data['pfpVerified'] ?? false,
          providerStatus: data['providerStatus'] ?? 'OFFLINE',
          currentBookingId: data['currentBookingId'],
          passportPhotoUrl: data['passportPhotoUrl'],
          handicapOrigin: data['handicapOrigin'] ?? 'new_golfer',
          importedIndex: data['importedIndex'] != null ? (data['importedIndex'] is int ? (data['importedIndex'] as int).toDouble() : data['importedIndex']) : null,
          isProvisional: data['isProvisional'] ?? true,
          provisionalRounds: data['provisionalRounds'] ?? 0,
          anchorIndex: data['anchorIndex'] != null ? (data['anchorIndex'] is int ? (data['anchorIndex'] as int).toDouble() : data['anchorIndex']) : null,
          handicap: data['handicapIndex'] != null ? (data['handicapIndex'] is int ? (data['handicapIndex'] as int).toDouble() : data['handicapIndex']) : null,
          createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) ?? DateTime.now() : DateTime.now(),
          updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt']) ?? DateTime.now() : DateTime.now(),
        );
      });
});
