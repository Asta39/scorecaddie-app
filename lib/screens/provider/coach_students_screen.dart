import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import 'coach_dashboard_screen.dart' show coachGold;

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
          backgroundColor: coachGold,
          onRefresh: () async => ref.invalidate(coachStudentsProvider),
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              const ObTabHeader('Students').rise(),
              const SizedBox(height: 16),
              ObSplitCards(
                left: ObStat('Students', '${all.length}', valueColor: coachGold),
                right: ObStat('Still owe', '$owing'),
              ).rise(1),
              const SizedBox(height: 14),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Icon(LucideIcons.search, size: 18, color: Ob.creamA(.5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      cursorColor: coachGold,
                      style: Ob.body(15, weight: FontWeight.w600),
                      decoration: InputDecoration(border: InputBorder.none, isDense: true, hintText: 'Search by name', hintStyle: Ob.body(14, color: Ob.creamA(.4))),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                for (final (v, l) in const [(_Show.all, 'All'), (_Show.owing, 'Owe'), (_Show.paid, 'Paid up')]) ...[
                  GestureDetector(onTap: () => setState(() => _show = v), child: ObChip(l, on: _show == v, color: coachGold)),
                  const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 16),
              if (async.isLoading && all.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: coachGold)))
              else if (async.hasError && all.isEmpty)
                ObCard(child: Text('Couldn\'t load your students. Pull down to try again.', style: Ob.body(14, color: Ob.creamA(.7))))
              else if (all.isEmpty)
                const ObCard(
                  padding: EdgeInsets.all(20),
                  child: ObGuideRow(botAsset: 'assets/bots/star_idle.webp', botLabel: 'Your star avatar', text: 'Players who book your sessions show up here.', size: 72, fontSize: 16),
                )
              else if (shown.isEmpty)
                ObCard(child: Text('Nobody matches that.', style: Ob.body(14, color: Ob.creamA(.6))))
              else
                for (final s in shown) Padding(padding: const EdgeInsets.only(bottom: 10), child: _StudentCard(student: s)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});
  final _Student student;

  @override
  Widget build(BuildContext context) {
    final s = student;
    return ObCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProfileImage(url: s.avatar, name: s.name, size: 46, isCircle: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(16, weight: FontWeight.w800)),
              Text(s.sessions.isEmpty ? 'Coaching' : s.sessions.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          Text(s.owes ? 'Owes' : 'Paid', style: Ob.body(13, weight: FontWeight.w800, color: s.owes ? coachGold : Ob.lime)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: ObButton(
              tone: ObButtonTone.dark,
              height: 42,
              onPressed: () => context.push('/chat/${s.id}'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.messageCircle, size: 16, color: Ob.cream),
                const SizedBox(width: 6),
                Text('Message', style: Ob.label(14, weight: FontWeight.w800)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ObButton(
              height: 42,
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AssignDrillSheet(playerId: s.id, playerName: s.name),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.target, size: 16, color: Ob.ink),
                const SizedBox(width: 6),
                Text('Assign drill', style: Ob.label(14, weight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ]),
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
    return Container(
      height: MediaQuery.of(context).size.height * .75,
      decoration: const BoxDecoration(color: Ob.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: DefaultTextStyle(
        style: Ob.textBase,
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Ob.creamA(.2), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Assign a drill', style: Ob.display(26)),
                  Text('For ${widget.playerName}', style: Ob.body(13, color: Ob.creamA(.6))),
                ]),
              ),
              ObIconButton(icon: LucideIcons.x, label: 'Close', onPressed: () => Navigator.pop(context)),
            ]),
          ),
          Expanded(
            child: async.isLoading && drills.isEmpty
                ? const Center(child: CupertinoActivityIndicator(color: coachGold))
                : drills.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('You haven\'t made any drills yet.', style: Ob.body(15, color: Ob.creamA(.7))),
                          const SizedBox(height: 14),
                          ObButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/coach/drills/new');
                            },
                            child: Text('Make a drill', style: Ob.label(15, weight: FontWeight.w800)),
                          ),
                        ]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                        itemCount: drills.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d = drills[i];
                          final busy = _busyId == d['id'].toString();
                          return ObCard(
                            onTap: _busyId == null ? () => _assign(d) : null,
                            child: Row(children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(color: coachGold.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(LucideIcons.target, color: coachGold, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${d['name']}', style: Ob.body(15, weight: FontWeight.w800)),
                                  Text('${d['category'] ?? ''}', style: Ob.body(12, color: Ob.creamA(.55))),
                                ]),
                              ),
                              busy
                                  ? const CupertinoActivityIndicator(color: coachGold)
                                  : Text('Send', style: Ob.body(14, weight: FontWeight.w800, color: coachGold)),
                            ]),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
