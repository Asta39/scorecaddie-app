import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/database/database.dart' as db;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/streak_widget.dart';
import '../provider/coach_dashboard_screen.dart';
import '../../core/utils/course_logo_helper.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/loading_spinner.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile?.role == 'coach') {
          return CoachDashboardScreen();
        } else {
          return const PlayerDashboardView();
        }
      },
      loading: () => const LoadingSpinner(isFullScreen: true),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
// Re-implementing the Player View without circular dependencies or prefix errors
class PlayerDashboardView extends ConsumerStatefulWidget {
  const PlayerDashboardView({super.key});
  @override
  ConsumerState<PlayerDashboardView> createState() => _PlayerDashboardViewState();
}

class _PlayerDashboardViewState extends ConsumerState<PlayerDashboardView> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning,' : (hour < 17 ? 'Good afternoon,' : 'Good evening,');

    final profile = profileAsync.valueOrNull;
    final userName = profile?.name ?? user?.displayName?.split(' ').first ?? 'Golfer';
    final photoUrl = profile?.avatarUrl ?? user?.photoUrl;

    ref.listen(userProfileProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        final profile = next.value!;
        final user = ref.read(authStateProvider).valueOrNull;
        if (user != null && user.email != null) {
          ref.read(friendServiceProvider).syncMyProfileToCloud(
            name: profile.name,
            email: user.email!,
            avatarUrl: profile.avatarUrl,
            handicapIndex: profile.handicap,
          );
        }
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncServiceProvider).syncAllPending(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildTopHeader(context, ref, greeting, userName, photoUrl),
            ..._buildPlayerDashboard(context, ref, profile),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, WidgetRef ref, String greeting, String userName, String? photoUrl) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 4,
      pinned: true,
      centerTitle: false,
      titleSpacing: 24,
      toolbarHeight: 80,
      shape: const Border(bottom: BorderSide(color: AppColors.grey100, width: 1)),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 20, color: AppColors.grey400),
          onPressed: () async {
            TopNotification.showSuccess(context, 'Syncing data...');
            await ref.read(syncServiceProvider).syncAllPending();
          },
        ),
        const SizedBox(width: 8),
      ],
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(greeting, style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(userName, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: ProfileImage(url: photoUrl, name: userName, size: 48, isCircle: true),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerDashboard(BuildContext context, WidgetRef ref, db.UserProfile? profile) {
    final recentRounds = ref.watch(recentRoundsProvider);
    final totalRounds = ref.watch(totalRoundsProvider);
    final averageScore = ref.watch(averageScoreProvider);
    final bestScore = ref.watch(bestScoreProvider);

    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildCalendar(context),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStartRoundCTA(context),
            ),
            const SizedBox(height: 8),
            const StreakWidget(),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildSectionHeader('PERFORMANCE OVERVIEW', () => context.push('/analytics')),
            const SizedBox(height: 16),
          ]),
        ),
      ),
      _buildStatsGrid(context, ref, profile, totalRounds, averageScore, bestScore),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildSectionHeader('PAST ACTIVITIES', () => context.push('/rounds-history')),
            const SizedBox(height: 16),
            _buildPastActivitiesList(context, recentRounds),
          ]),
        ),
      ),
    ];
  }

  Widget _buildStartRoundCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/select-course'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.golfLime,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: AppColors.golfLime.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
              child: const Icon(LucideIcons.play, color: AppColors.grey900, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('START ROUND', style: TextStyle(color: AppColors.grey900, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  SizedBox(height: 4),
                  Text('Ready for the first tee?', style: TextStyle(color: AppColors.grey900.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.grey900, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isToday ? AppColors.golfLime : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: !isToday ? Border.all(color: AppColors.grey100) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][index], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isToday ? AppColors.grey900.withValues(alpha: 0.7) : AppColors.grey400)),
                  const SizedBox(height: 4),
                  Text(day.day.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isToday ? AppColors.grey900 : AppColors.grey900)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref, db.UserProfile? profile, AsyncValue<int> totalRounds, AsyncValue<double?> averageScore, AsyncValue<int?> bestScore) {
    final handicapStatus = ref.watch(handicapProvider).valueOrNull;
    final hIndex = handicapStatus?.currentIndex;
    final trend = handicapStatus?.trend ?? 0.0;
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard(
            'Handicap Index', 
            hIndex != null ? hIndex.toStringAsFixed(1) : 'N/A', 
            LucideIcons.target, 
            AppColors.golfLime, 
            isAccent: true,
            textColorOverride: AppColors.grey900,
            trend: trend,
            subLabel: handicapStatus?.lowIndex != null ? 'LOW: ${handicapStatus!.lowIndex!.toStringAsFixed(1)}' : null,
          ),
          averageScore.when(data: (s) => _buildStatCard('Avg Score', s?.toStringAsFixed(1) ?? 'N/A', LucideIcons.trendingUp, Colors.white), loading: () => _buildStatCard('Avg Score', '...', LucideIcons.trendingUp, Colors.white), error: (_, _) => _buildStatCard('Avg Score', 'Err', LucideIcons.trendingUp, Colors.white)),
          totalRounds.when(data: (c) => _buildStatCard('Total Rounds', c.toString(), LucideIcons.calendar, Colors.white), loading: () => _buildStatCard('Total Rounds', '...', LucideIcons.calendar, Colors.white), error: (_, _) => _buildStatCard('Total Rounds', 'Err', LucideIcons.calendar, Colors.white)),
          bestScore.when(data: (s) => _buildStatCard('Best Round', s?.toString() ?? 'N/A', LucideIcons.award, AppColors.golfLime, isAccent: true, textColorOverride: AppColors.grey900), loading: () => _buildStatCard('Best Round', '...', LucideIcons.award, AppColors.golfLime, isAccent: true, textColorOverride: AppColors.grey900), error: (_, _) => _buildStatCard('Best Round', 'Err', LucideIcons.award, AppColors.golfLime, isAccent: true, textColorOverride: AppColors.grey900)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isAccent = false, Color? textColorOverride, double? trend, String? subLabel}) {
    return Container(
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(28), 
        border: Border.all(color: AppColors.grey100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColorOverride ?? AppColors.grey900, size: 20),
              if (trend != null && trend != 0)
                Row(
                  children: [
                    Icon(trend < 0 ? LucideIcons.arrowDown : LucideIcons.arrowUp, color: trend < 0 ? AppColors.golfLime : AppColors.doubleBogey, size: 12),
                    const SizedBox(width: 2),
                    Text(trend.abs().toStringAsFixed(1), style: TextStyle(color: trend < 0 ? AppColors.golfLime : AppColors.doubleBogey, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: TextStyle(color: textColorOverride?.withValues(alpha: 0.7) ?? AppColors.grey500, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
          Text(value, style: TextStyle(color: textColorOverride ?? AppColors.grey900, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          if (subLabel != null)
            Text(subLabel, style: TextStyle(color: textColorOverride?.withValues(alpha: 0.5) ?? AppColors.grey400, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildPastActivitiesList(BuildContext context, AsyncValue<List<db.Round>> recentRounds) {
    return recentRounds.when(
      data: (rounds) {
        if (rounds.isEmpty) return const Center(child: Text('No rounds yet'));
        final list = rounds.take(3).map((r) => _buildActivityTile(context, r)).toList();
        return Column(children: list);
      },
      loading: () => const LoadingSpinner(size: 60),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildActivityTile(BuildContext context, db.Round round) {
    final logoPath = CourseLogoHelper.getLogoAssetPath(round.courseName);

    return GestureDetector(
      onTap: () => context.push('/round/${round.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.grey100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: logoPath != null ? Colors.white : AppColors.emerald50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: logoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, _) => _fallbackIcon(),
                      ),
                    )
                  : _fallbackIcon(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    round.courseName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('MMM d').format(round.playedAt)} • ${round.totalScore} Strokes',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: round.scoreVsPar <= 0 ? AppColors.golfLime.withValues(alpha: 0.1) : AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                round.scoreVsPar > 0 ? '+${round.scoreVsPar}' : '${round.scoreVsPar}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: round.scoreVsPar <= 0 ? AppColors.emerald700 : AppColors.grey900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _fallbackIcon() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.golf_course_rounded, color: AppColors.emerald700, size: 24),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAction) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)), GestureDetector(onTap: onAction, child: const Text('See All', style: TextStyle(color: AppColors.grey900, fontSize: 13, fontWeight: FontWeight.w700)))]);
  }
}
