import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/coaching_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../profile/profile_screen.dart';

/// The coach's colour: the star's gold.
const coachGold = Color(0xFFB7791F);

/// When a recurring session next runs, or null once it has finished.
DateTime? nextOccurrence(CoachingSession s, [DateTime? from]) {
  final asked = from ?? DateTime.now();
  final now = asked.isBefore(s.startDate) ? s.startDate : asked;
  final parts = s.startTime.split(':');
  final h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final end = DateTime(s.endDate.year, s.endDate.month, s.endDate.day, 23, 59);
  for (var i = 0; i < 14; i++) {
    final d = DateTime(now.year, now.month, now.day + i, h, m);
    if (d.isBefore(now)) continue;
    if (d.isAfter(end)) return null;
    if (s.daysOfWeek.contains(d.weekday)) return d;
  }
  return null;
}

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  final _kes = NumberFormat('#,###');

  Future<void> _refresh() async {
    ref.invalidate(coachSessionsProvider);
    ref.invalidate(coachStudentsProvider);
    ref.invalidate(coachProfileStatsProvider);
    ref.invalidate(coachRevenueBreakdownProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(coachProfileStatsProvider).valueOrNull;
    final live = ref.watch(coachRealtimeProfileProvider).valueOrNull;
    final revenue = ref.watch(coachRevenueBreakdownProvider).valueOrNull;
    final sessions = ref.watch(coachSessionsProvider).valueOrNull ?? const <CoachingSession>[];
    final students = ref.watch(coachStudentsProvider).valueOrNull ?? const <Map<String, dynamic>>[];

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Morning' : (hour < 17 ? 'Afternoon' : 'Evening');
    final first = (profile?.name ?? 'Coach').trim().split(' ').first;
    final name = first.isEmpty ? 'Coach' : first[0].toUpperCase() + first.substring(1);

    final upcoming = [
      for (final s in sessions)
        if (nextOccurrence(s) case final at?) (s, at),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final next = upcoming.firstOrNull;
    final owing = students.where((e) => e['payment_status'] != 'fully_paid').length;
    final available = (profile?.providerStatus ?? 'OFFLINE') == 'AVAILABLE';

    final mpesa = revenue?['MPESA'] ?? 0, cash = revenue?['CASH'] ?? 0, bank = revenue?['BANK'] ?? 0;
    final rating = ((live?['rating'] ?? stats?['rating'] ?? 0) as num).toDouble();

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: Ob.lime,
          onRefresh: _refresh,
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              ObTabHeader('Today', actions: [
                const NotificationBell(color: Ob.cream),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Your profile and settings',
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: ProfileImage(url: profile?.avatarUrl, name: profile?.name ?? 'C', size: 34, isCircle: true),
                  ),
                ),
              ]),
              Text('${DateFormat('EEE d MMM').format(DateTime.now())} · $greeting, $name', style: Ob.body(15, color: Ob.creamA(.6))),
              const SizedBox(height: 16),
              _nextUp(next),
              const SizedBox(height: 22),
              ObGroup(header: 'This week', children: [
                ObRow('Sessions coming up', value: '${upcoming.length}'),
                ObRow('Students', value: '${stats?['students'] ?? students.length}', onTap: () => context.go('/coach/students')),
                ObRow('Collected',
                    subtitle: 'M-Pesa ${_kes.format(mpesa)} · Cash ${_kes.format(cash)} · Bank ${_kes.format(bank)}',
                    value: 'KES ${_kes.format(mpesa + cash + bank)}',
                    onTap: () => context.go('/coach/payments')),
                ObRow('Still owe', value: '$owing', valueColor: owing > 0 ? Ob.warn : null, onTap: () => context.go('/coach/payments')),
                if (rating > 0) ObRow('Rating', value: rating.toStringAsFixed(1)),
              ]),
              const SizedBox(height: 22),
              ObGroup(children: [
                ObRow('Taking bookings',
                    subtitle: available ? 'Players can book you now' : 'Hidden from new bookings',
                    trailing: CupertinoSwitch(
                      value: available,
                      activeTrackColor: Ob.lime,
                      onChanged: (v) => ref.read(supabaseServiceProvider).updateStatus(v ? 'AVAILABLE' : 'OFFLINE'),
                    )),
                ObRow('New session', titleColor: Ob.lime, onTap: () => context.push('/create-session')),
                ObRow('New drill', titleColor: Ob.lime, onTap: () => context.push('/coach/drills/new')),
              ]),
              const SizedBox(height: 22),
              _recent(students),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextUp((CoachingSession, DateTime)? next) {
    if (next == null) {
      return ObGroup(children: [
        ObRow('No sessions coming up', subtitle: 'Create one and players can book it', onTap: () => context.push('/create-session')),
      ]);
    }
    final (s, at) = next;
    final today = DateUtils.isSameDay(at, DateTime.now());
    final when = '${today ? 'Today' : DateFormat('EEE d MMM').format(at)} · ${DateFormat.Hm().format(at)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Next up · $when', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.6))),
        const SizedBox(height: 4),
        Text(s.name, style: Ob.display(24, height: 1.15)),
        Text([if (s.location.isNotEmpty) s.location, '${s.enrollmentCount} of ${s.maxPlayers} booked'].join(' · '), style: Ob.body(15, color: Ob.creamA(.6))),
        const SizedBox(height: 14),
        ObButton(height: 50, radius: 14, onPressed: () => context.push('/coach/session/${s.id}'), child: Text('Open session', style: Ob.label(17))),
      ]),
    );
  }

  Widget _recent(List<Map<String, dynamic>> list) {
    if (ref.watch(coachStudentsProvider).isLoading && list.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(color: Ob.lime));
    }
    if (list.isEmpty) {
      return ObGroup(header: 'New students', children: [ObRow('Nobody yet', subtitle: 'Students show up here when they join a session')]);
    }
    return ObGroup(header: 'New students', children: [
      for (final e in list.take(3))
        ObRow(
          (e['profile'] as Map?)?['name'] ?? 'Golfer',
          subtitle: 'Joined ${e['coaching_sessions']?['name'] ?? 'a session'}',
          leading: ProfileImage(url: (e['profile'] as Map?)?['avatarUrl'], name: (e['profile'] as Map?)?['name'], size: 36, isCircle: true),
          value: e['payment_status'] == 'fully_paid' ? 'Paid' : 'Owes',
          valueColor: e['payment_status'] == 'fully_paid' ? null : Ob.warn,
          onTap: () => context.go('/coach/students'),
        ),
    ]);
  }
}
