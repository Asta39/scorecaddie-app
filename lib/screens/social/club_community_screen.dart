import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/club_feed_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/top_notification.dart';

class ClubCommunityScreen extends ConsumerStatefulWidget {
  const ClubCommunityScreen({super.key});

  @override
  ConsumerState<ClubCommunityScreen> createState() => _ClubCommunityScreenState();
}

class _ClubCommunityScreenState extends ConsumerState<ClubCommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ('Overview', LucideIcons.layoutGrid),
    ('Feed', LucideIcons.radio),
    ('Events', LucideIcons.trophy),
    ('Members', LucideIcons.users),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Club Community',
          style: TextStyle(
            color: AppColors.grey900,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: AppColors.grey900),
            onPressed: () {
              // TODO: Search for new clubs to join
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.emerald700,
          unselectedLabelColor: AppColors.grey400,
          indicatorColor: AppColors.emerald700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _FeedTab(),
          _EventsTab(),
          _MembersTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(userClubMembershipsProvider);

    return membershipsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (memberships) {
        final homeClub = memberships.where((m) => m.isHomeClub).firstOrNull;
        final guestClubs = memberships.where((m) => !m.isHomeClub).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Home Club',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 16),
              if (homeClub != null)
                _buildHeroCard(context, homeClub.clubId, homeClub.clubName, homeClub.status == 'active')
              else
                _buildNoHomeClubCard(context, ref, memberships.map((m) => m.clubId).toSet()),
                
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Guest Memberships',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showJoinClubDialog(context, ref, memberships.map((m) => m.clubId).toSet()),
                    child: const Text('Discover', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  ...guestClubs.map((c) => _buildGuestClubCard(context, c.clubName, c.status, c.clubId)),
                  _buildAddClubCard(context, ref, memberships.map((m) => m.clubId).toSet()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(BuildContext context, String clubId, String clubName, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (isActive) context.push('/club-life/$clubId');
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [AppColors.golfLime, AppColors.golfLime.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.golfLime.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.grey900.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(isActive ? LucideIcons.checkCircle2 : LucideIcons.clock, color: AppColors.grey900, size: 14),
                      const SizedBox(width: 6),
                      Text(isActive ? 'Primary' : 'Pending', style: const TextStyle(color: AppColors.grey900, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.moreHorizontal, color: AppColors.grey900),
              ],
            ),
            const Spacer(),
            const Text(
              'Your Home Club',
              style: TextStyle(color: AppColors.grey700, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              clubName,
              style: const TextStyle(color: AppColors.grey900, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(LucideIcons.mapPin, color: AppColors.grey700, size: 14),
                SizedBox(width: 4),
                Text('Location', style: TextStyle(color: AppColors.grey700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHomeClubCard(BuildContext context, WidgetRef ref, Set<String> existingClubIds) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.home, size: 48, color: AppColors.grey300),
          const SizedBox(height: 16),
          const Text('No Home Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Join a club to get started.', style: TextStyle(color: AppColors.grey500)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showJoinClubDialog(context, ref, existingClubIds),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald700, foregroundColor: Colors.white),
            child: const Text('Find a Club'),
          ),
        ],
      ),
    );
  }

  void _showJoinClubDialog(BuildContext context, WidgetRef ref, Set<String> existingClubIds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final availableAsync = ref.watch(availableClubsProvider);
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Join a Club', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: availableAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error: $e')),
                        data: (clubs) {
                          final unjoinedClubs = clubs.where((c) => !existingClubIds.contains(c['id'])).toList();
                          if (unjoinedClubs.isEmpty) {
                            return const Center(child: Text('No more clubs available to join.'));
                          }
                          return ListView.separated(
                            itemCount: unjoinedClubs.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final club = unjoinedClubs[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(LucideIcons.home, color: AppColors.emerald700),
                                ),
                                title: Text(club['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(club['location'] ?? ''),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final supabase = Supabase.instance.client;
                                      final userId = supabase.auth.currentUser?.id;
                                      if (userId == null) return;
                                      
                                      await supabase.from('player_club_memberships').insert({
                                        'player_id': userId,
                                        'club_id': club['id'],
                                        'status': 'pending',
                                        'is_home_club': existingClubIds.isEmpty, // First club is home club
                                      });
                                      
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        TopNotification.showSuccess(
                                          context,
                                          "We've sent your request to join ${club['name'] ?? 'the club'}! The admin will verify it shortly.",
                                        );
                                        ref.invalidate(userClubMembershipsProvider);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        TopNotification.showError(
                                          context,
                                          "Couldn't send request: $e",
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.emerald50,
                                    foregroundColor: AppColors.emerald700,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Request'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuestClubCard(BuildContext context, String name, String status, String clubId) {
    final isActive = status == 'active';
    return GestureDetector(
      onTap: () {
        if (isActive) context.push('/club-life/$clubId');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.users, color: AppColors.grey700, size: 20),
                ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.emerald50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isActive ? AppColors.emerald700 : Colors.orange.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ],
          ),
          const Spacer(),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey900)),
          const SizedBox(height: 4),
          const Text('Guest Member', style: TextStyle(color: AppColors.grey500, fontSize: 12)),
        ],
      ),
    ),
  );
}

  Widget _buildAddClubCard(BuildContext context, WidgetRef ref, Set<String> existingClubIds) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emerald50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald200, style: BorderStyle.solid),
      ),
      child: InkWell(
        onTap: () => _showJoinClubDialog(context, ref, existingClubIds),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.plus, color: AppColors.emerald700, size: 32),
            SizedBox(height: 8),
            Text('Join Club', style: TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(aggregatedClubPostsProvider).when(
      data: (posts) {
        final feedPosts = posts.where((p) => p.postType != 'competition').toList();
        if (feedPosts.isEmpty) return const Center(child: Text('No recent posts from your clubs.'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: feedPosts.length,
          itemBuilder: (context, index) {
            final post = feedPosts[index];
            return _buildPostCard(
              type: post.postType,
              title: post.title,
              content: post.content,
              timeAgo: _formatDate(post.createdAt),
              author: post.authorName,
              imageUrl: post.imageUrl,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading feed: $e')),
    );
  }
}

class _EventsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(aggregatedClubPostsProvider).when(
      data: (posts) {
        final compPosts = posts.where((p) => p.postType == 'fixture' || p.postType == 'result' || p.postType == 'competition').toList();
        if (compPosts.isEmpty) return const Center(child: Text('No upcoming events from your clubs.'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: compPosts.length,
          itemBuilder: (context, index) {
            final post = compPosts[index];
            return _buildPostCard(
              type: post.postType,
              title: post.title,
              content: post.content,
              timeAgo: _formatDate(post.createdAt),
              author: post.authorName,
              imageUrl: post.imageUrl,
              actionText: post.postType == 'fixture' || post.postType == 'competition' ? 'Register Now' : null,
              onAction: post.postType == 'fixture' || post.postType == 'competition' 
                ? () => context.push('/competitions/${post.id}')
                : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading events: $e')),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(aggregatedClubMembersProvider).when(
      data: (members) {
        final activeMembers = members.where((m) => m.status == 'active').toList();
        if (activeMembers.isEmpty) return const Center(child: Text('No active members found.'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activeMembers.length,
          itemBuilder: (context, index) {
            final member = activeMembers[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.emerald50,
                backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                child: member.avatarUrl == null
                    ? Text(member.name[0].toUpperCase(), style: const TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold))
                    : null,
              ),
              title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(member.handicap != null ? 'Handicap: ${member.handicap}' : 'No handicap'),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading members: $e')),
    );
  }
}

String _formatDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

Widget _buildPostCard({
  required String type,
  required String title,
  required String content,
  required String timeAgo,
  required String author,
  String? actionText,
  String? imageUrl,
  VoidCallback? onAction,
}) {
  IconData icon;
  Color iconColor;
  Color bgColor;

  switch (type) {
    case 'announcement':
    case 'notice':
      icon = LucideIcons.megaphone;
      iconColor = Colors.orange;
      bgColor = Colors.orange.withOpacity(0.1);
      break;
    case 'competition':
    case 'fixture':
      icon = LucideIcons.trophy;
      iconColor = AppColors.emerald700;
      bgColor = AppColors.emerald50;
      break;
    case 'result':
      icon = LucideIcons.award;
      iconColor = Colors.purple;
      bgColor = Colors.purple.withOpacity(0.1);
      break;
    default:
      icon = LucideIcons.bell;
      iconColor = Colors.blue;
      bgColor = Colors.blue.withOpacity(0.1);
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.grey100),
      boxShadow: [
        BoxShadow(
          color: AppColors.grey200.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.grey900)),
                        Text('$author • $timeAgo', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.grey400)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(content, style: const TextStyle(fontSize: 14, color: AppColors.grey600, height: 1.5, fontWeight: FontWeight.w500)),
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald50,
                      foregroundColor: AppColors.emerald700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
