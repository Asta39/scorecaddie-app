import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart' as db;
import '../../providers/app_providers.dart';
import '../provider/coach_dashboard_screen.dart';
import '../../widgets/loading_spinner.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';


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
  /// The index shown in the hero (no roll-up animation: it's data).
  double? _shownIndex;

  void _rollIndex(double? last, double? current) => _shownIndex = current;

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

    final homeClub = profile?.homeCourseName;
    final avg = ref.watch(averageScoreProvider).valueOrNull;
    final total = ref.watch(totalRoundsProvider).valueOrNull;

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              ObTabHeader('Today', actions: [_bell()]),
              const SizedBox(height: 2),
              Text(
                ['$greeting, $userName', if (homeClub != null && homeClub.isNotEmpty) homeClub].join(' · '),
                style: Ob.body(15, color: Ob.creamA(.6)),
              ),
              const SizedBox(height: 16),
              _indexCard(handicap),
              const SizedBox(height: 26),
              ObGroup(header: 'Next tee time', children: [_nextTeeTime(upcoming)]),
              const SizedBox(height: 26),
              ObGroup(header: 'This week', children: [
                ObRow('Rounds this week', value: '${streak?.playedDatesThisWeek.length ?? 0}'),
                ObRow('Weekly streak', subtitle: _streakLine(streak), value: '${streak?.count ?? 0} ${(streak?.count ?? 0) == 1 ? 'week' : 'weeks'}'),
                ObRow('Average score', value: avg == null ? '—' : avg.toStringAsFixed(1)),
                ObRow('Rounds played', value: total?.toString() ?? '—', onTap: () => context.push('/rounds-history')),
              ]),
              const SizedBox(height: 26),
              _recentRounds(ref.watch(recentRoundsProvider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bell() => const SizedBox(width: 44, height: 44, child: Center(child: NotificationBell(color: Ob.lime)));

  List<CasualTeeTimeBooking> _upcomingTeeTimes(List<CasualTeeTimeBooking> all) {
    final now = DateTime.now();
    final list = all.where((b) => _teeDateTime(b).isAfter(now)).toList()..sort((a, b) => _teeDateTime(a).compareTo(_teeDateTime(b)));
    return list;
  }

  DateTime _teeDateTime(CasualTeeTimeBooking b) {
    final parts = b.teeTime.split(':');
    return DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day, int.tryParse(parts[0]) ?? 0, parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  String _streakLine(StreakInfo? info) => switch (info?.status) {
        StreakStatus.atRisk => 'Play before Sunday to keep it going',
        StreakStatus.broken => 'One round this week starts a new one',
        StreakStatus.noRounds || null => 'Play once a week to build one',
        _ => 'You’ve played this week',
      };

  /// The one hero number: the handicap index, its change this month, and the
  /// two things you came to do.
  Widget _indexCard(HandicapStatus? h) {
    final current = h?.currentIndex;
    final last = h?.lastIndex;
    final delta = (current != null && last != null) ? current - last : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          label: 'Handicap index ${current?.toStringAsFixed(1) ?? 'not set'}. Open stats',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.go('/analytics'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Handicap Index', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.6)))),
                Text('WHS', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.45))),
              ]),
              const SizedBox(height: 4),
              Text(current == null ? '—' : (_shownIndex ?? current).toStringAsFixed(1), style: Ob.display(56, height: 1.05, color: current == null ? Ob.creamA(.3) : Ob.cream)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  if (delta != null && delta.abs() >= 0.05)
                    TextSpan(
                      text: '${delta < 0 ? '▼' : '▲'} ${delta.abs().toStringAsFixed(1)} ',
                      style: Ob.body(15, weight: FontWeight.w600, color: delta < 0 ? const Color(0xFF15803D) : Ob.warn),
                    ),
                  TextSpan(
                    text: current == null
                        ? 'Appears after ${h?.roundsNeededForUpdate ?? 3} more rounds'
                        : [if (delta != null && delta.abs() >= 0.05) 'this month', if (h?.lowIndex != null) 'Low ${h!.lowIndex!.toStringAsFixed(1)}'].join(' · '),
                    style: Ob.body(15, color: Ob.creamA(.6)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ObButton(
              onPressed: () => context.push('/select-course'),
              height: 50,
              radius: 14,
              padding: EdgeInsets.zero,
              child: Text('Start round', style: Ob.label(17)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ObButton(
              tone: ObButtonTone.dark,
              onPressed: () => context.push('/book-tee-time'),
              height: 50,
              radius: 14,
              padding: EdgeInsets.zero,
              child: Text('Book tee time', style: Ob.label(17)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _nextTeeTime(List<CasualTeeTimeBooking> upcoming) {
    if (upcoming.isEmpty) {
      return ObRow('Nothing booked', subtitle: 'Book a tee time at your club', onTap: () => context.push('/book-tee-time'));
    }
    final b = upcoming.first;
    final t = _teeDateTime(b);
    final days = DateUtils.dateOnly(t).difference(DateUtils.dateOnly(DateTime.now())).inDays;
    final day = days == 0 ? 'Today' : days == 1 ? 'Tomorrow' : DateFormat('EEE d MMM').format(t);
    return ObRow('$day · ${DateFormat('HH:mm').format(t)}', subtitle: b.courseName, onTap: () => context.push('/tee-times'));
  }

  Widget _recentRounds(AsyncValue<List<db.Round>> rounds) {
    final list = rounds.valueOrNull ?? const <db.Round>[];
    return ObGroup(header: 'Recent rounds', children: [
      if (rounds.isLoading && list.isEmpty)
        const ObRow('Loading…')
      else if (rounds.hasError && list.isEmpty)
        const ObRow('Couldn’t load your rounds')
      else if (list.isEmpty)
        ObRow('No rounds yet', subtitle: 'Your rounds show up here', onTap: () => context.push('/select-course'))
      else
        for (final r in list.take(3)) _roundRow(r),
    ]);
  }

  Widget _roundRow(db.Round r) {
    final vsPar = r.scoreVsPar;
    return ObRow(
      r.courseName,
      subtitle: '${DateFormat('EEE d MMM').format(r.playedAt)} · ${r.holesPlayed} holes',
      value: '${r.totalScore}  ${vsPar == 0 ? 'E' : (vsPar > 0 ? '+$vsPar' : '$vsPar')}',
      valueColor: Ob.cream,
      onTap: () => context.push('/round/${r.id}'),
    );
  }
}
