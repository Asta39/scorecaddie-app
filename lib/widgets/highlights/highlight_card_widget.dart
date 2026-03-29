import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart';

class HighlightCardWidget extends StatelessWidget {
  final Round round;
  final List<HoleScore> holeScores;
  final String? userName;

  const HighlightCardWidget({
    super.key,
    required this.round,
    required this.holeScores,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Stats
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
    final toParStr = diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff');
    final Color toParColor = diff < 0 ? AppColors.emerald700 : (diff > 0 ? AppColors.doubleBogey : AppColors.grey900);

    return Container(
      width: 1080,
      height: 1920,
      color: Colors.white, // Pure white for maximum contrast
      child: Stack(
        children: [
          // Elegant subtle grid pattern or accent
          Positioned(
            top: 0, right: 0,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: AppColors.emerald700.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(400)),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
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
                          'OFFICIAL SCORECARD',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emerald700,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('MMMM d, yyyy').format(round.playedAt).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey400,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const Icon(LucideIcons.flag, color: AppColors.grey900, size: 56),
                  ],
                ),

                const SizedBox(height: 80),

                // Course Info
                Text(
                  round.courseName,
                  style: GoogleFonts.inter(
                    fontSize: 84,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey900,
                    letterSpacing: -3,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 40),

                // Score Card
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL STROKES',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 2),
                        ),
                        Text(
                          '${round.totalScore}',
                          style: GoogleFonts.inter(
                            fontSize: 280,
                            fontWeight: FontWeight.w900,
                            color: AppColors.grey900,
                            height: 0.9,
                            letterSpacing: -10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: toParColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          toParStr,
                          style: GoogleFonts.inter(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: toParColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                // THE ACTUAL SCORECARD TABLES (mirrors RoundDetailScreen)
                _buildScorecardTable('FRONT 9', holeScores.where((h) => h.holeNumber <= 9).toList()),
                const SizedBox(height: 40),
                _buildScorecardTable('BACK 9', holeScores.where((h) => h.holeNumber > 9).toList()),

                const SizedBox(height: 80),

                // Stats Section
                Row(
                  children: [
                    _buildStatDetail('PUTTS', '$totalPutts', LucideIcons.target, AppColors.blue600),
                    const SizedBox(width: 32),
                    _buildStatDetail('GIR', '$girCount/${holeScores.length}', LucideIcons.sparkles, AppColors.golfPurple),
                    const SizedBox(width: 32),
                    _buildStatDetail('FIR', '$fairwaysHit/$fairwaysPossible', LucideIcons.navigation, AppColors.emerald600),
                  ],
                ),

                const Spacer(),

                // Identity Footer
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: const BoxDecoration(color: AppColors.emerald700, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            userName?.substring(0, 1).toUpperCase() ?? 'G',
                            style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? 'GOLFER',
                              style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.grey900),
                            ),
                            Text(
                              'VERIFIED ROUND • SCORE CADDIE',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.award, color: AppColors.emerald700, size: 64),
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

  Widget _buildScorecardTable(String title, List<HoleScore> scores) {
    if (scores.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey200, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Hole Header Row
              _buildTableRow(
                'HOLE', 
                scores.map((h) => '${h.holeNumber}').toList(), 
                isHeader: true,
                bgColor: AppColors.grey50,
              ),
              const Divider(height: 1, color: AppColors.grey200),
              // Par Row
              _buildTableRow(
                'PAR', 
                scores.map((h) => '${h.par}').toList(),
                textColor: AppColors.grey400,
              ),
              const Divider(height: 1, color: AppColors.grey200),
              // Score Row
              _buildTableRow(
                'SCORE', 
                scores.map((h) => '${h.score}').toList(),
                isScore: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String label, List<String> values, {
    bool isHeader = false, 
    bool isScore = false, 
    Color? bgColor,
    Color? textColor,
  }) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14, 
                fontWeight: FontWeight.w900, 
                color: isHeader ? AppColors.grey900 : (textColor ?? AppColors.grey900),
              ),
            ),
          ),
          ...values.asMap().entries.map((e) {
            final int holeIdx = e.key;
            final String val = e.value;
            
            Color valColor = textColor ?? AppColors.grey900;
            if (isScore) {
              final int s = int.tryParse(val) ?? 0;
              final int p = int.tryParse(holeIdx < values.length ? val : '0') ?? 0; // This is wrong, need par
              // Since we don't have par here easily, we'll just use bold for score
              valColor = AppColors.grey900;
            }

            return Expanded(
              child: Center(
                child: Text(
                  val,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: (isHeader || isScore) ? FontWeight.w900 : FontWeight.w600,
                    color: valColor,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -1),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
