import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/analytics_models.dart';
import '../../core/utils/handicap.dart';

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
    return Container(
      width: 1080,
      height: 1920,
      color: const Color(0xFF0F172A), // Deep Slate
      child: Stack(
        children: [
          // Background Decor (Similar to Practice share)
          Positioned(
            top: -300,
            right: -300,
            child: Container(
              width: 900,
              height: 900,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.golfLime.withValues(alpha: 0.15),
                    AppColors.golfLime.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildHandicapSection(),
                const SizedBox(height: 40),
                _buildPerformanceGrid(),
                const SizedBox(height: 40),
                _buildHoleTypeAnalysis(),
                const SizedBox(height: 40),
                _buildNineHoleComparisonChart(),
                const Spacer(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAREER STATS',
              style: GoogleFonts.inter(
                color: AppColors.golfLime,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName.toUpperCase(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        const Icon(LucideIcons.award, color: AppColors.golfLime, size: 80),
      ],
    );
  }

  Widget _buildHandicapSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HANDICAP INDEX',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                HandicapCalculator.format(stats.handicapIndex),
                style: GoogleFonts.inter(color: AppColors.golfLime, fontSize: 160, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(width: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '${stats.roundsPlayed} ROUNDS',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 32, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem('Best Score', stats.bestScoreString, LucideIcons.trophy, AppColors.golfLime)),
            const SizedBox(width: 32),
            Expanded(child: _buildStatItem('Avg Score', stats.avgScoreString, LucideIcons.activity, Colors.white)),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildStatItem('Fairways', '${stats.fairwayHitPercentage.toInt()}%', LucideIcons.flag, Colors.white)),
            const SizedBox(width: 32),
            Expanded(child: _buildStatItem('GIR', '${stats.greensInRegulationPercentage.toInt()}%', LucideIcons.target, Colors.white)),
            const SizedBox(width: 32),
            Expanded(child: _buildStatItem('Putts/H', (stats.puttsPerRound / 18).toStringAsFixed(1), LucideIcons.circle, Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white24, size: 32),
          const SizedBox(height: 20),
          Text(value, style: GoogleFonts.inter(color: valueColor, fontSize: 48, fontWeight: FontWeight.w900)),
          Text(label.toUpperCase(), style: GoogleFonts.inter(color: Colors.white24, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildHoleTypeAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOLE TYPE ANALYSIS (AVG)',
          style: GoogleFonts.inter(color: Colors.white30, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [3, 4, 5].map((par) {
            final avg = stats.parAverages[par] ?? 0;
            final isGood = avg <= par;
            return Container(
              width: 250,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    'PAR $par',
                    style: GoogleFonts.inter(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    avg > 0 ? avg.toStringAsFixed(1) : '—',
                    style: GoogleFonts.inter(
                      color: isGood ? AppColors.golfLime : Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNineHoleComparisonChart() {
    if (stats.front9Scores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FRONT 9 vs BACK 9',
              style: GoogleFonts.inter(color: Colors.white30, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            Row(
              children: [
                _buildLegendItem('Front', AppColors.golfLime.withValues(alpha: 0.5)),
                const SizedBox(width: 32),
                _buildLegendItem('Back', AppColors.golfLime),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          height: 300,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 16),
                    ),
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: stats.front9Scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.golfLime.withValues(alpha: 0.5),
                  barWidth: 6,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.golfLime.withValues(alpha: 0.05)),
                ),
                LineChartBarData(
                  spots: stats.back9Scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.golfLime,
                  barWidth: 6,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.golfLime.withValues(alpha: 0.05)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(color: Colors.white30, fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${userName.toLowerCase().replaceAll(' ', '')}',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32),
              ),
              Text(
                'ELEVATE YOUR GAME • WWW.SCORECADDIE.APP',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Icon(LucideIcons.award, color: AppColors.golfLime, size: 80),
        ],
      ),
    );
  }
}
