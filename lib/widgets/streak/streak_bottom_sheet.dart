import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/streak_provider.dart';
import '../../providers/stats_providers.dart';
import '../../providers/auth_providers.dart';
import '../../core/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/practice_analysis_service.dart';
import 'package:fl_chart/fl_chart.dart';

class StreakBottomSheet extends ConsumerWidget {
  final StreakInfo info;

  const StreakBottomSheet({super.key, required this.info});

  static void show(BuildContext context, StreakInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreakBottomSheet(info: info),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(advancedStatsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildFlameHeader(user?.displayName ?? 'Golfer'),
                  const SizedBox(height: 32),
                  _buildWeekProgress(ref),
                  const SizedBox(height: 32),
                  statsAsync.when(
                    data: (stats) => _buildStatsCard(context, ref, stats),
                    loading: () => const Center(child: CupertinoActivityIndicator(color: AppColors.emerald700)),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  profileAsync.when(
                    data: (profile) => _buildBadgeCard(profile?.badgesJson),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.grey200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildFlameHeader(String name) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.golfLime.withValues(alpha: 0.1),
              ),
            ),
            const Icon(LucideIcons.flame, color: AppColors.golfLime, size: 48),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${info.count}',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -2),
        ),
        const Text(
          'Week Streak',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.grey900),
        ),
        const SizedBox(height: 8),
        Text(
          'You are doing really great, ${name.split(' ').first}!',
          style: const TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildWeekProgress(WidgetRef ref) {
    final now = DateTime.now();
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final normalizedWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayDate = normalizedWeekStart.add(Duration(days: index));
        final isToday = dayDate.day == now.day && dayDate.month == now.month && dayDate.year == now.year;
        
        final hasPlayed = info.playedDatesThisWeek.any((d) => 
          d.day == dayDate.day && d.month == dayDate.month && d.year == dayDate.year
        );

        return Column(
          children: [
            Text(
              days[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isToday ? AppColors.grey900 : AppColors.grey400,
              ),
            ),
            const SizedBox(height: 8),
            if (hasPlayed)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.golfLime),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: isToday ? AppColors.grey100 : Colors.transparent,
                  border: isToday ? null : Border.all(color: AppColors.grey100)
                ),
                child: Center(
                  child: Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w900, 
                      color: isToday ? AppColors.grey900 : AppColors.grey200
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref, dynamic stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text('Your Stats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey400)),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: 'Rounds', value: '${stats.roundsPlayed}'),
                _StatItem(label: 'Avg', value: stats.roundsPlayed > 0 && stats.recentScores.isNotEmpty ? '${(stats.recentScores.last + 72).toInt()}' : '--'),
                _StatItem(label: 'FWY', value: '${stats.fairwayHitPercentage.toInt()}%'),
                _StatItem(label: 'GIR', value: '${stats.greensInRegulationPercentage.toInt()}%'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.grey100),
          InkWell(
            onTap: () => InsightsBottomSheet.show(context, ref, stats),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.sparkles, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  const Text('AI Insights Available', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.purple)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String? badgesJson) {
    List<dynamic> badges = [];
    if (badgesJson != null) {
      try {
        badges = jsonDecode(badgesJson);
      } catch (_) {}
    }

    String badgeTitle = 'Consistency King';
    String badgeSubtitle = 'Play every week to earn';
    bool hasStreakBadge = false;

    if (badges.contains('streak_3')) { badgeTitle = 'Streak Master'; badgeSubtitle = '3 Week Streak Earned'; hasStreakBadge = true; }
    if (badges.contains('streak_10')) { badgeTitle = 'Iron Man'; badgeSubtitle = '10 Week Streak Earned'; hasStreakBadge = true; }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasStreakBadge 
            ? [const Color(0xFFFFFBEB), const Color(0xFFFFF0C2)]
            : [AppColors.grey50, AppColors.grey50]
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: hasStreakBadge ? const Color(0xFFFFE082) : AppColors.grey100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hasStreakBadge ? 'Earned a Badge' : 'Next Milestone', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasStreakBadge ? const Color(0xFFB8860B) : AppColors.grey400)),
                const SizedBox(height: 4),
                Text(badgeTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900)),
                Text(badgeSubtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hasStreakBadge ? const Color(0xFFB8860B).withValues(alpha: 0.7) : AppColors.grey400)),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hasStreakBadge ? const Color(0xFFFFD700) : AppColors.grey100,
              shape: BoxShape.circle,
              boxShadow: hasStreakBadge ? [const BoxShadow(color: Color(0x66FFD700), blurRadius: 10, offset: Offset(0, 4))] : null,
            ),
            child: Icon(LucideIcons.medal, color: hasStreakBadge ? Colors.white : AppColors.grey200, size: 24),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.grey900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400)),
      ],
    );
  }
}

class InsightsBottomSheet extends ConsumerStatefulWidget {
  final dynamic stats;
  const InsightsBottomSheet({super.key, required this.stats});

  static void show(BuildContext context, WidgetRef ref, dynamic stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsightsBottomSheet(stats: stats),
    );
  }

  @override
  ConsumerState<InsightsBottomSheet> createState() => _InsightsBottomSheetState();
}

class _InsightsBottomSheetState extends ConsumerState<InsightsBottomSheet> {
  bool _isLoading = true;
  String _insightText = '';

  @override
  void initState() {
    super.initState();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    try {
      final aiService = ref.read(practiceAnalysisServiceProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      final name = user?.displayName?.split(' ').first ?? 'Golfer';

      final insight = await aiService.analyzePerformance(
        playerName: name,
        stats: widget.stats,
      );
      
      if (mounted) {
        setState(() {
          _insightText = insight;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _insightText = 'Insights unavailable at the moment. Keep up the great work!';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Insights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900)),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoading
                      ? const Center(child: CupertinoActivityIndicator(color: Colors.purple))
                      : Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            _insightText,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.grey800, height: 1.5),
                          ),
                        ),
                  const SizedBox(height: 32),
                  const Text('RECENT PERFORMANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.grey400, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('${widget.stats.roundsPlayed}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.golfLime)),
                           const Text('Total Rounds', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                        ],
                      ),
                      if (widget.stats.scoreTrend != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             Row(
                               children: [
                                 Icon(widget.stats.scoreTrend! <= 0 ? LucideIcons.trendingDown : LucideIcons.trendingUp, 
                                   color: widget.stats.scoreTrend! <= 0 ? AppColors.emerald700 : AppColors.doubleBogey, size: 16),
                                 const SizedBox(width: 4),
                                 Text('${widget.stats.scoreTrend!.abs().toStringAsFixed(1)}', 
                                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: widget.stats.scoreTrend! <= 0 ? AppColors.emerald700 : AppColors.doubleBogey)),
                               ],
                             ),
                             const Text('Strokes Trend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 180,
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.grey900,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('GOT IT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final scores = (widget.stats.recentScores as List<double>).toList();
    if (scores.isEmpty) return const Center(child: Text('Play rounds to see your trend'));

    final spots = scores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value + 72)).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: AppColors.grey300, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: scores.reduce((a, b) => a < b ? a : b) + 72 - 3,
        maxY: scores.reduce((a, b) => a > b ? a : b) + 72 + 3,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: AppColors.golfLime,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.golfLime.withValues(alpha: 0.2), AppColors.golfLime.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
