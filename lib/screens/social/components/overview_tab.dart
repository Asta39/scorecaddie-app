import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/club_feed_provider.dart';
import '../../../core/models/competition.dart';
import '../../../providers/competition_providers.dart';
import '../../../widgets/top_notification.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/profile_image.dart';
import '../../../widgets/pill.dart';
import '../../../providers/app_providers.dart';

class ClubOverviewTab extends ConsumerWidget {
  const ClubOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeClub = ref.watch(activeClubProvider);
    final membershipsAsync = ref.watch(userClubMembershipsProvider);
    final postsAsync = ref.watch(activeClubFeedProvider);
    final membersAsync = ref.watch(activeClubMembersListProvider);
    final competitionsAsync = ref.watch(competitionsForClubProvider(activeClub?.clubId ?? ''));
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 'Golfer';

    return membershipsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (memberships) {
        final existingClubIds = memberships.map((m) => m.clubId).toSet();
        final guestClubs = memberships.where((m) => m.clubId != activeClub?.clubId).toList();

        final allPosts = postsAsync.valueOrNull ?? [];
        final allMembers = membersAsync.valueOrNull ?? [];
        final allCompetitions = competitionsAsync.valueOrNull ?? [];
        
        final upcomingComps = allCompetitions.where((c) => c.status == 'open_for_entry' || c.status == 'upcoming' || c.status == 'in_progress').toList();
        final activeMembersCount = allMembers.where((m) => m.status == 'active').length;
        
        final latestResult = allPosts.where((p) => p.postType == 'result').firstOrNull;
        final latestActivity = allPosts.where((p) => p.postType != 'competition' && p.postType != 'result').firstOrNull;

        final profileAsync = ref.watch(userProfileProvider);
        final profile = profileAsync.valueOrNull;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ACTIVE CLUB MEMBERSHIP CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  activeClub?.isHomeClub == true ? 'HOME CLUB' : 'SELECTED CLUB',
                  style: const TextStyle(color: AppColors.grey600, fontSize: AppTypeScale.caption, fontWeight: FontWeight.w700, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 12),
              if (activeClub != null) ...[  
                // Pending approval banner
                if (activeClub.status == 'pending')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.clock, size: 20, color: Colors.amber.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your membership is pending approval by the club admin.',
                              style: TextStyle(fontSize: AppTypeScale.body, color: Colors.amber.shade800, fontWeight: FontWeight.w600, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ClubMembershipCard(
                    clubName: activeClub.clubName,
                    memberName: userName,
                    membershipNumber: activeClub.membershipNumber,
                    renewalDate: activeClub.renewalDate,
                    avatarUrl: profile?.avatarUrl,
                    isPending: activeClub.status == 'pending',
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEmptyStateCard('No Clubs Joined', 'You haven\'t joined any clubs yet.'),
                ),

              const SizedBox(height: 16),

              // 2. QUICK STATS STRIP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatPill(LucideIcons.users, activeMembersCount > 0 ? '$activeMembersCount' : '--', 'Members', AppColors.golfLime),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatPill(LucideIcons.calendar, upcomingComps.isNotEmpty ? '${upcomingComps.length}' : '--', 'Upcoming', AppColors.golfLime),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatPill(LucideIcons.checkCircle, '--', 'Next Round', AppColors.golfLime),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. UPCOMING EVENTS
              _buildSectionHeader('Upcoming Events', 'See all', () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: upcomingComps.isEmpty
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildEmptyStateCard('No Upcoming Events', 'Events will appear here.'),
                      ],
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: upcomingComps.length,
                      itemBuilder: (context, index) {
                        final comp = upcomingComps[index];
                        return _buildEventCard(context, comp);
                      },
                    ),
              ),

              const SizedBox(height: 24),

              // 4. LATEST RESULT
              _buildSectionHeader('Latest Result', 'All results', () {}),
              if (latestResult != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: PostCard(
                    type: latestResult.postType,
                    title: latestResult.title,
                    content: latestResult.content,
                    timeAgo: formatTimeAgo(latestResult.createdAt),
                    author: latestResult.authorName,
                    imageUrl: latestResult.imageUrl,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: Text('No results published yet.', style: TextStyle(color: AppColors.grey500)),
                    ),
                  ),
                ),

