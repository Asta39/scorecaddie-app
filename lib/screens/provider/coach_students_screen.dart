import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/coaching_notes.dart';
import '../../core/utils/url_helper.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_forms.dart';
import '../social/player_profile_screen.dart' show publicProfileProvider, publicProfileStatsProvider;

enum _Show { all, owing, paid }

/// One player across however many of the coach's sessions they've joined.
class _Student {
  _Student(this.id, this.name, this.avatar);
  final String id;
  final String name;
  final String? avatar;
  final sessions = <String>[];
  bool owes = false;
}

List<_Student> _group(List<Map<String, dynamic>> enrollments) {
  final byId = <String, _Student>{};
  for (final e in enrollments) {
    final p = e['profile'] as Map?;
    final id = (p?['id'] ?? e['player_id'] ?? '').toString();
    if (id.isEmpty) continue;
    final s = byId.putIfAbsent(id, () => _Student(id, (p?['name'] ?? 'Golfer').toString(), p?['avatarUrl'] as String?));
    final session = (e['coaching_sessions'] as Map?)?['name'];
    if (session != null && !s.sessions.contains(session)) s.sessions.add(session.toString());
    if (e['payment_status'] != 'fully_paid') s.owes = true;
  }
  return byId.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

class CoachStudentsScreen extends ConsumerStatefulWidget {
  const CoachStudentsScreen({super.key});

  @override
  ConsumerState<CoachStudentsScreen> createState() => _CoachStudentsScreenState();
}

class _CoachStudentsScreenState extends ConsumerState<CoachStudentsScreen> {
  String _query = '';
  _Show _show = _Show.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachStudentsProvider);
    final all = _group(async.valueOrNull ?? const []);
    final owing = all.where((s) => s.owes).length;
    final shown = all.where((s) {
      if (_query.isNotEmpty && !s.name.toLowerCase().contains(_query.toLowerCase())) return false;
      return switch (_show) { _Show.all => true, _Show.owing => s.owes, _Show.paid => !s.owes };
    }).toList();

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: RefreshIndicator(
          color: Ob.ink,
          backgroundColor: Ob.lime,
          onRefresh: () async => ref.invalidate(coachStudentsProvider),
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              const ObTabHeader('Students'),
              if (all.isNotEmpty) Text('${all.length} students · $owing still owe', style: Ob.body(15, color: Ob.creamA(.6))),
              const SizedBox(height: 12),
              CupertinoSearchTextField(
                placeholder: 'Search',
                onChanged: (v) => setState(() => _query = v),
                style: Ob.body(17),
              ),
              const SizedBox(height: 12),
              ObGooSegmented<_Show>(
                options: const [(_Show.all, 'All'), (_Show.owing, 'Owe'), (_Show.paid, 'Paid up')],
                selected: _show,
                onChanged: (v) => setState(() => _show = v),
              ),
              const SizedBox(height: 16),
              if (async.isLoading && all.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (async.hasError && all.isEmpty)
                const ObGroup(children: [ObRow('Couldn’t load your students', subtitle: 'Pull down to try again')])
              else if (all.isEmpty)
                const ObGroup(children: [ObRow('No students yet', subtitle: 'Players who book your sessions show up here')])
              else if (shown.isEmpty)
                const ObGroup(children: [ObRow('Nobody matches that')])
              else
                ObGroup(children: [
                  for (final s in shown)
                    ObRow(
                      s.name,
                      subtitle: s.sessions.isEmpty ? 'Coaching' : s.sessions.join(' · '),
                      leading: ProfileImage(url: s.avatar, name: s.name, size: 36, isCircle: true),
                      value: s.owes ? 'Owes' : null,
                      valueColor: Ob.warn,
                      onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => _StudentScreen(student: s))),
                    ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// One student: their game, their sessions, and the two things a coach does.
class _StudentScreen extends ConsumerWidget {
  const _StudentScreen({required this.student});
  final _Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = student;
    final profile = ref.watch(publicProfileProvider(s.id)).valueOrNull;
    final stats = ref.watch(publicProfileStatsProvider(s.id)).valueOrNull;
    final hcp = (profile?['handicapIndex'] as num?)?.toDouble();
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
            children: [
              ObTopBar('Students', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 14),
              Row(children: [
                ProfileImage(url: s.avatar, name: s.name, size: 60, isCircle: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(22, height: 1.15)),
                    Text(
                      [if (hcp != null) 'HI ${hcp.toStringAsFixed(1)}', if (stats?['homeCourse'] != null) '${stats!['homeCourse']}'].join(' · '),
                      style: Ob.body(15, color: Ob.creamA(.6)),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: ObButton(
                    height: 50,
                    radius: 14,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _AssignDrillSheet(playerId: s.id, playerName: s.name),
                    ),
                    child: Text('Assign drill', style: Ob.label(17)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ObButton(
                    height: 50,
                    radius: 14,
                    tone: ObButtonTone.light,
                    onPressed: (profile?['phone'] ?? '').toString().isEmpty ? null : () => UrlHelper.launchCaller('${profile!['phone']}'),
                    child: Text('Call', style: Ob.body(17, weight: FontWeight.w600)),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              ObGroup(header: 'Game', children: [
                ObRow('Handicap', value: hcp?.toStringAsFixed(1) ?? '—'),
                ObRow('Rounds played', value: '${stats?['totalRounds'] ?? 0}'),
                ObRow('Average score', value: stats?['avgScore']?.toString() ?? '—'),
                ObRow('Best score', value: stats?['bestScore']?.toString() ?? '—'),
              ]),
              const SizedBox(height: 22),
              CoachingNotes(
                coachId: ref.watch(authStateProvider).valueOrNull?.id ?? '',
                playerId: s.id,
                otherName: s.name.split(' ').first,
              ),
              const SizedBox(height: 22),
              ObGroup(header: 'With you', children: [
                for (final name in s.sessions) ObRow(name),
                ObRow('Payment', value: s.owes ? 'Owes' : 'Paid up', valueColor: s.owes ? Ob.warn : null),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignDrillSheet extends ConsumerStatefulWidget {
  const _AssignDrillSheet({required this.playerId, required this.playerName});
  final String playerId;
  final String playerName;

  @override
  ConsumerState<_AssignDrillSheet> createState() => _AssignDrillSheetState();
}

class _AssignDrillSheetState extends ConsumerState<_AssignDrillSheet> {
  String? _busyId;

  Future<void> _assign(Map<String, dynamic> drill) async {
    setState(() => _busyId = drill['id'].toString());
    try {
      await ref.read(coachingServiceProvider).assignDrillToPlayer(drillId: drill['id'], playerId: widget.playerId);
      ref.invalidate(coachAssignmentsProvider);
      if (!mounted) return;
      Navigator.pop(context);
      TopNotification.showSuccess(context, '${drill['name']} sent to ${widget.playerName.split(' ').first}');
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t assign the drill: $e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachDrillTemplatesProvider);
    final drills = async.valueOrNull ?? const <Map<String, dynamic>>[];
    return ObSheet(
      title: 'Assign a drill',
      subtitle: 'For ${widget.playerName}',
      height: MediaQuery.of(context).size.height * .75,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: async.isLoading && drills.isEmpty
          ? const Center(child: CupertinoActivityIndicator(color: Ob.lime))
          : ListView(children: [
              ObGroup(children: [
                if (drills.isEmpty) const ObRow('You haven’t made any drills yet'),
                for (final d in drills)
                  ObRow(
                    '${d['name']}',
                    subtitle: '${d['category'] ?? ''}',
                    trailing: _busyId == d['id'].toString()
                        ? const CupertinoActivityIndicator(color: Ob.lime)
                        : Text('Send', style: Ob.body(17, weight: FontWeight.w600, color: Ob.lime)),
                    onTap: _busyId == null ? () => _assign(d) : null,
                  ),
                ObRow('Make a drill', titleColor: Ob.lime, onTap: () {
                  Navigator.pop(context);
                  context.push('/coach/drills/new');
                }),
              ]),
            ]),
    );
  }
}
