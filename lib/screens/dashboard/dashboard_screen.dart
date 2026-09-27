import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart' as db;
import '../../providers/app_providers.dart';
import '../provider/coach_dashboard_screen.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile?.role == 'coach') {
          return CoachDashboardScreen();
        } else {
          return const PlayerDashboardView();
        }
      },
      loading: () => const LoadingSpinner(isFullScreen: true),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
// Re-implementing the Player View without circular dependencies or prefix errors
class PlayerDashboardView extends ConsumerStatefulWidget {
  const PlayerDashboardView({super.key});

  @override
  ConsumerState<PlayerDashboardView> createState() => _PlayerDashboardViewState();
}

class _PlayerDashboardViewState extends ConsumerState<PlayerDashboardView> {
  /// The index shown in the hero. It starts at last month's value and rolls
  /// to today's, so a change is something you see happen.
  double? _shownIndex;
  bool _rolled = false;

  void _rollIndex(double? last, double? current) {
    if (_rolled || current == null) return;
    _rolled = true;
    if (last == null || last == current || MediaQuery.of(context).disableAnimations) {
      _shownIndex = current;
      return;
    }
    _shownIndex = last;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _shownIndex = current);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final user = ref.watch(authStateProvider).valueOrNull;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final first = (profile?.name ?? user?.displayName ?? 'Golfer').trim().split(' ').first;
    final userName = first.isEmpty ? 'Golfer' : first[0].toUpperCase() + first.substring(1);

