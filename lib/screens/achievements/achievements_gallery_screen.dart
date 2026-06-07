import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/achievement_model.dart';
import '../../widgets/achievement_dialog.dart';

class AchievementsGalleryScreen extends ConsumerWidget {
  const AchievementsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.grey900)),
        centerTitle: false,
      ),
      body: profileAsync.when(
        data: (profile) {
          final earnedIds = _parseBadges(profile?.badgesJson);
          return _buildContent(context, earnedIds);
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Set<String> _parseBadges(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>().toSet();
    } catch (e) {
      debugPrint('Error parsing badges: $e');
    }
    return {};
  }

  Widget _buildContent(BuildContext context, Set<String> earnedIds) {
    final categories = AchievementCategory.values;
    final totalEarned = earnedIds.length;
    final totalBadges = Achievement.allAchievements.length;

    // Calculate total points
    int totalPoints = 0;
    for (var a in Achievement.allAchievements) {
      if (earnedIds.contains(a.id)) {
        totalPoints += a.points;
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildProgressCard(totalEarned, totalBadges, totalPoints),
          ),
        ),
        ...categories.map((cat) => _buildCategorySection(cat, earnedIds)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildProgressCard(int earned, int total, int points) {
    final percent = total > 0 ? (earned / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.golfLime,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL PROGRESS', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$earned', style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text('/ $total', style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.black.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(LucideIcons.sparkles, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('REWARDS COLLECTED', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  Text('$points PTS', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(AchievementCategory category, Set<String> earnedIds) {
    final catAchievements = Achievement.allAchievements.where((a) => a.category == category).toList();
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 12),
            child: Row(
              children: [
                _getCategoryIcon(category),
                const SizedBox(width: 8),
                Text(
                  category.name.toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: catAchievements.length,
            itemBuilder: (context, i) {
              final a = catAchievements[i];
              final isEarned = earnedIds.contains(a.id);
              return _buildBadgeItem(context, a, isEarned);
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, Achievement a, bool isEarned) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, a, isEarned),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isEarned ? Colors.white : Colors.white.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              boxShadow: isEarned ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))] : null,
            ),
            child: Icon(
              a.icon,
              size: 26,
              color: isEarned ? AppColors.emerald700 : AppColors.grey200,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isEarned ? AppColors.grey900 : AppColors.grey300,
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Achievement a, bool isEarned) {
    AchievementDialog.show(context, a, isEarned: isEarned);
  }

  Widget _getCategoryIcon(AchievementCategory cat) {
    IconData icon;
    switch (cat) {
      case AchievementCategory.scoring: icon = LucideIcons.target; break;
      case AchievementCategory.consistency: icon = LucideIcons.activity; break;
      case AchievementCategory.activity: icon = LucideIcons.calendar; break;
      case AchievementCategory.explorer: icon = LucideIcons.map; break;
      case AchievementCategory.social: icon = LucideIcons.users; break;
    }
    return Icon(icon, size: 16, color: AppColors.grey400);
  }
}
