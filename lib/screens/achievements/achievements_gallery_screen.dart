import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/models/achievement_model.dart';

class AchievementsGalleryScreen extends ConsumerWidget {
  const AchievementsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.grey900)),
        centerTitle: false,
      ),
      body: profileAsync.when(
        data: (profile) {
          final earnedIds = _parseBadges(profile?.badgesJson);
          return _buildContent(context, earnedIds);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildProgressCard(totalEarned, totalBadges),
          ),
        ),
        ...categories.map((cat) => _buildCategorySection(cat, earnedIds)).toList(),
      ],
    );
  }

  Widget _buildProgressCard(int earned, int total) {
    final percent = total > 0 ? (earned / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.emerald700, AppColors.emerald900]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Progress', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('$earned', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              Text(' / $total', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.grey500, letterSpacing: 1),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEarned ? AppColors.grey50 : AppColors.grey50.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              a.icon,
              size: 28,
              color: isEarned ? AppColors.emerald700 : AppColors.grey300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            a.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isEarned ? AppColors.grey900 : AppColors.grey300,
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetail(BuildContext context, Achievement a, bool isEarned) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(a.icon, size: 64, color: isEarned ? AppColors.emerald700 : AppColors.grey200),
            const SizedBox(height: 24),
            Text(a.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              a.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.grey500),
            ),
            const SizedBox(height: 32),
            if (!isEarned)
              const Text('Locked Milestone', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey400)),
            if (isEarned)
              Text('Earned +${a.points} pts', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.emerald700)),
          ],
        ),
      ),
    );
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
