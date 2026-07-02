import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  final postsResponse = await supabase
      .from('club_posts')
      .select('id, title, content, post_type, image_url, created_at, profiles:User(name)')
      .filter('club_id', 'in', clubIds)
      .order('created_at', ascending: false);

  final compsResponse = await supabase
      .from('competitions')
      .select('id, name, description, created_at, poster_url, club_id, Course:club_id(name)')
      .filter('club_id', 'in', clubIds)
      .eq('is_template', false)
      .order('created_at', ascending: false);

  final posts = (postsResponse as List).map((post) => ClubPost.fromJson(post)).toList();

  final comps = (compsResponse as List).map((comp) {
    final clubName = comp['Course'] != null ? comp['Course']['name'] : 'Club Admin';
    return ClubPost(
      id: comp['id'],
      title: comp['name'] ?? 'Competition',
      content: comp['description'] ?? 'Join the upcoming competition!',
      postType: 'competition',
      imageUrl: comp['poster_url'],
      createdAt: DateTime.parse(comp['created_at']),
      authorName: clubName,
    );
  }).toList();

  final allPosts = [...posts, ...comps];
  allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return allPosts;
});

class ClubMember {
  final String id;
  final String playerId;
  final String name;
  final String status;
  final double? handicap;
  final String? avatarUrl;
  final String privacyLevel;

  ClubMember({
    required this.id,
    required this.playerId,
    required this.name,
    required this.status,
    this.handicap,
    this.avatarUrl,
    required this.privacyLevel,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'],
      playerId: json['player_id'],
      name: json['user_profiles']?['name'] ?? 'Unknown',
      status: json['status'],
      handicap: json['user_profiles']?['handicap']?.toDouble(),
      avatarUrl: json['user_profiles']?['avatar_url'],
      privacyLevel: json['user_profiles']?['privacyLevel'] ?? 'Private',
    );
  }
}

final clubMembersProvider = FutureProvider.autoDispose.family<List<ClubMember>, String>((ref, clubId) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('player_club_memberships')
      .select('id, player_id, status, user_profiles:User!player_club_memberships_player_id_fkey(name, handicap:handicapIndex, avatar_url:avatarUrl, privacyLevel)')
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
      .select('id, player_id, status, user_profiles:User!player_club_memberships_player_id_fkey(name, handicap:handicapIndex, avatar_url:avatarUrl, privacyLevel)')
      .filter('club_id', 'in', clubIds);

  return (response as List).map((m) => ClubMember.fromJson(m)).toList();
});

class UserClubMembership {
  final String id;
  final String clubId;
  final String status;
  final bool isHomeClub;
  final String clubName;
  final String? membershipNumber;
  final DateTime? renewalDate;

  UserClubMembership({
    required this.id,
    required this.clubId,
    required this.status,
    required this.isHomeClub,
    required this.clubName,
    this.membershipNumber,
    this.renewalDate,
  });
}

final userClubMembershipsProvider = FutureProvider.autoDispose<List<UserClubMembership>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  // Step 1: Fetch memberships (with new optional columns)
  List membershipResponse;
  try {
    membershipResponse = await supabase
        .from('player_club_memberships')
        .select('id, club_id, status, is_home_club, membership_number, renewal_date')
        .eq('player_id', userId);
  } catch (_) {
    // Fallback without new columns if migration hasn't run yet
    membershipResponse = await supabase
        .from('player_club_memberships')
        .select('id, club_id, status, is_home_club')
        .eq('player_id', userId);
  }

  if (membershipResponse.isEmpty) return [];

  // Step 2: Fetch club names separately (avoids nested join RLS issues)
  final clubIds = membershipResponse.map((m) => m['club_id'] as String).toList();
  final clubsResponse = await supabase
      .from('clubs')
      .select('id, name')
      .inFilter('id', clubIds);

  final clubsMap = {
    for (var c in (clubsResponse as List)) c['id']: c['name'] as String
  };

  return membershipResponse.map<UserClubMembership>((m) {
    final renewalStr = m['renewal_date'] as String?;
    return UserClubMembership(
      id: m['id'],
      clubId: m['club_id'],
      status: m['status'],
      isHomeClub: m['is_home_club'] ?? false,
      clubName: clubsMap[m['club_id']] ?? 'Unknown Club',
      membershipNumber: m['membership_number'] as String?,
      renewalDate: renewalStr != null ? DateTime.tryParse(renewalStr) : null,
    );
  }).toList();
});

final availableClubsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('clubs').select('id, name, location').eq('status', 'active').order('name');
  return List<Map<String, dynamic>>.from(response);
});

final activeClubIdProvider = StateProvider<String?>((ref) => null);

final activeClubProvider = Provider<UserClubMembership?>((ref) {
  final membershipsAsync = ref.watch(userClubMembershipsProvider);
  final activeId = ref.watch(activeClubIdProvider);
  
  if (membershipsAsync.valueOrNull == null || membershipsAsync.valueOrNull!.isEmpty) return null;
  final memberships = membershipsAsync.valueOrNull!;
  
  if (activeId != null) {
    try {
      return memberships.firstWhere((m) => m.clubId == activeId);
    } catch (_) {}
  }
  
  try {
    return memberships.firstWhere((m) => m.isHomeClub);
  } catch (_) {
    return memberships.first;
  }
});

final activeClubFeedProvider = FutureProvider.autoDispose<List<ClubPost>>((ref) async {
  final activeClub = ref.watch(activeClubProvider);
  if (activeClub == null) return [];

  final supabase = Supabase.instance.client;
  
  final postsResponse = await supabase
      .from('club_posts')
      .select('id, title, content, post_type, image_url, created_at, profiles:User(name)')
      .eq('club_id', activeClub.clubId)
      .order('created_at', ascending: false);

  final compsResponse = await supabase
      .from('competitions')
      .select('id, name, description, created_at, poster_url, club_id, Course:club_id(name)')
      .eq('club_id', activeClub.clubId)
      .eq('is_template', false)
      .order('created_at', ascending: false);

  final posts = (postsResponse as List).map((post) => ClubPost.fromJson(post)).toList();

  final comps = (compsResponse as List).map((comp) {
    final clubName = comp['Course'] != null ? comp['Course']['name'] : 'Club Admin';
    return ClubPost(
      id: comp['id'],
      title: comp['name'] ?? 'Competition',
      content: comp['description'] ?? 'Join the upcoming competition!',
      postType: 'competition',
      imageUrl: comp['poster_url'],
      createdAt: DateTime.parse(comp['created_at']),
      authorName: clubName,
    );
  }).toList();

  final allPosts = [...posts, ...comps];
  allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return allPosts;
});

final activeClubMembersListProvider = FutureProvider.autoDispose<List<ClubMember>>((ref) async {
  final activeClub = ref.watch(activeClubProvider);
  if (activeClub == null) return [];

  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('player_club_memberships')
      .select('id, player_id, status, user_profiles:User!player_club_memberships_player_id_fkey(name, handicap:handicapIndex, avatar_url:avatarUrl)')
      .eq('club_id', activeClub.clubId);

  return (response as List).map((m) => ClubMember.fromJson(m)).toList();
});
