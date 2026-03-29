import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/database/database.dart' as db;
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/utils/handicap.dart';
import 'package:drift/drift.dart' as drift;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning,' : (hour < 17 ? 'Good afternoon,' : 'Good evening,');

    final profile = profileAsync.valueOrNull;
    final userName = profile?.name ?? user?.displayName?.split(' ').first ?? 'Golfer';
    final photoUrl = profile?.avatarUrl ?? user?.photoURL;
    final role = profile?.role ?? 'player';

    // DEBUG: print role to console
    debugPrint('DASHBOARD: Rendering for role -> $role');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildTopHeader(context, ref, greeting, userName, photoUrl, role),
          if (role == 'coach')
            ..._buildCoachDashboard(context, ref, profile)
          else if (role == 'caddie')
            ..._buildCaddieDashboard(context, ref, profile)
          else
            ..._buildPlayerDashboard(context, ref, profile),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, WidgetRef ref, String greeting, String userName, String? photoUrl, String role) {
    final roleDisplay = role == 'coach' ? 'Pro Coach' : (role == 'caddie' ? 'Pro Caddie' : '');

    return SliverAppBar(
      backgroundColor: const Color(0xFFF2F2F7),
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      centerTitle: false,
      titleSpacing: 24,
      toolbarHeight: 80,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role != 'player')
                  Text(
                    roleDisplay.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.emerald700,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  )
                else
                  Text(
                    greeting,
                    style: const TextStyle(
                      color: AppColors.grey500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: const TextStyle(
                    color: AppColors.grey900,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: _buildProfilePicture(photoUrl, userName),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(String? avatarUrl, String userName) {
    ImageProvider? imageProvider;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        imageProvider = NetworkImage(avatarUrl);
      } else {
        final file = File(avatarUrl);
        if (file.existsSync()) {
          imageProvider = FileImage(file);
        }
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey200,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        image: imageProvider != null 
          ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
          : null,
      ),
      child: imageProvider == null 
        ? Center(child: Text(userName.isNotEmpty ? userName[0] : 'G', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.grey500)))
        : null,
    );
  }

  // ============================================================================
  // COACH DASHBOARD
  // ============================================================================

  List<Widget> _buildCoachDashboard(BuildContext context, WidgetRef ref, db.UserProfile? profile) {
    final provider = ref.watch(currentProviderProvider).valueOrNull;
    final interactionsAsync = ref.watch(providerInteractionsProvider);
    final interactions = interactionsAsync.valueOrNull ?? [];
    
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfessionalMetricsRow(
                context,
                rating: provider?.rating ?? 0.0,
                students: provider?.totalBookings ?? 0,
                views: provider?.views ?? 0,
                primaryColor: AppColors.purple700,
              ),
              const SizedBox(height: 32),
              
              _buildAvailabilityCard(
                context,
                isAvailable: provider?.isAvailable ?? true,
                onToggle: (val) => _toggleAvailability(val),
                role: 'Coach',
              ),
              
              const SizedBox(height: 40),
              _buildSectionHeader('PENDING REQUESTS', () => context.push('/profile/friends')),
              const SizedBox(height: 16),
              _buildModernInteractionsList(interactions, emptyMessage: 'You\'re all caught up!'),
              
              const SizedBox(height: 40),
              _buildSectionHeader('PROFESSIONAL STATUS', null),
              const SizedBox(height: 16),
              _buildProfessionalStatusCard(
                provider: provider,
                role: 'Coach',
                color: AppColors.purple700,
              ),
              
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    ];
  }

  // ============================================================================
  // CADDIE DASHBOARD
  // ============================================================================

  List<Widget> _buildCaddieDashboard(BuildContext context, WidgetRef ref, db.UserProfile? profile) {
    final provider = ref.watch(currentProviderProvider).valueOrNull;
    final interactionsAsync = ref.watch(providerInteractionsProvider);
    final interactions = interactionsAsync.valueOrNull ?? [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfessionalMetricsRow(
                context,
                rating: provider?.rating ?? 0.0,
                students: provider?.totalBookings ?? 0, 
                views: provider?.views ?? 0,
                primaryColor: AppColors.blue700,
                studentLabel: 'Rounds',
              ),
              const SizedBox(height: 32),

              _buildAvailabilityCard(
                context,
                isAvailable: provider?.isAvailable ?? true,
                onToggle: (val) => _toggleAvailability(val),
                role: 'Caddie',
              ),
              
              const SizedBox(height: 40),
              _buildSectionHeader('ACTIVE BOOKINGS', () => context.push('/profile/friends')),
              const SizedBox(height: 16),
              _buildModernInteractionsList(interactions, emptyMessage: 'No active bookings.'),
              
              const SizedBox(height: 40),
              _buildSectionHeader('PROFESSIONAL STATUS', null),
              const SizedBox(height: 16),
              _buildProfessionalStatusCard(
                provider: provider,
                role: 'Caddie',
                color: AppColors.blue700,
              ),
              
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    ];
  }

  // ============================================================================
  // SHARED PROFESSIONAL WIDGETS (iOS Style)
  // ============================================================================

  void _toggleAvailability(bool val) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    
    final database = ref.read(databaseProvider);
    await (database.update(database.providers)..where((p) => p.userId.equals(user.uid)))
        .write(db.ProvidersCompanion(isAvailable: drift.Value(val)));
    
    // Immediate sync to Firestore
    final providerList = await (database.select(database.providers)..where((p) => p.userId.equals(user.uid))).get();
    if (providerList.isNotEmpty) {
      await ref.read(syncServiceProvider).syncProvider(providerList.first);
    }
    
    ref.invalidate(currentProviderProvider);
  }

  Widget _buildAvailabilityCard(BuildContext context, {required bool isAvailable, required Function(bool) onToggle, required String role}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.emerald700 : AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isAvailable ? AppColors.emerald700 : AppColors.grey900).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(isAvailable ? LucideIcons.checkCircle2 : LucideIcons.moon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'AVAILABLE NOW' : 'OFF DUTY',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                Text(
                  isAvailable ? 'Players can book your $role services.' : 'You are currently hidden from marketplace.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: isAvailable, 
            onChanged: onToggle,
            activeColor: AppColors.golfLime,
            trackColor: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalStatusCard({required db.Provider? provider, required String role, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(LucideIcons.award, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verified $role', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                    Text('${provider?.experience ?? 0} Years Experience', style: const TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.grey100),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Member Since', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(DateFormat('MMM yyyy').format(provider?.createdAt ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Rate', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 13)),
              Text('KES ${provider?.price?.toInt() ?? 0} /hr', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalMetricsRow(BuildContext context, {
    required double rating,
    required int students,
    required int views,
    required Color primaryColor,
    String studentLabel = 'Students'
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(rating.toStringAsFixed(1), 'Rating', LucideIcons.star, AppColors.golfLime, isPrimary: true),
          Container(height: 40, width: 1, color: AppColors.grey100),
          _buildMetricItem(students.toString(), studentLabel, LucideIcons.users, primaryColor),
          Container(height: 40, width: 1, color: AppColors.grey100),
          _buildMetricItem(views.toString(), 'Views', LucideIcons.eye, AppColors.grey900),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label, IconData icon, Color iconColor, {bool isPrimary = false}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
                letterSpacing: -1,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: iconColor),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.grey400,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildModernInteractionsList(List<db.Interaction> interactions, {required String emptyMessage}) {
    final pending = interactions.where((i) => i.status == 'pending').toList();
    if (pending.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          children: [
            const Icon(LucideIcons.checkCircle2, size: 40, color: AppColors.grey300),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: pending.take(3).map((i) => _buildModernRequestTile(i)).toList(),
    );
  }

  Widget _buildModernRequestTile(db.Interaction interaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey100),
            ),
            child: const Icon(LucideIcons.user, color: AppColors.grey400, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking Request', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                const SizedBox(height: 4),
                Text(
                  '${interaction.type.toUpperCase()} • ${DateFormat('MMM d').format(interaction.timestamp)}',
                  style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.chevronRight, color: AppColors.emerald700, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactReviewsList(String? providerId) {
    if (providerId == null) return const SizedBox.shrink();
    
    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.grey100),
            ),
            child: const Text('No reviews yet', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w600)),
          );
        }
        return Column(children: reviews.take(2).map((r) => _buildModernReviewTile(r)).toList());
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Text('Error loading reviews: $e'),
    );
  }

  Widget _buildModernReviewTile(db.Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.playerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.grey900)),
              Row(children: List.generate(5, (i) => Icon(LucideIcons.star, size: 14, color: i < review.rating ? AppColors.golfLime : AppColors.grey200))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.grey600, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PLAYER DASHBOARD (Preserved)
  // ============================================================================

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
            const SizedBox(height: 16), // Space from header
            _buildCalendar(context),
            const SizedBox(height: 24), // Increased space between calendar and CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildStartRoundCTA(context),
            ),
          ],
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildSectionHeader('PERFORMANCE OVERVIEW', () => context.push('/analytics')),
            const SizedBox(height: 16),
            _buildStatsGrid(context, ref, profile, totalRounds, averageScore, bestScore),
            const SizedBox(height: 40),
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
      onTap: () {
        context.push('/select-course');
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.golfLime,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.golfLime.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey900.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.play, color: AppColors.grey900, size: 28),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START ROUND',
                    style: TextStyle(
                      color: AppColors.grey900,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready for the first tee?',
                    style: TextStyle(
                      color: AppColors.grey700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
          final dayName = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][index];

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isToday ? AppColors.emerald700 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isToday ? [
                  BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                ] : null,
                border: !isToday ? Border.all(color: AppColors.grey100) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isToday ? Colors.white.withValues(alpha: 0.8) : AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isToday ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref, db.UserProfile? profile, AsyncValue<int> totalRounds, AsyncValue<double?> averageScore, AsyncValue<int?> bestScore) {
    final advancedStats = ref.watch(advancedStatsProvider).valueOrNull;
    final hcpValue = advancedStats?.handicapIndex ?? profile?.handicap;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          'Handicap',
          hcpValue != null ? HandicapCalculator.format(hcpValue) : 'N/A',
          LucideIcons.target,
          AppColors.golfLime,
          isAccent: true,
          chartData: (advancedStats != null && advancedStats.handicapHistory.length >= 2) ? advancedStats.handicapHistory : null,
        ),
        averageScore.when(
          data: (score) => _buildStatCard('Avg Score', score?.toStringAsFixed(1) ?? 'N/A', LucideIcons.trendingUp, Colors.white, chartData: advancedStats?.recentScores),
          loading: () => _buildStatCard('Avg Score', '...', LucideIcons.trendingUp, Colors.white),
          error: (e, _) => _buildStatCard('Avg Score', 'Error', LucideIcons.trendingUp, Colors.white),
        ),
        totalRounds.when(
          data: (count) => _buildStatCard('Total Rounds', count.toString(), LucideIcons.calendar, Colors.white),
          loading: () => _buildStatCard('Total Rounds', '...', LucideIcons.calendar, Colors.white),
          error: (e, _) => _buildStatCard('Total Rounds', 'Error', LucideIcons.calendar, Colors.white),
        ),
        bestScore.when(
          data: (score) => _buildStatCard(
            'Best Round', 
            score?.toString() ?? 'N/A', 
            LucideIcons.award, 
            AppColors.emerald800,
            isAccent: true,
            textColorOverride: Colors.white,
          ),
          loading: () => _buildStatCard('Best Round', '...', LucideIcons.award, AppColors.emerald800, isAccent: true, textColorOverride: Colors.white),
          error: (e, _) => _buildStatCard('Best Round', 'Error', LucideIcons.award, AppColors.emerald800, isAccent: true, textColorOverride: Colors.white),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {List<double>? chartData, bool isAccent = false, Color? textColorOverride}) {
    final textColor = textColorOverride ?? AppColors.grey900;
    final subtextColor = textColorOverride?.withValues(alpha: 0.7) ?? (isAccent ? AppColors.grey900.withValues(alpha: 0.6) : AppColors.grey500);
    final iconColor = textColorOverride?.withValues(alpha: 0.8) ?? (isAccent ? AppColors.grey900.withValues(alpha: 0.8) : AppColors.emerald700);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          if (chartData != null && chartData.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: chartData.reduce((a, b) => a < b ? a : b) - 1,
                    maxY: chartData.reduce((a, b) => a > b ? a : b) + 1,
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.4,
                        color: iconColor.withValues(alpha: 0.4),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(), 
            style: TextStyle(
              color: subtextColor, 
              fontSize: 10, 
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            style: TextStyle(
              color: textColor, 
              fontSize: 24, 
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastActivitiesList(BuildContext context, AsyncValue<List<db.Round>> recentRounds) {
    return recentRounds.when(
      data: (rounds) {
        if (rounds.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.calendar, size: 32, color: AppColors.grey300),
                ),
                const SizedBox(height: 16),
                const Text('No rounds played yet', style: TextStyle(color: AppColors.grey400, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: rounds.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final round = entry.value;
              final isLast = index == 2 || index == rounds.length - 1;
              return _buildActivityTile(context, round, isLast);
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  Widget _buildActivityTile(BuildContext context, db.Round round, bool isLast) {
    return GestureDetector(
      onTap: () => context.push('/round/${round.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey100),
                  ),
                  child: const Center(child: Icon(LucideIcons.mapPin, color: AppColors.grey500, size: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        round.courseName,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.grey900, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM d').format(round.playedAt)} • ${round.totalScore} Strokes',
                        style: const TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: round.scoreVsPar <= 0 ? AppColors.emerald50 : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    round.scoreVsPar > 0 ? '+${round.scoreVsPar}' : '${round.scoreVsPar == 0 ? 'E' : round.scoreVsPar}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: round.scoreVsPar <= 0 ? AppColors.emerald700 : AppColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 64, top: 16),
                child: Divider(height: 1, color: AppColors.grey100),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title, 
          style: const TextStyle(
            color: AppColors.grey500, 
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2
          )
        ),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: const Text('See All', style: TextStyle(color: AppColors.emerald700, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
