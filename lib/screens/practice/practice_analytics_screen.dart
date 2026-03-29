import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/analytics_models.dart';
import '../../widgets/highlights/practice_analytics_highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import '../../core/utils/unit_formatter.dart';
import 'package:screenshot/screenshot.dart';

class PracticeAnalyticsScreen extends ConsumerStatefulWidget {
  const PracticeAnalyticsScreen({super.key});

  @override
  ConsumerState<PracticeAnalyticsScreen> createState() => _PracticeAnalyticsScreenState();
}

class _PracticeAnalyticsScreenState extends ConsumerState<PracticeAnalyticsScreen> {
  bool _showBallsTrend = false;

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(practiceAnalyticsProvider);
    final formatter = ref.watch(unitFormatterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.grey900, letterSpacing: -0.5)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: AppColors.grey900),
            onPressed: () => analyticsAsync.whenData((stats) => _shareHighlight(context, ref, stats, formatter)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (stats) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernSummaryCard(stats),
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(_showBallsTrend ? 'VOLUME TREND' : 'ACCURACY TREND'),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _showBallsTrend = !_showBallsTrend),
                    child: Text(_showBallsTrend ? 'Show Accuracy' : 'Show Volume', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emerald700)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTrendChart(stats),
              
              const SizedBox(height: 40),
              _buildSectionTitle('CLUB BREAKDOWN'),
              const SizedBox(height: 16),
              _buildClubBreakdownList(stats.clubBreakdown, formatter),
              
              const SizedBox(height: 40),
              _buildSectionTitle('PERFORMANCE INSIGHTS'),
              const SizedBox(height: 16),
              _buildInsightsGrid(stats),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: AppColors.grey400,
      ),
    );
  }

  Widget _buildModernSummaryCard(PracticeStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('SESSIONS', '${stats.totalSessions}', LucideIcons.calendar, AppColors.emerald700),
              _buildVerticalDivider(),
              _buildSummaryItem('TOTAL BALLS', '${stats.totalBalls}', LucideIcons.target, AppColors.blue700),
              _buildVerticalDivider(),
              _buildSummaryItem('TOTAL TIME', '${stats.totalTime.inHours}h', LucideIcons.clock, AppColors.purple700),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Color(0xFFF2F2F7)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Balls hit this month', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${stats.totalBallsThisMonth}', style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: const Color(0xFFF2F2F7));
  }

  Widget _buildTrendChart(PracticeStats stats) {
    final trendData = _showBallsTrend ? stats.ballsHitTrend.map((e) => e.toDouble()).toList() : stats.accuracyTrend;
    
    if (trendData.length < 2) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.grey100)),
        child: const Center(child: Text('More sessions needed for trend data', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w600))),
      );
    }

    final maxY = trendData.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 32, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.grey900.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: trendData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
              isCurved: true,
              curveSmoothness: 0.4,
              color: _showBallsTrend ? AppColors.blue600 : AppColors.golfLime,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: _showBallsTrend ? AppColors.blue600 : AppColors.golfLime,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    (_showBallsTrend ? AppColors.blue600 : AppColors.golfLime).withValues(alpha: 0.2),
                    (_showBallsTrend ? AppColors.blue600 : AppColors.golfLime).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubBreakdownList(List<ClubPracticeStat> clubBreakdown, UnitFormatter formatter) {
    if (clubBreakdown.isEmpty) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: clubBreakdown.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;
          final isLast = i == clubBreakdown.length - 1;
          final progress = (stat.ballsHit / clubBreakdown.first.ballsHit).clamp(0.0, 1.0);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(LucideIcons.hammer, size: 16, color: AppColors.grey400),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stat.clubName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                              Text('${stat.ballsHit} balls hit', style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatter.formatDistance(stat.avgDistance), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.grey900)),
                            Text('ACC: ${stat.accuracy.toInt()}%', style: TextStyle(color: stat.accuracy > 70 ? AppColors.emerald700 : AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFF2F2F7),
                        valueColor: AlwaysStoppedAnimation<Color>(stat.accuracy > 70 ? AppColors.emerald500 : AppColors.grey300),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.only(left: 72),
                  child: Divider(height: 1, color: Color(0xFFF2F2F7)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsGrid(PracticeStats stats) {
    return Column(
      children: [
        _buildModernInsightRow('Strongest Club', stats.bestAccuracyClub, LucideIcons.award, AppColors.golfLime),
        const SizedBox(height: 12),
        _buildModernInsightRow('Most Practiced', stats.mostPracticedClub, LucideIcons.hammer, AppColors.blue700),
        const SizedBox(height: 12),
        _buildModernInsightRow('Average Session', '${stats.avgSessionMinutes.toInt()} min', LucideIcons.activity, AppColors.emerald700),
      ],
    );
  }

  Widget _buildModernInsightRow(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 14, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.grey900)),
        ],
      ),
    );
  }

  void _shareHighlight(BuildContext context, WidgetRef ref, PracticeStats stats, UnitFormatter formatter) {
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final service = ref.read(highlightCardServiceProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Share Progress', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
            const SizedBox(height: 32),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 260,
                height: 462, 
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Screenshot(
                    controller: service.controller,
                    child: PracticeAnalyticsHighlightCardWidget(
                      stats: stats,
                      userName: userProfile?.name,
                      formatter: formatter,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  service.shareHighlight(
                    cardWidget: PracticeAnalyticsHighlightCardWidget(
                      stats: stats,
                      userName: userProfile?.name,
                      formatter: formatter,
                    ),
                    context: context,
                    text: 'Grinding on ScoreCaddie! 🏌️‍♂️⛳ #GolfStats #PracticeMastery',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Share to Social Media', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