    ref.listen(userProfileProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        final profile = next.value!;
        final user = ref.read(authStateProvider).valueOrNull;
        if (user != null && user.email != null) {
          ref.read(friendServiceProvider).syncMyProfileToCloud(
            name: profile.name,
            email: user.email!,
            avatarUrl: profile.avatarUrl,
            handicapIndex: profile.handicap,
          );
        }
      }
    });

    final handicap = ref.watch(handicapProvider).valueOrNull;
    _rollIndex(handicap?.lastIndex, handicap?.currentIndex);
    final streak = ref.watch(streakProvider).valueOrNull;
    final upcoming = _upcomingTeeTimes(ref.watch(casualTeeTimeBookingsProvider).valueOrNull ?? const []);

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: Ob.lime,
          onRefresh: () => ref.read(syncServiceProvider).syncAllPending(),
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              ObTabHeader('$greeting, $userName', actions: [_bell()]).rise(),
              const SizedBox(height: 16),
              ObGuideRow(botAsset: ObBot.ball.happy, botLabel: 'Your golf-ball avatar, grinning', text: _nudge(streak, upcoming)).rise(1),
              const SizedBox(height: 18),
              _indexCard(handicap).rise(2),
              const SizedBox(height: 18),
              _actions().rise(3),
              const SizedBox(height: 18),
              _streakCard(streak),
              const SizedBox(height: 18),
              _numbers(),
              const SizedBox(height: 24),
              ObEyebrow('Next tee time', action: 'See all', onAction: () => context.push('/tee-times')),
              const SizedBox(height: 12),
              _nextTeeTime(upcoming),
              const SizedBox(height: 24),
              ObEyebrow('Recent rounds', action: 'See all', onAction: () => context.push('/rounds-history')),
              const SizedBox(height: 12),
              _recentRounds(ref.watch(recentRoundsProvider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bell() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF0B160F), Color(0xFF1F3326)]),
          border: Border.all(color: const Color(0xFF2F4A39)),
        ),
        child: const Center(child: NotificationBell(color: Ob.cream)),
      );

  List<CasualTeeTimeBooking> _upcomingTeeTimes(List<CasualTeeTimeBooking> all) {
    final now = DateTime.now();
    final list = all.where((b) => _teeDateTime(b).isAfter(now)).toList()..sort((a, b) => _teeDateTime(a).compareTo(_teeDateTime(b)));
    return list;
  }

  DateTime _teeDateTime(CasualTeeTimeBooking b) {
    final parts = b.teeTime.split(':');
    return DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day, int.tryParse(parts[0]) ?? 0, parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  /// What your golf ball says: the most useful thing right now.
  String _nudge(StreakInfo? streak, List<CasualTeeTimeBooking> upcoming) {
    if (upcoming.isNotEmpty) {
      final t = _teeDateTime(upcoming.first);
      final days = DateUtils.dateOnly(t).difference(DateUtils.dateOnly(DateTime.now())).inDays;
      final when = days == 0 ? 'today' : days == 1 ? 'tomorrow' : DateFormat('EEEE').format(t);
      return 'Tee time $when at ${DateFormat('HH:mm').format(t)}. Let’s go!';
    }
    return switch (streak?.status) {
      StreakStatus.noRounds || null => 'Play a round and I’ll start keeping score.',
      StreakStatus.atRisk => 'No round yet this week. Keep the streak alive?',
      StreakStatus.broken => 'New week, new streak. Tee one up?',
      _ => 'Nice week. Fancy a range session?',
    };
  }

  Widget _indexCard(HandicapStatus? h) {
    final current = h?.currentIndex;
    final last = h?.lastIndex;
    final delta = (current != null && last != null) ? current - last : null;
    return ObHeroCard(
      onTap: () => context.push('/analytics'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ObEyebrow('Handicap index', trailing: ObChip('Official WHS', on: true)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (current == null)
                Text('—', style: Ob.display(72, height: 1.1, color: Ob.creamA(.35)))
              else
                ObRollingNumber(value: _shownIndex ?? current, fontSize: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (delta != null && delta.abs() >= 0.05)
                        Row(children: [
                          Icon(delta < 0 ? LucideIcons.arrowDown : LucideIcons.arrowUp, size: 14, color: delta < 0 ? Ob.lime : Ob.warn),
                          const SizedBox(width: 2),
                          Text(delta.abs().toStringAsFixed(1), style: Ob.label(14, weight: FontWeight.w800).copyWith(color: delta < 0 ? Ob.lime : Ob.warn)),
                          Text('  this month', style: Ob.body(12, color: Ob.creamA(.6))),
                        ]),
                      Text(
                        current == null
                            ? 'Appears after ${h?.roundsNeededForUpdate ?? 3} more rounds'
                            : (h?.lowIndex != null ? 'Low ${h!.lowIndex!.toStringAsFixed(1)}' : 'Tap for your stats'),
                        style: Ob.body(12, color: Ob.creamA(.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions() => Row(
        children: [
          Expanded(
            flex: 5,
            child: ObButton(
              onPressed: () => context.push('/select-course'),
              height: 56,
              padding: EdgeInsets.zero,
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.flag, size: 18), const SizedBox(width: 8), Text('Start round', style: Ob.label(16, weight: FontWeight.w800))]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: ObButton(
              tone: ObButtonTone.dark,
              onPressed: () => context.push('/book-tee-time'),
              height: 56,
              padding: EdgeInsets.zero,
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.calendar, size: 18), const SizedBox(width: 8), Text('Tee time', style: Ob.label(16, weight: FontWeight.w800))]),
            ),
          ),
        ],
      );

  Widget _streakCard(StreakInfo? info) {
    final now = DateTime.now();
    final monday = DateUtils.dateOnly(now.subtract(Duration(days: now.weekday - 1)));
    final played = List<bool>.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return (info?.playedDatesThisWeek ?? const []).any((p) => DateUtils.isSameDay(p, d));
    });
    final count = info?.count ?? 0;
    final line = switch (info?.status) {
      StreakStatus.atRisk => 'Play once before Sunday to keep it going.',
      StreakStatus.broken => 'Your streak ended. One round this week starts a new one.',
      StreakStatus.noRounds || null => 'Play a round every week to build a streak.',
      _ => 'You’ve played this week. See you next week!',
    };
    return ObCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ObEyebrow('Weekly streak',
              trailing: Row(children: [
                Icon(LucideIcons.flame, size: 16, color: count > 0 ? Ob.warn : Ob.creamA(.4)),
                const SizedBox(width: 6),
                Text('$count ${count == 1 ? 'week' : 'weeks'}', style: Ob.display(20, color: count > 0 ? Ob.warn : Ob.creamA(.5))),
              ])),
          const SizedBox(height: 14),
          ObWeekDots(played: played, today: now.weekday - 1),
          const SizedBox(height: 10),
          Text(line, style: Ob.body(13, height: 1.45, color: Ob.creamA(.62))),
        ],
      ),
    );
  }

  Widget _numbers() {
    final avg = ref.watch(averageScoreProvider).valueOrNull;
    final total = ref.watch(totalRoundsProvider).valueOrNull;
    return ObSplitCards(
      left: ObStat('Average score', avg == null ? '—' : avg.toStringAsFixed(1)),
      right: ObStat('Rounds played', total?.toString() ?? '—'),
    );
  }

  Widget _nextTeeTime(List<CasualTeeTimeBooking> upcoming) {
    if (upcoming.isEmpty) {
      return ObCard(
        onTap: () => context.push('/book-tee-time'),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Icon(LucideIcons.calendar, color: Ob.lime, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Text('Nothing booked yet. Grab a tee time?', style: Ob.body(14, weight: FontWeight.w700))),
          Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
        ]),
      );
    }
    final b = upcoming.first;
    final t = _teeDateTime(b);
    return ObCard(
      onTap: () => context.push('/tee-times'),
      child: Row(
        children: [
          ObCrest(b.courseName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(DateFormat('EEEE d MMMM').format(t), style: Ob.body(13, color: Ob.creamA(.6))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(DateFormat('EEE').format(t).toUpperCase(), style: Ob.label(11, weight: FontWeight.w800).copyWith(color: Ob.lime, letterSpacing: .8)),
              Text(DateFormat('HH:mm').format(t), style: Ob.display(22, height: 1, color: Ob.lime)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _recentRounds(AsyncValue<List<db.Round>> rounds) {
    return rounds.when(
      loading: () => const SizedBox(height: 80, child: LoadingSpinner(size: 60)),
      error: (e, _) => Text('Couldn’t load your rounds.', style: Ob.body(14, color: Ob.creamA(.6))),
      data: (list) {
        if (list.isEmpty) {
          return ObCard(child: Text('Your rounds will show up here after your first one.', style: Ob.body(14, color: Ob.creamA(.62))));
        }
        final shown = list.take(3).toList();
        return ObCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const ObHair(),
              _roundRow(shown[i], first: i == 0),
            ],
          ]),
        );
      },
    );
  }

  Widget _roundRow(db.Round r, {bool first = false}) {
    final vsPar = r.scoreVsPar;
    return Semantics(
      button: true,
      label: '${r.courseName}, ${r.totalScore}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/round/${r.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            ObCrest(r.courseName, size: 40, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${DateFormat('EEE d MMM').format(r.playedAt)} · ${r.holesPlayed} holes', style: Ob.body(12, color: Ob.creamA(.55))),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${r.totalScore}', style: Ob.display(26, height: 1)),
              Text(vsPar == 0 ? 'Level' : (vsPar > 0 ? '+$vsPar' : '$vsPar'),
                  style: Ob.label(12, weight: FontWeight.w800).copyWith(color: vsPar <= 0 || first ? Ob.lime : Ob.creamA(.55))),
            ]),
          ]),
        ),
      ),
    );
  }
}
