import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';

class CoachStudentsScreen extends ConsumerStatefulWidget {
  const CoachStudentsScreen({super.key});

  @override
  ConsumerState<CoachStudentsScreen> createState() => _CoachStudentsScreenState();
}

class _CoachStudentsScreenState extends ConsumerState<CoachStudentsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(coachStudentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text(
          'My Students',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.grey900,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -1,
          ),
        ),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSearchBar(isDark),
          ),
          studentsAsync.when(
            data: (enrollments) {
              if (enrollments.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(isDark),
                );
              }

              final filtered = enrollments.where((e) {
                final player = e['profile'] as Map<String, dynamic>?;
                final name = player?['name']?.toString().toLowerCase() ?? '';
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                 return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('No students matching "$_searchQuery"', 
                      style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600)),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _StudentCard(
                      enrollment: filtered[index],
                      isDark: isDark,
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('Error loading students: $e', 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.doubleBogey, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.grey800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 20, color: AppColors.grey400),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.grey900,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.emerald700.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.users, size: 40, color: AppColors.emerald700),
        ),
        const SizedBox(height: 24),
        Text(
          'No students yet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'When players book your coaching sessions, they will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey500, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends ConsumerWidget {
  final Map<String, dynamic> enrollment;
  final bool isDark;

  const _StudentCard({required this.enrollment, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = enrollment['profile'] as Map<String, dynamic>?;
    final session = enrollment['coaching_sessions'] as Map<String, dynamic>?;
    final playerName = profile?['name'] ?? 'Unknown Player';
    final playerId = profile?['id'] as String? ?? '';
    final avatarUrl = profile?['avatarUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.2), width: 2),
                    ),
                    child: ProfileImage(
                      url: avatarUrl, 
                      size: 56, 
                      borderRadius: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playerName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.grey900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 12, color: AppColors.grey400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                session?['name'] ?? 'Active Session',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildPaymentBadge(enrollment['payment_status']),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: isDark ? AppColors.grey700.withValues(alpha: 0.3) : AppColors.grey50,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: LucideIcons.messageCircle,
                      label: 'Message',
                      onTap: () => context.push('/chat/$playerId'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: LucideIcons.target,
                      label: 'Assign Drill',
                      onTap: () => _showAssignDrillModal(context, ref, playerId, playerName),
                      isDark: isDark,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(dynamic status) {
    final bool isPaid = status == 'fully_paid';
    final color = isPaid ? AppColors.emerald700 : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isPaid ? 'PAID' : 'PENDING',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAssignDrillModal(BuildContext context, WidgetRef ref, String playerId, String playerName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AssignDrillModal(
        playerId: playerId,
        playerName: playerName,
        isDark: isDark,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary 
              ? AppColors.emerald700 
              : (isDark ? AppColors.grey800 : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: isDark ? AppColors.grey700 : AppColors.grey200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isPrimary ? Colors.white : AppColors.emerald700),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isPrimary ? Colors.white : (isDark ? Colors.white : AppColors.grey800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignDrillModal extends ConsumerWidget {
  final String playerId;
  final String playerName;
  final bool isDark;

  const _AssignDrillModal({
    required this.playerId,
    required this.playerName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey900 : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assign Drill', 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.grey900, letterSpacing: -0.5)),
                    Text('Choose a template for $playerName', 
                      style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: isDark ? AppColors.grey800 : Colors.white, shape: BoxShape.circle),
                    child: Icon(LucideIcons.x, size: 20, color: AppColors.grey400),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ref.watch(coachDrillTemplatesProvider).when(
              data: (templates) {
                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.target, size: 64, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        const Text('No drill templates found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Create templates in your Practice menu first.', 
                          textAlign: TextAlign.center, 
                          style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
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
                        title: Text(drill['name'], 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppColors.grey900)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(drill['category'].toString().toUpperCase(), 
                            style: const TextStyle(color: AppColors.emerald700, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        trailing: const Icon(LucideIcons.plusCircle, color: AppColors.emerald700, size: 24),
                        onTap: () async {
                          try {
                            await ref.read(coachingServiceProvider).assignDrillToPlayer(
                              drillId: drill['id'],
                              playerId: playerId,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              TopNotification.showSuccess(context, 'Drill assigned to $playerName');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              TopNotification.showError(context, 'Error: $e');
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
