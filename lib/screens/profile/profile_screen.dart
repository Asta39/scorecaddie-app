import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/utils/handicap.dart';
import '../../core/models/analytics_models.dart';
import '../../core/database/database.dart';
import '../../core/database/database.dart' as db;
import '../../core/models/achievement_model.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = ref.read(userProfileProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user.name;
        if (user.firebaseUid != null) {
          ref.read(achievementServiceProvider).checkAllAchievements(user.firebaseUid!);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
        final user = ref.read(authStateProvider).valueOrNull;
        if (user != null) {
          await ref.read(profileServiceProvider).updateProfile(
            user.uid, 
            db.UserProfilesCompanion(avatarUrl: drift.Value(pickedFile.path))
          );
          ref.invalidate(userProfileProvider);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(advancedStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          profileAsync.valueOrNull?.role == 'coach' ? 'Coach Profile' : 'My Profile', 
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 20)
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppColors.grey900),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile?.role == 'coach') {
            return _buildCoachProfile(context, profile);
          } else if (profile?.role == 'caddie') {
            return _buildCaddieProfile(context, profile);
          }
          return _buildPlayerProfile(context, profile, statsAsync.valueOrNull);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCoachProfile(BuildContext context, UserProfile? profile) {
    final providerAsync = ref.watch(currentProviderProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIdentityHeader(profile),
          const SizedBox(height: 32),
          
          providerAsync.when(
            data: (provider) => Column(
              children: [
                _buildCoachStatsRow(provider),
                const SizedBox(height: 40),
                if (provider != null) _buildProfessionalBio(provider),
                const SizedBox(height: 40),
                if (provider != null) _buildSpecializations(provider),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading professional info: $e'),
          ),

          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('STUDENT REVIEWS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildRecentReviewsList(profile?.firebaseUid),

          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('ACCOUNT & SETTINGS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context, profile),
        ],
      ),
    );
  }

  Widget _buildCaddieProfile(BuildContext context, UserProfile? profile) {
    final providerAsync = ref.watch(currentProviderProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIdentityHeader(profile),
          const SizedBox(height: 32),
          
          providerAsync.when(
            data: (provider) => Column(
              children: [
                _buildCaddieStatsRow(provider),
                const SizedBox(height: 40),
                if (provider != null) _buildProfessionalBio(provider),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading caddie info: $e'),
          ),

          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('PLAYER REVIEWS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildRecentReviewsList(profile?.firebaseUid),

          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('ACCOUNT & SETTINGS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context, profile),
        ],
      ),
    );
  }

  Widget _buildPlayerProfile(BuildContext context, UserProfile? profile, AdvancedStats? stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIdentityHeader(profile),
          const SizedBox(height: 32),
          
          if (stats != null) _buildHandicapCard(profile, stats),
          const SizedBox(height: 40),
          
          _buildAchievementsSection(profile),
          const SizedBox(height: 40),
          
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('CAREER SUMMARY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(stats),
          const SizedBox(height: 40),
          
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('ACCOUNT & PREFERENCES', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context, profile),
        ],
      ),
    );
  }

  Widget _buildCoachStatsRow(db.Provider? provider) {
    return Row(
      children: [
        Expanded(child: _ProfessionalStatItem(label: 'RATING', value: provider?.rating.toStringAsFixed(1) ?? '0.0', icon: LucideIcons.star, color: AppColors.golfLime)),
        const SizedBox(width: 12),
        Expanded(child: _ProfessionalStatItem(label: 'STUDENTS', value: provider?.totalBookings.toString() ?? '0', icon: LucideIcons.users, color: AppColors.emerald700)),
        const SizedBox(width: 12),
        Expanded(child: _ProfessionalStatItem(label: 'VIEWS', value: provider?.views.toString() ?? '0', icon: LucideIcons.eye, color: AppColors.grey900)),
      ],
    );
  }

  Widget _buildCaddieStatsRow(db.Provider? provider) {
    return Row(
      children: [
        Expanded(child: _ProfessionalStatItem(label: 'RATING', value: provider?.rating.toStringAsFixed(1) ?? '0.0', icon: LucideIcons.star, color: AppColors.golfLime)),
        const SizedBox(width: 12),
        Expanded(child: _ProfessionalStatItem(label: 'ROUNDS', value: provider?.totalBookings.toString() ?? '0', icon: LucideIcons.flag, color: AppColors.emerald700)),
        const SizedBox(width: 12),
        Expanded(child: _ProfessionalStatItem(label: 'VIEWS', value: provider?.views.toString() ?? '0', icon: LucideIcons.eye, color: AppColors.grey900)),
      ],
    );
  }

  Widget _buildProfessionalBio(db.Provider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROFESSIONAL BIO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Text(
            provider.bio ?? 'No bio provided yet. Complete your profile to attract more students.',
            style: const TextStyle(fontSize: 15, color: AppColors.grey800, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecializations(db.Provider provider) {
    final specs = _parseList(provider.specializationsJson);
    if (specs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SPECIALIZATIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: specs.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emerald100),
            ),
            child: Text(
              s.toUpperCase(), 
              style: const TextStyle(color: AppColors.emerald700, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)
            ),
          )).toList(),
        ),
      ],
    );
  }

  List<String> _parseList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded.cast<String>();
    } catch (e) {
      debugPrint('Error parsing json list: $e');
    }
    return [];
  }

  Widget _buildIdentityHeader(UserProfile? profile) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey50,
                  border: Border.all(color: AppColors.grey100, width: 4),
                  image: _imageFile != null 
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : (profile?.avatarUrl != null && (profile?.avatarUrl?.isNotEmpty ?? false)
                        ? (profile!.avatarUrl!.startsWith('http')
                            ? DecorationImage(image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover)
                            : DecorationImage(image: FileImage(File(profile.avatarUrl!)), fit: BoxFit.cover))
                        : null),
                ),
                child: (profile?.avatarUrl == null && _imageFile == null)
                    ? const Icon(LucideIcons.user, size: 44, color: AppColors.grey200)
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emerald700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(LucideIcons.camera, color: AppColors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(profile?.name ?? 'Guest User', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.qrCode, size: 20, color: AppColors.grey400),
              onPressed: () => _showQRCodeDialog(profile),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey900, 
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            (profile?.role ?? 'PLAYER').toUpperCase(), 
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => context.push('/profile/settings'),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.emerald50,
            foregroundColor: AppColors.emerald700,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('Edit Professional Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildHandicapCard(UserProfile? profile, AdvancedStats stats) {
    final displayHandicap = stats.handicapIndex ?? profile?.handicap ?? 0.0;
    final isHandicapEligible = stats.isHandicapEligible || profile?.handicap != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emerald900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.emerald900.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HANDICAP INDEX', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  isHandicapEligible ? HandicapCalculator.format(displayHandicap) : 'PENDING',
                  style: const TextStyle(color: AppColors.golfLime, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.trendingDown, color: AppColors.golfLime, size: 28),
                const SizedBox(height: 6),
                Text(
                  stats.scoreTrend != null && stats.scoreTrend! < 0 ? 'Improving' : 'Stable',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AdvancedStats? stats) {
    return Row(
      children: [
        Expanded(child: _CareerStatItem(label: 'ROUNDS', value: stats?.roundsPlayed.toString() ?? '0', icon: LucideIcons.flag, color: AppColors.emerald700)),
        const SizedBox(width: 12),
        Expanded(child: _CareerStatItem(label: 'BEST', value: stats?.bestScoreString ?? '—', icon: LucideIcons.trophy, color: AppColors.emerald800)),
        const SizedBox(width: 12),
        Expanded(child: _CareerStatItem(label: 'AVG', value: stats?.avgScoreString ?? '—', icon: LucideIcons.trendingDown, color: AppColors.grey900)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, UserProfile? profile) {
    final bool isProvider = profile?.role == 'coach' || profile?.role == 'caddie';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: LucideIcons.briefcase, 
            label: isProvider ? 'Professional Bag' : 'My Bag', 
            subtitle: 'Manage equipment', 
            onTap: () => context.push('/profile/bag'),
            isFirst: true,
          ),
          _Divider(),
          _ActionTile(
            icon: LucideIcons.users, 
            label: isProvider ? 'Contacts' : 'Friends', 
            subtitle: isProvider ? 'Students and friends' : 'Connect with others', 
            onTap: () => context.push('/profile/friends'),
          ),
          _Divider(),
          _ActionTile(
            icon: LucideIcons.mapPin, 
            label: 'Home Course', 
            subtitle: profile?.homeCourseName ?? 'None set', 
            onTap: () => _showCoursePicker(),
          ),
          if (!isProvider) ...[
            _Divider(),
            _ActionTile(
              icon: LucideIcons.award, 
              label: 'Badges', 
              subtitle: '${_parseBadges(profile?.badgesJson).length} earned', 
              onTap: () => context.push('/achievements'),
            ),
          ],
          _Divider(),
          _ActionTile(
            icon: LucideIcons.logOut, 
            label: 'Sign Out', 
            subtitle: 'Logout from ScoreCaddie', 
            onTap: () async {
              await ref.read(firebaseAuthServiceProvider).signOut();
              if (mounted) context.go('/auth');
            },
            isLast: true,
            labelColor: AppColors.doubleBogey,
          ),
        ],
      ),
    );
  }

  Widget _Divider() => Padding(
    padding: const EdgeInsets.only(left: 64),
    child: Divider(height: 1, color: AppColors.grey100),
  );

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

  Widget _buildAchievementsSection(UserProfile? profile) {
    final earnedIds = _parseBadges(profile?.badgesJson);
    final allBadges = Achievement.allAchievements;
    final displayBadges = allBadges.where((a) => earnedIds.contains(a.id)).toList();
    if (displayBadges.isEmpty) displayBadges.addAll(allBadges.take(5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ACHIEVEMENTS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
            TextButton(
              onPressed: () => context.push('/achievements'),
              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.emerald700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: displayBadges.length,
            itemBuilder: (context, i) {
              final b = displayBadges[i];
              final isEarned = earnedIds.contains(b.id);
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEarned ? AppColors.white : AppColors.grey50, 
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isEarned ? AppColors.emerald700.withValues(alpha: 0.1) : AppColors.grey100, width: 1.5),
                  boxShadow: isEarned ? [BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b.icon, color: isEarned ? AppColors.emerald700 : AppColors.grey200, size: 32),
                    const SizedBox(height: 8),
                    Text(b.title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isEarned ? AppColors.grey900 : AppColors.grey300), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReviewsList(String? providerId) {
    if (providerId == null) return const SizedBox.shrink();
    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.grey100)),
            child: const Text('No reviews yet', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w700)),
          );
        }
        return Column(children: reviews.take(3).map((r) => _buildReviewTile(r)).toList());
      },
      loading: () => Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Text('Error loading reviews: $e'),
    );
  }

  Widget _buildReviewTile(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grey100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.playerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.grey900)),
              Row(children: List.generate(5, (i) => Icon(LucideIcons.star, size: 14, color: i < review.rating ? AppColors.golfLime : AppColors.grey200))),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showQRCodeDialog(UserProfile? profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan to Connect', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 220,
              child: QrImageView(
                data: 'scorecaddie://friend/add/${profile?.firebaseUid ?? 'unknown'}',
                version: QrVersions.auto,
                size: 220.0,
                foregroundColor: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 20),
            Text(profile?.name ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text('UID: ${profile?.firebaseUid ?? 'unknown'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.grey400, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (profile?.firebaseUid != null) {
                        Clipboard.setData(ClipboardData(text: profile!.firebaseUid!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID Copied!'), behavior: SnackBarBehavior.floating));
                      }
                    },
                    child: const Icon(LucideIcons.copy, size: 16, color: AppColors.emerald700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: AppColors.grey900, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCoursePicker() {
    final coursesAsync = ref.watch(coursesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Home Course', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            Expanded(
              child: coursesAsync.when(
                data: (courses) => ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(courses[i].name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      subtitle: Text(courses[i].location ?? 'Kenya', style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () {
                        _updateField('homeCourse', courses[i]);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                loading: () => Center(child: CupertinoActivityIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateField(String field, dynamic value) async {
    final db = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    try {
      if (field == 'homeCourse') {
        final course = value as Course;
        await (db.update(db.userProfiles)..where((u) => u.firebaseUid.equals(user.uid))).write(UserProfilesCompanion(homeCourseId: drift.Value(course.id), homeCourseName: drift.Value(course.name)));
      }
      ref.invalidate(userProfileProvider);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }
}

class _ProfessionalStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ProfessionalStatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white60),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final Color? labelColor;

  const _ActionTile({required this.icon, required this.label, required this.subtitle, required this.onTap, this.isFirst = false, this.isLast = false, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(top: isFirst ? const Radius.circular(28) : Radius.zero, bottom: isLast ? const Radius.circular(28) : Radius.zero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey100)),
              child: Icon(icon, color: labelColor ?? AppColors.grey700, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: labelColor ?? AppColors.grey900)),
                  Text(subtitle, style: const TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.grey200, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CareerStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _CareerStatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white60),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white60, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}
