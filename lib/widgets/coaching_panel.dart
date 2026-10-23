import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/models/coaching_summary.dart';
import '../core/utils/calendar_helper.dart';
import '../providers/app_providers.dart';
import '../screens/marketplace/caddie_marketplace_screen.dart';
import '../screens/onboarding/ob_app.dart';
import '../screens/onboarding/ob_style.dart';

/// The player's coaching on the You tab: what's next, what's coming, and
/// what's done. A way to find a coach when there's nothing booked.
class CoachingPanel extends ConsumerWidget {
  const CoachingPanel({super.key});

  static String _hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  static String _when(CoachingOccurrenceDetail o) {
    final today = DateUtils.isSameDay(o.date, DateTime.now());
    return '${today ? 'Today' : DateFormat('EEE d MMM').format(o.date)} · ${_hm(o.startTime)}';
  }

  void _findCoach(BuildContext context, WidgetRef ref) {
    ref.read(marketplaceRoleFilterProvider.notifier).state = 'coach';
    context.push('/pros', extra: {'role': 'coach'});
  }

  Widget _addToCalendar(CoachingOccurrenceDetail o) => IconButton(
        tooltip: 'Add to calendar',
        onPressed: () => CalendarHelper.addSessionToCalendar(
          sessionName: o.sessionName,
          location: o.location,
          date: o.date,
          startTime: o.startTime,
          durationMinutes: o.durationMinutes,
        ),
        icon: Icon(LucideIcons.calendarPlus, size: 20, color: Ob.creamA(.6)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerCoachingSummaryStreamProvider);
    final summary = async.valueOrNull;

    if (summary == null) {
      if (async.isLoading) {
        return const Padding(padding: EdgeInsets.all(24), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
      }
      return ObGroup(header: 'Coaching', children: [
        ObRow('Couldn’t load your coaching', subtitle: 'Tap to try again', onTap: () => ref.invalidate(playerCoachingSummaryStreamProvider)),
      ]);
    }

    if (summary.upcoming.isEmpty && summary.past.isEmpty) {
      return ObGroup(header: 'Coaching', children: [
        ObRow('Find a coach',
            subtitle: 'Lessons you book show up here',
            leading: const ObRowIcon(LucideIcons.graduationCap, Ob.lime),
            onTap: () => _findCoach(context, ref)),
      ]);
    }

    final next = summary.nextSession;
    final later = summary.upcoming.where((o) => o.id != next?.id).take(3).toList();
    final sessions = {for (final o in summary.upcoming) o.sessionId}.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (next != null)
        ObGroup(
          header: 'Coaching',
          footer: '${summary.upcoming.length} ${summary.upcoming.length == 1 ? 'date' : 'dates'} booked'
              '${sessions > 1 ? ' across $sessions sessions' : ''}.',
          children: [
            ObRow(
              next.sessionName,
              subtitle: 'Next: ${_when(next)}\nCoach ${next.coachName} · ${next.location}',
              leading: const ObRowIcon(LucideIcons.calendar, Ob.lime),
              trailing: _addToCalendar(next),
              onTap: () => context.push('/coaching/session/${next.sessionId}'),
            ),
            for (final o in later)
              ObRow(_when(o), subtitle: o.sessionId == next.sessionId ? null : o.sessionName, onTap: () => context.push('/coaching/session/${o.sessionId}')),
          ],
        ),
      if (summary.past.isNotEmpty) ...[
        const SizedBox(height: 22),
        ObGroup(header: 'Done', children: [
          for (final o in summary.past.take(3))
            ObRow(
              o.sessionName,
              subtitle: '${DateFormat('EEE d MMM').format(o.date)} · Coach ${o.coachName}',
              value: switch (o.attended) { true => 'Attended', false => 'Missed', null => null },
              valueColor: o.attended == false ? Ob.warn : null,
              onTap: () => context.push('/coaching/session/${o.sessionId}'),
            ),
        ]),
      ],
      const SizedBox(height: 22),
      ObGroup(children: [ObRow('Find another coach', titleColor: Ob.lime, onTap: () => _findCoach(context, ref))]),
    ]);
  }
}
