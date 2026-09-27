import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../screens/onboarding/ob_style.dart';
import '../screens/onboarding/ob_widgets.dart';
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
          margin: const EdgeInsets.symmetric(vertical: 8),
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
              style: Ob.display(22),
            ),
            if (summary.upcomingCount > 0)
              Text(
                '${summary.upcomingCount} sessions booked',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Ob.creamA(.55),
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
            backgroundColor: Ob.cardFill,
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
        color: Ob.cardFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Ob.bg,
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
        unselectedLabelColor: Ob.creamA(.55),
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Ob.cream),
          ),
          subtitle: Text(
            '${DateFormat('MMM d').format(item.date)} • ${item.startTime}',
            style: TextStyle(color: Ob.creamA(.55), fontSize: 13),
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
          color: Ob.cardFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Ob.cardFill),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book a New Lesson',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Ob.cream),
                  ),
                  Text(
                    'Explore pros at your local club',
                    style: TextStyle(color: Ob.creamA(.55), fontSize: 12),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
          child: const Icon(LucideIcons.graduationCap, color: Ob.lime, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Get a coach', style: Ob.body(16, weight: FontWeight.w800)),
            Text('Book a session and see it here.', style: Ob.body(12, color: Ob.creamA(.6))),
          ]),
        ),
        ObButton(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          onPressed: () {
            ref.read(marketplaceRoleFilterProvider.notifier).state = 'coach';
            context.go('/caddie', extra: {'role': 'coach'});
          },
          child: Text('Find', style: Ob.label(14, weight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        color: Ob.cardFill,
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
