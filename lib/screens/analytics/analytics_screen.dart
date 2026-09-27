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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
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
        ObGuideRow(botAsset: ObBot.ball.idle, botLabel: 'Your golf-ball avatar', text: 'Play a round and your stats start here.').rise(1),
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
    final avg = shown.isEmpty ? null : shown.reduce((a, b) => a + b) / shown.length;
    final best = shown.isEmpty ? null : shown.reduce(math.min);
    String vsPar(double v) => v == 0 ? 'Level' : (v > 0 ? '+${v.toStringAsFixed(1)}' : v.toStringAsFixed(1));

    return [
      ObGooSegmented<int>(
        options: const [(5, 'Last 5'), (10, 'Last 10'), (20, 'Last 20')],
        selected: _range,
        onChanged: (v) => setState(() => _range = v),
      ).rise(1),
      const SizedBox(height: 16),
      _indexHero(stats, handicap).rise(2),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _tile('Average', avg == null ? '—' : vsPar(avg), sub: 'vs par')),
        const SizedBox(width: 10),
        Expanded(child: _tile('Best', best == null ? '—' : vsPar(best), sub: 'vs par', color: Ob.lime)),
        const SizedBox(width: 10),
        Expanded(child: _tile('Rounds', '${shown.length}', sub: 'of ${stats.roundsPlayed}')),
      ]),
      const SizedBox(height: 16),
      if (shown.length >= 2) ...[
        ObCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ObEyebrow('Score vs par', trailing: Text('Last ${shown.length} rounds', style: Ob.body(12, color: Ob.creamA(.55)))),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: Semantics(
                label: 'Strokes over par in your last ${shown.length} rounds',
                child: CustomPaint(painter: _TrendPainter(shown)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
      ],
      _bestEight(handicap),
      const SizedBox(height: 24),
      const ObEyebrow('Your game'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: [
          _tile('Fairways hit', '${stats.fairwayHitPercentage.toInt()}%', icon: LucideIcons.flag),
          _tile('Greens in regulation', '${stats.greensInRegulationPercentage.toInt()}%', icon: LucideIcons.target),
          _tile('Putts a hole', (stats.puttsPerRound / 18).toStringAsFixed(1), icon: LucideIcons.circle),
          _tile('Penalties a round', stats.penaltiesPerRound.toStringAsFixed(1), icon: LucideIcons.triangleAlert),
        ],
      ),
      const SizedBox(height: 24),
      const ObEyebrow('Average by hole'),
      const SizedBox(height: 12),
      Row(children: [
        for (final par in [3, 4, 5]) ...[
          if (par > 3) const SizedBox(width: 10),
          Expanded(child: _parTile(par, stats.parAverages[par])),
        ],
      ]),
      const SizedBox(height: 16),
      ObSplitCards(
        left: ObStat('Front 9', stats.front9Avg > 0 ? stats.front9Avg.toStringAsFixed(1) : '—', valueSize: 28),
        right: ObStat('Back 9', stats.back9Avg > 0 ? stats.back9Avg.toStringAsFixed(1) : '—', valueSize: 28),
      ),
      const SizedBox(height: 12),
      ObSplitCards(
        left: ObStat('9-hole rounds · ${stats.nineHoleRoundsPlayed}', stats.nineHoleRoundsPlayed == 0 ? '—' : vsPar(stats.nineHoleAvgVsPar), valueSize: 28),
        right: ObStat('18-hole rounds · ${stats.eighteenHoleRoundsPlayed}', stats.eighteenHoleRoundsPlayed == 0 ? '—' : vsPar(stats.eighteenHoleAvgVsPar), valueSize: 28),
      ),
      if (stats.courseStats.isNotEmpty) ...[
        const SizedBox(height: 24),
        ObEyebrow('By course', trailing: Text('${stats.courseStats.length}', style: Ob.label(12).copyWith(color: Ob.creamA(.55)))),
        const SizedBox(height: 12),
        ObCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            for (var i = 0; i < stats.courseStats.length; i++) ...[
              if (i > 0) const ObHair(),
              _courseRow(stats.courseStats[i]),
            ],
          ]),
        ),
      ],
    ];
  }

  Widget _indexHero(AdvancedStats stats, HandicapStatus? h) {
    final idx = h?.currentIndex ?? stats.handicapIndex;
    final needed = (5 - stats.roundsPlayedToHandicap).clamp(0, 5);
    return ObHeroCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('HANDICAP INDEX', style: Ob.eyebrow()),
            const SizedBox(height: 2),
            if (idx == null) Text('—', style: Ob.display(60, height: 1.05, color: Ob.creamA(.35))) else ObRollingNumber(value: idx, fontSize: 60),
            Text(
              needed > 0 ? 'Play $needed more for an official index' : [if (h?.lowIndex != null) 'Low ${h!.lowIndex!.toStringAsFixed(1)}', 'Official WHS'].join(' · '),
              style: Ob.body(12, color: Ob.creamA(.6)),
            ),
          ]),
        ),
        BotImage(ObBot.ball.idle, size: 96),
      ]),
    );
  }

  Widget _tile(String label, String value, {String? sub, Color? color, IconData? icon}) => ObCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 14, color: Ob.lime), const SizedBox(width: 6)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, weight: FontWeight.w600, color: Ob.creamA(.6)))),
          ]),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(value, key: ValueKey(value), maxLines: 1, style: Ob.display(26, height: 1, color: color ?? Ob.cream)),
          ),
          if (sub != null) Text(sub, style: Ob.body(11, color: Ob.creamA(.5))),
        ]),
      );

  Widget _parTile(int par, double? avg) {
    final over = avg == null ? null : avg - par;
    final worst = over != null && over >= 1.1;
    return ObCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Par ${par}s', style: Ob.body(12, weight: FontWeight.w600, color: Ob.creamA(.6))),
        const SizedBox(height: 8),
        Text(avg?.toStringAsFixed(1) ?? '—', style: Ob.display(28, height: 1)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: over == null ? 0 : (over / 1.5).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: .08),
            valueColor: AlwaysStoppedAnimation(worst ? Ob.warn : Ob.lime),
          ),
        ),
        const SizedBox(height: 6),
        Text(over == null ? 'No data yet' : '${over >= 0 ? '+' : ''}${over.toStringAsFixed(1)} a hole', style: Ob.body(11, color: Ob.creamA(.55))),
      ]),
    );
  }

  /// WHS: the index is the average of the best 8 differentials of the last 20.
  Widget _bestEight(HandicapStatus? status) {
    final rounds = (ref.watch(recentRoundsProvider).valueOrNull ?? const <db.Round>[]).where((r) => r.scoreDifferential != null).take(20).toList();
    if (rounds.isEmpty || status == null) return const SizedBox.shrink();
    final counting = rounds.where((r) => status.bestRoundIds.contains(r.id)).map((r) => r.scoreDifferential!).toList()..sort();
    return ObCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ObEyebrow('Best ${counting.length} of your last ${rounds.length}'),
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
                    color: status.bestRoundIds.contains(r.id) ? Ob.lime : Colors.white.withValues(alpha: .05),
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
              : 'Your index is the average of the lime ones. Beat ${counting.last.toStringAsFixed(1)} and one of them drops out.',
          style: Ob.body(13, height: 1.45, color: Ob.creamA(.62)),
        ),
      ]),
    );
  }

  Widget _courseRow(CourseStat cs) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          ObCrest(cs.courseName, size: 40, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cs.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700)),
              Text('${cs.roundsPlayed} ${cs.roundsPlayed == 1 ? 'round' : 'rounds'} · best ${cs.bestScore}', style: Ob.body(12, color: Ob.creamA(.55))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(cs.avgScore.toStringAsFixed(1), style: Ob.display(22, height: 1)),
            Text('average', style: Ob.body(11, color: Ob.creamA(.55))),
          ]),
        ]),
      );

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
          color: Color(0xFF0D1A12),
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
    final grid = Paint()..color = const Color(0x0FFFFFFF);
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
