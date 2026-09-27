import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';
import '../../providers/app_providers.dart';
import '../../core/models/analytics_models.dart';
import '../../widgets/highlights/practice_analytics_highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

enum _Measure { accuracy, volume }

class PracticeAnalyticsScreen extends ConsumerStatefulWidget {
  const PracticeAnalyticsScreen({super.key});

  @override
  ConsumerState<PracticeAnalyticsScreen> createState() => _PracticeAnalyticsScreenState();
}

class _PracticeAnalyticsScreenState extends ConsumerState<PracticeAnalyticsScreen> {
  _Measure _measure = _Measure.accuracy;

  String _hm(Duration d) => d.inHours > 0 ? '${d.inHours} h ${d.inMinutes.remainder(60)} min' : '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(practiceAnalyticsProvider);
    final formatter = ref.watch(unitFormatterProvider);
    final stats = async.valueOrNull;

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
              ObTopBar('Practice stats', onBack: () => context.pop(), actions: [
                if (stats != null && stats.totalSessions > 0)
                  ObIconButton(icon: LucideIcons.share2, label: 'Share', onPressed: () => _shareHighlight(context, stats, formatter)),
              ]),
              const SizedBox(height: 16),
              if (async.isLoading && stats == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (stats == null || stats.totalSessions == 0)
                ObCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ObGuideRow(botAsset: ObBot.clover.idle, botLabel: 'Daniel the clover', text: 'Hit a practice session and I\'ll start charting it.', size: 76, fontSize: 16),
                    const SizedBox(height: 14),
                    ObButton(onPressed: () => context.go('/practice'), child: Text('Go practise', style: Ob.label(15, weight: FontWeight.w800))),
                  ]),
                )
              else
                ..._body(stats, formatter),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(PracticeStats s, UnitFormatter formatter) {
    final trend = _measure == _Measure.accuracy ? s.accuracyTrend : s.ballsHitTrend.map((e) => e.toDouble()).toList();
    final clubs = [...s.clubBreakdown]..sort((a, b) => b.ballsHit.compareTo(a.ballsHit));
    final best = clubs.where((c) => c.ballsHit >= 10).fold<ClubPracticeStat?>(null, (a, c) => a == null || c.accuracy > a.accuracy ? c : a);

    return [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(28), border: Border.all(color: Ob.lime.withValues(alpha: .2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BALLS THIS MONTH', style: Ob.eyebrow()),
          const SizedBox(height: 4),
          Text('${s.totalBallsThisMonth}', style: Ob.display(64, height: 1)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ObChip('${s.totalSessions} sessions'),
            ObChip(_hm(s.totalTime)),
            ObChip('${s.totalBalls} balls in all'),
          ]),
        ]),
      ).rise(),
      const SizedBox(height: 16),
      ObGooSegmented<_Measure>(
        options: const [(_Measure.accuracy, 'On target'), (_Measure.volume, 'Balls hit')],
        selected: _measure,
        onChanged: (v) => setState(() => _measure = v),
      ),
      const SizedBox(height: 12),
      ObCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ObEyebrow(_measure == _Measure.accuracy ? 'On target, by session' : 'Balls, by session', trailing: Text('Last ${trend.length}', style: Ob.body(12, color: Ob.creamA(.55)))),
          const SizedBox(height: 12),
          SizedBox(height: 130, child: trend.isEmpty ? Center(child: Text('Not enough sessions yet.', style: Ob.body(13, color: Ob.creamA(.55)))) : _Bars(values: trend, percent: _measure == _Measure.accuracy)),
        ]),
      ),
      if (clubs.isNotEmpty) ...[
        const SizedBox(height: 22),
        const ObEyebrow('Club by club'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final c in clubs.take(8))
              ObCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.clubName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.6))),
                  const Spacer(),
                  Text('${c.accuracy.round()}%', style: Ob.display(26, height: 1, color: c.accuracy >= 60 ? Ob.lime : (c.accuracy >= 40 ? Ob.cream : Ob.warn))),
                  Text('${c.ballsHit} balls · ${c.avgDistance > 0 ? formatter.formatDistance(c.avgDistance) : '—'}', style: Ob.body(11, color: Ob.creamA(.55))),
                ]),
              ),
          ],
        ),
      ],
      const SizedBox(height: 18),
      ObGuideRow(
        botAsset: ObBot.clover.happy,
        botLabel: 'Daniel the clover',
        text: best != null
            ? 'Your ${best.clubName} is your most reliable at ${best.accuracy.round()}%. ${s.mostPracticedClub.isNotEmpty && s.mostPracticedClub != best.clubName ? 'Maybe give the ${s.mostPracticedClub} a rest?' : 'Keep it going.'}'
            : 'Hit 10 balls with a club and I\'ll tell you how it\'s going.',
        size: 80,
        fontSize: 16,
      ),
    ];
  }

  void _shareHighlight(BuildContext context, PracticeStats stats, UnitFormatter formatter) {
    final name = ref.read(userProfileProvider).valueOrNull?.name;
    final service = ref.read(highlightCardServiceProvider);
    Widget card() => PracticeAnalyticsHighlightCardWidget(stats: stats, userName: name, formatter: formatter);
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'Share your progress',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(width: 200, height: 356, child: FittedBox(fit: BoxFit.contain, child: Screenshot(controller: service.controller, child: card()))),
            ),
          ),
          const SizedBox(height: 18),
          ObButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.shareHighlight(cardWidget: card(), context: context, text: 'Grinding on ScoreCaddie! 🏌️‍♂️⛳ #GolfStats');
            },
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.share2, size: 18, color: Ob.ink),
              const SizedBox(width: 8),
              Text('Share', style: Ob.label(16, weight: FontWeight.w800)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Rounded bars that spring up; the latest one is lime.
class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.percent});
  final List<double> values;
  final bool percent;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(percent ? 100 : 1, (a, b) => b > a ? b : a);
    return LayoutBuilder(builder: (context, c) {
      final n = values.length;
      final w = ((c.maxWidth - (n - 1) * 8) / n).clamp(8.0, 30.0);
      return Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final (i, v) in values.indexed)
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(percent ? '${v.round()}' : '${v.round()}', style: Ob.body(10, weight: FontWeight.w700, color: Ob.creamA(.5))),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (v / max).clamp(.04, 1)),
              duration: Duration(milliseconds: 500 + i * 40),
              curve: Curves.easeOutBack,
              builder: (_, t, _) => Container(
                width: w,
                height: 96 * t,
                decoration: BoxDecoration(color: i == n - 1 ? Ob.lime : Ob.lime.withValues(alpha: .35), borderRadius: BorderRadius.circular(9)),
              ),
            ),
          ]),
      ]);
    });
  }
}
