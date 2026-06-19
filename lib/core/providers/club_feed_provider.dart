import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:score_caddie/providers/app_providers.dart';

class ClubPost {
  final String id;
  final String title;
  final String content;
  final String postType;
  final String? imageUrl;
  final DateTime createdAt;
  final String authorName;

  ClubPost({
    required this.id,
    required this.title,
    required this.content,
    required this.postType,
    this.imageUrl,
    required this.createdAt,
    required this.authorName,
  });

  factory ClubPost.fromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      postType: json['post_type'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      authorName: json['profiles']?['name'] ?? 'Club Admin',
    );
  }
}

final clubPostsProvider = FutureProvider.autoDispose.family<List<ClubPost>, String>((ref, clubId) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('club_posts')
      .select('id, title, content, post_type, image_url, created_at, profiles:User(name)')
      .eq('club_id', clubId)
      .order('created_at', ascending: false);

  return (response as List).map((post) => ClubPost.fromJson(post)).toList();
});

final aggregatedClubPostsProvider = FutureProvider.autoDispose<List<ClubPost>>((ref) async {
  final memberships = await ref.watch(userClubMembershipsProvider.future);
  if (memberships.isEmpty) return [];

  final clubIds = memberships.map((m) => m.clubId).toList();
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('club_posts')
      .select('id, title, content, post_type, image_url, created_at, profiles:User(name)')
      .filter('club_id', 'in', clubIds)
      .order('created_at', ascending: false);

  return (response as List).map((post) => ClubPost.fromJson(post)).toList();
});

class ClubMember {
  final String id;
  final String playerId;
  final String name;
  final String status;
  final double? handicap;
  final String? avatarUrl;

  ClubMember({
    required this.id,
    required this.playerId,
    required this.name,
    required this.status,
    this.handicap,
    this.avatarUrl,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'],
      playerId: json['player_id'],
      name: json['user_profiles']?['name'] ?? 'Unknown',
      status: json['status'],
      handicap: json['user_profiles']?['handicap']?.toDouble(),
      avatarUrl: json['user_profiles']?['avatar_url'],
    );
  }
}

final clubMembersProvider = FutureProvider.autoDispose.family<List<ClubMember>, String>((ref, clubId) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('player_club_memberships')
      .select('id, player_id, status, user_profiles:User(name, handicap:handicapIndex, avatar_url:avatarUrl)')
      .eq('club_id', clubId);

  return (response as List).map((m) => ClubMember.fromJson(m)).toList();
});

final aggregatedClubMembersProvider = FutureProvider.autoDispose<List<ClubMember>>((ref) async {
  final memberships = await ref.watch(userClubMembershipsProvider.future);
  if (memberships.isEmpty) return [];

  final clubIds = memberships.map((m) => m.clubId).toList();
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('player_club_memberships')
      .select('id, player_id, status, user_profiles:User(name, handicap:handicapIndex, avatar_url:avatarUrl)')
      .filter('club_id', 'in', clubIds);

  return (response as List).map((m) => ClubMember.fromJson(m)).toList();
});

class UserClubMembership {
  final String id;
  final String clubId;
  final String status;
  final bool isHomeClub;
  final String clubName;

  UserClubMembership({
    required this.id,
    required this.clubId,
    required this.status,
    required this.isHomeClub,
    required this.clubName,
  });

  factory UserClubMembership.fromJson(Map<String, dynamic> json) {
    return UserClubMembership(
      id: json['id'],
      clubId: json['club_id'],
      status: json['status'],
      isHomeClub: json['is_home_club'] ?? false,
      clubName: json['clubs']?['name'] ?? 'Unknown Club',
    );
  }
}

final userClubMembershipsProvider = FutureProvider.autoDispose<List<UserClubMembership>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final membershipResponse = await supabase
      .from('player_club_memberships')
      .select('id, club_id, status, is_home_club')
      .eq('player_id', userId);

  if ((membershipResponse as List).isEmpty) return [];

  final clubIds = membershipResponse.map((m) => m['club_id'] as String).toList();
  final clubsResponse = await supabase
      .from('clubs')
      .select('id, name')
      .filter('id', 'in', clubIds);

  final clubsMap = {
    for (var c in (clubsResponse as List)) c['id']: c['name']
  };

  return membershipResponse.map((m) {
    return UserClubMembership(
      id: m['id'],
      clubId: m['club_id'],
      status: m['status'],
      isHomeClub: m['is_home_club'] ?? false,
      clubName: clubsMap[m['club_id']] ?? 'Unknown Club',
    );
  }).toList();
});

final availableClubsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('clubs').select('id, name, location').eq('status', 'active').order('name');
  return List<Map<String, dynamic>>.from(response);
});
