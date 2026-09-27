import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../widgets/voice_beam.dart';
import '../../widgets/voice_orb_visualizer.dart' show OrbState;
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart' as db_pkg;

class PracticeRangeScreen extends ConsumerWidget {
  const PracticeRangeScreen({super.key});

  Future<void> _startSession(BuildContext context, WidgetRef ref, String type, {int? drillId, String? coachDrillId, int? targetDistance}) async {
    _showLoggingChoice(context, ref, (isVoice) => _createSession(context, ref, type, isVoice: isVoice, drillId: drillId, coachDrillId: coachDrillId, targetDistance: targetDistance));
  }

  Future<void> _createSession(BuildContext context, WidgetRef ref, String type, {required bool isVoice, int? drillId, String? coachDrillId, int? targetDistance}) async {
    {
      final database = ref.read(databaseProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      final syncService = ref.read(syncServiceProvider);

      if (user == null) return;
      final supabaseId = const Uuid().v4();

      // 1. Local Insert
      final sessionId = await database.into(database.practiceSessions).insert(
        db_pkg.PracticeSessionsCompanion.insert(
          userId: user.uid,
          supabaseId: drift.Value(supabaseId),
          startTime: drift.Value(DateTime.now()),
          sessionType: drift.Value(type),
          drillId: drift.Value(drillId),
          coachDrillId: drift.Value(coachDrillId),
          targetDistance: drift.Value(targetDistance),
        ),
      );

      // 2. Instant Sync
      final fullSession = await (database.select(database.practiceSessions)..where((s) => s.id.equals(sessionId))).get().then((list) => list.firstOrNull);
      if (fullSession != null) {
        syncService.syncPracticeSession(fullSession).catchError((e) => debugPrint('Sync error: $e'));
      }

      // 3. Navigate based on choice
      if (context.mounted) {
        context.push('/practice/session/$sessionId?isVoice=$isVoice');
      }
    }
  }

  /// Voice with Daniel, or typing each shot: asked before a drill starts.
  void _showLoggingChoice(BuildContext context, WidgetRef ref, Function(bool isVoice) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1A12),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0x40A3E635))),
        ),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 16),
              ObGuideRow(botAsset: ObBot.clover.idle, botLabel: 'Daniel the clover', text: 'How do you want to log shots?', size: 80, fontSize: 18),
              const SizedBox(height: 16),
              ObButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  onSelected(true);
                },
                height: 56,
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.mic, size: 18), const SizedBox(width: 8), Text('Talk to Daniel', style: Ob.label(16, weight: FontWeight.w800))]),
              ),
              const SizedBox(height: 10),
              ObButton(
                tone: ObButtonTone.dark,
                onPressed: () {
                  Navigator.pop(sheet);
                  onSelected(false);
                },
                height: 56,
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.penLine, size: 18), const SizedBox(width: 8), Text('Type each shot', style: Ob.label(16, weight: FontWeight.w800))]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Free practice straight from the Daniel card: no need to ask how.
  Future<void> _startFree(BuildContext context, WidgetRef ref, {required bool voice}) =>
      _createSession(context, ref, 'FREE', isVoice: voice);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            ObTabHeader('Practice', actions: [
              ObIconButton(icon: LucideIcons.chartColumn, label: 'Practice stats', onPressed: () => context.push('/practice/analytics')),
              ObIconButton(icon: LucideIcons.plus, label: 'Build a drill', onPressed: () => context.push('/practice/drills/new')),
            ]).rise(),
            const SizedBox(height: 16),
            _danielCard(context, ref).rise(1),
            ref.watch(assignedDrillsProvider).when(
                  data: (assigned) => assigned.isEmpty
                      ? const SizedBox.shrink()
                      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          const SizedBox(height: 24),
                          const ObEyebrow('From your coach'),
                          const SizedBox(height: 12),
                          for (final a in assigned)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _assignedCard(context, ref, a['drill'] as Map<String, dynamic>, (a['coach']?['name'] as String?) ?? 'Your coach'),
                            ),
                        ]),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
            const SizedBox(height: 24),
            const ObEyebrow('Drills for you'),
            const SizedBox(height: 12),
            StreamBuilder<List<Drill>>(
              stream: (db.select(db.drills)..where((d) => d.userId.isNull() | d.userId.equals(user?.uid ?? ''))).watch(),
              builder: (context, snapshot) {
                final drills = snapshot.data ?? const <Drill>[];
                return SizedBox(
                  height: 176,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      for (final d in drills) Padding(padding: const EdgeInsets.only(right: 12), child: _drillCard(context, ref, d)),
                      _buildOwn(context),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const ObEyebrow('Recent sessions'),
            const SizedBox(height: 12),
            _buildRecentSessions(db, user?.uid, context),
          ],
        ),
      ),
    );
  }

  Widget _danielCard(BuildContext context, WidgetRef ref) {
    return ObHeroCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObGuideRow(botAsset: ObBot.clover.idle, botLabel: 'Daniel the clover', text: 'Tell me every shot. I’ll keep the count.', size: 92, fontSize: 18, maxBubble: 226),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(height: 60, color: Ob.bg.withValues(alpha: .55), child: const ExcludeSemantics(child: VoiceBeam(state: OrbState.idle, scale: .6))),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 13,
              child: ObButton(
                onPressed: () => _startFree(context, ref, voice: true),
                height: 52,
                padding: EdgeInsets.zero,
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.mic, size: 18), const SizedBox(width: 8), Text('Talk to Daniel', style: Ob.label(16, weight: FontWeight.w800))]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 10,
              child: ObButton(
                tone: ObButtonTone.dark,
                onPressed: () => _startFree(context, ref, voice: false),
                height: 52,
                padding: EdgeInsets.zero,
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.penLine, size: 17), const SizedBox(width: 8), Text('Type it', style: Ob.label(16, weight: FontWeight.w800))]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _assignedCard(BuildContext context, WidgetRef ref, Map<String, dynamic> drill, String coachName) {
    final minutes = drill['duration_minutes'];
    final difficulty = (drill['difficulty'] as String?) ?? '';
    return ObCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Transform.translate(offset: const Offset(-8, 0), child: BotImage(ObBot.star.idle, size: 52, semanticLabel: 'Your coach')),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$coachName set this', style: Ob.body(12, weight: FontWeight.w600, color: Ob.creamA(.6))),
                Text((drill['name'] as String?) ?? 'Drill', style: Ob.display(23, height: 1.1)),
              ]),
            ),
          ]),
          if ((drill['description'] as String?)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 10),
            Text(drill['description'] as String, style: Ob.body(14, height: 1.45, color: Ob.creamA(.72))),
          ],
          const SizedBox(height: 14),
          Row(children: [
            if (minutes != null) ObChip('$minutes min'),
            if (difficulty.isNotEmpty) ...[const SizedBox(width: 6), ObChip(_titleCase(difficulty))],
            const Spacer(),
            ObButton(
              onPressed: () => _startSession(context, ref, 'COACH_DRILL', coachDrillId: drill['id']),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text('Start', style: Ob.label(15, weight: FontWeight.w800)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _drillCard(BuildContext context, WidgetRef ref, Drill drill) {
    return Semantics(
      button: true,
      label: '${drill.name}, ${drill.durationMinutes} minutes',
      child: GestureDetector(
        onTap: () => _startSession(context, ref, 'DRILL', drillId: drill.id),
        child: Container(
          width: 206,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0x0FFFFFFF))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ObChip(_titleCase(drill.difficulty)),
                const Spacer(),
                Container(width: 34, height: 34, decoration: const BoxDecoration(color: Ob.lime, shape: BoxShape.circle), child: const Icon(LucideIcons.play, size: 14, color: Ob.ink)),
              ]),
              const SizedBox(height: 10),
              Text(drill.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.display(21, height: 1.1)),
              const Spacer(),
              Text('${drill.durationMinutes} min · ${drill.description}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.58))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwn(BuildContext context) => Semantics(
        button: true,
        label: 'Build your own drill',
        child: GestureDetector(
          onTap: () => context.push('/practice/drills/new'),
          child: Container(
            width: 150,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .16), width: 2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(LucideIcons.plus, size: 22, color: Ob.creamA(.72)),
              const SizedBox(height: 8),
              Text('Build your own', style: Ob.label(14).copyWith(color: Ob.creamA(.72))),
            ]),
          ),
        ),
      );

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  Widget _buildRecentSessions(AppDatabase db, String? userId, BuildContext context) {
    if (userId == null) return const SizedBox();
    return StreamBuilder<List<PracticeSession>>(
      stream: (db.select(db.practiceSessions)
            ..where((s) => s.userId.equals(userId) & s.endTime.isNotNull())
            ..orderBy([(t) => drift.OrderingTerm.desc(t.startTime)])
            ..limit(8))
          .watch(),
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <PracticeSession>[];
        if (list.isEmpty) {
          return ObCard(child: Text('Finished sessions show up here, with Daniel’s notes.', style: Ob.body(14, color: Ob.creamA(.62))));
        }
        return ObCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const ObHair(),
              _sessionRow(context, list[i]),
            ],
          ]),
        );
      },
    );
  }

  Widget _sessionRow(BuildContext context, PracticeSession session) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final type = switch (session.sessionType) { 'FREE' => 'Free practice', 'DRILL' => 'Drill', 'COACH_DRILL' => 'Coach’s drill', final t => t };
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/practice/summary/${session.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(months[session.startTime.month - 1], style: Ob.label(10, weight: FontWeight.w800).copyWith(color: Ob.creamA(.55))),
                Text('${session.startTime.day}', style: Ob.display(17, height: 1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(type, style: Ob.body(15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${session.totalBalls} balls · ${_formatDuration(session.endTime!.difference(session.startTime))}', style: Ob.body(12, color: Ob.creamA(.55))),
              ]),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.4)),
          ]),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    return '${d.inMinutes} min';
  }
}
