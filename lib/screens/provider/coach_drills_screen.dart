import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import 'coach_drill_builder_screen.dart';

class CoachDrillsScreen extends ConsumerStatefulWidget {
  const CoachDrillsScreen({super.key});

  @override
  ConsumerState<CoachDrillsScreen> createState() => _CoachDrillsScreenState();
}

class _CoachDrillsScreenState extends ConsumerState<CoachDrillsScreen> with SingleTickerProviderStateMixin {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Drills',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.grey900,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.emerald700,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.emerald700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: const [
            Tab(text: 'MY TEMPLATES'),
            Tab(text: 'ASSIGNED'),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Offset to clear the floating nav bar
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/coach/drills/new'),
          backgroundColor: AppColors.emerald700,
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: const Text('New Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TemplatesTab(isDark: isDark),
          _AssignedTab(isDark: isDark),
        ],
      ),
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  final bool isDark;
  const _TemplatesTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(coachDrillTemplatesProvider);

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return _buildEmptyState(
            LucideIcons.target,
            'No templates created',
            'Create drill templates to quickly assign them to your students.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final drill = templates[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.emerald700.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.target, color: AppColors.emerald700, size: 22),
                ),
                title: Text(drill['name'], 
                  style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900)),
                subtitle: Text('${drill['category']} • ${drill['difficulty']} • ${drill['drill_steps']?[0]?['count'] ?? 0} steps', 
                  style: const TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.grey300),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => CoachDrillBuilderScreen(drill: drill),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.grey300),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900)),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500, height: 1.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _AssignedTab extends ConsumerWidget {
  final bool isDark;
  const _AssignedTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(coachAssignmentsProvider);

    return assignmentsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return _buildEmptyState(
            LucideIcons.clipboardList,
            'No drills assigned',
            'You haven\'t assigned any drills to your students yet.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final a = list[i];
            final drill = a['drill'] as Map?;
            final player = a['player'] as Map?;
            final date = DateTime.parse(a['assigned_at']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: ProfileImage(url: player?['avatarUrl'], size: 48, borderRadius: 12),
                title: Text(
                  player?['name'] ?? 'Golfer',
                  style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Assigned: ${drill?['name'] ?? 'Drill'}',
                      style: const TextStyle(color: AppColors.emerald700, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(date.toLocal()),
                      style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.grey300),
                onTap: () {
                  // View student progress or assignment details
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.grey300),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900)),
            const SizedBox(height: 8),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500, height: 1.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
