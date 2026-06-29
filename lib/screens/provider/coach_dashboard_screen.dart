import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/profile_image.dart';

class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final statsAsync = ref.watch(coachProfileStatsProvider);
    final realtimeProfileAsync = ref.watch(coachRealtimeProfileProvider);
    final revenueAsync = ref.watch(coachRevenueBreakdownProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(profile, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Quick Actions Pill Bar ──────────────────────────────────
                _buildPillActions(context, isDark),
                
                const SizedBox(height: 32),

                // ── Performance Metrics ─────────────────────────────────────
                const Text('PERFORMANCE METRICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                statsAsync.when(
                  data: (stats) {
                    // MERGE REAL-TIME DATA: Override views/rating from the stream if available
                    final mergedStats = Map<String, dynamic>.from(stats);
                    realtimeProfileAsync.whenData((rt) {
                      if (rt.containsKey('views')) mergedStats['views'] = rt['views'];
                      if (rt.containsKey('rating')) mergedStats['rating'] = rt['rating'];
                    });
                    
                    return _buildStatsGrid(mergedStats, isDark);
                  },
                  loading: () => const Center(child: CupertinoActivityIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
                
                const SizedBox(height: 32),

                // ── Revenue Section ─────────────────────────────────────────
                const Text('FINANCIAL OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                revenueAsync.when(
                  data: (rev) => _buildRevenueCard(rev, isDark),
                  loading: () => const SizedBox(height: 100, child: Center(child: CupertinoActivityIndicator())),
                  error: (_, _) => const SizedBox(),
                ),

                const SizedBox(height: 32),

                // ── Recent Students Activity ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECENT ACTIVITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                    TextButton(
                      onPressed: () => context.push('/coach/students'),
                      child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.emerald700)),
                    ),
                  ],
                ),
                _buildRecentActivityList(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(db.UserProfile? profile, bool isDark) {
    final bool isAvailable = (profile?.providerStatus ?? 'OFFLINE') == 'AVAILABLE';

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        centerTitle: false,
        title: Text(profile?.name.split(' ').first ?? 'Professional', 
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.grey900, 
            fontWeight: FontWeight.w900, 
            fontSize: 22, 
            letterSpacing: -0.5
          ),
        ),
        background: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
          alignment: Alignment.bottomLeft,
          child: const Text('Pro Dashboard', style: TextStyle(color: AppColors.grey400, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ),
      ),
      actions: [
        CupertinoSwitch(
          value: isAvailable,
          activeTrackColor: AppColors.emerald500,
          onChanged: (val) {
            ref.read(supabaseServiceProvider).updateStatus(val ? 'AVAILABLE' : 'OFFLINE');
          },
        ),
        const SizedBox(width: 16),
      ],
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  Widget _buildPillActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          _PillBtn(label: 'Schedule', icon: LucideIcons.calendar, color: Colors.indigo, onTap: () => context.push('/coach/sessions')),
          _PillBtn(label: 'Templates', icon: LucideIcons.target, color: AppColors.emerald700, onTap: () => context.push('/coach/drills')),
          _PillBtn(label: 'Payments', icon: LucideIcons.creditCard, color: Colors.orange, onTap: () => context.push('/coach/payments')),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _MetricCard(label: 'Avg Rating', value: stats['rating'].toStringAsFixed(1), icon: LucideIcons.star, color: Colors.amber, isDark: isDark),
        _MetricCard(label: 'Total Students', value: stats['students'].toString(), icon: LucideIcons.users, color: AppColors.emerald700, isDark: isDark),
        _MetricCard(label: 'Profile Views', value: stats['views'].toString(), icon: LucideIcons.eye, color: Colors.indigo, isDark: isDark),
        _MetricCard(label: 'New Activity', value: '+${stats['activity']}', icon: LucideIcons.trendingUp, color: AppColors.emerald500, isDark: isDark),
      ],
    );
  }

  Widget _buildRevenueCard(Map<String, double> revenue, bool isDark) {
    final fmt = NumberFormat('#,###');
    final total = revenue.values.fold<double>(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.emerald700.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.wallet, color: AppColors.emerald700, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Collected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey500)),
                    Text('KES ${fmt.format(total)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900, letterSpacing: -1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _RevenueMiniStat(label: 'MPESA', amount: revenue['MPESA'] ?? 0, color: AppColors.emerald500),
              _RevenueMiniStat(label: 'CASH', amount: revenue['CASH'] ?? 0, color: Colors.orange),
              _RevenueMiniStat(label: 'BANK', amount: revenue['BANK'] ?? 0, color: Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(bool isDark) {
    final studentsAsync = ref.watch(coachStudentsProvider);
    return studentsAsync.when(
      data: (list) {
        if (list.isEmpty) return const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text('No student activity yet')));
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: list.length > 3 ? 3 : list.length,
          itemBuilder: (context, i) {
            final profile = list[i]['profile'] as Map?;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  ProfileImage(url: profile?['avatarUrl'], size: 40, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?['name'] ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text('Joined ${list[i]['coaching_sessions']?['name'] ?? 'Session'}', 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _buildMiniPaymentBadge(list[i]['payment_status']),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildMiniPaymentBadge(dynamic status) {
    final bool isPaid = status == 'fully_paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (isPaid ? AppColors.emerald700 : Colors.orange).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(isPaid ? 'PAID' : 'PENDING', style: TextStyle(color: isPaid ? AppColors.emerald700 : Colors.orange, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = status == 'AVAILABLE';
    final color = isAvailable ? AppColors.emerald500 : AppColors.grey400;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(isAvailable ? 'LIVE' : 'OFFLINE', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900, letterSpacing: -1)),
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _RevenueMiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _RevenueMiniStat({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.grey500)),
            ],
          ),
          const SizedBox(height: 2),
          Text('KES ${fmt.format(amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.grey700)),
        ],
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PillBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Column(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: AppColors.grey600, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
