import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/analytics_models.dart';
import '../../core/utils/handicap.dart';
import '../../widgets/highlights/analytics_highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import 'package:screenshot/screenshot.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(advancedStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () => statsAsync.whenData((stats) => _shareHighlight(context, ref, stats)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
        error: (e, s) => Center(child: Text('Error loading stats: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdvancedStats stats) {
    if (stats.roundsPlayed == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.barChart3, size: 64, color: AppColors.grey200),
            const SizedBox(height: 16),
            const Text('No rounds played yet', style: TextStyle(color: AppColors.grey500, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Start a round to see your analytics', style: TextStyle(color: AppColors.grey400)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendSummary(context, stats),
          const SizedBox(height: 32),
          
          _buildScoreTrendChart(context, stats),
          const SizedBox(height: 32),
          
          _buildHandicapCard(context, stats),
          const SizedBox(height: 32),
          
          _buildStatsGrid(context, stats),
          const SizedBox(height: 32),
          
          _buildHoleTypeBreakdown(context, stats),
          const SizedBox(height: 32),
          
          _buildFrontBackComparison(context, stats),
        ],
      ),
    );
  }

  Widget _buildTrendSummary(BuildContext context, AdvancedStats stats) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Avg Score',
            value: (stats.recentScores.isNotEmpty 
              ? (stats.recentScores.reduce((a, b) => a + b) / stats.recentScores.length)
              : 0).toStringAsFixed(1),
            trend: stats.scoreTrend,
            trendLabel: stats.recentScores.isNotEmpty ? 'Last: ${stats.recentScores.last.toInt()}' : null,
            isNegativeBetter: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Putts/Rnd',
            value: stats.puttsPerRound.toStringAsFixed(1),
            trend: stats.puttsTrend,
            trendLabel: 'v History',
            isNegativeBetter: true,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreTrendChart(BuildContext context, AdvancedStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Score Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.grey900)),
        const SizedBox(height: 4),
        Text('Last ${stats.recentScores.length} rounds (v Par)', style: const TextStyle(fontSize: 14, color: AppColors.grey500)),
        const SizedBox(height: 20),
        Container(
          height: 220,
          padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: AppColors.grey400, fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Actual Scores
                LineChartBarData(
                  spots: stats.recentScores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.grey900,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                ),
                // Moving Average
                LineChartBarData(
                  spots: stats.movingAverage.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.emerald500,
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandicapCard(BuildContext context, AdvancedStats stats) {
    final progress = (stats.roundsPlayedToHandicap / 5).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emerald900, // Darker, more professional background
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald900.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HANDICAP INDEX', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.golfLime.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('GHIN', style: TextStyle(color: AppColors.golfLime, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                stats.isHandicapEligible 
                  ? HandicapCalculator.format(stats.handicapIndex)
                  : 'N/A',
                style: const TextStyle(
                  color: AppColors.golfLime, 
                  fontSize: 52, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              if (stats.isHandicapEligible)
                const Text(
                  'INDEX',
                  style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              if (!stats.isHandicapEligible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${stats.roundsPlayedToHandicap}/5 rounds',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.golfLime),
              minHeight: 6,
            ),
          ),
          if (!stats.isHandicapEligible)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Play ${5 - stats.roundsPlayedToHandicap} more rounds for an official index',
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdvancedStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('DETAILED STATS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _AestheticStatCard(
              label: 'Fairways', 
              value: '${stats.fairwayHitPercentage.toInt()}%', 
              icon: LucideIcons.flag,
              color: AppColors.emerald700,
            ),
            _AestheticStatCard(
              label: 'Greens', 
              value: '${stats.greensInRegulationPercentage.toInt()}%', 
              icon: LucideIcons.target,
              color: AppColors.emerald800,
            ),
            _AestheticStatCard(
              label: 'Penalties', 
              value: stats.penaltiesPerRound.toStringAsFixed(1), 
              icon: LucideIcons.alertTriangle,
              color: AppColors.grey900,
            ),
            _AestheticStatCard(
              label: 'Putts/Hole', 
              value: (stats.puttsPerRound / 18).toStringAsFixed(1), 
              icon: LucideIcons.circle,
              color: AppColors.emerald600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHoleTypeBreakdown(BuildContext context, AdvancedStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOLE AVERAGES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          ...[3, 4, 5].map((par) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Par $par', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900, fontSize: 15)),
                    Text(
                      stats.parAverages[par]?.toStringAsFixed(1) ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.grey900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (stats.parAverages[par] ?? 0) / (par + 2),
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (stats.parAverages[par] ?? 0) <= par.toDouble() ? AppColors.emerald500 : AppColors.grey600
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFrontBackComparison(BuildContext context, AdvancedStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.emerald800, AppColors.emerald900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald900.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('HALF BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _iOSNineHoleStat(label: 'FRONT 9', value: stats.front9Avg)),
              Container(height: 40, width: 1, color: Colors.white10),
              Expanded(child: _iOSNineHoleStat(label: 'BACK 9', value: stats.back9Avg)),
            ],
          ),
          if (stats.front9Avg > 0 && stats.back9Avg > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.golfLime, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    stats.front9Avg < stats.back9Avg ? 'Stronger on Front 9' : 'Stronger on Back 9',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  void _shareHighlight(BuildContext context, WidgetRef ref, AdvancedStats stats) {
    final userProfile = ref.read(userProfileProvider).valueOrNull;
    final service = ref.read(highlightCardServiceProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Show above bottom navigation bar
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('All-Time Golf Analytics', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            const Text('Share your career highlights with your network.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            
            // Preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 260,
                  height: 462, // 1080x1920 scaled
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: AnalyticsHighlightCardWidget(
                      stats: stats,
                      userName: userProfile?.name ?? user?.displayName?.split(' ').first ?? 'Golfer',
                      avatarUrl: userProfile?.avatarUrl ?? user?.photoURL,
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
                    cardWidget: AnalyticsHighlightCardWidget(
                      stats: stats,
                      userName: userProfile?.name ?? user?.displayName?.split(' ').first ?? 'Golfer',
                      avatarUrl: userProfile?.avatarUrl ?? user?.photoURL,
                    ),
                    context: context,
                    text: 'My all-time golf stats on ScoreCaddie! 🏌️‍♂️⛳ #GolfAnalytics #GolfLife',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.share2, size: 20),
                    SizedBox(width: 12),
                    Text('Share to Social Media', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final double? trend;
  final String? trendLabel;
  final bool isNegativeBetter;

  const _StatCard({required this.label, required this.value, this.trend, this.trendLabel, this.isNegativeBetter = true});

  @override
  Widget build(BuildContext context) {
    Color trendColor = Colors.grey;
    IconData? trendIcon;
    
    if (trend != null && trend != 0) {
      bool isBetter = isNegativeBetter ? trend! < 0 : trend! > 0;
      trendColor = isBetter ? AppColors.emerald600 : AppColors.doubleBogey;
      trendIcon = trend! < 0 ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.grey900)),
              if (trendIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trendIcon, size: 14, color: trendColor),
              ],
            ],
          ),
          if (trendLabel != null) ...[
            const SizedBox(height: 4),
            Text(trendLabel!, style: TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _AestheticStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AestheticStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white60, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _iOSNineHoleStat extends StatelessWidget {
  final String label;
  final double value;
  const _iOSNineHoleStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Text(
          value > 0 ? value.toStringAsFixed(1) : '—', 
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
        ),
      ],
    );
  }
}
