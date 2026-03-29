import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/utils/handicap.dart';
import 'dart:io';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name ?? 'Player Profile', style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: false,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          
          final isPrivate = profile['privacyLevel'] == 'Private';
          final hcp = (profile['handicap'] as num?)?.toDouble();
          final bestScore = profile['bestScore'] as int?;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            child: Column(
              children: [
                _buildHeader(profile, hcp, bestScore),
                const SizedBox(height: 40),
                
                if (isPrivate)
                  _buildPrivatePlaceholder()
                else
                  _buildDetailedStats(profile),
              ],
            ),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile, double? hcp, int? bestScore) {
    final createdAt = (profile['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    return Column(
      children: [
        _buildLargeAvatar(profile['avatarUrl'], profile['name'] ?? 'G'),
        const SizedBox(height: 20),
        Text(profile['name'] ?? 'Golfer', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(
          'MEMBER SINCE ${DateFormat('MMM yyyy').format(createdAt)}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hcp != null) ...[
              _buildHandicapBadge(hcp),
              const SizedBox(width: 12),
            ],
            if (bestScore != null)
              _buildBestScoreBadge(bestScore),
          ],
        ),
      ],
    );
  }

  Widget _buildLargeAvatar(String? url, String name) {
    ImageProvider? imageProvider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        imageProvider = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) imageProvider = FileImage(file);
      }
    }

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
      ),
      child: imageProvider == null 
          ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 44, color: AppColors.grey200)))
          : null,
    );
  }

  Widget _buildHandicapBadge(double hcp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.emerald900,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.emerald900.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('HANDICAP INDEX', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(width: 12),
          Text(
            HandicapCalculator.format(hcp),
            style: const TextStyle(color: AppColors.golfLime, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBestScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('BEST SCORE', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          const SizedBox(width: 12),
          Text(
            score.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PLAYER OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        _buildInfoGroup([
          _buildInfoRow(LucideIcons.trendingUp, 'Skill Level', profile['skillLevel'] ?? 'Amateur'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.footprints, 'Play Style', profile['playStyle'] ?? 'Mixed'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.flag, 'Preferred Tees', profile['preferredTees'] ?? 'Standard'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.mapPin, 'Home Course', profile['homeCourse'] ?? 'None set'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.maximize, 'Distance Units', profile['units'] ?? 'Yards'),
        ]),
        
        const SizedBox(height: 40),
        const Text('ACCOUNT INFORMATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        _buildInfoGroup([
          _buildInfoRow(LucideIcons.mail, 'Email Status', 'Verified Player'),
          _buildDivider(),
          _buildInfoRow(LucideIcons.shield, 'Privacy Level', profile['privacyLevel'] ?? 'Public'),
        ]),
      ],
    );
  }

  Widget _buildInfoGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: AppColors.grey600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.grey500)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.grey900)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.only(left: 66),
    child: Divider(height: 1, color: AppColors.grey100.withValues(alpha: 0.5)),
  );

  Widget _buildPrivatePlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
            child: const Icon(LucideIcons.lock, size: 40, color: AppColors.grey200),
          ),
          const SizedBox(height: 24),
          const Text('Private Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.grey900)),
          const SizedBox(height: 8),
          const Text(
            'Detailed stats are hidden based on this player\'s privacy settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey500, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

final publicProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) async {
  final sync = ref.read(syncServiceProvider);
  return sync.getPublicProfileData(uid);
});
