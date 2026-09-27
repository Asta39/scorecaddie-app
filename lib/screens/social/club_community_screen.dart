import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/providers/club_feed_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import 'components/overview_tab.dart';

/// The Club tab: your club's header with a switcher, then Overview, Feed,
/// Events and Members on a goo switch.
class ClubCommunityScreen extends ConsumerStatefulWidget {
  const ClubCommunityScreen({super.key});

  @override
  ConsumerState<ClubCommunityScreen> createState() => _ClubCommunityScreenState();
}

class _ClubCommunityScreenState extends ConsumerState<ClubCommunityScreen> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    final activeClub = ref.watch(activeClubProvider);
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                ObCrest(activeClub?.clubName ?? '?', size: 56, radius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(activeClub?.isHomeClub == false ? 'GUEST CLUB' : 'HOME CLUB', style: Ob.eyebrow()),
                    const SizedBox(height: 2),
                    Text(activeClub?.clubName ?? 'Your club', maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.display(25, height: 1.05)),
                  ]),
                ),
                ObIconButton(icon: LucideIcons.repeat, label: 'Switch club', onPressed: _showSwitcher),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: ObGooSegmented<String>(
                options: const [('overview', 'Overview'), ('feed', 'Feed'), ('events', 'Events'), ('members', 'Members')],
                selected: _tab,
                fontSize: 13,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: const ['overview', 'feed', 'events', 'members'].indexOf(_tab),
                children: const [ClubOverviewTab(), _FeedTab(), _EventsTab(), _MembersTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwitcher() {
    final memberships = ref.read(userClubMembershipsProvider).valueOrNull;
    if (memberships == null || memberships.isEmpty) return;
    final activeId = ref.read(activeClubProvider)?.clubId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1A12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0x40A3E635))),
        ),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 16),
            Text('Switch club', style: Ob.display(24)),
            const SizedBox(height: 12),
            for (final m in memberships)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    ref.read(activeClubIdProvider.notifier).state = m.clubId;
                    Navigator.pop(sheet);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.clubId == activeId ? Ob.lime.withValues(alpha: .08) : Ob.cardFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: m.clubId == activeId ? Ob.lime : const Color(0x0FFFFFFF), width: 2),
                    ),
                    child: Row(children: [
                      ObCrest(m.clubName, size: 40, radius: 12),
                      const SizedBox(width: 12),
                      Expanded(child: Text(m.clubName, style: Ob.body(15, weight: FontWeight.w700))),
                      if (m.status == 'pending') const ObChip('Pending', color: Ob.warn),
                      if (m.isHomeClub) const ObChip('Home', on: true),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activeClubFeedProvider).when(
          loading: () => const Center(child: CircularProgressIndicator(color: Ob.lime)),
          error: (e, _) => Center(child: Text('Couldn’t load the feed.', style: Ob.body(14, color: Ob.creamA(.7)))),
          data: (posts) {
            final feed = posts.where((p) => p.postType != 'competition').toList();
            if (feed.isEmpty) {
              return Padding(padding: const EdgeInsets.all(20), child: Text('No posts from your club yet.', style: Ob.body(14, color: Ob.creamA(.62))));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              itemCount: feed.length,
              itemBuilder: (context, i) => PostCard(
                type: feed[i].postType,
                title: feed[i].title,
                content: feed[i].content,
                timeAgo: formatTimeAgo(feed[i].createdAt),
                author: feed[i].authorName,
                imageUrl: feed[i].imageUrl,
              ),
            );
          },
        );
  }
}

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab();

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  bool _calendar = false;
  DateTime _selected = DateTime.now();
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return ref.watch(activeClubFeedProvider).when(
          loading: () => const Center(child: CircularProgressIndicator(color: Ob.lime)),
          error: (e, _) => Center(child: Text('Couldn’t load events.', style: Ob.body(14, color: Ob.creamA(.7)))),
          data: (posts) {
            final events = posts.where((p) => p.postType == 'fixture' || p.postType == 'result' || p.postType == 'competition').toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                Center(
                  child: SizedBox(
                    width: 260,
                    child: ObGooSegmented<bool>(
                      height: 38,
                      fontSize: 13,
                      options: const [(false, 'List'), (true, 'Calendar')],
                      selected: _calendar,
                      onChanged: (v) => setState(() => _calendar = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_calendar) ..._calendarView(events) else ..._list(events),
              ],
            );
          },
        );
  }

  PostCard _card(ClubPost p) {
    final canEnter = p.postType == 'fixture' || p.postType == 'competition';
    return PostCard(
      type: p.postType,
      title: p.title,
      content: p.content,
      timeAgo: formatTimeAgo(p.createdAt),
      author: p.authorName,
      imageUrl: p.imageUrl,
      actionText: canEnter ? 'See and enter' : null,
      onAction: canEnter ? () => context.push('/competitions/${p.id}') : null,
    );
  }

  List<Widget> _list(List<ClubPost> events) => events.isEmpty
      ? [ObCard(child: Text('No events from your club yet.', style: Ob.body(14, color: Ob.creamA(.62))))]
      : [for (final e in events) _card(e)];

  List<Widget> _calendarView(List<ClubPost> events) {
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final lead = DateTime(_month.year, _month.month).weekday - 1;
    final onDay = events.where((p) => DateUtils.isSameDay(p.createdAt, _selected)).toList();
    return [
      ObCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(children: [
          Row(children: [
            ObIconButton(icon: LucideIcons.chevronLeft, label: 'Previous month', size: 40, onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
            Expanded(child: Center(child: Text(DateFormat('MMMM yyyy').format(_month), style: Ob.display(20)))),
            ObIconButton(icon: LucideIcons.chevronRight, label: 'Next month', size: 40, onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(d, style: Ob.label(12).copyWith(color: Ob.creamA(.45))))),
          ]),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++) _dayCell(DateTime(_month.year, _month.month, d), events),
            ],
          ),
        ]),
      ),
      const SizedBox(height: 16),
      ObEyebrow(DateFormat('EEEE d MMMM').format(_selected)),
      const SizedBox(height: 12),
      if (onDay.isEmpty) Text('Nothing on this day.', style: Ob.body(14, color: Ob.creamA(.55))) else for (final e in onDay) _card(e),
    ];
  }

  Widget _dayCell(DateTime day, List<ClubPost> events) {
    final selected = DateUtils.isSameDay(day, _selected);
    final today = DateUtils.isSameDay(day, DateTime.now());
    final has = events.any((p) => DateUtils.isSameDay(p.createdAt, day));
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat('d MMMM').format(day) + (has ? ', has events' : ''),
      child: GestureDetector(
        onTap: () => setState(() => _selected = day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? Ob.lime : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: today && !selected ? Ob.lime : Colors.transparent),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${day.day}', style: Ob.label(13, weight: FontWeight.w700).copyWith(color: selected ? Ob.ink : Ob.cream)),
            if (has) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: selected ? Ob.ink : Ob.lime, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab();

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return ref.watch(activeClubMembersListProvider).when(
          loading: () => const Center(child: CircularProgressIndicator(color: Ob.lime)),
          error: (e, _) => Center(child: Text('Couldn’t load members.', style: Ob.body(14, color: Ob.creamA(.7)))),
          data: (members) {
            final active = members.where((m) => m.status == 'active').toList();
            final shown = active.where((m) => m.name.toLowerCase().contains(_query.toLowerCase())).toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: Ob.body(15),
                  cursorColor: Ob.lime,
                  decoration: InputDecoration(
                    hintText: 'Search ${active.length} members',
                    hintStyle: Ob.body(15, color: Ob.creamA(.35)),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5)),
                    filled: true,
                    fillColor: Ob.field,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Ob.fieldBorder, width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Ob.lime, width: 2)),
                  ),
                ),
                const SizedBox(height: 14),
                if (shown.isEmpty)
                  Text(_query.isEmpty ? 'No members yet.' : 'Nobody called “$_query”.', style: Ob.body(14, color: Ob.creamA(.6)))
                else
                  ObCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(children: [
                      for (var i = 0; i < shown.length; i++) ...[
                        if (i > 0) const ObHair(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            ProfileImage(url: shown[i].avatarUrl, name: shown[i].name, size: 40, isCircle: true),
                            const SizedBox(width: 12),
                            Expanded(child: Text(shown[i].name, style: Ob.body(15, weight: FontWeight.w700))),
                            if (shown[i].privacyLevel == 'Public' && shown[i].handicap != null)
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(shown[i].handicap!.toStringAsFixed(1), style: Ob.display(20, height: 1)),
                                Text('index', style: Ob.body(11, color: Ob.creamA(.55))),
                              ])
                            else
                              Icon(LucideIcons.lock, size: 16, color: Ob.creamA(.35)),
                          ]),
                        ),
                      ],
                    ]),
                  ),
              ],
            );
          },
        );
  }
}
