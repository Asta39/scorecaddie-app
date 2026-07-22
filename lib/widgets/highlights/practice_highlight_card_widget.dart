import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';
import 'highlight_card_kit.dart';

/// Shareable practice-session card. Same flat white system as the round and
/// analytics cards — consistency was the point; these three used to look
/// like three different apps.
class PracticeHighlightCardWidget extends StatelessWidget {
  final PracticeSession session;
  final List<PracticeShot> shots;
  final List<Club> clubs;
  final Drill? drill;
  final String? userName;
  final String? avatarUrl;
  final dynamic formatter; // UnitFormatter

  const PracticeHighlightCardWidget({
    super.key,
    required this.session,
    required this.shots,
    required this.clubs,
    this.drill,
    this.userName,
    this.avatarUrl,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(session.startTime);
    final totalShots = shots.length;
    final greatCount = shots.where((s) => s.quality == 'GREAT').length;
    final goodCount = shots.where((s) => s.quality == 'GOOD').length;
    final consistency = totalShots > 0 ? ((greatCount + goodCount) / totalShots * 100).toInt() : 0;

    return HighlightCardCanvas(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightCardHeader(
            eyebrow: 'Practice session',
            title: drill?.name ?? '${session.sessionType} Session',
            subtitle: '$dateStr · $totalShots balls tracked',
          ),
          const SizedBox(height: 48),
          Text('Consistency', style: HighlightCardKit.eyebrow()),
          const SizedBox(height: 6),
          Text('$consistency%', style: HighlightCardKit.hero(size: 188)),
          const SizedBox(height: 6),
          Text('$greatCount great · $goodCount good', style: HighlightCardKit.body()),
          const SizedBox(height: 44),
          Text('Shot quality over time', style: HighlightCardKit.eyebrow()),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.grey100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const labels = {1: 'Miss', 2: 'Okay', 3: 'Good', 4: 'Great'};
                        return Text(labels[value.toInt()] ?? '', style: HighlightCardKit.statLabel().copyWith(fontSize: 14));
                      },
                      reservedSize: 56,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: shots.length > 1 ? (shots.length - 1).toDouble() : 5,
                minY: 0.5,
                maxY: 4.5,
                lineBarsData: [
                  LineChartBarData(
                    spots: shots.asMap().entries.map((e) {
                      double val = 2;
                      switch (e.value.quality) {
                        case 'MISS': val = 1; break;
                        case 'OKAY': val = 2; break;
                        case 'GOOD': val = 3; break;
                        case 'GREAT': val = 4; break;
                      }
                      return FlSpot(e.key.toDouble(), val);
                    }).toList(),
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
          const SizedBox(height: 48),
          HighlightStatRow(stats: [
            HighlightStat(label: 'Avg Distance', value: _calculateAvgDistance()),
            HighlightStat(label: 'Best Club', value: _getBestClub()),
            HighlightStat(label: 'Duration', value: _getDuration()),
          ]),
          const Spacer(),
          HighlightCardFooter(userName: userName, avatarUrl: avatarUrl),
        ],
      ),
    );
  }

  String _calculateAvgDistance() {
    final validShots = shots.where((s) => s.distance != null).toList();
    if (validShots.isEmpty) return '—';
    final avg = validShots.fold(0.0, (sum, s) => sum + (s.distance ?? 0.0)) / validShots.length;
    return formatter.formatDistance(avg);
  }

  String _getBestClub() {
    if (shots.isEmpty) return 'N/A';

    final Map<int, int> qualityScores = {};
    for (var s in shots) {
      int score = 0;
      switch (s.quality) {
        case 'GREAT': score = 4; break;
        case 'GOOD': score = 3; break;
        case 'OKAY': score = 2; break;
        case 'MISS': score = 1; break;
      }
      qualityScores[s.clubId] = (qualityScores[s.clubId] ?? 0) + score;
    }

    int? bestClubId;
    int maxScore = -1;
    qualityScores.forEach((id, score) {
      if (score > maxScore) {
        maxScore = score;
        bestClubId = id;
      }
    });

    if (bestClubId != null) {
      try {
        return clubs.firstWhere((c) => c.id == bestClubId).type;
      } catch (_) {
        return 'Iron';
      }
    }
    return 'Iron';
  }

  String _getDuration() {
    if (session.endTime == null) return 'N/A';
    final diff = session.endTime!.difference(session.startTime);
    return '${diff.inMinutes}m';
  }
}
