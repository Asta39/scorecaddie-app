import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/utils/handicap.dart';
import '../../widgets/profile_image.dart';

class PlayerProfileScreen extends ConsumerWidget {
  final String userId;
  final String? name;

  const PlayerProfileScreen({
    super.key,
    required this.userId,
    this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));
    final statsAsync = ref.watch(publicProfileStatsProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? Colors.white : AppColors.grey900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name ?? 'Player Profile', 
          style: TextStyle(color: isDark ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildErrorState(context, 'Profile not found', 'This player may have deleted their account or changed their ID.');
          }
          
          return statsAsync.when(
            data: (stats) => _buildContent(context, profile, stats, isDark),
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, _) => _buildErrorState(
              context, 
              'Unable to Load Stats', 
              e.toString().contains('42501') 
                ? 'Permission denied. Please check database security policies.'
                : 'Error: $e', 
              onRetry: () => ref.invalidate(publicProfileStatsProvider(userId))
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, s) => _buildErrorState(
          context, 
          'Network Error', 
          'Please check your internet connection and try again.', 
          onRetry: () => ref.invalidate(publicProfileProvider(userId))
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> profile, Map<String, dynamic>? stats, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Centered Identity Header ──────────────────────────────────────
            _buildIdentityHeader(profile),
            const SizedBox(height: 32),

            // ── Career Stats Grid ─────────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('CAREER STATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            _buildStatsGrid(profile, stats),
            
            const SizedBox(height: 32),

            // ── Recent Activity ───────────────────────────────────────────────
            if (stats?['recentScore'] != null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('RECENT ROUND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 12),
              _buildRecentRoundCard(stats!['recentScore'], isDark),
              const SizedBox(height: 32),
            ],

            // ── Achievements ──────────────────────────────────────────────────
            if (stats?['achievements'] != null && (stats!['achievements'] as List).isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('ACHIEVEMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 12),
              _buildAchievementsRow(stats['achievements'], isDark),
              const SizedBox(height: 32),
            ],

            // ── Account Info ──────────────────────────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('PLAYER INFO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 12),
            _buildInfoList(profile, stats, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(Map<String, dynamic> profile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileImage(
          url: profile['avatarUrl'],
          name: profile['name'] ?? 'G',
          size: 100,
          isCircle: true,
        ),
        const SizedBox(height: 16),
        Text(profile['name'] ?? 'Golfer', 
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.golfLime,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            (profile['role'] ?? 'PLAYER').toUpperCase(),
            style: const TextStyle(color: AppColors.grey900, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> profile, Map<String, dynamic>? stats) {
    final hcp = (profile['handicapIndex'] as num?)?.toDouble() ?? 0.0;
    
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'HANDICAP', value: HandicapCalculator.format(hcp), color: AppColors.golfLime, textColor: AppColors.grey900)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'BEST', value: stats?['bestScore']?.toString() ?? '—', color: AppColors.grey900)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'AVG', value: stats?['avgScore']?.toString() ?? '—', color: Colors.white, textColor: AppColors.grey800, hasBorder: true)),
      ],
    );
  }

  Widget _buildRecentRoundCard(Map<String, dynamic> round, bool isDark) {
    final date = DateTime.parse(round['date']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: AppColors.golfLime.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: Text('${round['score']}', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.golfLime)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round['course'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text(DateFormat('MMMM d, yyyy').format(date), style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: AppColors.grey200, size: 18),
        ],
      ),
    );
  }

  Widget _buildAchievementsRow(List<dynamic> achievements, bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: achievements.length,
        itemBuilder: (context, i) {
          final a = achievements[i];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.golfLime.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getIcon(a['icon']), color: AppColors.golfLime, size: 24),
                const SizedBox(height: 6),
                Text(a['title'], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoList(Map<String, dynamic> profile, Map<String, dynamic>? stats, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.grey700 : AppColors.grey100),
      ),
      child: Column(
        children: [
          _InfoTile(icon: LucideIcons.mapPin, label: 'Home Club', value: stats?['homeCourse'] ?? 'None set', isFirst: true),
          _divider(isDark),
          _InfoTile(icon: LucideIcons.flag, label: 'Total Rounds', value: '${stats?['totalRounds'] ?? 0} played'),
          _divider(isDark),
          _InfoTile(icon: LucideIcons.trendingUp, label: 'Skill Level', value: profile['skillLevel'] ?? 'Amateur'),
          _divider(isDark),
          _InfoTile(icon: LucideIcons.footprints, label: 'Play Style', value: profile['playStyle'] ?? 'Mixed', isLast: true),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Padding(
    padding: const EdgeInsets.only(left: 56), 
    child: Divider(height: 1, color: isDark ? AppColors.grey700 : AppColors.grey100.withValues(alpha: 0.5))
  );

  Widget _buildErrorState(BuildContext context, String title, String sub, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.doubleBogey),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.grey500)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CupertinoButton(
                color: AppColors.golfLime,
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'trophy': return LucideIcons.trophy;
      case 'medal': return LucideIcons.medal;
      case 'flame': return LucideIcons.flame;
      default: return LucideIcons.award;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final bool hasBorder;
  const _StatBox({required this.label, required this.value, required this.color, this.textColor = Colors.white, this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(20),
        border: hasBorder ? Border.all(color: AppColors.grey200) : null,
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: textColor.withValues(alpha: 0.5), letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;
  const _InfoTile({required this.icon, required this.label, required this.value, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grey400),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.grey500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

final publicProfileProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.read(friendServiceProvider).streamProfile(uid);
});

final publicProfileStatsProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.read(friendServiceProvider).streamPlayerStats(uid);
});
