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
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/utils/url_helper.dart';
import '../../core/models/analytics_models.dart';
import '../../core/database/database.dart';
import '../../core/database/database.dart' as db;
import '../../core/models/achievement_model.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/coaching_panel.dart';
import '../../widgets/loading_spinner.dart';

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
        if (user.uid != null) {
          ref.read(achievementServiceProvider).checkAllAchievements(user.uid!);
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
            user.id, 
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          profileAsync.valueOrNull?.role == 'coach' 
            ? 'Coach Profile' 
            : (profileAsync.valueOrNull?.role == 'caddie' ? 'Caddie Profile' : 'My Profile'), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 20)
        ),
        centerTitle: false,
        actions: [
          if (profileAsync.valueOrNull?.role == 'coach' || profileAsync.valueOrNull?.role == 'caddie')
            IconButton(
              icon: const Icon(LucideIcons.share2, color: AppColors.grey900, size: 20),
              onPressed: () {
                final provider = ref.read(currentProviderProvider).valueOrNull;
                if (provider != null) {
                  UrlHelper.shareProfile(
                    userId: provider.userId,
                    name: provider.name,
                    role: provider.role,
                  );
                }
              },
            ),
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
        loading: () => const LoadingSpinner(),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCoachProfile(BuildContext context, UserProfile? profile) {
    final providerAsync = ref.watch(currentProviderProvider);
    final statsAsync = ref.watch(coachProfileStatsProvider);
    final revenueAsync = ref.watch(coachRevenueBreakdownProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIdentityHeader(profile),
          const SizedBox(height: 32),
          
          statsAsync.when(
            data: (stats) => _buildRealtimeCoachStats(stats),
            loading: () => const LoadingSpinner(size: 60),
            error: (_, _) => const SizedBox(),
          ),

          const SizedBox(height: 32),
          revenueAsync.when(
            data: (rev) => _buildRevenueBreakdown(rev),
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),

          const SizedBox(height: 40),
          providerAsync.when(
            data: (provider) => Column(
              children: [
                if (provider != null) _buildProfessionalBio(provider),
                const SizedBox(height: 40),
                if (provider != null) _buildSpecializations(provider),
              ],
            ),
            loading: () => const LoadingSpinner(size: 60),
            error: (e, _) => Text('Error loading professional info: $e'),
          ),

          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('STUDENT REVIEWS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildRecentReviewsList(profile?.uid),

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

  Widget _buildRealtimeCoachStats(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _ProfessionalStatItem(label: 'RATING', value: stats['rating'].toStringAsFixed(1), icon: LucideIcons.star, color: AppColors.golfLime)),
            const SizedBox(width: 12),
            Expanded(child: _ProfessionalStatItem(label: 'STUDENTS', value: stats['students'].toString(), icon: LucideIcons.users, color: AppColors.emerald700)),
            const SizedBox(width: 12),
            Expanded(child: _ProfessionalStatItem(label: 'VIEWS', value: stats['views'].toString(), icon: LucideIcons.eye, color: AppColors.grey900)),
          ],
        ),
        const SizedBox(height: 12),
        _ProfessionalStatItem(
          label: 'STUDENT ACTIVITY (30D)', 
          value: '${stats['activity']} new enrollments', 
          icon: LucideIcons.activity, 
          color: AppColors.blue600,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown(Map<String, double> revenue) {
    final fmt = NumberFormat('#,###');
    final total = revenue.values.fold<double>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('REVENUE BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.grey100),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Collected', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey500)),
                  Text('KES ${fmt.format(total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.emerald700)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              _revenueRow('Cash Payments', revenue['CASH'] ?? 0, Colors.orange),
              const SizedBox(height: 12),
              _revenueRow('MPESA', revenue['MPESA'] ?? 0, AppColors.emerald500),
              const SizedBox(height: 12),
              _revenueRow('Bank Transfer', revenue['BANK'] ?? 0, AppColors.blue600),
            ],
          ),
        ),
      ],
    );
  }

  Widget _revenueRow(String label, double amount, Color color) {
    final fmt = NumberFormat('#,###');
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey800)),
        const Spacer(),
        Text('KES ${fmt.format(amount)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
      ],
    );
  }

  Widget _buildCaddieProfile(BuildContext context, UserProfile? profile) {
    final providerAsync = ref.watch(currentProviderProvider);

    return providerAsync.when(
      data: (provider) {
        if (provider == null) return const Center(child: Text('Caddie profile not found'));
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCaddieIdentityHeader(profile, provider),
              const SizedBox(height: 32),
              
              _CaddieProfileSection(
                title: 'PUBLIC PROFILE PREVIEW',
                child: _buildPublicProfilePreview(provider),
              ),
              
              const SizedBox(height: 32),
              
              _CaddieProfileSection(
                title: 'ACCOUNT SETTINGS',
                child: _buildCaddieAccountSettings(context, profile, provider),
              ),
            ],
          ),
        );
      },
      loading: () => const LoadingSpinner(),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCaddieIdentityHeader(UserProfile? profile, db.Provider provider) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.1), width: 4),
                ),
                child: ProfileImage(
                  url: _imageFile?.path ?? profile?.avatarUrl,
                  name: profile?.name,
                  size: 110,
                  isCircle: true,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey900,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(LucideIcons.camera, color: AppColors.golfLime, size: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          profile?.name ?? 'Caddie', 
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1)
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.emerald700, 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald700.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Text(
            'CERTIFIED CADDIE', 
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)
          ),
        ),
      ],
    );
  }

  Widget _buildPublicProfilePreview(db.Provider provider) {
    final courses = _parseList(provider.coursesJson);
    final homeClub = courses.isNotEmpty ? courses.first : 'No home club set';
    final isAvailable = provider.isAvailable;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _previewItem(LucideIcons.mapPin, 'Home Club', homeClub),
          _previewDivider(),
          _previewItem(LucideIcons.briefcase, 'Years of Experience', '${provider.experience} Years'),
          _previewDivider(),
          _previewItem(LucideIcons.fileText, 'Bio', provider.bio ?? 'No bio provided'),
          _previewDivider(),
          _previewItem(
            LucideIcons.circleDot, 
            'Availability Status', 
            isAvailable ? 'Available' : 'Unavailable',
            valueColor: isAvailable ? AppColors.emerald600 : AppColors.grey400,
          ),
        ],
      ),
    );
  }

  Widget _previewItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.grey400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(), 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 1.0)
                ),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w700, 
                    color: valueColor ?? AppColors.grey900,
                    height: 1.4,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Divider(height: 1, indent: 54),
  );

  Widget _buildCaddieAccountSettings(BuildContext context, UserProfile? profile, db.Provider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _CaddieSettingTile(
            icon: LucideIcons.userPlus,
            label: 'Edit Profile',
            onTap: () => context.push('/profile/settings'),
            isFirst: true,
          ),
          _settingsDivider(),
          _CaddieSettingTile(
            icon: LucideIcons.creditCard,
            label: 'Subscription Status',
            subtitle: 'Free Trial · 7 Days Left', 
            onTap: () => _showSubscriptionBottomSheet(context, profile, provider),
          ),
          _settingsDivider(),
          _CaddieSettingTile(
            icon: LucideIcons.externalLink,
            label: 'Manage Subscription',
            subtitle: 'Paystack Portal',
            onTap: () {},
          ),
          _settingsDivider(),
          _CaddieSettingTile(
            icon: LucideIcons.logOut,
            label: 'Log Out',
            labelColor: AppColors.doubleBogey,
            onTap: () async {
              await ref.read(supabaseAuthServiceProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showSubscriptionBottomSheet(BuildContext context, UserProfile? profile, db.Provider provider) {
    // Determine trial dates (fallback to today + 7 days if null)
    final now = DateTime.now();
    final trialStart = profile?.createdAt ?? now;
    final trialEnd = trialStart.add(const Duration(days: 7));
    final daysLeft = trialEnd.difference(now).inDays;
    final isTrial = daysLeft > 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Subscription', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text(
              isTrial ? 'You are currently on a 7-day free trial.' : 'Your subscription is active.',
              style: const TextStyle(color: AppColors.grey500, fontSize: 15, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 40),
            
            _buildSubscriptionInfoCard(
              title: 'CURRENT STATUS',
              value: isTrial ? 'FREE TRIAL' : 'ACTIVE PAID',
              valueColor: isTrial ? AppColors.blue700 : AppColors.emerald600,
              icon: LucideIcons.shieldCheck,
            ),
            const SizedBox(height: 16),
            
            if (isTrial) ...[
              _buildSubscriptionInfoCard(
                title: 'TRIAL PERIOD',
                value: '${DateFormat('MMM d').format(trialStart)} - ${DateFormat('MMM d, yyyy').format(trialEnd)}',
                subtitle: '$daysLeft days remaining',
                icon: LucideIcons.calendar,
              ),
              const SizedBox(height: 16),
              _buildSubscriptionInfoCard(
                title: 'UPCOMING CHARGE',
                value: 'KES 280.00',
                subtitle: 'Will be charged on ${DateFormat('MMM d').format(trialEnd)}',
                icon: LucideIcons.creditCard,
              ),
            ] else ...[
              _buildSubscriptionInfoCard(
                title: 'LAST PAYMENT',
                value: 'KES 280.00',
                subtitle: 'Paid via M-Pesa on ${DateFormat('MMM d').format(now)}',
                icon: LucideIcons.checkCircle2,
              ),
              const SizedBox(height: 16),
              _buildSubscriptionInfoCard(
                title: 'NEXT RENEWAL',
                value: DateFormat('MMM d, yyyy').format(now.add(const Duration(days: 30))),
                subtitle: 'Automatic renewal enabled',
                icon: LucideIcons.refreshCw,
              ),
            ],
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfoCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey25,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, size: 20, color: AppColors.grey400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor ?? AppColors.grey900)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsDivider() => const Padding(
    padding: EdgeInsets.only(left: 64),
    child: Divider(height: 1),
  );

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
          const SizedBox(height: 24),
          
          _buildTeeTimeReminderCard(context),
          const SizedBox(height: 40),
          
          Align(
            alignment: Alignment.centerLeft,
            child: const Text('CAREER SUMMARY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(stats),
          const SizedBox(height: 48),
          
          const CoachingPanel(),
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
              ProfileImage(
                url: _imageFile?.path ?? profile?.avatarUrl,
                name: profile?.name,
                size: 110,
                isCircle: true,
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
    final handicapStatus = ref.watch(handicapProvider).valueOrNull;
    final displayHandicap = handicapStatus?.currentIndex ?? profile?.handicap ?? 0.0;
    final isHandicapEligible = handicapStatus?.currentIndex != null || profile?.handicap != null;

    return GestureDetector(
      onTap: () {
        if (handicapStatus != null) {
          _showWHSAuditSheet(context, handicapStatus);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emerald900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppColors.emerald900.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('HANDICAP INDEX', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(
                      isHandicapEligible ? displayHandicap.toStringAsFixed(1) : 'PENDING',
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
                    Icon(
                      (handicapStatus?.trend ?? 0.0) <= 0 ? LucideIcons.trendingDown : LucideIcons.trendingUp, 
                      color: (handicapStatus?.trend ?? 0.0) <= 0 ? AppColors.golfLime : AppColors.doubleBogey, 
                      size: 28
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (handicapStatus?.trend ?? 0.0) < 0 ? 'Improving' : 'Stable',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (handicapStatus?.lowIndex != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LOW INDEX (LAST 365D)', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text(
                    handicapStatus!.lowIndex!.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildStatsGrid(AdvancedStats? stats) {
    return Row(
      children: [
        Expanded(child: _CareerStatItem(label: 'ROUNDS', value: stats?.roundsPlayed.toString() ?? '0', icon: LucideIcons.flag, color: AppColors.golfLime)),
        const SizedBox(width: 12),
        Expanded(child: _CareerStatItem(label: 'BEST', value: stats?.bestScoreString ?? '—', icon: LucideIcons.trophy, color: AppColors.golfLime)),
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
          _divider(),
          _ActionTile(
            icon: LucideIcons.users, 
            label: isProvider ? 'Contacts' : 'Friends', 
            subtitle: isProvider ? 'Friends' : 'Connect with others', 
            onTap: () => context.push('/profile/friends'),
          ),
          _divider(),
          _ActionTile(
            icon: LucideIcons.mapPin, 
            label: 'Home Course', 
            subtitle: profile?.homeCourseName ?? 'None set', 
            onTap: () => _showCoursePicker(),
          ),
          if (!isProvider) ...[
            _divider(),
            _ActionTile(
              icon: LucideIcons.award, 
              label: 'Badges', 
              subtitle: '${_parseBadges(profile?.badgesJson).length} earned', 
              onTap: () => context.push('/achievements'),
            ),
          ],
          _divider(),
          _ActionTile(
            icon: LucideIcons.logOut, 
            label: 'Sign Out', 
            subtitle: 'Logout from ScoreCaddie', 
            onTap: () async {
              await ref.read(supabaseAuthServiceProvider).signOut();
              if (context.mounted) context.go('/auth');
            },
            isLast: true,
            labelColor: AppColors.doubleBogey,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
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

  Widget _buildTeeTimeReminderCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/profile/tee-time-reminders'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.golfLime, Color(0xFFB8E986)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.golfLime.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.bell, color: AppColors.grey900, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tee Time Reminders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.grey900, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('Never miss a round', style: TextStyle(fontSize: 13, color: AppColors.grey900.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.grey900, size: 24),
          ],
        ),
      ),
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
      loading: () => const Center(child: CupertinoActivityIndicator()),
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
              Row(
                children: List.generate(5, (i) => Icon(
                  i < review.rating ? Icons.star_rounded : Icons.star_border_rounded, 
                  size: 14, 
                  color: i < review.rating ? AppColors.golfLime : AppColors.grey300,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showQRCodeDialog(UserProfile? profile) {
    // If there's already a code, show the dialog immediately.
    // If not, generate one silently and refresh before showing.
    if (profile?.friendCode == null) {
      ref.read(friendServiceProvider).ensureFriendCode().then((_) {
        ref.invalidate(userProfileProvider);
      });
    }

    showDialog(
      context: context,
      builder: (context) => _QRCodeDialog(profile: profile, ref: ref),
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
                      subtitle: Text(courses[i].location, style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () {
                        _updateField('homeCourse', courses[i]);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                loading: () => const Center(child: CupertinoActivityIndicator()),
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
        await (db.update(db.userProfiles)..where((u) => u.uid.equals(user.id))).write(UserProfilesCompanion(homeCourseId: drift.Value(course.id), homeCourseName: drift.Value(course.name)));
      }
      ref.invalidate(userProfileProvider);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  void _showWHSAuditSheet(BuildContext context, HandicapStatus status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => _WHSAuditContent(status: status, scrollController: controller),
      ),
    );
  }
}

class _ProfessionalStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;
  const _ProfessionalStatItem({required this.label, required this.value, required this.icon, required this.color, this.isWide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white60),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: isWide ? 20 : 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(28), 
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
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

class _WHSAuditContent extends ConsumerWidget {
  final HandicapStatus status;
  final ScrollController scrollController;

  const _WHSAuditContent({required this.status, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundsAsync = ref.watch(last20RoundsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: roundsAsync.when(
        data: (rounds) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildAuditHeader(status),
            const SizedBox(height: 32),
            _buildFormulaBlock(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ROUNDS USED IN CALCULATION (8 of 20)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendItem(true, 'Used in calc'),
                const SizedBox(width: 16),
                _buildLegendItem(false, 'Not used'),
              ],
            ),
            const SizedBox(height: 24),
            ...rounds.map((r) => _buildRoundRow(r, status.bestRoundIds.contains(r.round.id))),
            const SizedBox(height: 32),
            _buildArithmeticBreakdown(rounds, status),
            const SizedBox(height: 40),
          ],
        ),
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAuditHeader(HandicapStatus status) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.emerald900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald900.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CURRENT INDEX', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text(
                  status.currentIndex?.toStringAsFixed(1) ?? '—', 
                  style: const TextStyle(color: AppColors.golfLime, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.5)
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white10),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('LOW (365 DAYS)', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(
                status.lowIndex?.toStringAsFixed(1) ?? '—', 
                style: const TextStyle(color: AppColors.golfLime, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WHS FORMULA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.grey500, letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diff = (Gross - Course Rating) × 113 / Slope',
                style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: AppColors.emerald700, fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Index = avg of best 8 of 20 diffs × 0.96',
                style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w900, color: AppColors.emerald700, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                '20 most recent rounds are ranked by score differential. The best 8 are averaged, then multiplied by 0.96 to produce your handicap index.',
                style: TextStyle(color: AppColors.grey600, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(bool isUsed, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isUsed ? AppColors.emerald500 : Colors.transparent,
            shape: BoxShape.circle,
            border: isUsed ? null : Border.all(color: AppColors.grey400, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRoundRow(RoundWithTee item, bool isBest) {
    final round = item.round;
    final tee = item.tee;
    final df = DateFormat('d MMM yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isBest ? AppColors.emerald500 : Colors.transparent,
              shape: BoxShape.circle,
              border: isBest ? null : Border.all(color: AppColors.grey400, width: 1.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(round.courseName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.grey900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(df.format(round.playedAt), style: const TextStyle(color: AppColors.grey400, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.grey300, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      'Par ${tee?.par ?? 72} · Slope ${tee?.slopeRating ?? '—'}', 
                      style: const TextStyle(color: AppColors.grey400, fontSize: 12, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${round.adjustedGrossScore ?? round.totalScore}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.grey500),
                  ),
                  const SizedBox(width: 4),
                  const Text('gross', style: TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isBest ? const Color(0xFFE0F2F1) : AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text('DIFF', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.grey400)),
                Text(
                  (round.scoreDifferential != null) 
                    ? (round.scoreDifferential! > 0 ? '+' : '') + round.scoreDifferential!.toStringAsFixed(1)
                    : '—',
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 14, 
                    color: isBest ? const Color(0xFF00796B) : AppColors.grey900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArithmeticBreakdown(List<RoundWithTee> rounds, HandicapStatus status) {
    if (status.bestSum == null) return const SizedBox.shrink();
    
    final bestCount = status.bestRoundIds.length;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _breakdownRow('Sum of $bestCount best diffs', status.bestSum!.toStringAsFixed(1)),
          _breakdownDivider(),
          _breakdownRow('Average (÷ $bestCount)', status.bestAverage!.toStringAsFixed(2)),
          _breakdownDivider(),
          _breakdownRow('× 0.96 multiplier', status.bestAverageWithMultiplier!.toStringAsFixed(2)),
          _breakdownDivider(),
          _breakdownRow('Soft cap applied?', (status.currentIndex ?? 0) != status.bestAverageWithMultiplier ? 'Yes' : 'No'),
          _breakdownDivider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Handicap index', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              Text(
                status.currentIndex?.toStringAsFixed(1) ?? '—', 
                style: const TextStyle(color: AppColors.golfLime, fontSize: 24, fontWeight: FontWeight.w900)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(
            value, 
            style: const TextStyle(
              color: AppColors.golfLime, 
              fontSize: 16, 
              fontWeight: FontWeight.w900,
            )
          ),
        ],
      ),
    );
  }

  Widget _breakdownDivider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
  );
}

class _CaddieProfileSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _CaddieProfileSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title, 
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w800, 
              color: AppColors.grey500, 
              letterSpacing: 1.2
            )
          ),
        ),
        child,
      ],
    );
  }
}

class _CaddieSettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final Color? labelColor;

  const _CaddieSettingTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(28) : Radius.zero,
        bottom: isLast ? const Radius.circular(28) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: labelColor ?? AppColors.grey700, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 16, 
                      color: labelColor ?? AppColors.grey900,
                      letterSpacing: -0.3,
                    )
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!, 
                      style: const TextStyle(
                        color: AppColors.grey400, 
                        fontSize: 13, 
                        fontWeight: FontWeight.w500
                      )
                    ),
                  ],
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.grey200, size: 18),
          ],
        ),
      ),
    );
  }
}

/// A self-refreshing QR code dialog that watches userProfileProvider.
/// When ensureFriendCode() completes and the provider is invalidated,
/// this dialog updates automatically — no close/reopen needed.
class _QRCodeDialog extends ConsumerWidget {
  final UserProfile? profile;
  final WidgetRef ref;

  const _QRCodeDialog({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef innerRef) {
    // Watch the live profile so we get the friendCode the moment it's generated
    final liveProfile = innerRef.watch(userProfileProvider).valueOrNull ?? profile;
    final friendCode = liveProfile?.friendCode;
    final qrData = friendCode != null
        ? 'scorecaddie://friend/add/$friendCode'
        : 'scorecaddie://friend/add/${liveProfile?.uid ?? 'unknown'}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Scan to Connect',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            height: 220,
            child: friendCode == null
                ? const LoadingSpinner(size: 120)
                : QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.grey900,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.grey900,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          Text(liveProfile?.name ?? 'Golfer',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                friendCode == null
                    ? const Text('Generating...',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: AppColors.grey400,
                            fontWeight: FontWeight.bold))
                    : Text(
                        friendCode,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5),
                      ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (friendCode != null) {
                      Clipboard.setData(ClipboardData(text: friendCode));
                      TopNotification.showSuccess(context, 'Friend Code Copied!');
                    }
                  },
                  child: Icon(
                    LucideIcons.copy,
                    size: 16,
                    color: friendCode != null ? AppColors.emerald700 : AppColors.grey300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