              // 5. ACTIVITY FEED PREVIEW
              _buildSectionHeader('Club Activity', 'View feed', () {}),
              if (latestActivity != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: PostCard(
                    type: latestActivity.postType,
                    title: latestActivity.title,
                    content: latestActivity.content,
                    timeAgo: formatTimeAgo(latestActivity.createdAt),
                    author: latestActivity.authorName,
                    imageUrl: latestActivity.imageUrl,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: Text('No recent activity.', style: TextStyle(color: AppColors.grey500)),
                    ),
                  ),
                ),

              // 6. GUEST MEMBERSHIPS
              _buildSectionHeader('Guest Memberships', 'Discover', () {}),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    ...guestClubs.map((c) => _buildGuestClubCard(context, c)),
                    _buildAddClubCard(context, ref, existingClubIds),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: color == AppColors.golfLime ? AppColors.grey900 : color),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: AppTypeScale.caption, color: AppColors.grey600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: AppTypeScale.title, fontWeight: FontWeight.w800, color: AppColors.grey900)),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, AppTypeScale.minTapTarget), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel, style: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w700, color: AppColors.emerald700)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String title, String subtitle) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarOff, size: 34, color: AppColors.grey300),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.body, color: AppColors.grey900)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: AppTypeScale.caption, color: AppColors.grey600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Competition comp) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comp.posterUrl != null && comp.posterUrl!.isNotEmpty)
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(comp.posterUrl!, width: double.infinity, fit: BoxFit.cover),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.golfLime,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(
                  child: Icon(LucideIcons.trophy, size: 36, color: AppColors.grey900),
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.body, color: AppColors.grey900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    comp.description ?? 'Tap to view event details',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: AppTypeScale.caption, color: AppColors.grey600, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => context.push('/competitions/${comp.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golfLime,
                  foregroundColor: AppColors.grey900,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Enter', style: TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestClubCard(BuildContext context, UserClubMembership club) {
    final isActive = club.status == 'active';
    return GestureDetector(
      onTap: () {
        if (isActive) context.push('/club-life/${club.clubId}');
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.golfLime,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(club.clubName[0].toUpperCase(), style: const TextStyle(color: AppColors.grey900, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            Text(club.clubName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.body, color: AppColors.grey900), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Pill(
              label: isActive ? 'Enter Club' : 'Pending',
              background: isActive ? AppColors.golfLime.withValues(alpha: 0.2) : Colors.orange.shade50,
              foreground: isActive ? AppColors.grey900 : Colors.orange.shade700,
              dense: true,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddClubCard(BuildContext context, WidgetRef ref, Set<String> existingClubIds) {
    return GestureDetector(
      onTap: () => _showJoinClubDialog(context, ref, existingClubIds),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.golfLime.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.golfLime, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.golfLime.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.plus, color: AppColors.grey900, size: 18),
            ),
            const SizedBox(height: 12),
            const Text('Explore\nClubs', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w800, fontSize: AppTypeScale.caption)),
          ],
        ),
      ),
    );
  }



  void _showJoinClubDialog(BuildContext context, WidgetRef ref, Set<String> existingClubIds) {
    // We can copy the existing modal bottom sheet logic from club_community_screen.dart here.
    // To save space, it will be added shortly via another edit, or we can just keep the dialog in the main file
    // and pass a callback. For now, since we have all the info, I will put it here.
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
                                  child: const Icon(LucideIcons.home, color: AppColors.golfLime),
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
                                          "We've sent your request to join \${club['name'] ?? 'the club'}! The admin will verify it shortly.",
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
}

// ────────────────────────────────────────────────────────────────────────────
// Custom Club Membership Card
// iOS aesthetic: off-white frosted surface, golf illustration watermark,
// floating drop shadow, no border.
// ────────────────────────────────────────────────────────────────────────────
class _ClubMembershipCard extends StatelessWidget {
  final String clubName;
  final String memberName;
  final String? membershipNumber;
  final DateTime? renewalDate;
  final String? avatarUrl;
  final bool isPending;

  const _ClubMembershipCard({
    required this.clubName,
    required this.memberName,
    this.membershipNumber,
    this.renewalDate,
    this.avatarUrl,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final renewalText = renewalDate != null
        ? '${renewalDate!.day.toString().padLeft(2, '0')}/${renewalDate!.month.toString().padLeft(2, '0')}/${renewalDate!.year}'
        : '—';

    return Container(
      width: double.infinity,
      height: 148,
      decoration: BoxDecoration(
        // Slightly off-white — warmer than pure white, like a premium card
        color: const Color(0xFFF5F5F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Golf illustration watermark
          Positioned(
            right: -18,
            bottom: -18,
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(
                size: const Size(160, 160),
                painter: _GolfIllustrationPainter(),
              ),
            ),
          ),
          Positioned(
            right: 110,
            top: -30,
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _GolfBallPainter(),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Club name label
                      Text(
                        clubName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.grey600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Member name
                      Text(
                        memberName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.grey900,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      // Bottom row: member number + renewal
                      Row(
                        children: [
                          _InfoChip(
                            label: 'MEMBER',
                            value: membershipNumber ?? '—',
                          ),
                          const SizedBox(width: 12),
                          _InfoChip(
                            label: 'RENEWAL',
                            value: renewalText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right: profile picture
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: ProfileImage(
                      url: avatarUrl,
                      size: 68,
                      name: memberName,
                      isCircle: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Pending tint overlay
          if (isPending)
            Positioned(
              top: 14,
              left: 14,
              child: Pill(
                icon: LucideIcons.clock,
                label: 'PENDING',
                background: Colors.amber.shade100,
                foreground: Colors.amber.shade800,
                dense: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 0.6)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: AppTypeScale.caption, fontWeight: FontWeight.w700, color: AppColors.grey800, fontFamily: 'monospace')),
      ],
    );
  }
}

// Minimal golf flag + hole illustration painter
class _GolfIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Flagpole
    canvas.drawLine(Offset(size.width * 0.35, size.height * 0.1), Offset(size.width * 0.35, size.height * 0.85), paint);
    // Flag
    final flagPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.1)
      ..lineTo(size.width * 0.7, size.height * 0.22)
      ..lineTo(size.width * 0.35, size.height * 0.34)
      ..close();
    canvas.drawPath(flagPath, paint..style = PaintingStyle.fill);
    // Ground arc / hole
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.35, size.height * 0.85),
      width: size.width * 0.55,
      height: size.height * 0.15,
    );
    canvas.drawArc(rect, 0, 3.14159, false, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple golf ball painter
class _GolfBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    canvas.drawCircle(center, radius, paint);
    // Dimple lines
    for (var i = -2; i <= 2; i++) {
      final y = center.dy + i * radius * 0.3;
      final halfW = (radius * radius - (y - center.dy) * (y - center.dy));
      if (halfW > 0) {
        final hw = halfW < 0 ? 0.0 : halfW;
        canvas.drawLine(
          Offset(center.dx - hw * 0.6, y),
          Offset(center.dx + hw * 0.6, y),
          paint..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
