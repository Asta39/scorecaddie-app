import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/analytics_models.dart';
import '../../core/utils/handicap.dart';
import 'highlight_card_kit.dart';

/// Shareable career-stats card. Same flat white system as the round card —
/// no dark canvas, no glow blobs. Handicap index is the one hero number;
/// everything else sits in a plain stat row and a restrained line chart.
class AnalyticsHighlightCardWidget extends StatelessWidget {
  final AdvancedStats stats;
  final String userName;
  final String? avatarUrl;

  const AnalyticsHighlightCardWidget({
    super.key,
    required this.stats,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return HighlightCardCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightCardHeader(
            eyebrow: 'CAREER STATS',
            title: userName,
            subtitle: '${stats.roundsPlayed} rounds logged',
          ),
          const SizedBox(height: 56),
          Text('HANDICAP INDEX', style: HighlightCardKit.eyebrow()),
          const SizedBox(height: 8),
          Text(HandicapCalculator.format(stats.handicapIndex), style: HighlightCardKit.hero(size: 200)),
          const SizedBox(height: 40),
          HighlightStatRow(stats: [
            HighlightStat(label: 'Best Score', value: stats.bestScoreString),
            HighlightStat(label: 'Avg Score', value: stats.avgScoreString),
            HighlightStat(label: 'Fairways', value: '${stats.fairwayHitPercentage.toInt()}%'),
            HighlightStat(label: 'GIR', value: '${stats.greensInRegulationPercentage.toInt()}%'),
          ]),
          const SizedBox(height: 48),
          Text('AVERAGE BY PAR', style: HighlightCardKit.eyebrow()),
          const SizedBox(height: 20),
          Row(
            children: [3, 4, 5].map((par) {
              final avg = stats.parAverages[par] ?? 0;
              final isGood = avg > 0 && avg <= par;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAR $par', style: HighlightCardKit.statLabel()),
                      const SizedBox(height: 4),
                      Text(
                        avg > 0 ? avg.toStringAsFixed(1) : '—',
                        style: HighlightCardKit.title(size: 40, color: isGood ? AppColors.emerald700 : AppColors.grey900),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (stats.front9Scores.isNotEmpty) ...[
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('FRONT 9 VS BACK 9', style: HighlightCardKit.eyebrow()),
                Row(
                  children: [
                    _legend('Front', AppColors.grey400),
                    const SizedBox(width: 24),
                    _legend('Back', AppColors.emerald700),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.grey100, strokeWidth: 1),
                  ),
                  titlesData: const FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: stats.front9Scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: AppColors.grey400,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: stats.back9Scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: AppColors.emerald700,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          HighlightCardFooter(userName: userName, avatarUrl: avatarUrl),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: HighlightCardKit.statLabel()),
      ],
    );
  }
}
