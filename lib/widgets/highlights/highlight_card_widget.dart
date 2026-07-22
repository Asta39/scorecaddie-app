import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';
import 'highlight_card_kit.dart';

/// Shareable round-complete card. Full redesign — flat white canvas, one
/// accent color spent on the to-par pill, and a real hole-by-hole scorecard
/// as the centerpiece instead of a decorative stat grid.
class HighlightCardWidget extends StatelessWidget {
  final Round round;
  final List<HoleScore> holeScores;
  final String? userName;
  final String? avatarUrl;

  const HighlightCardWidget({
    super.key,
    required this.round,
    required this.holeScores,
    this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    int totalPutts = 0;
    int fairwaysHit = 0;
    int fairwaysPossible = 0;
    int girCount = 0;

    for (final s in holeScores) {
      if (s.putts != null) totalPutts += s.putts!;
      if (s.fairwayHit != null && s.par > 3) {
        fairwaysPossible++;
        if (s.fairwayHit == 'Hit') fairwaysHit++;
      }
      if (s.putts != null && (s.score - s.putts!) <= (s.par - 2)) {
        girCount++;
      }
    }

    final diff = round.totalScore - round.coursePar;
    final toParStr = diff == 0 ? 'EVEN PAR' : (diff > 0 ? '+$diff TO PAR' : '$diff TO PAR');
    final toParBg = diff < 0 ? AppColors.emerald700 : (diff > 0 ? AppColors.grey900 : AppColors.grey700);

    return HighlightCardCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightCardHeader(
            eyebrow: 'Round complete',
            title: round.courseName,
            subtitle: DateFormat('MMMM d, yyyy').format(round.playedAt),
          ),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${round.totalScore}', style: HighlightCardKit.hero()),
              const SizedBox(width: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: HighlightAccentBadge(label: toParStr, background: toParBg),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Total strokes', style: HighlightCardKit.statLabel()),
          const SizedBox(height: 44),
          _ScorecardTable(title: 'Front 9', scores: holeScores.where((h) => h.holeNumber <= 9).toList()),
          const SizedBox(height: 24),
          _ScorecardTable(title: 'Back 9', scores: holeScores.where((h) => h.holeNumber > 9).toList()),
          const SizedBox(height: 44),
          HighlightStatRow(stats: [
            HighlightStat(label: 'Putts', value: '$totalPutts'),
            HighlightStat(label: 'Greens in Reg', value: '$girCount/${holeScores.length}'),
            HighlightStat(label: 'Fairways', value: '$fairwaysHit/$fairwaysPossible'),
          ]),
          const Spacer(),
          HighlightCardFooter(userName: userName, avatarUrl: avatarUrl),
        ],
      ),
    );
  }
}

class _ScorecardTable extends StatelessWidget {
  final String title;
  final List<HoleScore> scores;

  const _ScorecardTable({required this.title, required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: HighlightCardKit.eyebrow()),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey25,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _row('Hole', scores.map((h) => '${h.holeNumber}').toList(), bold: true),
              _row('Par', scores.map((h) => '${h.par}').toList(), color: AppColors.grey500),
              _row('Score', scores.map((h) => '${h.score}').toList(), bold: true, bg: Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, List<String> values, {bool bold = false, Color? color, Color? bg}) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: HighlightCardKit.statLabel(color: color ?? AppColors.grey900)
                  .copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
          ...values.map((v) => Expanded(
                child: Center(
                  child: Text(
                    v,
                    style: HighlightCardKit.statLabel(color: color ?? AppColors.grey900).copyWith(
                          fontSize: 24,
                          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                          fontFeatures: HighlightCardKit.tabular,
                        ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
