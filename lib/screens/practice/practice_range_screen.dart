import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart' as db_pkg;

class PracticeRangeScreen extends ConsumerWidget {
  const PracticeRangeScreen({super.key});

  Future<void> _startSession(BuildContext context, WidgetRef ref, String type, {int? drillId, String? coachDrillId, int? targetDistance}) async {
    _showLoggingChoice(context, ref, (isVoice) async {
      final database = ref.read(databaseProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      final syncService = ref.read(syncServiceProvider);

      if (user == null) return;
      final supabaseId = const Uuid().v4();

      // 1. Local Insert
      final sessionId = await database.into(database.practiceSessions).insert(
        db_pkg.PracticeSessionsCompanion.insert(
          userId: user.uid,
          supabaseId: drift.Value(supabaseId),
          startTime: drift.Value(DateTime.now()),
          sessionType: drift.Value(type),
          drillId: drift.Value(drillId),
          coachDrillId: drift.Value(coachDrillId),
          targetDistance: drift.Value(targetDistance),
        ),
      );

      // 2. Instant Sync
      final fullSession = await (database.select(database.practiceSessions)..where((s) => s.id.equals(sessionId))).get().then((list) => list.firstOrNull);
      if (fullSession != null) {
        syncService.syncPracticeSession(fullSession).catchError((e) => debugPrint('Sync error: $e'));
      }

      // 3. Navigate based on choice
      if (context.mounted) {
        context.push('/practice/session/$sessionId?isVoice=$isVoice');
      }
    });
  }

  void _showLoggingChoice(BuildContext context, WidgetRef ref, Function(bool isVoice) onSelected) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.golfLime.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.mic, color: AppColors.emerald700, size: 32),
              ),
              const SizedBox(height: 24),
              const Text('Start Grinding', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.grey900, decoration: TextDecoration.none)),
              const SizedBox(height: 12),
              const Text(
                'Choose your logging style.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500, decoration: TextDecoration.none, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildChoiceBtn(
                label: 'Voice AI (Daniel)', 
                sub: 'Premium, hands-free', 
                icon: LucideIcons.sparkles, 
                color: AppColors.emerald700,
                onTap: () {
                  Navigator.pop(context);
                  onSelected(true);
                }
              ),
              const SizedBox(height: 12),
              _buildChoiceBtn(
                label: 'Manual Entry', 
                sub: 'Classic logging', 
                icon: LucideIcons.edit3, 
                color: AppColors.grey400,
                onTap: () {
                  Navigator.pop(context);
                  onSelected(false);
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceBtn({required String label, required String sub, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey100),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.grey900, decoration: TextDecoration.none)),
                  Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.grey400, decoration: TextDecoration.none)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Practice', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppColors.grey900, letterSpacing: -0.5)),
        centerTitle: false,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode Selectors
                  Row(
                    children: [
                      _buildModeCard(
                        context,
                        ref,
                        'Free Practice',
                        'Casual tracking',
                        LucideIcons.target,
                        AppColors.emerald700,
                        () => _startSession(context, ref, 'FREE'),
                      ),
                      const SizedBox(width: 16),
                      _buildModeCard(
                        context,
                        ref,
                        'Performance',
                        'Range insights',
                        LucideIcons.barChart2,
                        AppColors.golfLime,
                        () => context.push('/practice/analytics'),
                        isAccent: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Phase 3: Assigned Drills Section
                  ref.watch(assignedDrillsProvider).when(
                    data: (assigned) {
                      if (assigned.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('ASSIGNED BY COACH', null),
                          const SizedBox(height: 16),
                          ...assigned.map((a) {
                            final drill = a['drill'];
                            final coachName = a['coach']['name'] ?? 'Your Coach';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAssignedDrillCard(context, ref, drill, coachName),
                            );
                          }),
                          const SizedBox(height: 28),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  
                  // Popular Drills Title
                  _buildSectionHeader('POPULAR DRILLS', () {}),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Drills Stream
          StreamBuilder<List<Drill>>(
            stream: (db.select(db.drills)..where((d) => d.userId.isNull() | d.userId.equals(user?.uid ?? ''))).watch(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: CupertinoActivityIndicator()));
              }
              final drills = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDrillCard(context, ref, drills[index]),
                      );
                    },
                    childCount: drills.length,
                  ),
                ),
              );
            },
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Custom Drill Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => context.push('/practice/drills/new'),
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Create Custom Drill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.grey500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  
                  _buildSectionHeader('RECENT SESSIONS', null),
                  const SizedBox(height: 16),
                  _buildRecentSessions(db, user?.uid, context),
                  
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: const Text('See All', style: TextStyle(color: AppColors.emerald700, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _buildModeCard(BuildContext context, WidgetRef ref, String title, String sub, IconData icon, Color color, VoidCallback onTap, {bool isAccent = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isAccent ? color : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isAccent ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: isAccent ? Colors.white : color, size: 24),
              ),
              const SizedBox(height: 24),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: isAccent ? AppColors.grey900 : AppColors.grey900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(color: isAccent ? AppColors.grey900.withValues(alpha: 0.6) : AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedDrillCard(BuildContext context, WidgetRef ref, Map<String, dynamic> drill, String coachName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emerald700,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.emerald700.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.award, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASSIGNED BY ${coachName.toUpperCase()}', 
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                    ),
                    const SizedBox(height: 2),
                    Text(drill['name'] ?? 'Assigned Drill', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: -0.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDrillTag(LucideIcons.clock, '${drill['duration_minutes']}m', Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 16),
              _buildDrillTag(LucideIcons.flame, (drill['difficulty'] as String? ?? 'MED').toUpperCase(), Colors.white.withValues(alpha: 0.7)),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: const Text('Start Now', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.emerald700)),
                onPressed: () => _startSession(context, ref, 'COACH_DRILL', coachDrillId: drill['id']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrillCard(BuildContext context, WidgetRef ref, Drill drill) {
    final diffColor = _getDifficultyColor(drill.difficulty);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.target, color: AppColors.emerald700, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drill.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.grey900, letterSpacing: -0.3)),
                    Text(drill.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDrillTag(LucideIcons.clock, '${drill.durationMinutes}m', AppColors.grey400),
              const SizedBox(width: 16),
              _buildDrillTag(LucideIcons.flame, drill.difficulty.toUpperCase(), diffColor),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
                child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                onPressed: () => _startSession(context, ref, 'DRILL', drillId: drill.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrillTag(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner': return AppColors.emerald600;
      case 'intermediate': return AppColors.blue600;
      case 'advanced': return AppColors.birdie;
      case 'expert': return AppColors.doubleBogey;
      default: return AppColors.grey500;
    }
  }

  Widget _buildRecentSessions(AppDatabase db, String? userId, BuildContext context) {
    if (userId == null) return const SizedBox();
    
    return StreamBuilder<List<PracticeSession>>(
      stream: (db.select(db.practiceSessions)
            ..where((s) => s.userId.equals(userId) & s.endTime.isNotNull())
            ..orderBy([(t) => drift.OrderingTerm.desc(t.startTime)])
            ..limit(8))
          .watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: const Column(
              children: [
                Icon(LucideIcons.calendar, color: AppColors.grey100, size: 40),
                SizedBox(height: 12),
                Text('No completed sessions', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: snapshot.data!.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              final isLast = index == snapshot.data!.length - 1;
              return Column(
                children: [
                  ListTile(
                    onTap: () => context.push('/practice/summary/${session.id}'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.history, color: AppColors.grey400, size: 20),
                    ),
                    title: Text(session.sessionType, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                    subtitle: Text('${session.totalBalls} balls • ${_formatDuration(session.endTime!.difference(session.startTime))}', 
                      style: const TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${session.startTime.day}/${session.startTime.month}',
                          style: const TextStyle(color: AppColors.grey400, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey200),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(left: 72),
                      child: Divider(height: 1, color: Color(0xFFF2F2F7)),
                    ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    return '${d.inMinutes}m';
  }
}
