import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/analytics_models.dart';
import '../../core/utils/unit_formatter.dart';

class PracticeAnalyticsHighlightCardWidget extends StatelessWidget {
  final PracticeStats stats;
  final String? userName;
  final UnitFormatter? formatter;

  const PracticeAnalyticsHighlightCardWidget({
    super.key,
    required this.stats,
    this.userName,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM yyyy').format(DateTime.now());
    final avgAccuracy = stats.accuracyTrend.isNotEmpty 
        ? (stats.accuracyTrend.reduce((a, b) => a + b) / stats.accuracyTrend.length).toInt()
        : 0;

    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Decor
          Positioned(
            bottom: -150,
            right: -150,
            child: Icon(
              LucideIcons.landmark,
              size: 600,
              color: AppColors.golfLime.withValues(alpha: 0.03),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'PRACTICE MASTERY',
                          style: GoogleFonts.inter(
                            color: AppColors.golfLime,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ANALYTICS SUMMARY',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'Data as of $dateStr',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 24),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.award, color: AppColors.golfLime, size: 100),
                  ],
                ),
                
                const SizedBox(height: 60),
                
                // Top Summary Glass Card
                Container(
                  padding: const EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('SESSIONS', '${stats.totalSessions}'),
                      _buildHeaderStat('BALLS HIT', '${stats.totalBalls}'),
                      _buildHeaderStat('AVG ACC', '$avgAccuracy%'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Chart Row (Pie & Mini Bar)
                Row(
                  children: [
                    // Pie Chart: Quality Distribution
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 450,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'SHOT QUALITY',
                              style: GoogleFonts.inter(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                            const SizedBox(height: 32),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 8,
                                  centerSpaceRadius: 60,
                                  sections: _buildPieSections(avgAccuracy),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Vertical Bar Chart: Club Accuracy
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 450,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'CLUB MASTERY',
                              style: GoogleFonts.inter(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                            ),
                            const SizedBox(height: 32),
                            Expanded(
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barGroups: stats.clubBreakdown.take(4).toList().asMap().entries.map((e) {
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.accuracy,
                                          color: AppColors.golfLime,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= stats.clubBreakdown.length) return const SizedBox();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(stats.clubBreakdown[index].clubName.substring(0, 1).toUpperCase(), 
                                                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Accuracy Trend Line Chart
                Text(
                  'PERFORMANCE PROGRESSION (LAST 10 SESSIONS)',
                  style: GoogleFonts.inter(color: Colors.white30, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 300,
                  padding: const EdgeInsets.fromLTRB(20, 40, 40, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 25,
                            getTitlesWidget: (val, meta) => Text('${val.toInt()}%', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: stats.accuracyTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                          isCurved: true,
                          color: AppColors.golfLime,
                          barWidth: 6,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 6, 
                              color: AppColors.golfLime, 
                              strokeWidth: 2, 
                              strokeColor: const Color(0xFF0D1B2A)
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [AppColors.golfLime.withValues(alpha: 0.2), AppColors.golfLime.withValues(alpha: 0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Insights Row
                Row(
                  children: [
                    _buildInsightBox(
                      'MOST PRACTICED', 
                      stats.mostPracticedClub, 
                      LucideIcons.hammer,
                      subtitle: formatter != null && stats.clubBreakdown.isNotEmpty 
                        ? 'Avg: ${formatter!.formatDistance(stats.clubBreakdown.firstWhere((c) => c.clubName == stats.mostPracticedClub, orElse: () => stats.clubBreakdown.first).avgDistance)}'
                        : null,
                    ),
                    const SizedBox(width: 32),
                    _buildInsightBox('MAX ACCURACY', stats.bestAccuracyClub, LucideIcons.target),
                  ],
                ),

                const SizedBox(height: 60),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          '@${userName?.toLowerCase().replaceAll(' ', '') ?? 'golfer'}',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 36),
                        ),
                        Text(
                          'Powered by ScoreCaddie Practice Engine',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 20),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.target, color: AppColors.golfLime, size: 80),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
        Text(label, style: GoogleFonts.inter(color: AppColors.golfLime, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildInsightBox(String label, String value, IconData icon, {String? subtitle}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.golfLime, size: 32),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.inter(color: AppColors.golfLime, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(int accuracy) {
    // Synthetic distribution based on overall accuracy
    return [
      PieChartSectionData(color: AppColors.golfLime, value: accuracy.toDouble(), title: 'GREAT', radius: 30, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      PieChartSectionData(color: AppColors.emerald500, value: 20, title: 'GOOD', radius: 25, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      PieChartSectionData(color: Colors.orangeAccent, value: (100 - accuracy).toDouble().clamp(0, 100), title: 'MISSED', radius: 20, showTitle: false),
    ];
  }
}
