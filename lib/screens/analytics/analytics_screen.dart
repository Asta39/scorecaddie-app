import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/analytics_models.dart';
import '../../widgets/highlights/analytics_highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import '../../widgets/loading_spinner.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(advancedStatsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
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
        data: (stats) => _buildContent(context, ref, stats),
        loading: () => const LoadingSpinner(),
        error: (e, s) => Center(child: Text('Error loading stats: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AdvancedStats stats) {
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrendSummary(context, stats),
                const SizedBox(height: 32),
                _buildScoreTrendChart(context, stats),
                const SizedBox(height: 32),
                _buildHandicapCard(context, ref, stats),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('DETAILED STATS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _AestheticStatCard(
                label: 'Fairways', 
                value: '${stats.fairwayHitPercentage.toInt()}%', 
                icon: LucideIcons.flag,
                color: AppColors.golfLime,
              ),
              _AestheticStatCard(
                label: 'Greens', 
                value: '${stats.greensInRegulationPercentage.toInt()}%', 
                icon: LucideIcons.target,
                color: AppColors.golfLime,
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
                color: AppColors.golfLime,
                textColorOverride: AppColors.grey900,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHoleTypeBreakdown(context, stats),
                const SizedBox(height: 32),
                _buildFrontBackComparison(context, stats),
                const SizedBox(height: 32),
                _buildRoundTypeComparison(context, stats),
                if (stats.courseStats.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildCourseStats(context, stats),
                ],
              ],
            ),
          ),
        ),
      ],
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
                  color: AppColors.golfLime,
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

  Widget _buildHandicapCard(BuildContext context, WidgetRef ref, AdvancedStats stats) {
    final handicapStatus = ref.watch(handicapProvider).valueOrNull;
    final progress = (stats.roundsPlayedToHandicap / 5).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.grey900,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
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
                    decoration: BoxDecoration(color: AppColors.golfLime.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Text('OFFICIAL WHS', style: TextStyle(color: AppColors.golfLime, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    handicapStatus?.currentIndex != null 
                      ? handicapStatus!.currentIndex!.toStringAsFixed(1)
                      : 'N/A',
                    style: const TextStyle(color: AppColors.golfLime, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -2),
                  ),
                  const SizedBox(width: 8),
                  const Text('INDEX', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              if (handicapStatus?.lowIndex != null) ...[
                const SizedBox(height: 8),
                Text('LOW INDEX (365D): ${handicapStatus!.lowIndex!.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
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
              if (stats.roundsPlayedToHandicap < 5)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Play ${5 - stats.roundsPlayedToHandicap} more rounds for an official index', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
        if (handicapStatus != null && handicapStatus.bestRoundIds.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text('HANDICAP AUDIT (BEST 8)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          _buildHandicapAuditList(ref, handicapStatus),
        ],
      ],
    );
  }

  Widget _buildHandicapAuditList(WidgetRef ref, HandicapStatus status) {
    final recentRounds = ref.watch(recentRoundsProvider).valueOrNull ?? [];
    // We only care about the last 20 for the audit
    final auditRounds = recentRounds.take(20).toList();

    return Column(
      children: auditRounds.map((round) {
        final isBest = status.bestRoundIds.contains(round.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isBest ? AppColors.golfLime.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isBest ? AppColors.golfLime.withValues(alpha: 0.3) : AppColors.grey100),
          ),
          child: Row(
            children: [
              if (isBest) 
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(LucideIcons.checkCircle2, color: AppColors.golfLime, size: 16),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(round.courseName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: isBest ? AppColors.grey900 : AppColors.grey600)),
                    Text('${round.totalScore} Strokes • ${round.playedAt.day}/${round.playedAt.month}', style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(round.scoreDifferential?.toStringAsFixed(1) ?? '—', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isBest ? AppColors.golfLime : AppColors.grey400)),
                  const Text('DIFF', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.grey400)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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
                      (stats.parAverages[par] ?? 0) <= par.toDouble() ? AppColors.golfLime : AppColors.grey600
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
          colors: [AppColors.grey800, AppColors.grey900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              Expanded(child: _IosNineHoleStat(label: 'FRONT 9', value: stats.front9Avg)),
              Container(height: 40, width: 1, color: Colors.white10),
              Expanded(child: _IosNineHoleStat(label: 'BACK 9', value: stats.back9Avg)),
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


  Widget _buildRoundTypeComparison(BuildContext context, AdvancedStats stats) {
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
          const Text('ROUND TYPE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('9 HOLES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      '${stats.nineHoleRoundsPlayed}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.grey900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.nineHoleAvgVsPar == 0 ? '—' : (stats.nineHoleAvgVsPar > 0 ? '+${stats.nineHoleAvgVsPar.toStringAsFixed(1)}' : stats.nineHoleAvgVsPar.toStringAsFixed(1)),
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: stats.nineHoleAvgVsPar <= 0 ? AppColors.golfLime : AppColors.doubleBogey,
                      ),
                    ),
                    const Text('AVG VS PAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                  ],
                ),
              ),
              Container(width: 1, height: 80, color: AppColors.grey200),
              Expanded(
                child: Column(
                  children: [
                    const Text('18 HOLES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      '${stats.eighteenHoleRoundsPlayed}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.grey900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.eighteenHoleAvgVsPar == 0 ? '—' : (stats.eighteenHoleAvgVsPar > 0 ? '+${stats.eighteenHoleAvgVsPar.toStringAsFixed(1)}' : stats.eighteenHoleAvgVsPar.toStringAsFixed(1)),
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: stats.eighteenHoleAvgVsPar <= 0 ? AppColors.golfLime : AppColors.doubleBogey,
                      ),
                    ),
                    const Text('AVG VS PAR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.grey400)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStats(BuildContext context, AdvancedStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.grey800, AppColors.grey900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.map, color: AppColors.golfLime, size: 18),
              const SizedBox(width: 8),
              const Text('COURSE STATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 20),
          ...stats.courseStats.take(5).map((cs) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(cs.courseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 1,
                  child: Text('${cs.roundsPlayed}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    cs.bestVsPar != null
                        ? (cs.bestVsPar == 0 ? 'E' : cs.bestVsPar! > 0 ? '+${cs.bestVsPar}' : '${cs.bestVsPar}')
                        : '—',
                    style: const TextStyle(color: AppColors.golfLime, fontWeight: FontWeight.w900, fontSize: 13),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )),
          if (stats.courseStats.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text('+ ${stats.courseStats.length - 5} more courses', style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20)),
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
                      avatarUrl: userProfile?.avatarUrl ?? user?.photoUrl,
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
                      avatarUrl: userProfile?.avatarUrl ?? user?.photoUrl,
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
      trendColor = isBetter ? AppColors.golfLime : AppColors.doubleBogey;
      trendIcon = trend! < 0 ? Icons.arrow_downward : Icons.arrow_upward;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.golfLime)),
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
  final Color? textColorOverride;
  const _AestheticStatCard({required this.label, required this.value, required this.icon, required this.color, this.textColorOverride});

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
          Icon(icon, color: textColorOverride?.withValues(alpha: 0.6) ?? Colors.white60, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColorOverride ?? Colors.white, letterSpacing: -1)),
              Text(label.toUpperCase(), style: TextStyle(color: textColorOverride?.withValues(alpha: 0.6) ?? Colors.white60, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _IosNineHoleStat extends StatelessWidget {
  final String label;
  final double value;
  const _IosNineHoleStat({required this.label, required this.value});

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
