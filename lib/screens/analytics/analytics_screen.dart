import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../providers/app_providers.dart';
import '../../core/models/analytics_models.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/highlights/analytics_highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import '../../widgets/loading_spinner.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  /// How many recent rounds the trend numbers use.
  int _range = 20;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(advancedStatsProvider);
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: statsAsync.when(
          loading: () => const LoadingSpinner(),
          error: (e, _) => Center(child: Text('Couldn’t load your stats.', style: Ob.body(15, color: Ob.creamA(.7)))),
          data: (stats) => ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              ObTabHeader('Stats', actions: [
                if (stats.roundsPlayed > 0) ObIconButton(icon: LucideIcons.share2, label: 'Share your stats', onPressed: () => _shareHighlight(context, ref, stats)),
              ]).rise(),
              const SizedBox(height: 16),
              if (stats.roundsPlayed == 0) ..._empty() else ..._content(stats),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _empty() => [
        ObGroup(children: [const ObRow('No rounds yet', subtitle: 'Play a round and your stats start here')]),
        const SizedBox(height: 16),
        ObButton(
          onPressed: () => context.push('/select-course'),
          child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.flag, size: 18), const SizedBox(width: 8), Text('Start a round', style: Ob.label(16, weight: FontWeight.w800))]),
        ),
      ];

  List<Widget> _content(AdvancedStats stats) {
    final handicap = ref.watch(handicapProvider).valueOrNull;
    final scores = stats.recentScores;
    final shown = scores.length > _range ? scores.sublist(scores.length - _range) : scores;
    final before = scores.length > shown.length ? scores.sublist(math.max(0, scores.length - 2 * shown.length), scores.length - shown.length) : const <double>[];
    double? mean(List<double> l) => l.isEmpty ? null : l.reduce((a, b) => a + b) / l.length;
    final avg = mean(shown);
    final prev = mean(before);
    final best = shown.isEmpty ? null : shown.reduce(math.min);
    String vsPar(double v) => v == 0 ? 'Level' : (v > 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1));

    // The chart's takeaway, in one sentence (as Apple Weather does).
    final insight = avg == null
        ? null
        : prev == null
            ? 'Averaging ${vsPar(avg)} over your last ${shown.length} ${shown.length == 1 ? 'round' : 'rounds'}.'
            : (avg - prev).abs() < 0.05
                ? 'Averaging ${vsPar(avg)}, the same as the ${before.length} rounds before.'
                : 'Averaging ${vsPar(avg)}, ${(avg - prev).abs().toStringAsFixed(1)} ${avg < prev ? 'better' : 'worse'} than the ${before.length} rounds before.';

    final idx = handicap?.currentIndex ?? stats.handicapIndex;
    final needed = (5 - stats.roundsPlayedToHandicap).clamp(0, 5);

    String perHole(int par) {
      final a = stats.parAverages[par];
      if (a == null) return '—';
      final o = a - par;
      return '${a.toStringAsFixed(1)}  (${o >= 0 ? '+' : ''}${o.toStringAsFixed(1)})';
    }

    return [
      ObGooSegmented<int>(
        options: const [(5, 'Last 5'), (10, 'Last 10'), (20, 'Last 20')],
        selected: _range,
        onChanged: (v) => setState(() => _range = v),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Handicap Index', style: Ob.body(13, weight: FontWeight.w600, color: Ob.creamA(.6))),
          const SizedBox(height: 4),
          Text(idx?.toStringAsFixed(1) ?? '—', style: Ob.display(56, height: 1.05, color: idx == null ? Ob.creamA(.3) : Ob.cream)),
          Text(
            needed > 0 ? 'Play $needed more for an official index' : [if (handicap?.lowIndex != null) 'Low ${handicap!.lowIndex!.toStringAsFixed(1)}', 'World Handicap System'].join(' · '),
            style: Ob.body(15, color: Ob.creamA(.6)),
          ),
        ]),
      ),
      if (insight != null) ...[
        const SizedBox(height: 22),
        Text(insight, style: Ob.body(17, weight: FontWeight.w600)),
      ],
      if (shown.length >= 2) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Strokes vs par · last ${shown.length} rounds', style: Ob.body(13, color: Ob.creamA(.6))),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: Semantics(
                label: 'Strokes over par in your last ${shown.length} rounds: ${shown.map((v) => v.round()).join(', ')}',
                child: CustomPaint(painter: _TrendPainter(shown)),
              ),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 26),
      ObGroup(header: 'Scoring · last ${shown.length} rounds', children: [
        ObRow('Average vs par', value: avg == null ? '—' : vsPar(avg)),
        ObRow('Best vs par', value: best == null ? '—' : vsPar(best), valueColor: best != null && best <= 0 ? const Color(0xFF15803D) : null),
        ObRow('Rounds played', value: '${stats.roundsPlayed}'),
      ]),
      const SizedBox(height: 26),
      ObGroup(header: 'Your game', children: [
        ObRow('Fairways hit', value: '${stats.fairwayHitPercentage.toInt()}%'),
        ObRow('Greens in regulation', value: '${stats.greensInRegulationPercentage.toInt()}%'),
        ObRow('Putts per hole', value: (stats.puttsPerRound / 18).toStringAsFixed(1)),
        ObRow('Penalties per round', value: stats.penaltiesPerRound.toStringAsFixed(1)),
      ]),
      const SizedBox(height: 26),
      ObGroup(header: 'Average by hole', footer: 'In brackets: strokes over par per hole.', children: [
        ObRow('Par 3s', value: perHole(3)),
        ObRow('Par 4s', value: perHole(4)),
        ObRow('Par 5s', value: perHole(5)),
        ObRow('Front 9', value: stats.front9Avg > 0 ? stats.front9Avg.toStringAsFixed(1) : '—'),
        ObRow('Back 9', value: stats.back9Avg > 0 ? stats.back9Avg.toStringAsFixed(1) : '—'),
        ObRow('9-hole rounds', subtitle: '${stats.nineHoleRoundsPlayed} played', value: stats.nineHoleRoundsPlayed == 0 ? '—' : vsPar(stats.nineHoleAvgVsPar)),
        ObRow('18-hole rounds', subtitle: '${stats.eighteenHoleRoundsPlayed} played', value: stats.eighteenHoleRoundsPlayed == 0 ? '—' : vsPar(stats.eighteenHoleAvgVsPar)),
      ]),
      const SizedBox(height: 26),
      _bestEight(handicap),
      if (stats.courseStats.isNotEmpty) ...[
        const SizedBox(height: 26),
        ObGroup(header: 'By course', children: [
          for (final cs in stats.courseStats)
            ObRow(cs.courseName, subtitle: '${cs.roundsPlayed} ${cs.roundsPlayed == 1 ? 'round' : 'rounds'} · best ${cs.bestScore}', value: 'avg ${cs.avgScore.toStringAsFixed(1)}'),
        ]),
      ],
    ];
  }

  /// WHS: the index is the average of the best 8 differentials of the last 20.
  Widget _bestEight(HandicapStatus? status) {
    final rounds = (ref.watch(recentRoundsProvider).valueOrNull ?? const <db.Round>[]).where((r) => r.scoreDifferential != null).take(20).toList();
    if (rounds.isEmpty || status == null) return const SizedBox.shrink();
    final counting = rounds.where((r) => status.bestRoundIds.contains(r.id)).map((r) => r.scoreDifferential!).toList()..sort();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Best ${counting.length} of your last ${rounds.length} differentials', style: Ob.body(13, color: Ob.creamA(.6))),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.45,
          children: [
            for (final r in rounds)
              Semantics(
                label: 'Differential ${r.scoreDifferential!.toStringAsFixed(1)}${status.bestRoundIds.contains(r.id) ? ', counts' : ''}',
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: status.bestRoundIds.contains(r.id) ? Ob.lime : Ob.field,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(r.scoreDifferential!.toStringAsFixed(1),
                      style: Ob.display(16, color: status.bestRoundIds.contains(r.id) ? Ob.ink : Ob.creamA(.5))),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          counting.isEmpty
              ? 'Your index appears once you have enough rounds.'
              : 'Your index is the average of the green ones. Beat ${counting.last.toStringAsFixed(1)} and one of them drops out.',
          style: Ob.body(13, height: 1.45, color: Ob.creamA(.62)),
        ),
      ]),
    );
  }


  void _shareHighlight(BuildContext context, WidgetRef ref, AdvancedStats stats) {
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final service = ref.read(highlightCardServiceProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Show above bottom navigation bar
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text('Share your stats', style: Ob.display(26)),
            const SizedBox(height: 8),
            Text('A card with your career highlights, ready for WhatsApp or Instagram.', textAlign: TextAlign.center, style: Ob.body(15, color: Ob.creamA(.7))),
            const SizedBox(height: 32),
            
            // Preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 260,
                  height: 462, // 1080x1920 scaled
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: AnalyticsHighlightCardWidget(
                      stats: stats,
                      userName: userProfile?.name ?? user?.displayName?.split(' ').first ?? 'Golfer',
                      avatarUrl: userProfile?.avatarUrl ?? user?.photoUrl,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            ObButton(
              width: double.infinity,
              onPressed: () {
                Navigator.pop(context);
                service.shareHighlight(
                  cardWidget: AnalyticsHighlightCardWidget(
                    stats: stats,
                    userName: userProfile?.name ?? user?.displayName?.split(' ').first ?? 'Golfer',
                    avatarUrl: userProfile?.avatarUrl ?? user?.photoUrl,
                  ),
                  context: context,
                  text: 'My golf stats on ScoreCaddie #GolfAnalytics',
                );
              },
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.share2, size: 18), const SizedBox(width: 8), Text('Share', style: Ob.label(16, weight: FontWeight.w800))]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Not now', style: Ob.label(15).copyWith(color: Ob.creamA(.6))),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Score against par per round: a lime line with a soft fill, the latest
/// round larger. Lower is better, so the axis is flipped (under par is high).
class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = values.reduce(math.min) - 2, hi = values.reduce(math.max) + 2;
    final grid = Paint()..color = const Color(0x243C3C43);
    for (var i = 0; i < 3; i++) {
      final y = 14 + i * (size.height - 28) / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      final v = hi - i * (hi - lo) / 2;
      final tp = TextPainter(text: TextSpan(text: v >= 0 ? '+${v.round()}' : '${v.round()}', style: Ob.label(10).copyWith(color: Ob.creamA(.4))), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height - 2));
    }
    Offset pt(int i) => Offset(4 + i * (size.width - 40) / (values.length - 1), 14 + (values[i] - lo) / (hi - lo) * (size.height - 28));
    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(pt(i).dx, pt(i).dy);
    }
    final area = Path.from(line)..lineTo(pt(values.length - 1).dx, size.height)..lineTo(pt(0).dx, size.height)..close();
    canvas.drawPath(area, Paint()..color = Ob.lime.withValues(alpha: .10));
    canvas.drawPath(line, Paint()..color = Ob.lime..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
    for (var i = 0; i < values.length; i++) {
      final last = i == values.length - 1;
      canvas.drawCircle(pt(i), last ? 5.5 : 3.5, Paint()..color = Ob.lime);
      canvas.drawCircle(pt(i), last ? 5.5 : 3.5, Paint()..color = Ob.cardFill..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values.join() != values.join();
}
