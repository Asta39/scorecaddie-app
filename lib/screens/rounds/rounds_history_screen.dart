import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

/// Colour for a score relative to par.
Color toParColor(int toPar) => toPar < 0 ? Ob.lime : (toPar <= 5 ? Ob.cream : (toPar <= 15 ? const Color(0xFF7DD3FC) : Ob.warn));
String toParText(int toPar) => toPar == 0 ? 'E' : (toPar > 0 ? '+$toPar' : '$toPar');

class RoundsHistoryScreen extends ConsumerWidget {
  const RoundsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(roundsProvider);
    final rounds = async.valueOrNull ?? const <Round>[];

    // Group by month, newest first.
    final byMonth = <String, List<Round>>{};
    for (final r in [...rounds]..sort((a, b) => b.playedAt.compareTo(a.playedAt))) {
      byMonth.putIfAbsent(DateFormat('MMMM yyyy').format(r.playedAt), () => []).add(r);
    }
    final full = rounds.where((r) => r.holesPlayed >= 18).toList();
    final best = full.isEmpty ? null : full.map((r) => r.totalScore).reduce((a, b) => a < b ? a : b);

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
              ObTopBar('Your rounds', onBack: () => context.pop()),
              const SizedBox(height: 16),
              if (async.isLoading && rounds.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
              else if (rounds.isEmpty)
                ObCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ObGuideRow(botAsset: ObBot.ball.happy, botLabel: 'Your golf-ball avatar', text: 'No rounds yet. Your first one lands here.', size: 72, fontSize: 16),
                    const SizedBox(height: 16),
                    ObButton(
                      onPressed: () => context.push('/select-course'),
                      child: Text('Start a round', style: Ob.label(15, weight: FontWeight.w800)),
                    ),
                  ]),
                )
              else ...[
                ObSplitCards(
                  left: ObStat('Rounds', '${rounds.length}', valueColor: Ob.lime),
                  right: ObStat('Best 18', best?.toString() ?? '—'),
                ).rise(),
                for (final e in byMonth.entries) ...[
                  const SizedBox(height: 22),
                  ObEyebrow(e.key),
                  const SizedBox(height: 10),
                  for (final r in e.value) Padding(padding: const EdgeInsets.only(bottom: 10), child: _RoundRow(round: r)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  const _RoundRow({required this.round});
  final Round round;

  @override
  Widget build(BuildContext context) {
    final toPar = round.totalScore - round.coursePar;
    return ObCard(
      onTap: () => context.push('/round/${round.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        ObCrest(round.courseName, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(round.courseName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Row(children: [
              Text('${DateFormat('EEE d MMM').format(round.playedAt)} · ${round.holesPlayed} holes', style: Ob.body(12, color: Ob.creamA(.55))),
              if (round.notes.isNotEmpty) ...[const SizedBox(width: 6), Icon(LucideIcons.fileText, size: 12, color: Ob.creamA(.45))],
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${round.totalScore}', style: Ob.display(26, height: 1)),
          Text(toParText(toPar), style: Ob.body(13, weight: FontWeight.w800, color: toParColor(toPar))),
        ]),
      ]),
    );
  }
}
