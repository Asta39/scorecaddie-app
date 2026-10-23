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
          backgroundColor: Ob.lime,
          onRefresh: () async {
            ref.invalidate(coachDrillTemplatesProvider);
            ref.invalidate(coachAssignmentsProvider);
          },
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              ObTabHeader('Drills', actions: [
                ObIconButton(icon: LucideIcons.plus, label: 'New drill', onPressed: () => context.push('/coach/drills/new')),
              ]),
              Text('${templates.length} drills · ${assigned.length} sent to players', style: Ob.body(15, color: Ob.creamA(.6))),
              const SizedBox(height: 14),
              ObGooSegmented<_View>(
                options: const [(_View.mine, 'My drills'), (_View.assigned, 'Sent')],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
              const SizedBox(height: 16),
              if (async.isLoading && (_view == _View.mine ? templates : assigned).isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (async.hasError && (_view == _View.mine ? templates : assigned).isEmpty)
                const ObGroup(children: [ObRow('Couldn’t load these', subtitle: 'Pull down to try again')])
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
    return [
      ObGroup(children: [
        if (templates.isEmpty) const ObRow('No drills yet', subtitle: 'Build one once, send it to any player'),
        for (final d in templates)
          ObRow(
            '${d['name']}',
            subtitle: [d['category'], d['difficulty'], '${(d['drill_steps'] as List?)?.firstOrNull?['count'] ?? 0} steps'].where((e) => e != null).join(' · '),
            leading: const ObRowIcon(LucideIcons.target, Ob.lime),
            onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => CoachDrillBuilderScreen(drill: d))),
          ),
        ObRow('Make a drill', titleColor: Ob.lime, onTap: () => context.push('/coach/drills/new')),
      ]),
    ];
  }

  List<Widget> _assigned(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return [const ObGroup(children: [ObRow('Nothing sent yet', subtitle: 'Send a drill from a student’s page')])];
    }
    return [
      ObGroup(children: [
        for (final a in list)
          ObRow(
            '${(a['player'] as Map?)?['name'] ?? 'Golfer'}',
            subtitle: '${(a['drill'] as Map?)?['name'] ?? 'Drill'}',
            leading: ProfileImage(url: (a['player'] as Map?)?['avatarUrl'], name: (a['player'] as Map?)?['name'], size: 36, isCircle: true),
            value: _when(a['assigned_at']),
          ),
      ]),
    ];
  }

  String _when(dynamic iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    return d == null ? '' : DateFormat('d MMM').format(d);
  }
}
