import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/competition.dart';
import '../../../core/providers/club_feed_provider.dart';
import '../../../providers/competition_providers.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/top_notification.dart';
import '../../onboarding/ob_app.dart';
import '../../onboarding/ob_style.dart';
import '../../onboarding/ob_widgets.dart';

/// Club → Overview: your membership, the club at a glance, what's coming up,
/// the restaurant, the latest result and news, and your other clubs.
class ClubOverviewTab extends ConsumerWidget {
  const ClubOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeClub = ref.watch(activeClubProvider);
    final membershipsAsync = ref.watch(userClubMembershipsProvider);
    final posts = ref.watch(activeClubFeedProvider).valueOrNull ?? const <ClubPost>[];
    final members = ref.watch(activeClubMembersListProvider).valueOrNull ?? const [];
    final comps = ref.watch(competitionsForClubProvider(activeClub?.clubId ?? '')).valueOrNull ?? const <Competition>[];

    return membershipsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Ob.lime)),
      error: (e, _) => Center(child: Text('Couldn’t load your clubs.', style: Ob.body(14, color: Ob.creamA(.7)))),
      data: (memberships) {
        final existingIds = memberships.map((m) => m.clubId).toSet();
        final otherClubs = memberships.where((m) => m.clubId != activeClub?.clubId).toList();
        final upcoming = comps.where((c) => c.status == 'open_for_entry' || c.status == 'upcoming' || c.status == 'in_progress').toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        final activeMembers = members.where((m) => m.status == 'active').length;
        final latestResult = posts.where((p) => p.postType == 'result').firstOrNull;
        final latestNews = posts.where((p) => p.postType != 'competition' && p.postType != 'result').firstOrNull;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          children: [
            if (activeClub == null)
              ObCard(child: Text('You haven’t joined a club yet. Find yours below.', style: Ob.body(14, color: Ob.creamA(.7))))
            else ...[
              if (activeClub.status == 'pending') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Ob.warn.withValues(alpha: .1), borderRadius: BorderRadius.circular(18), border: Border.all(color: Ob.warn.withValues(alpha: .4))),
                  child: Row(children: [
                    const Icon(LucideIcons.clock, size: 18, color: Ob.warn),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Your membership is waiting for the club to approve it.', style: Ob.body(14, weight: FontWeight.w700))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              _MembershipCard(club: activeClub),
            ],
            const SizedBox(height: 16),
            ObSplitCards(
              left: ObStat('Members', activeMembers > 0 ? '$activeMembers' : '—'),
              right: ObStat('Coming up', '${upcoming.length}'),
            ),
            const SizedBox(height: 24),
            const ObEyebrow('Upcoming events'),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              ObCard(child: Text('No events on the calendar yet.', style: Ob.body(14, color: Ob.creamA(.62))))
            else
              for (final c in upcoming.take(3)) Padding(padding: const EdgeInsets.only(bottom: 10), child: _EventRow(comp: c)),
            const SizedBox(height: 14),
            ObCard(
              onTap: () => context.push('/restaurant'),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Ob.warn.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.utensils, size: 20, color: Ob.warn),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Clubhouse restaurant', style: Ob.body(15, weight: FontWeight.w700)),
                    Text('Browse the menu or book a table', style: Ob.body(12, color: Ob.creamA(.58))),
                  ]),
                ),
                Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
              ]),
            ),
            const SizedBox(height: 24),
            const ObEyebrow('Latest result'),
            const SizedBox(height: 12),
            if (latestResult != null)
              PostCard(type: latestResult.postType, title: latestResult.title, content: latestResult.content, timeAgo: formatTimeAgo(latestResult.createdAt), author: latestResult.authorName, imageUrl: latestResult.imageUrl)
            else
              ObCard(child: Text('No results published yet.', style: Ob.body(14, color: Ob.creamA(.62)))),
            const SizedBox(height: 12),
            const ObEyebrow('Club news'),
            const SizedBox(height: 12),
            if (latestNews != null)
              PostCard(type: latestNews.postType, title: latestNews.title, content: latestNews.content, timeAgo: formatTimeAgo(latestNews.createdAt), author: latestNews.authorName, imageUrl: latestNews.imageUrl)
            else
              ObCard(child: Text('Nothing new from the club.', style: Ob.body(14, color: Ob.creamA(.62)))),
            const SizedBox(height: 12),
            const ObEyebrow('Your other clubs'),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final c in otherClubs) Padding(padding: const EdgeInsets.only(right: 12), child: _OtherClubCard(club: c)),
                  _ExploreCard(onTap: () => _showJoinSheet(context, ref, existingIds)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showJoinSheet(BuildContext context, WidgetRef ref, Set<String> existingIds) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        height: MediaQuery.of(sheet).size.height * .72,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1A12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0x40A3E635))),
        ),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Consumer(builder: (context, ref, _) {
            final available = ref.watch(availableClubsProvider);
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 16),
              Text('Join a club', style: Ob.display(26)),
              const SizedBox(height: 4),
              Text('The club confirms your membership before you’re in.', style: Ob.body(14, color: Ob.creamA(.62))),
              const SizedBox(height: 16),
              Expanded(
                child: available.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: Ob.lime)),
                  error: (e, _) => Center(child: Text('Couldn’t load clubs.', style: Ob.body(14, color: Ob.creamA(.7)))),
                  data: (clubs) {
                    final open = clubs.where((c) => !existingIds.contains(c['id'])).toList();
                    if (open.isEmpty) return Center(child: Text('You’re in every club on ScoreCaddie.', style: Ob.body(14, color: Ob.creamA(.62))));
                    return ListView.separated(
                      itemCount: open.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final club = open[i];
                        final name = (club['name'] as String?) ?? 'Club';
                        return ObCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            ObCrest(name, size: 44, radius: 13, logoUrl: club['logo_url'] as String?),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: Ob.body(15, weight: FontWeight.w700)),
                                if ((club['location'] as String?)?.isNotEmpty ?? false) Text(club['location'] as String, style: Ob.body(12, color: Ob.creamA(.55))),
                              ]),
                            ),
                            ObButton(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              onPressed: () async {
                                try {
                                  final supabase = Supabase.instance.client;
                                  final userId = supabase.auth.currentUser?.id;
                                  if (userId == null) return;
                                  await supabase.from('player_club_memberships').insert({
                                    'player_id': userId,
                                    'club_id': club['id'],
                                    'status': 'pending',
                                    'is_home_club': existingIds.isEmpty,
                                  });
                                  if (sheet.mounted) {
                                    Navigator.pop(sheet);
                                    TopNotification.showSuccess(context, 'Request sent to $name. The club will confirm it shortly.');
                                    ref.invalidate(userClubMembershipsProvider);
                                  }
                                } catch (e) {
                                  if (context.mounted) TopNotification.showError(context, 'Couldn’t send the request: $e');
                                }
                              },
                              child: Text('Request', style: Ob.label(13, weight: FontWeight.w800)),
                            ),
                          ]),
                        );
                      },
                    );
                  },
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.club});
  final UserClubMembership club;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (club.membershipNumber != null && club.membershipNumber!.isNotEmpty) 'No. ${club.membershipNumber}',
      if (club.renewalDate != null) 'Renews ${DateFormat('MMM yyyy').format(club.renewalDate!)}',
    ];
    return ObHeroCard(
      edge: club.isHomeClub ? null : const Color(0x33FFFFFF),
      child: Row(children: [
        ObCrest(club.clubName, size: 60, radius: 18),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(club.isHomeClub ? 'HOME CLUB' : 'GUEST MEMBER', style: Ob.eyebrow()),
            const SizedBox(height: 2),
            Text(club.clubName, style: Ob.display(22, height: 1.1)),
            if (details.isNotEmpty) ...[const SizedBox(height: 4), Text(details.join(' · '), style: Ob.body(12, color: Ob.creamA(.6)))],
          ]),
        ),
        if (club.status == 'pending') const ObChip('Pending', color: Ob.warn),
      ]),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.comp});
  final Competition comp;

  @override
  Widget build(BuildContext context) {
    final live = comp.status == 'in_progress';
    return ObCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/competitions/${comp.id}'),
      child: Row(children: [
        Container(
          width: 52,
          height: 58,
          decoration: BoxDecoration(color: live ? Ob.lime : Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(DateFormat('MMM').format(comp.startDate).toUpperCase(), style: Ob.label(11, weight: FontWeight.w800).copyWith(color: live ? Ob.ink : Ob.lime)),
            Text('${comp.startDate.day}', style: Ob.display(26, height: 1, color: live ? Ob.ink : Ob.lime)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(comp.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(live ? 'Live now' : _format(comp.competitionType), style: Ob.body(12, color: live ? Ob.lime : Ob.creamA(.58))),
          ]),
        ),
        Text(live ? 'Leaderboard' : comp.status == 'open_for_entry' ? 'Enter' : 'View', style: Ob.label(13, weight: FontWeight.w800).copyWith(color: Ob.lime)),
      ]),
    );
  }

  static String _format(String t) => switch (t) {
        'strokeplay' => 'Stroke play',
        'stableford' => 'Stableford',
        'matchplay' => 'Match play',
        'betterball' => 'Better ball',
        'foursome' => 'Foursomes',
        'bogey' => 'Bogey competition',
        _ => t,
      };
}

class _OtherClubCard extends ConsumerWidget {
  const _OtherClubCard({required this.club});
  final UserClubMembership club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = club.status == 'active';
    return GestureDetector(
      onTap: active ? () => ref.read(activeClubIdProvider.notifier).state = club.clubId : null,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x0FFFFFFF))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ObCrest(club.clubName, size: 44, radius: 13),
          const SizedBox(height: 10),
          Text(club.clubName, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w700, height: 1.25)),
          const Spacer(),
          active ? const ObChip('Switch to it', on: true) : const ObChip('Pending', color: Ob.warn),
        ]),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Join another club',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 140,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withValues(alpha: .16), width: 2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.plus, size: 22, color: Ob.creamA(.72)),
              const SizedBox(height: 8),
              Text('Join a club', style: Ob.label(14).copyWith(color: Ob.creamA(.72))),
            ]),
          ),
        ),
      );
}
