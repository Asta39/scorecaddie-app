import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/analytics_models.dart';
import '../../core/utils/unit_formatter.dart';
import 'highlight_card_kit.dart';

/// Shareable monthly practice-mastery card. Replaces the old pie chart +
/// bar chart + navy-gradient combo with the same flat white system as the
/// other three cards, a simple accuracy-bar list instead of a pie, and one
/// clean trend line instead of a glowing gradient-filled one.
class PracticeAnalyticsHighlightCardWidget extends StatelessWidget {
  final PracticeStats stats;
  final String? userName;
  final String? avatarUrl;
  final UnitFormatter? formatter;

  const PracticeAnalyticsHighlightCardWidget({
    super.key,
    required this.stats,
    this.userName,
    this.avatarUrl,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM yyyy').format(DateTime.now());
    final avgAccuracy = stats.accuracyTrend.isNotEmpty
        ? (stats.accuracyTrend.reduce((a, b) => a + b) / stats.accuracyTrend.length).toInt()
        : 0;

    return HighlightCardCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightCardHeader(
            eyebrow: 'PRACTICE MASTERY',
            title: dateStr,
            subtitle: '${stats.totalSessions} sessions logged',
          ),
          const SizedBox(height: 40),
          HighlightStatRow(stats: [
            HighlightStat(label: 'Sessions', value: '${stats.totalSessions}'),
            HighlightStat(label: 'Balls Hit', value: '${stats.totalBalls}'),
            HighlightStat(label: 'Avg Accuracy', value: '$avgAccuracy%'),
          ]),
          const SizedBox(height: 48),
          Text('CLUB ACCURACY', style: HighlightCardKit.eyebrow()),
          const SizedBox(height: 20),
          ...stats.clubBreakdown.take(4).map((c) => _ClubAccuracyRow(clubName: c.clubName, accuracy: c.accuracy)),
          if (stats.accuracyTrend.isNotEmpty) ...[
            const SizedBox(height: 40),
            Text('ACCURACY TREND', style: HighlightCardKit.eyebrow()),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.grey100, strokeWidth: 1),
                  ),
                  titlesData: const FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: stats.accuracyTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
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
          HighlightStatRow(stats: [
            HighlightStat(label: 'Most Practiced', value: stats.mostPracticedClub),
            HighlightStat(label: 'Best Accuracy', value: stats.bestAccuracyClub),
          ]),
          const SizedBox(height: 40),
          HighlightCardFooter(userName: userName, avatarUrl: avatarUrl),
        ],
      ),
    );
  }
}

class _ClubAccuracyRow extends StatelessWidget {
  final String clubName;
  final double accuracy;

  const _ClubAccuracyRow({required this.clubName, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(clubName, style: HighlightCardKit.body(color: AppColors.grey900, size: 22))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (accuracy / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.emerald700),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            child: Text('${accuracy.toInt()}%', textAlign: TextAlign.right, style: HighlightCardKit.body(color: AppColors.grey900, size: 22)),
          ),
        ],
      ),
    );
  }
}
