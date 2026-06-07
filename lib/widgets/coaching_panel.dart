import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/models/coaching_summary.dart';
import '../providers/app_providers.dart';
import '../core/utils/calendar_helper.dart';
import '../screens/marketplace/caddie_marketplace_screen.dart';

class CoachingPanel extends ConsumerStatefulWidget {
  const CoachingPanel({super.key});

  @override
  ConsumerState<CoachingPanel> createState() => _CoachingPanelState();
}

class _CoachingPanelState extends ConsumerState<CoachingPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(playerCoachingSummaryStreamProvider);

    return summaryAsync.when(
      loading: () => const _LoadingShimmer(),
      error: (e, _) => _ErrorState(error: e.toString()),
      data: (summary) {
        if (summary.upcoming.isEmpty && summary.past.isEmpty) {
          return const _EmptyState();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(summary),
              const SizedBox(height: 16),
              if (summary.nextSession != null) ...[
                _buildNextSessionCard(summary.nextSession!),
                const SizedBox(height: 24),
              ],
              _buildTabs(),
              const SizedBox(height: 16),
              _buildTabContent(summary),
              const SizedBox(height: 16),
              _buildMarketplaceLink(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(PlayerCoachingSummary summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coaching',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (summary.upcomingCount > 0)
              Text(
                '${summary.upcomingCount} sessions booked',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
              ),
          ],
        ),
        IconButton(
          onPressed: () {
            // Future: Open dedicated coaching calendar
          },
          icon: const Icon(LucideIcons.calendar, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.grey100,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  Widget _buildNextSessionCard(CoachingOccurrenceDetail occurrence) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.golfLime,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.golfLime.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.golfLime.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NEXT SESSION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.flag, color: Colors.white70, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                occurrence.sessionName,
                style: const TextStyle(
                  color: AppColors.grey900,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.user, color: Colors.white.withValues(alpha: 0.8), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Coach ${occurrence.coachName}',
                    style: TextStyle(
                      color: AppColors.grey900.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _IconLabel(
                    icon: LucideIcons.calendar,
                    label: DateFormat('EEE, MMM d').format(occurrence.date),
                  ),
                  const SizedBox(width: 16),
                  _IconLabel(
                    icon: LucideIcons.clock,
                    label: occurrence.startTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/coaching/session/${occurrence.sessionId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grey900,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => CalendarHelper.addSessionToCalendar(
                        sessionName: occurrence.sessionName,
                        location: occurrence.location,
                        date: occurrence.date,
                        startTime: occurrence.startTime,
                        durationMinutes: occurrence.durationMinutes,
                      ),
                      icon: const Icon(LucideIcons.calendarPlus, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Message Coach
                      },
                      icon: const Icon(LucideIcons.messageCircle, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.golfLime,
        unselectedLabelColor: AppColors.grey500,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildTabContent(PlayerCoachingSummary summary) {
    return SizedBox(
      height: 240,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSessionList(summary.upcoming, 'No upcoming sessions', isPast: false),
          _buildSessionList(summary.past, 'No past sessions', isPast: true),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<CoachingOccurrenceDetail> items, String emptyMsg, {bool isPast = false}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: const TextStyle(color: AppColors.grey400),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 48),
      itemBuilder: (context, index) {
        final item = items[index];
        Widget trailingWidget = const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey300);
        
        if (isPast && item.attended != null) {
          if (item.attended == true) {
            trailingWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Attended', style: TextStyle(color: AppColors.golfLime, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.checkCircle2, color: AppColors.golfLime, size: 16),
              ],
            );
          } else {
             trailingWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Missed', style: TextStyle(color: AppColors.doubleBogey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.xCircle, color: AppColors.doubleBogey, size: 16),
              ],
            );
          }
        } else if (!isPast) {
          trailingWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => CalendarHelper.addSessionToCalendar(
                  sessionName: item.sessionName,
                  location: item.location,
                  date: item.date,
                  startTime: item.startTime,
                  durationMinutes: item.durationMinutes,
                ),
                icon: const Icon(LucideIcons.calendarPlus, size: 18, color: AppColors.grey400),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey300),
            ],
          );
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.golfLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.calendarCheck, color: AppColors.golfLime, size: 20),
          ),
          title: Text(
            item.sessionName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            '${DateFormat('MMM d').format(item.date)} • ${item.startTime}',
            style: const TextStyle(color: AppColors.grey500, fontSize: 13),
          ),
          trailing: trailingWidget,
          onTap: () => context.push('/coaching/session/${item.sessionId}'),
        );
      },
    );
  }

  Widget _buildMarketplaceLink() {
    return InkWell(
      onTap: () {
        ref.read(marketplaceRoleFilterProvider.notifier).state = 'coach';
        context.go('/caddie', extra: {'role': 'coach'});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.golfLime.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.search, color: AppColors.golfLime, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book a New Lesson',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    'Explore pros at your local club',
                    style: TextStyle(color: AppColors.grey500, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: AppColors.grey400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _IconLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.grey900, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.graduationCap, size: 48, color: AppColors.grey300),
          const SizedBox(height: 16),
          const Text(
            'Start Professional Coaching',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Improve your game with expert guidance. Book your first session today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey500, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(marketplaceRoleFilterProvider.notifier).state = 'coach';
              context.go('/caddie', extra: {'role': 'coach'});
            },
            icon: const Icon(LucideIcons.search, size: 18),
            label: const Text('Find a Coach'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.golfLime,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    if (error.toString().contains('RealtimeSubscribeException') || error.toString().contains('timeout')) {
      return const _EmptyState();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Error loading coaching: $error', style: const TextStyle(color: Colors.red)),
    );
  }
}
