import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

final supabaseSocialServiceProvider = Provider<SupabaseSocialService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return SupabaseSocialService(user?.id);
});

class SupabaseSocialService {
  final String? _uid;
  final SupabaseClient _supabase = Supabase.instance.client;

  SupabaseSocialService(this._uid);

  // --- Friends ---

  Future<void> sendFriendRequest(String friendId) async {
    if (_uid == null) return;
    await _supabase.from('Friend').upsert({
      'userId': _uid,
      'friendId': friendId,
      'status': 'PENDING',
    }, onConflict: 'userId,friendId');
  }

  Future<void> acceptFriendRequest(String friendId) async {
    if (_uid == null) return;
    
    // Update the request sent to me
    await _supabase.from('Friend').update({
      'status': 'ACCEPTED',
    }).eq('userId', friendId).eq('friendId', _uid);

    // Also create the reciprocal relationship
    await _supabase.from('Friend').upsert({
      'userId': _uid,
      'friendId': friendId,
      'status': 'ACCEPTED',
    }, onConflict: 'userId,friendId');
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    if (_uid == null) return [];
    final data = await _supabase.from('Friend')
      .select('friendId, status, profiles:friendId(name, avatarUrl)')
      .eq('userId', _uid)
      .eq('status', 'ACCEPTED');
    return List<Map<String, dynamic>>.from(data);
  }

  // --- Leaderboards ---

  Future<List<Map<String, dynamic>>> getGlobalLeaderboard() async {
    // This could pull from a View or a complex query
    // For now, let's pull users with best handicaps
    final data = await _supabase.from('User')
      .select('id, name, avatarUrl, handicapIndex')
      .order('handicapIndex', ascending: true)
      .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getRoundLeaderboard(String groupRoundId) async {
    // Pull participants and their scores for a specific group round
    final data = await _supabase.from('GroupRoundParticipant')
      .select('userId, role, scores, profiles:userId(name, avatarUrl)')
      .eq('groupRoundId', groupRoundId);
    return List<Map<String, dynamic>>.from(data);
  }
}
