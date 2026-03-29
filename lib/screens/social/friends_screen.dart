import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/services/friend_service.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 24, letterSpacing: -0.5)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          requestsAsync.when(
            data: (requests) => requests.isEmpty 
                ? const SliverToBoxAdapter(child: SizedBox()) 
                : SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _buildRequestsSection(context, requests, ref),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(child: LinearProgressIndicator(color: AppColors.emerald700)),
            error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MY FRIENDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                  TextButton.icon(
                    onPressed: () => _showAddFriendDialog(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Add New', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.emerald700,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      backgroundColor: AppColors.emerald50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          friendsAsync.when(
            data: (friends) => friends.isEmpty 
                ? SliverFillRemaining(child: _buildEmptyState(context)) 
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _buildFriendCard(context, friends[i], ref, i == 0, i == friends.length - 1),
                        childCount: friends.length,
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(BuildContext context, List<Map<String, dynamic>> requests, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.emerald700, borderRadius: BorderRadius.circular(8)),
              child: const Icon(LucideIcons.userPlus, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'PENDING INVITES (${requests.length})', 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.emerald700, letterSpacing: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...requests.map((req) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildAvatar(req['fromAvatar'], req['fromName'] ?? 'G', size: 50),
            title: Text(req['fromName'] ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.grey900)),
            subtitle: const Text('Wants to connect with you', style: TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCircleIconButton(
                  icon: LucideIcons.check, 
                  color: AppColors.emerald700, 
                  onTap: () async {
                    await ref.read(friendServiceProvider).respondToRequest(req['id'], true);
                    ref.invalidate(friendsProvider);
                    final uid = ref.read(authStateProvider).valueOrNull?.uid;
                    if (uid != null) ref.read(achievementServiceProvider).checkAllAchievements(uid);
                  }
                ),
                const SizedBox(width: 8),
                _buildCircleIconButton(
                  icon: LucideIcons.x, 
                  color: AppColors.doubleBogey, 
                  onTap: () => ref.read(friendServiceProvider).respondToRequest(req['id'], false)
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(LucideIcons.users, size: 64, color: AppColors.grey100),
          ),
          const SizedBox(height: 24),
          const Text('No friends yet', style: TextStyle(color: AppColors.grey900, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Connect with others to compare\nstats and climb the leaderboard.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Friend friend, WidgetRef ref, bool isFirst, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(28) : Radius.zero,
          bottom: isLast ? const Radius.circular(28) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/player/${friend.friendId}?name=${Uri.encodeComponent(friend.friendName ?? 'Golfer')}'),
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(28) : Radius.zero,
              bottom: isLast ? const Radius.circular(28) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildAvatar(friend.friendAvatar, friend.friendName ?? 'G', size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(friend.friendName ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.grey900)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.barChart2, size: 12, color: AppColors.emerald700),
                            const SizedBox(width: 4),
                            const Text('View performance', style: TextStyle(color: AppColors.emerald700, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: AppColors.grey200, size: 20),
                ],
              ),
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 92),
              child: Divider(height: 1, color: AppColors.grey100.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String initial, {required double size}) {
    ImageProvider? imageProvider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        imageProvider = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) imageProvider = FileImage(file);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey100, width: 1),
        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
      ),
      child: imageProvider == null 
          ? Center(child: Text(initial.isNotEmpty ? initial[0].toUpperCase() : 'G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * 0.4, color: AppColors.grey300)))
          : null,
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final idController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) {
        bool isSearching = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => CupertinoAlertDialog(
            title: const Text('Add Friend'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text('Enter your friend\'s Firebase UID to connect.'),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: idController,
                  placeholder: 'Paste UID here',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10)),
                  autofocus: true,
                ),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CupertinoActivityIndicator(),
                  ),
              ],
            ),
            actions: [
              CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: isSearching ? null : () async {
                  if (idController.text.trim().isEmpty) return;
                  setDialogState(() => isSearching = true);
                  final profile = await ref.read(friendServiceProvider).fetchProfile(idController.text.trim());
                  setDialogState(() => isSearching = false);
                  if (profile == null) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Player not found.'), behavior: SnackBarBehavior.floating));
                    return;
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showConfirmationDialog(context, ref, idController.text.trim(), profile);
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref, String uid, Map<String, dynamic> profile) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connect?'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            _buildAvatar(profile['avatarUrl'], profile['name'] ?? 'G', size: 80),
            const SizedBox(height: 12),
            Text(profile['name'] ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            const Text('Send a friend request to this player?'),
          ],
        ),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final success = await ref.read(friendServiceProvider).sendFriendRequest(uid);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Invite sent!' : 'Unable to send invite.'), behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}
