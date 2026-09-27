import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/coaching_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

/// The coach's colour: the star's gold.
const coachGold = Color(0xFFF5C531);

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

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: coachGold,
          onRefresh: _refresh,
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              ObTabHeader('$greeting, $name', actions: [_bell()]).rise(),
              const SizedBox(height: 14),
              ObGuideRow(botAsset: ObBot.star.happy, botLabel: 'Your star avatar, smiling', text: _nudge(next, owing)).rise(1),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => ref.read(supabaseServiceProvider).updateStatus(available ? 'OFFLINE' : 'AVAILABLE'),
                child: Row(children: [
                  ObChip(available ? 'Taking bookings' : 'Not taking bookings', on: available, color: coachGold),
                  const SizedBox(width: 8),
                  Text('Tap to switch', style: Ob.body(12, color: Ob.creamA(.5))),
                ]),
              ).rise(1),
              const SizedBox(height: 14),
              _nextUp(next).rise(2),
              const SizedBox(height: 14),
              _actions().rise(3),
              const SizedBox(height: 14),
              ObSplitCards(
                left: ObStat('Rating', ((live?['rating'] ?? stats?['rating'] ?? 0) as num).toStringAsFixed(1), valueColor: coachGold),
                right: ObStat('Students', '${stats?['students'] ?? students.length}'),
              ),
              const SizedBox(height: 14),
              _revenue(revenue),
              const SizedBox(height: 24),
              ObEyebrow('Recent students', action: 'See all', onAction: () => context.go('/coach/students')),
              const SizedBox(height: 10),
              _recent(students),
            ],
          ),
        ),
      ),
    );
  }

  String _nudge((CoachingSession, DateTime)? next, int owing) {
    if (next == null) return 'Nothing booked yet. Set up a session and I\'ll keep the roll.';
    final (s, at) = next;
    final today = DateUtils.isSameDay(at, DateTime.now());
    final when = today ? 'at ${DateFormat.Hm().format(at)}' : DateFormat('EEE').format(at);
    final owes = owing == 0 ? 'Everyone\'s paid up.' : '$owing still ${owing == 1 ? 'owes' : 'owe'}.';
    return '${s.name} $when. $owes';
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

  Widget _nextUp((CoachingSession, DateTime)? next) {
    if (next == null) {
      return ObCard(
        onTap: () => context.push('/create-session'),
        child: Row(children: [
          const Icon(LucideIcons.calendarPlus, color: coachGold),
          const SizedBox(width: 12),
          Expanded(child: Text('No sessions coming up. Create one.', style: Ob.body(14, weight: FontWeight.w700))),
          Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
        ]),
      );
    }
    final (s, at) = next;
    final today = DateUtils.isSameDay(at, DateTime.now());
    final when = '${today ? 'TODAY' : DateFormat('EEE d MMM').format(at).toUpperCase()} · ${DateFormat.Hm().format(at)}';
    final fill = s.maxPlayers == 0 ? 0.0 : (s.enrollmentCount / s.maxPlayers).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => context.push('/coach/session/${s.id}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF2A2410), borderRadius: BorderRadius.circular(28), border: Border.all(color: coachGold, width: 2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('NEXT UP · $when', style: Ob.body(12, weight: FontWeight.w800, color: coachGold).copyWith(letterSpacing: 1.6))),
            ObChip(s.sessionType == 'private' ? 'Private' : 'Group'),
          ]),
          const SizedBox(height: 8),
          Text(s.name, style: Ob.display(26, height: 1.05)),
          if (s.location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(s.location, style: Ob.body(13, color: Ob.creamA(.6))),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: fill, minHeight: 8, backgroundColor: Ob.creamA(.08), color: coachGold),
              ),
            ),
            const SizedBox(width: 12),
            Text('${s.enrollmentCount} of ${s.maxPlayers}', style: Ob.body(13, weight: FontWeight.w700)),
            const SizedBox(width: 12),
            Text('Open →', style: Ob.body(13, weight: FontWeight.w800, color: coachGold)),
          ]),
        ]),
      ),
    );
  }

  Widget _actions() {
    Widget tile(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: ObCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 14),
            radius: 20,
            child: Column(children: [
              Icon(icon, size: 20, color: coachGold),
              const SizedBox(height: 6),
              Text(label, style: Ob.body(13, weight: FontWeight.w800)),
            ]),
          ),
        );
    return Row(children: [
      tile(LucideIcons.plus, 'New session', () => context.push('/create-session')),
      const SizedBox(width: 8),
      tile(LucideIcons.target, 'New drill', () => context.push('/coach/drills/new')),
      const SizedBox(width: 8),
      tile(LucideIcons.wallet, 'Payments', () => context.go('/coach/payments')),
    ]);
  }

  Widget _revenue(Map<String, double>? rev) {
    final mpesa = rev?['MPESA'] ?? 0, cash = rev?['CASH'] ?? 0, bank = rev?['BANK'] ?? 0;
    final total = mpesa + cash + bank;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(26), border: Border.all(color: Ob.lime.withValues(alpha: .2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ObEyebrow('Collected'),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('KES ', style: Ob.body(15, weight: FontWeight.w700, color: Ob.creamA(.6))),
          Text(_kes.format(total), style: Ob.display(44, height: 1)),
        ]),
        const SizedBox(height: 12),
        if (total > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 14,
              child: Row(children: [
                if (mpesa > 0) Expanded(flex: (mpesa * 100 ~/ total).clamp(1, 100), child: Container(color: Ob.lime)),
                if (cash > 0) Expanded(flex: (cash * 100 ~/ total).clamp(1, 100), child: Container(color: coachGold)),
                if (bank > 0) Expanded(flex: (bank * 100 ~/ total).clamp(1, 100), child: Container(color: const Color(0xFF7DD3FC))),
              ]),
            ),
          )
        else
          Container(height: 14, decoration: BoxDecoration(color: Ob.creamA(.08), borderRadius: BorderRadius.circular(7))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('M-Pesa ${_kes.format(mpesa)}', style: Ob.body(12, weight: FontWeight.w700, color: Ob.lime)),
          Text('Cash ${_kes.format(cash)}', style: Ob.body(12, weight: FontWeight.w700, color: coachGold)),
          Text('Bank ${_kes.format(bank)}', style: Ob.body(12, weight: FontWeight.w700, color: const Color(0xFF7DD3FC))),
        ]),
      ]),
    );
  }

  Widget _recent(List<Map<String, dynamic>> list) {
    if (ref.watch(coachStudentsProvider).isLoading && list.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(color: coachGold));
    }
    if (list.isEmpty) {
      return ObCard(child: Text('Students show up here when they join a session.', style: Ob.body(13, color: Ob.creamA(.6))));
    }
    return ObCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        for (final (i, e) in list.take(3).indexed) ...[
          if (i > 0) const ObHair(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(children: [
              ProfileImage(url: (e['profile'] as Map?)?['avatarUrl'], name: (e['profile'] as Map?)?['name'], size: 36, isCircle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((e['profile'] as Map?)?['name'] ?? 'Golfer', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w700)),
                  Text('Joined ${e['coaching_sessions']?['name'] ?? 'a session'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.55))),
                ]),
              ),
              e['payment_status'] == 'fully_paid'
                  ? Text('Paid', style: Ob.body(13, weight: FontWeight.w800, color: Ob.lime))
                  : Text('Owes', style: Ob.body(13, weight: FontWeight.w800, color: coachGold)),
            ]),
          ),
        ],
      ]),
    );
  }
}
