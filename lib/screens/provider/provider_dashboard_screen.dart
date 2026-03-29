import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart' as db;

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final interactionsAsync = ref.watch(providerInteractionsProvider);
    final providerAsync = ref.watch(currentProviderProvider);

    if (user == null) return const Center(child: CircularProgressIndicator());

    final isCoach = profile?.role == 'coach';
    // Prefer local profile name (Drift); fall back to Firebase Auth displayName
    final displayName = profile?.name ?? user.displayName ?? 'Professional';

    return Material(
      color: const Color(0xFFFBFBF9),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _SliverHeader(name: displayName, isCoach: isCoach),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const _QuickActions(),
                  const SizedBox(height: 32),
                  const Text('Performance Overview', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  interactionsAsync.when(
                    data: (interactions) => providerAsync.when(
                      data: (provider) => _StatsGrid(interactions: interactions, provider: provider),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 32),
                  const Text('Weekly Activity', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  interactionsAsync.when(
                    data: (interactions) => _WeeklyBarChart(interactions: interactions),
                    loading: () => const SizedBox(height: 200),
                    error: (_, _) => const SizedBox(),
                  ),
                  const SizedBox(height: 32),
                  const Text('Recent Activity', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          interactionsAsync.when(
            data: (interactions) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ActivityTile(interaction: interactions[index]),
                  childCount: interactions.length > 5 ? 5 : interactions.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _SliverHeader extends ConsumerWidget {
  final String name;
  final bool isCoach;
  const _SliverHeader({required this.name, required this.isCoach});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFFBFBF9),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back,', style: TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(isCoach ? 'Coach' : (name.split(' ').isNotEmpty ? name.split(' ').first : 'Professional'), 
              style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
          ],
        ),
        background: Container(color: const Color(0xFFFBFBF9)),
      ),
      actions: [
        IconButton(
          onPressed: () => ref.read(firebaseAuthServiceProvider).signOut(),
          icon: const Icon(LucideIcons.logOut, color: AppColors.grey900, size: 20),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionBtn(label: 'Edit Profile', icon: LucideIcons.user, onTap: () => context.push('/profile/settings')),
        const SizedBox(width: 12),
        // Navigate to profile settings where providers manage their availability
        _ActionBtn(label: 'Availability', icon: LucideIcons.calendar, onTap: () => context.push('/profile/settings')),
        const SizedBox(width: 12),
        // Navigate to the Caddie Marketplace (Discover tab)
        _ActionBtn(label: 'Contacts', icon: LucideIcons.users, onTap: () => context.push('/caddie')),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.grey900),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<db.Interaction> interactions;
  final db.Provider? provider;
  const _StatsGrid({required this.interactions, this.provider});

  @override
  Widget build(BuildContext context) {
    final contactsCount = interactions.length; 
    final sessions = interactions.where((i) => i.status == 'booked').length;
    final rating = provider?.rating ?? 0.0;
    final convRate = contactsCount > 0 ? (sessions / contactsCount * 100).toStringAsFixed(0) : '0';
    final views = provider?.views ?? 0;
    final streak = provider?.streak ?? 0;

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      childAspectRatio: 0.85,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(title: 'Contacts', value: '$contactsCount', icon: LucideIcons.phone, color: AppColors.golfSky, bgColor: AppColors.golfSky.withOpacity(0.1)),
        _StatCard(title: 'Sessions', value: '$sessions', icon: LucideIcons.flag, color: AppColors.emerald600, bgColor: AppColors.emerald600.withOpacity(0.1)),
        _StatCard(title: 'Rating', value: rating.toStringAsFixed(1), icon: LucideIcons.star, color: AppColors.golfSand, bgColor: AppColors.golfSand.withOpacity(0.1)),
        _StatCard(title: 'Conv. Rate', value: '$convRate%', icon: LucideIcons.trendingUp, color: AppColors.golfPurple, bgColor: AppColors.golfPurple.withOpacity(0.1)),
        _StatCard(title: 'Views', value: '$views', icon: LucideIcons.eye, color: AppColors.golfSand.withOpacity(0.8), bgColor: AppColors.golfSand.withOpacity(0.1)),
        _StatCard(title: 'Streak', value: '$streak', icon: LucideIcons.flame, color: AppColors.golfBrown, bgColor: AppColors.golfBrown.withOpacity(0.1)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
          Text(title, 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: color.withOpacity(0.8), fontWeight: FontWeight.w800, letterSpacing: 0)),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<db.Interaction> interactions;
  const _WeeklyBarChart({required this.interactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(); // local time
    final List<int> dailyCounts = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return interactions.where((i) {
        // Convert UTC → local before comparing calendar day
        final local = i.timestamp.isUtc ? i.timestamp.toLocal() : i.timestamp;
        return local.day == date.day && local.month == date.month && local.year == date.year;
      }).length;
    });

    final maxVal = (dailyCounts.isEmpty ? 5.0 : dailyCounts.reduce((a, b) => a > b ? a : b).toDouble()).clamp(5.0, 100.0);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal + 1,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A1A),
              tooltipRoundedRadius: 12,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} contacts',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = now.subtract(Duration(days: 6 - value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E').format(date)[0],
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyCounts[i].toDouble(),
                color: i == 6 ? AppColors.emerald700 : AppColors.emerald700.withOpacity(0.3),
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: const Color(0xFFF9FAFB),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final db.Interaction interaction;
  const _ActivityTile({required this.interaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWhatsApp = interaction.type == 'whatsapp';
    final String status = interaction.status;

    // Resolve the player's display name asynchronously
    final playerProfileAsync = ref.watch(specificUserProfileProvider(interaction.playerId));
    final playerName = playerProfileAsync.maybeWhen(
      data: (p) => p?.name ?? 'Player',
      orElse: () => 'Player',
    );

    // Format timestamp in local time
    final local = interaction.timestamp.isUtc ? interaction.timestamp.toLocal() : interaction.timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isWhatsApp ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
            child: Icon(
              isWhatsApp ? LucideIcons.messageCircle : LucideIcons.phone,
              color: isWhatsApp ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(playerName, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                Text(
                  '${DateFormat('MMM d, h:mm a').format(local)} • $status',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (status == 'pending')
            const Icon(LucideIcons.chevronRight, color: Color(0xFFD1D5DB), size: 20),
        ],
      ),
    );
  }
}
