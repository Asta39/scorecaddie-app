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
import 'coach_dashboard_screen.dart' show nextOccurrence;

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
          backgroundColor: Ob.lime,
          onRefresh: () async => ref.invalidate(coachSessionsProvider),
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              ObTabHeader('Sessions', actions: [
                ObIconButton(icon: LucideIcons.plus, label: 'New session', onPressed: () => context.push('/create-session')),
              ]),
              if (active.isNotEmpty) Text('${active.length} running · $taken of $seats seats filled', style: Ob.body(15, color: Ob.creamA(.6))),
              const SizedBox(height: 14),
              ObGooSegmented<_Filter>(
                options: const [(_Filter.active, 'Running'), (_Filter.past, 'Past'), (_Filter.cancelled, 'Cancelled')],
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 16),
              if (async.isLoading && sessions.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (async.hasError && sessions.isEmpty)
                ObGroup(children: [ObRow('Couldn’t load your sessions', subtitle: 'Pull down to try again')])
              else if (shown.isEmpty)
                ObGroup(children: [
                  ObRow(switch (_filter) {
                    _Filter.active => 'No sessions running',
                    _Filter.past => 'No finished sessions yet',
                    _Filter.cancelled => 'Nothing cancelled',
                  }),
                  if (_filter == _Filter.active) ObRow('New session', titleColor: Ob.lime, onTap: () => context.push('/create-session')),
                ])
              else
                ObGroup(children: [for (final s in shown) _row(context, s)]),
            ],
          ),
        ),
      ),
    );
  }

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _row(BuildContext context, CoachingSession s) {
    final next = nextOccurrence(s);
    final when = next != null
        ? DateFormat('EEE d MMM · HH:mm').format(next)
        : '${s.daysOfWeek.where((d) => d >= 1 && d <= 7).map((d) => _days[d - 1]).join(', ')} · ${s.startTime.length >= 5 ? s.startTime.substring(0, 5) : s.startTime}';
    return ObRow(
      s.name,
      subtitle: [when, if (s.location.isNotEmpty) s.location, 'KES ${NumberFormat('#,###').format(s.pricePerSession)}'].join(' · '),
      value: s.status == 'full' ? 'Full' : '${s.enrollmentCount}/${s.maxPlayers}',
      valueColor: s.status == 'cancelled' ? Ob.warn : null,
      onTap: () => context.push('/coach/session/${s.id}'),
    );
  }
}
