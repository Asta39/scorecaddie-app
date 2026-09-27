import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../widgets/highlights/highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';
import '../rounds/rounds_history_screen.dart' show toParColor, toParText;

class RoundDetailScreen extends ConsumerWidget {
  final int roundId;

  const RoundDetailScreen({super.key, required this.roundId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final round = ref.watch(singleRoundProvider(roundId));
    final scores = ref.watch(holeScoresProvider(roundId));
    final ready = round.hasValue && scores.hasValue;

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
              ObTopBar('Round', onBack: () => context.pop(), actions: [
                if (ready)
                  ObIconButton(
                    icon: LucideIcons.share2,
                    label: 'Share this round',
                    onPressed: () => _share(context, ref, round.value!, scores.value!),
                  ),
              ]),
              const SizedBox(height: 16),
              if (round.hasError || scores.hasError)
                ObCard(child: Text('Couldn\'t load this round.', style: Ob.body(14, color: Ob.creamA(.7))))
              else if (!ready)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else
                ..._body(round.value!, scores.value!),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(Round round, List<HoleScore> scores) {
    final toPar = round.totalScore - round.coursePar;
    var putts = 0, penalties = 0, fwHit = 0, fwTotal = 0, gir = 0;
    var birdies = 0, pars = 0, bogeys = 0, worse = 0;
    for (final s in scores) {
      putts += s.putts ?? 0;
      penalties += s.penalties ?? 0;
      if (s.fairwayHit != null) {
        fwTotal++;
        if (s.fairwayHit == 'Hit') fwHit++;
      }
      if (s.gir == true) gir++;
      final d = s.score - s.par;
      if (d < 0) {
        birdies++;
      } else if (d == 0) {
        pars++;
      } else if (d == 1) {
        bogeys++;
      } else {
        worse++;
      }
    }
    final sorted = [...scores]..sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
    final front = sorted.where((s) => s.holeNumber <= 9).toList();
    final back = sorted.where((s) => s.holeNumber > 9).toList();

    return [
      Row(children: [
        ObCrest(round.courseName, size: 56, radius: 16),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(round.courseName, style: Ob.display(24, height: 1.05)),
            const SizedBox(height: 4),
            Text(DateFormat('EEEE d MMMM yyyy · HH:mm').format(round.playedAt), style: Ob.body(12, color: Ob.creamA(.6))),
          ]),
        ),
      ]).rise(),
      const SizedBox(height: 16),
      ObHeroCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SCORE', style: Ob.eyebrow()),
            Text('${round.totalScore}', style: Ob.display(60, height: 1)),
          ]),
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(toParText(toPar), style: Ob.display(28, color: toParColor(toPar))),
          ),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${round.holesPlayed} holes', style: Ob.body(13, weight: FontWeight.w700)),
            Text('Par ${round.coursePar}', style: Ob.body(12, color: Ob.creamA(.6))),
          ]),
        ]),
      ).rise(1),
      const SizedBox(height: 12),
      Row(children: [
        _mini('Birdies+', birdies, Ob.lime),
        _mini('Pars', pars, Ob.cream),
        _mini('Bogeys', bogeys, const Color(0xFF7DD3FC)),
        _mini('Worse', worse, Ob.warn),
      ]),
      if (putts > 0 || fwTotal > 0) ...[
        const SizedBox(height: 12),
        ObSplitCards(
          left: ObStat('Putts', putts > 0 ? '$putts' : '—'),
          right: ObStat('Fairways', fwTotal > 0 ? '$fwHit/$fwTotal' : '—'),
        ),
      ],
      if (gir > 0 || penalties > 0) ...[
        const SizedBox(height: 10),
        ObSplitCards(
          left: ObStat('Greens hit', '$gir'),
          right: ObStat('Penalties', '$penalties', valueColor: penalties > 0 ? Ob.warn : null),
        ),
      ],
      if (round.notes.isNotEmpty) ...[
        const SizedBox(height: 22),
        const ObEyebrow('Your notes'),
        const SizedBox(height: 10),
        ObCard(child: Text(round.notes, style: Ob.body(14, height: 1.5, color: Ob.creamA(.85)))),
      ],
      const SizedBox(height: 22),
      const ObEyebrow('Scorecard'),
      const SizedBox(height: 10),
      if (scores.isEmpty)
        ObCard(child: Text('No hole scores were saved for this round.', style: Ob.body(13, color: Ob.creamA(.6))))
      else ...[
        if (front.isNotEmpty) _nine('Out', front),
        if (front.isNotEmpty && back.isNotEmpty) const SizedBox(height: 10),
        if (back.isNotEmpty) _nine('In', back),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 6, children: [
          _legend(Ob.lime, 'Under par', circle: true),
          _legend(Ob.cream, 'Par'),
          _legend(const Color(0xFF7DD3FC), 'Bogey', square: true),
          _legend(Ob.warn, 'Double+', square: true),
        ]),
      ],
    ];
  }

  Widget _mini(String label, int n, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Text('$n', style: Ob.display(22, color: c)),
            Text(label, style: Ob.body(11, color: Ob.creamA(.55))),
          ]),
        ),
      );

  Widget _nine(String label, List<HoleScore> holes) {
    final par = holes.fold(0, (a, s) => a + s.par);
    final total = holes.fold(0, (a, s) => a + s.score);
    return ObCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(children: [
        Row(children: [
          const SizedBox(width: 34),
          for (final s in holes) Expanded(child: Text('${s.holeNumber}', textAlign: TextAlign.center, style: Ob.body(11, weight: FontWeight.w800, color: Ob.creamA(.5)))),
          SizedBox(width: 36, child: Text(label, textAlign: TextAlign.center, style: Ob.body(11, weight: FontWeight.w800, color: Ob.creamA(.5)))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          SizedBox(width: 34, child: Text('Par', style: Ob.body(11, color: Ob.creamA(.5)))),
          for (final s in holes) Expanded(child: Text('${s.par}', textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.6)))),
          SizedBox(width: 36, child: Text('$par', textAlign: TextAlign.center, style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.6)))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(width: 34, child: Text('You', style: Ob.body(11, weight: FontWeight.w800))),
          for (final s in holes) Expanded(child: Center(child: _scoreMark(s.score, s.par))),
          SizedBox(width: 36, child: Text('$total', textAlign: TextAlign.center, style: Ob.display(16))),
        ]),
        if (holes.any((s) => s.putts != null)) ...[
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(width: 34, child: Text('Putts', style: Ob.body(11, color: Ob.creamA(.5)))),
            for (final s in holes) Expanded(child: Text(s.putts?.toString() ?? '·', textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.6)))),
            SizedBox(width: 36, child: Text('${holes.fold(0, (a, s) => a + (s.putts ?? 0))}', textAlign: TextAlign.center, style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.6)))),
          ]),
        ],
      ]),
    );
  }

  /// Classic scorecard marks: circles under par, squares over.
  Widget _scoreMark(int score, int par) {
    final d = score - par;
    final c = d < 0 ? Ob.lime : (d == 0 ? Ob.cream : (d == 1 ? const Color(0xFF7DD3FC) : Ob.warn));
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: d == 0
          ? null
          : BoxDecoration(
              shape: d < 0 ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: d < 0 ? null : BorderRadius.circular(6),
              border: Border.all(color: c, width: d <= -2 || d >= 2 ? 2.4 : 1.4),
            ),
      child: Text('$score', style: Ob.body(12, weight: FontWeight.w800, color: c)),
    );
  }

  Widget _legend(Color c, String label, {bool circle = false, bool square = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: square ? BorderRadius.circular(3) : null,
            border: Border.all(color: c, width: 1.4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Ob.body(11, color: Ob.creamA(.6))),
      ]);

  void _share(BuildContext context, WidgetRef ref, Round round, List<HoleScore> scores) {
    final user = ref.read(authStateProvider).valueOrNull;
    final service = ref.read(highlightCardServiceProvider);
    final name = user?.displayName ?? 'GOLFER';

    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'Share the round',
        subtitle: 'A card with your score, ready for WhatsApp or Instagram.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 220,
                height: 280,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Screenshot(controller: service.controller, child: HighlightCardWidget(round: round, holeScores: scores, userName: name)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ObButton(
            onPressed: () {
              Navigator.pop(ctx);
              service.shareHighlight(cardWidget: HighlightCardWidget(round: round, holeScores: scores, userName: name), context: context);
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
