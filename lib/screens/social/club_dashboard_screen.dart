import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:score_caddie/core/theme/app_theme.dart';
import 'package:score_caddie/core/providers/club_feed_provider.dart';

class ClubDashboardScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubDashboardScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends ConsumerState<ClubDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Club Life',
          style: TextStyle(
            color: AppColors.grey900,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.emerald700,
          unselectedLabelColor: AppColors.grey400,
          indicatorColor: AppColors.emerald700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(text: 'Home Feed'),
            Tab(text: 'Competitions'),
            Tab(text: 'Noticeboard'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeFeedTab(widget.clubId),
          _buildCompetitionsTab(widget.clubId),
          _buildNoticeboardTab(widget.clubId),
          _buildMembersTab(widget.clubId),
        ],
      ),
    );
  }

  Widget _buildHomeFeedTab(String clubId) {
    return ref.watch(clubPostsProvider(clubId)).when(
      data: (posts) {
        final feedPosts = posts.where((p) => p.postType != 'competition').toList();
        if (feedPosts.isEmpty) return const Center(child: Text('No posts yet.'));
        
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
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading posts')),
    );
  }

  Widget _buildCompetitionsTab(String clubId) {
    return ref.watch(clubPostsProvider(clubId)).when(
      data: (posts) {
        final compPosts = posts.where((p) => p.postType == 'fixture' || p.postType == 'result').toList();
        if (compPosts.isEmpty) return const Center(child: Text('No competitions yet.'));
        
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
              actionText: post.postType == 'fixture' ? 'Register Now' : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading competitions')),
    );
  }

  Widget _buildNoticeboardTab(String clubId) {
    return ref.watch(clubPostsProvider(clubId)).when(
      data: (posts) {
        final notices = posts.where((p) => p.postType == 'notice').toList();
        if (notices.isEmpty) return const Center(child: Text('No notices.'));
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notices.length,
          itemBuilder: (context, index) {
            final post = notices[index];
            return _buildPostCard(
              type: post.postType,
              title: post.title,
              content: post.content,
              timeAgo: _formatDate(post.createdAt),
              author: post.authorName,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading notices')),
    );
  }

  Widget _buildMembersTab(String clubId) {
    return ref.watch(clubMembersProvider(clubId)).when(
      data: (members) {
        final activeMembers = members.where((m) => m.status == 'active').toList();
        // ignore: unused_local_variable — pending count reserved for future badge UI
        final _ = members.where((m) => m.status == 'pending').toList();
        
        if (members.isEmpty) return const Center(child: Text('No members yet.'));
        
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Active Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900)),
            const SizedBox(height: 8),
            if (activeMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No active members.', style: TextStyle(color: AppColors.grey500)),
              ),
            ...activeMembers.map((m) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.emerald50,
                child: Text(m.name[0], style: const TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.bold)),
              ),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Handicap: ${m.handicap?.toStringAsFixed(1) ?? 'N/A'}'),
            )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading members: $e')),
    );
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
  }) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'announcement':
        icon = LucideIcons.megaphone;
        iconColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'competition':
        icon = LucideIcons.trophy;
        iconColor = AppColors.emerald700;
        bgColor = AppColors.emerald50;
        break;
      case 'result':
        icon = LucideIcons.award;
        iconColor = Colors.purple;
        bgColor = Colors.purple.withValues(alpha: 0.1);
        break;
      default:
        icon = LucideIcons.bell;
        iconColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
          if (actionText != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
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
    );
  }
}
