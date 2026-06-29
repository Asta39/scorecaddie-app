import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/database/database.dart' as db;

// Providers with Name-Based Merging for 100% accuracy
final courseRecordsProvider = FutureProvider.family<Map<String, LeaderboardEntry?>, db.Course>((ref, course) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.fetchCourseRecords(course.supabaseId ?? 'none', course.name);
});

final personalBestProvider = FutureProvider.family<Map<String, LeaderboardEntry?>, db.Course>((ref, course) async {
  final service = ref.watch(leaderboardServiceProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return {'gross': null, 'net': null};
  return service.fetchPersonalBest(user.id, course.supabaseId ?? 'none', course.name);
});

final courseHolesProvider = FutureProvider.family<List<db.CourseHole>, int>((ref, courseId) async {
  final database = ref.watch(databaseProvider);
  return database.getHolesForCourse(courseId);
});

class CourseProfileScreen extends ConsumerWidget {
  final db.Course course;
  const CourseProfileScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(courseRecordsProvider(course));
    final personalBestAsync = ref.watch(personalBestProvider(course));
    final holesAsync = ref.watch(courseHolesProvider(course.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          // 1. FLOATING HERO CARD (Replaces the block header)
          SliverToBoxAdapter(
            child: _buildHeroCard(context),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Rankings & Records'),
                  const SizedBox(height: 16),
                  
                  // 2. ACCURATE DATA DISPLAY
                  recordsAsync.when(
                    data: (recs) => _buildRecordsComparison(recs, personalBestAsync.valueOrNull ?? {}),
                    loading: () => _loadingCard(),
                    error: (e, _) => Center(child: Text('Data fetch error: $e')),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Hole Layout'),
                  const SizedBox(height: 16),
                  holesAsync.when(
                    data: (holes) => _buildHoleList(holes),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('No hole data available'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final String imageName = '${course.name.trim()}.jpeg';
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 60, 16, 0), // Floating effect
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 25, offset: const Offset(0, 15))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // REMOVED BACKGROUND ICON ENTIRELY
          Image.asset(
            'assets/images/$imageName',
            fit: BoxFit.cover,
            errorBuilder: (context, _, _) => Container(color: AppColors.grey900), 
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name.toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: AppColors.golfLime, size: 12),
                    const SizedBox(width: 6),
                    Text(course.location, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                child: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(label: 'PAR', value: '${course.par18 ?? 72}'),
          _divider(),
          _StatItem(label: 'HOLES', value: '${course.totalHoles}'),
          _divider(),
          _StatItem(label: 'REGION', value: course.region ?? 'Kenya'),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 30, width: 1, color: AppColors.grey100);

  Widget _buildSectionTitle(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 2));
  }

  Widget _buildRecordsComparison(Map<String, LeaderboardEntry?> cloudRecs, Map<String, LeaderboardEntry?> personalRecs) {
    return Column(
      children: [
        _RecordCard(title: 'Gross Records', allTime: cloudRecs['gross'], personal: personalRecs['gross']),
        const SizedBox(height: 12),
        _RecordCard(title: 'Net Records', allTime: cloudRecs['net'], personal: personalRecs['net']),
      ],
    );
  }

  Widget _buildHoleList(List<db.CourseHole> holes) {
    if (holes.isEmpty) return const Text('Syncing course layout...', style: TextStyle(color: AppColors.grey400, fontSize: 12));
    
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: holes.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, i) {
          final h = holes[i];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${h.holeNumber}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey300)),
                const SizedBox(height: 4),
                Text('${h.par}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.grey900)),
                const Text('PAR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.grey300, letterSpacing: 1)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _loadingCard() => Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)));
}

class _RecordCard extends StatelessWidget {
  final String title;
  final LeaderboardEntry? allTime;
  final LeaderboardEntry? personal;

  const _RecordCard({required this.title, this.allTime, this.personal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLUB RECORD', style: TextStyle(color: AppColors.golfLime, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    if (allTime != null) ...[
                      Row(
                        children: [
                          Text('${allTime!.score.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(allTime!.displayName.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                Text(DateFormat('dd MMM').format(allTime!.roundDate), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const Text('--', style: TextStyle(color: Colors.white10, fontSize: 32, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.05), margin: const EdgeInsets.symmetric(horizontal: 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR BEST', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    if (personal != null)
                      Text('${personal!.score.toInt()}', style: const TextStyle(color: AppColors.golfLime, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1))
                    else
                      const Text('--', style: TextStyle(color: Colors.white10, fontSize: 32, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900)),
      ],
    );
  }
}
