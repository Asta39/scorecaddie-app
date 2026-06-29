import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/club_feed_provider.dart';
import '../../../core/models/competition.dart';
import '../../../providers/competition_providers.dart';
import '../../../widgets/top_notification.dart';
import '../../../widgets/post_card.dart';

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
                  style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 12),
              if (activeClub != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CreditCardWidget(
                    cardNumber: '0000 0000 0000 1923',
                    expiryDate: '12/26',
                    cardHolderName: userName,
                    cvvCode: '123',
                    showBackView: false,
                    bankName: activeClub.clubName,
                    cardBgColor: AppColors.golfLime,
                    glassmorphismConfig: null,
                    isHolderNameVisible: true,
                    isSwipeGestureEnabled: false,
                    onCreditCardWidgetChange: (CreditCardBrand brand) {},
                    customCardTypeIcons: <CustomCardTypeIcon>[
                      CustomCardTypeIcon(
                        cardType: CardType.mastercard,
                        cardImage: Image.asset('assets/images/mastercard.png', height: 48, width: 48),
                      ),
                    ],
                  ),
                )
              else
                _buildEmptyStateCard('No Clubs Joined', 'You haven\'t joined any clubs yet.'),

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.grey500, fontWeight: FontWeight.w500)),
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String title, String subtitle) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.calendarOff, size: 32, color: AppColors.grey300),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.grey500), textAlign: TextAlign.center),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comp.posterUrl != null && comp.posterUrl!.isNotEmpty)
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(comp.posterUrl!, width: double.infinity, fit: BoxFit.cover),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.golfLime,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(LucideIcons.trophy, size: 32, color: AppColors.grey900),
                ),
              ),
            ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.grey900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comp.description ?? 'Tap to view event details',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                onPressed: () => context.push('/competitions/${comp.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.golfLime,
                  foregroundColor: AppColors.grey900,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Enter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.golfLime,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(club.clubName[0].toUpperCase(), style: const TextStyle(color: AppColors.grey900, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(club.clubName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.grey900), maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.golfLime.withValues(alpha: 0.2) : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                isActive ? 'Enter Club' : 'Pending',
                style: TextStyle(
                  color: isActive ? AppColors.grey900 : Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            const Text('Explore\nClubs', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.bold)),
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
