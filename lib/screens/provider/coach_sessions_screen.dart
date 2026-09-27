import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'coach_dashboard_screen.dart' show coachGold, nextOccurrence;

enum _Filter { active, past, cancelled }

class CoachSessionsScreen extends ConsumerStatefulWidget {
  const CoachSessionsScreen({super.key});

  @override
  ConsumerState<CoachSessionsScreen> createState() => _CoachSessionsScreenState();
}

class _CoachSessionsScreenState extends ConsumerState<CoachSessionsScreen> {
  _Filter _filter = _Filter.active;

  bool _matches(CoachingSession s) => switch (_filter) {
        _Filter.active => s.status == 'active' || s.status == 'full',
        _Filter.past => s.status == 'completed',
        _Filter.cancelled => s.status == 'cancelled',
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachSessionsProvider);
    final sessions = async.valueOrNull ?? const <CoachingSession>[];
    final active = sessions.where((s) => s.status == 'active' || s.status == 'full').toList();
    final seats = active.fold(0, (a, s) => a + s.maxPlayers);
    final taken = active.fold(0, (a, s) => a + s.enrollmentCount);
    final shown = sessions.where(_matches).toList()
      ..sort((a, b) => (nextOccurrence(a) ?? a.startDate).compareTo(nextOccurrence(b) ?? b.startDate));

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: coachGold,
          onRefresh: () async => ref.invalidate(coachSessionsProvider),
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              ObTabHeader('Sessions', actions: [
                ObIconButton(icon: LucideIcons.plus, label: 'New session', onPressed: () => context.push('/create-session')),
              ]).rise(),
              const SizedBox(height: 16),
              ObSplitCards(
                left: ObStat('Running', '${active.length}', valueColor: coachGold),
                right: ObStat('Seats filled', '$taken/$seats'),
              ).rise(1),
              const SizedBox(height: 16),
              ObGooSegmented<_Filter>(
                options: const [(_Filter.active, 'Active'), (_Filter.past, 'Past'), (_Filter.cancelled, 'Cancelled')],
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
                accent: coachGold,
              ).rise(2),
              const SizedBox(height: 16),
              if (async.isLoading && sessions.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: coachGold)))
              else if (async.hasError && sessions.isEmpty)
                ObCard(child: Text('Couldn\'t load your sessions. Pull down to try again.', style: Ob.body(14, color: Ob.creamA(.7))))
              else if (shown.isEmpty)
                _empty()
              else
                for (final s in shown) Padding(padding: const EdgeInsets.only(bottom: 12), child: _SessionCard(session: s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final text = switch (_filter) {
      _Filter.active => 'No sessions running. Create one and players can book it.',
      _Filter.past => 'Finished programmes land here.',
      _Filter.cancelled => 'Nothing cancelled.',
    };
    return ObCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ObGuideRow(botAsset: ObBot.star.idle, botLabel: 'Your star avatar', text: text, size: 72, fontSize: 16),
        if (_filter == _Filter.active) ...[
          const SizedBox(height: 16),
          ObButton(
            onPressed: () => context.push('/create-session'),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.plus, size: 18, color: Ob.ink),
              const SizedBox(width: 8),
              Text('New session', style: Ob.label(15, weight: FontWeight.w800)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final CoachingSession session;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final s = session;
    final next = nextOccurrence(s);
    final fill = s.maxPlayers == 0 ? 0.0 : (s.enrollmentCount / s.maxPlayers).clamp(0.0, 1.0);
    final (label, color) = switch (s.status) {
      'full' => ('Full', coachGold),
      'completed' => ('Past', Ob.creamA(.6)),
      'cancelled' => ('Cancelled', Ob.warn),
      _ => (s.sessionType, Ob.lime),
    };
    final when = next != null
        ? DateFormat('EEE d MMM · HH:mm').format(next)
        : '${s.daysOfWeek.where((d) => d >= 1 && d <= 7).map((d) => _days[d - 1]).join(', ')} · ${s.startTime.length >= 5 ? s.startTime.substring(0, 5) : s.startTime}';

    return ObCard(
      onTap: () => context.push('/coach/session/${s.id}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ObChip(label, on: true, color: color),
          const Spacer(),
          Text(when, style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.6))),
        ]),
        const SizedBox(height: 10),
        Text(s.name, style: Ob.display(22, height: 1.1)),
        if (s.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            Icon(LucideIcons.mapPin, size: 12, color: Ob.creamA(.5)),
            const SizedBox(width: 4),
            Expanded(child: Text(s.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.55)))),
          ]),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: fill, minHeight: 8, backgroundColor: Ob.creamA(.08), color: coachGold),
            ),
          ),
          const SizedBox(width: 12),
          Text('${s.enrollmentCount}/${s.maxPlayers}', style: Ob.display(17)),
        ]),
        const SizedBox(height: 8),
        Text('KES ${NumberFormat('#,###').format(s.pricePerSession)} a session · ${s.weeks} weeks', style: Ob.body(12, color: Ob.creamA(.6))),
      ]),
    );
  }
}
