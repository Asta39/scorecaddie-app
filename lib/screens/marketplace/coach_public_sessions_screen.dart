import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/models/coaching_model.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../provider/coach_dashboard_screen.dart' show nextOccurrence;

class CoachPublicSessionsScreen extends ConsumerStatefulWidget {
  final String coachId;
  const CoachPublicSessionsScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachPublicSessionsScreen> createState() => _CoachPublicSessionsScreenState();
}

class _CoachPublicSessionsScreenState extends ConsumerState<CoachPublicSessionsScreen> {
  String _kind = 'All';

  @override
  Widget build(BuildContext context) {
    final coach = ref.watch(specificProviderProvider(widget.coachId)).valueOrNull;
    final async = ref.watch(providerSessionsProvider(widget.coachId));
    final mine = ref.watch(playerEnrollmentsProvider).valueOrNull ?? const [];
    // Players only see sessions still open to book.
    final open = (async.valueOrNull ?? const <CoachingSession>[]).where((s) => s.status == 'active' || s.status == 'full').toList();
    final kinds = ['All', ...{for (final s in open) s.sessionType}];
    final shown = open.where((s) => _kind == 'All' || s.sessionType == _kind).toList();
    final first = (coach?.name ?? 'Coach').split(' ').first;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
            children: [
              ObTopBar('$first\'s sessions', onBack: () => context.pop()),
              const SizedBox(height: 16),
              if (kinds.length > 2) ...[
                ObGooSegmented<String>(options: [for (final k in kinds) (k, k)], selected: kinds.contains(_kind) ? _kind : 'All', onChanged: (v) => setState(() => _kind = v), fontSize: 13),
                const SizedBox(height: 14),
              ],
              if (async.isLoading && open.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (shown.isEmpty)
                ObCard(
                  padding: const EdgeInsets.all(18),
                  child: ObGuideRow(botAsset: ObBot.star.idle, botLabel: 'Coach star avatar', text: '$first has nothing open right now. Check back soon.', size: 72, fontSize: 16),
                )
              else
                for (final s in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SessionCard(session: s, coachId: widget.coachId, booked: mine.any((e) => e['session_id'] == s.id)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.coachId, required this.booked});
  final CoachingSession session;
  final String coachId;
  final bool booked;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final next = nextOccurrence(s);
    final left = (s.maxPlayers - s.enrollmentCount).clamp(0, 999);
    final fill = s.maxPlayers == 0 ? 0.0 : (s.enrollmentCount / s.maxPlayers).clamp(0.0, 1.0);
    return ObCard(
      onTap: () => context.push('/marketplace/coach/$coachId/session/${s.id}/book'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ObChip(s.sessionType, on: true),
          const Spacer(),
          Text('KES ${NumberFormat('#,###').format(s.pricePerSession)}', style: Ob.display(20)),
        ]),
        const SizedBox(height: 10),
        Text(s.name, style: Ob.display(22, height: 1.1)),
        const SizedBox(height: 6),
        Text(
          [if (next != null) DateFormat('EEE d MMM · HH:mm').format(next), '${s.weeks} weeks', '${s.durationMinutes} min'].join('  ·  '),
          style: Ob.body(12, color: Ob.creamA(.62)),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: fill, minHeight: 6, backgroundColor: Ob.creamA(.08), color: Ob.lime),
        ),
        const SizedBox(height: 8),
        Text(
          booked ? 'You\'re booked in' : (left == 0 ? 'Full' : '$left ${left == 1 ? 'place' : 'places'} left'),
          style: Ob.body(12, weight: FontWeight.w700, color: booked ? Ob.lime : (left == 0 ? Ob.warn : (left <= 2 ? const Color(0xFFF5C531) : Ob.creamA(.7)))),
        ),
      ]),
    );
  }
}
