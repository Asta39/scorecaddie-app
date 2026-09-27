import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'coach_dashboard_screen.dart' show coachGold;
import 'coach_drill_builder_screen.dart';

enum _View { mine, assigned }

class CoachDrillsScreen extends ConsumerStatefulWidget {
  const CoachDrillsScreen({super.key});

  @override
  ConsumerState<CoachDrillsScreen> createState() => _CoachDrillsScreenState();
}

class _CoachDrillsScreenState extends ConsumerState<CoachDrillsScreen> {
  _View _view = _View.mine;

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(coachDrillTemplatesProvider);
    final assignedAsync = ref.watch(coachAssignmentsProvider);
    final templates = templatesAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final assigned = assignedAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final async = _view == _View.mine ? templatesAsync : assignedAsync;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: coachGold,
          onRefresh: () async {
            ref.invalidate(coachDrillTemplatesProvider);
            ref.invalidate(coachAssignmentsProvider);
          },
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              ObTabHeader('Drills', actions: [
                ObIconButton(icon: LucideIcons.plus, label: 'New drill', onPressed: () => context.push('/coach/drills/new')),
              ]).rise(),
              const SizedBox(height: 16),
              ObSplitCards(
                left: ObStat('Your drills', '${templates.length}', valueColor: coachGold),
                right: ObStat('Sent to players', '${assigned.length}'),
              ).rise(1),
              const SizedBox(height: 16),
              ObGooSegmented<_View>(
                options: const [(_View.mine, 'My drills'), (_View.assigned, 'Assigned')],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
                accent: coachGold,
              ).rise(2),
              const SizedBox(height: 16),
              if (async.isLoading && (_view == _View.mine ? templates : assigned).isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: coachGold)))
              else if (async.hasError && (_view == _View.mine ? templates : assigned).isEmpty)
                ObCard(child: Text('Couldn\'t load these. Pull down to try again.', style: Ob.body(14, color: Ob.creamA(.7))))
              else if (_view == _View.mine)
                ..._mine(templates)
              else
                ..._assigned(assigned),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _mine(List<Map<String, dynamic>> templates) {
    if (templates.isEmpty) {
      return [
        ObCard(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ObGuideRow(botAsset: ObBot.star.idle, botLabel: 'Your star avatar', text: 'Build a drill once, send it to any player.', size: 72, fontSize: 16),
            const SizedBox(height: 16),
            ObButton(
              onPressed: () => context.push('/coach/drills/new'),
              child: Text('Make a drill', style: Ob.label(15, weight: FontWeight.w800)),
            ),
          ]),
        ),
      ];
    }
    return [
      for (final d in templates)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ObCard(
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => CoachDrillBuilderScreen(drill: d))),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: coachGold.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                child: const Icon(LucideIcons.target, color: coachGold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d['name']}', style: Ob.body(16, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    [d['category'], d['difficulty'], '${(d['drill_steps'] as List?)?.firstOrNull?['count'] ?? 0} steps'].where((e) => e != null).join(' · '),
                    style: Ob.body(12, color: Ob.creamA(.55)),
                  ),
                ]),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
            ]),
          ),
        ),
    ];
  }

  List<Widget> _assigned(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return [ObCard(child: Text('Drills you send from a student\'s card land here.', style: Ob.body(14, color: Ob.creamA(.6))))];
    }
    return [
      ObCard(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (final (i, a) in list.indexed) ...[
            if (i > 0) const ObHair(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(children: [
                ProfileImage(url: (a['player'] as Map?)?['avatarUrl'], name: (a['player'] as Map?)?['name'], size: 38, isCircle: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${(a['player'] as Map?)?['name'] ?? 'Golfer'}', style: Ob.body(14, weight: FontWeight.w700)),
                    Text('${(a['drill'] as Map?)?['name'] ?? 'Drill'}', style: Ob.body(12, weight: FontWeight.w700, color: coachGold)),
                  ]),
                ),
                Text(_when(a['assigned_at']), style: Ob.body(12, color: Ob.creamA(.5))),
              ]),
            ),
          ],
        ]),
      ),
    ];
  }

  String _when(dynamic iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    return d == null ? '' : DateFormat('d MMM').format(d);
  }
}
