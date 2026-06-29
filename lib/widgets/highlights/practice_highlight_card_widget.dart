import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';

class PracticeHighlightCardWidget extends StatelessWidget {
  final PracticeSession session;
  final List<PracticeShot> shots;
  final List<Club> clubs;
  final Drill? drill;
  final String? userName;
  final dynamic formatter; // UnitFormatter

  const PracticeHighlightCardWidget({
    super.key,
    required this.session,
    required this.shots,
    required this.clubs,
    this.drill,
    this.userName,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(session.startTime);
    final totalShots = shots.length;
    final greatCount = shots.where((s) => s.quality == 'GREAT').length;
    final goodCount = shots.where((s) => s.quality == 'GOOD').length;
    final consistency = totalShots > 0 ? ((greatCount + goodCount) / totalShots * 100).toInt() : 0;

    return Container(
      width: 1080,
      height: 1920,
      color: const Color(0xFF1C1C1E), // Dark Mode aesthetic
      child: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 600,
              height: 600,
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
                          'PRACTICE HIGHLIGHT',
                          style: GoogleFonts.inter(
                            color: AppColors.golfLime,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          drill?.name.toUpperCase() ?? '${session.sessionType} SESSION',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr • $totalShots Balls Tracked',
                          style: GoogleFonts.inter(
                            color: Colors.white60,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.target, color: AppColors.golfLime, size: 80),
                  ],
                ),
                
                const SizedBox(height: 80),
                
                // Consistency Card
                _buildValueCard(
                  label: 'CONSISTENCY SCORE',
                  value: '$consistency%',
                  subValue: '$greatCount Great • $goodCount Good',
                  color: AppColors.golfLime,
                ),
                
                const SizedBox(height: 60),
                
                // Chart Section
                Text(
                  'PERFORMANCE OVER TIME',
                  style: GoogleFonts.inter(
                    color: Colors.white30,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 450,
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
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
                              String text = '';
                              switch (value.toInt()) {
                                case 1: text = 'MISS'; break;
                                case 2: text = 'OKAY'; break;
                                case 3: text = 'GOOD'; break;
                                case 4: text = 'GREAT'; break;
                              }
                              return Text(text, style: const TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold));
                            },
                            reservedSize: 60,
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
                            double val = 1;
                            switch (e.value.quality) {
                              case 'MISS': val = 1; break;
                              case 'OKAY': val = 2; break;
                              case 'GOOD': val = 3; break;
                              case 'GREAT': val = 4; break;
                              default: val = 2;
                            }
                            return FlSpot(e.key.toDouble(), val);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.golfLime,
                          barWidth: 6,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.golfLime.withValues(alpha: 0.3),
                                AppColors.golfLime.withValues(alpha: 0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Quick Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        icon: LucideIcons.gauge,
                        label: 'AVG DIST',
                        value: _calculateAvgDistance(),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildMiniStat(
                        icon: LucideIcons.flame,
                        label: 'BEST CLUB',
                        value: _getBestClub(),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildMiniStat(
                        icon: LucideIcons.clock,
                        label: 'DURATION',
                        value: _getDuration(),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Footer
                Container(
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
                            '@${userName?.toLowerCase().replaceAll(' ', '') ?? 'golfer'}',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32),
                          ),
                          Text(
                            'Tracked with ScoreCaddie range metrics',
                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 18),
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.award, color: AppColors.golfLime, size: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({required String label, required String value, required String subValue, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            label,
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(color: color, fontSize: 120, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(width: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  subValue,
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.golfLime, size: 24),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calculateAvgDistance() {
    final validShots = shots.where((s) => s.distance != null).toList();
    if (validShots.isEmpty) return "—";
    final avg = validShots.fold(0.0, (sum, s) => sum + (s.distance ?? 0.0)) / validShots.length;
    return formatter.formatDistance(avg);
  }

  String _getBestClub() {
    if (shots.isEmpty) return "N/A";
    
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
        return "Iron";
      }
    }
    return "Iron";
  }

  String _getDuration() {
    if (session.endTime == null) return "N/A";
    final diff = session.endTime!.difference(session.startTime);
    return "${diff.inMinutes}m";
  }
}
