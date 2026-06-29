import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/profile_image.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../rounds/course_profile_screen.dart';
import '../../core/utils/connection_guard.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  LeaderboardTab _activeTab = LeaderboardTab.global;
  TimePeriod _period = TimePeriod.allTime;
  ScoringType _scoring = ScoringType.gross;
  String? _selectedCourseId;
  String? _selectedCourseName;
  db.Course? _selectedCourse;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardStreamProvider(LeaderboardParams(
      tab: _activeTab,
      period: _period,
      scoring: _scoring,
      courseId: _selectedCourseId,
    )));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterBar(),
              Expanded(
                child: leaderboardAsync.when(
                  data: (entries) => _buildContent(entries),
                  loading: () => _buildContent([]), // Show skeletons
                  error: (err, stack) => Center(child: Text('Error loading rankings: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rankings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.grey900, letterSpacing: -0.5)),
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(100)),
            child: Row(
              children: [
                _tabBtn('Friends', LeaderboardTab.friends),
                _tabBtn('Course', LeaderboardTab.course),
                _tabBtn('World', LeaderboardTab.global),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, LeaderboardTab tab) {
    final active = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeTab = tab);
          if (tab == LeaderboardTab.course && _selectedCourseId == null) {
            _showCoursePicker();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.grey900 : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.grey400)),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          if (_activeTab == LeaderboardTab.course) ...[
            _coursePickerChip(
              label: _selectedCourseName ?? 'SELECT COURSE',
              active: _selectedCourseId != null,
              onTap: _showCoursePicker,
              selectedCourse: _selectedCourse,
            ),
            const SizedBox(width: 12),
          ],
          _filterChip('GROSS', _scoring == ScoringType.gross, () => setState(() => _scoring = ScoringType.gross)),
          _filterChip('NET', _scoring == ScoringType.net, () => setState(() => _scoring = ScoringType.net)),
          const SizedBox(width: 12),
          _filterChip('THIS WEEK', _period == TimePeriod.thisWeek, () => setState(() => _period = TimePeriod.thisWeek)),
          _filterChip('THIS MONTH', _period == TimePeriod.thisMonth, () => setState(() => _period = TimePeriod.thisMonth)),
          _filterChip('ALL TIME', _period == TimePeriod.allTime, () => setState(() => _period = TimePeriod.allTime)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.golfLime : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: active ? AppColors.golfLime : AppColors.grey200),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.grey600)),
      ),
    );
  }

  Widget _coursePickerChip({required String label, required bool active, required VoidCallback onTap, db.Course? selectedCourse}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.emerald700 : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: active ? AppColors.emerald700 : AppColors.grey200),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 12, color: active ? Colors.white : AppColors.grey600),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: active ? Colors.white : AppColors.grey600)),
                ],
              ),
            ),
          ),
          if (active && selectedCourse != null) ...[
             const SizedBox(width: 8),
             GestureDetector(
               onTap: () {
                 debugPrint('INFO_NAV: Navigating to ${selectedCourse.name} Profile');
                 Navigator.push(context, MaterialPageRoute(builder: (context) => CourseProfileScreen(course: selectedCourse)));
               },
               child: Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(color: AppColors.grey100, shape: BoxShape.circle),
                 child: const Icon(LucideIcons.info, size: 14, color: AppColors.grey900),
               ),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(List<LeaderboardEntry> entries) {
    final user = ref.read(authStateProvider).valueOrNull;
    final myUid = user?.id;
    
    final myEntryIndex = entries.indexWhere((e) => e.userId == myUid);
    final myRank = myEntryIndex != -1 ? myEntryIndex + 1 : 0;
    final myEntry = myEntryIndex != -1 ? entries[myEntryIndex] : null;

    final top50 = entries.take(50).toList();
    final podium = top50.take(3).toList();
    final rest = top50.skip(3).toList();

    return RefreshIndicator(
      color: AppColors.emerald700,
      onRefresh: () async {
        await ConnectionGuard.run(context, () async {
          ref.invalidate(leaderboardStreamProvider(LeaderboardParams(
            tab: _activeTab,
            period: _period,
            scoring: _scoring,
            courseId: _selectedCourseId,
          )));
        });
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (podium.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPodium(podium),
            ),

          if (myRank > 50 && myEntry != null)
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('YOUR POSITION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.2)),
                     const SizedBox(height: 12),
                     _buildListTile(myRank, myEntry, isMe: true, isSticky: true),
                     const Divider(height: 40, color: AppColors.grey100),
                   ],
                 ),
               ),
             ),

          if (entries.isEmpty)
             SliverToBoxAdapter(
               child: Container(
                 padding: const EdgeInsets.symmetric(vertical: 64),
                 alignment: Alignment.center,
                 child: Column(
                   children: [
                     Icon(LucideIcons.trophy, color: AppColors.grey200, size: 48),
                     const SizedBox(height: 16),
                     const Text('No rankings yet', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
             ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final entry = rest[i];
                  return _buildListTile(i + 4, entry, isMe: entry.userId == myUid);
                },
                childCount: rest.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> podium) {
    final second = podium.length > 1 ? podium[1] : null;
    final first = podium.isNotEmpty ? podium[0] : null;
    final third = podium.length > 2 ? podium[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _PodiumCard(entry: second, rank: 2, height: 110, scoringType: _scoring)),
          const SizedBox(width: 12),
          Expanded(child: _PodiumCard(entry: first, rank: 1, height: 140, scoringType: _scoring)),
          const SizedBox(width: 12),
          Expanded(child: _PodiumCard(entry: third, rank: 3, height: 95, scoringType: _scoring)),
        ],
      ),
    );
  }

  Widget _buildListTile(int rank, LeaderboardEntry entry, {bool isMe = false, bool isSticky = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSticky ? AppColors.grey900 : (isMe ? AppColors.golfLime.withValues(alpha: 0.1) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isMe ? AppColors.golfLime : AppColors.grey100, width: isMe ? 2 : 1),
        boxShadow: [
          if (isMe || isSticky) BoxShadow(color: AppColors.golfLime.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w900, color: isSticky ? AppColors.golfLime : AppColors.grey400, fontSize: 16)),
          ),
          ProfileImage(url: entry.avatarUrl, name: entry.displayName, size: 44, isCircle: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName, style: TextStyle(fontWeight: FontWeight.w900, color: isSticky ? Colors.white : AppColors.grey900, fontSize: 15)),
                Row(
                  children: [
                    const Icon(LucideIcons.trendingUp, color: AppColors.emerald700, size: 10),
                    const SizedBox(width: 4),
                    Text('${entry.handicap.toStringAsFixed(1)} HCP', style: TextStyle(fontSize: 11, color: isSticky ? Colors.white70 : AppColors.grey500, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          if (_activeTab == LeaderboardTab.course && !isSticky)
             GestureDetector(
               onTap: () async {
                 if (entry.courseId != null) {
                    final dbInst = ref.read(databaseProvider);
                    final courseObj = await dbInst.getCourseBySupabaseId(entry.courseId!);
                    if (!mounted) return;
                    if (courseObj != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CourseProfileScreen(course: courseObj)));
                    }
                 }
               },
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
                 child: const Icon(LucideIcons.chevronRight, size: 14, color: AppColors.grey400),
               ),
             ),
          const SizedBox(width: 12),
          Text(
            '${entry.score.toInt()}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isSticky ? Colors.white : AppColors.grey900),
          ),
        ],
      ),
    );
  }

  void _showCoursePicker() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _CoursePickerSheet(
        onSelected: (course) {
          setState(() {
            _selectedCourse = course;
            _selectedCourseId = course.supabaseId;
            _selectedCourseName = course.name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int rank;
  final double height;
  final ScoringType scoringType;

  const _PodiumCard({required this.entry, required this.rank, required this.height, required this.scoringType});

  @override
  Widget build(BuildContext context) {
    final bool isSkeleton = entry == null;
    final Color metallicColor = rank == 1 
        ? const Color(0xFFFFD700) 
        : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

    final double avatarSize = rank == 1 ? 70 : 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: _WavyClipper(),
                    child: isSkeleton 
                      ? Container(color: AppColors.grey100)
                      : ProfileImage(url: entry!.avatarUrl, name: entry!.displayName, size: avatarSize, isCircle: false),
                  ),
                  CustomPaint(
                    size: Size(avatarSize, avatarSize),
                    painter: _WavyBorderPainter(color: metallicColor),
                  ),
                ],
              ),
            ),
            if (rank == 1 && !isSkeleton)
              const Positioned(
                top: -22,
                child: Icon(LucideIcons.crown, color: Color(0xFFFFD700), size: 30),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: isSkeleton ? AppColors.grey50 : AppColors.grey900,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
               if (!isSkeleton) BoxShadow(color: metallicColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSkeleton) ...[
                 Container(width: 40, height: 8, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(4))),
              ] else ...[
                Text(entry!.displayName.split(' ').first, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${entry!.score.toInt()}',
                  style: TextStyle(fontSize: rank == 1 ? 28 : 22, fontWeight: FontWeight.w900, color: metallicColor),
                ),
                Text(scoringType.name.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.5)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i <= 360; i++) {
      double angle = i * math.pi / 180;
      double wavyRadius = radius + 2 * math.sin(angle * 8); 
      double x = center.dx + wavyRadius * math.cos(angle);
      double y = center.dy + wavyRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _WavyBorderPainter extends CustomPainter {
  final Color color;
  _WavyBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final path = Path();
    final double radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i <= 360; i++) {
      double angle = i * math.pi / 180;
      double wavyRadius = radius + 2 * math.sin(angle * 8); 
      double x = center.dx + wavyRadius * math.cos(angle);
      double y = center.dy + wavyRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _CoursePickerSheet extends ConsumerStatefulWidget {
  final Function(db.Course) onSelected;
  const _CoursePickerSheet({required this.onSelected});

  @override
  ConsumerState<_CoursePickerSheet> createState() => _CoursePickerSheetState();
}

class _CoursePickerSheetState extends ConsumerState<_CoursePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SELECT COURSE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.grey900)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                icon: Icon(LucideIcons.search, size: 16, color: AppColors.grey400),
                hintText: 'Search golf clubs...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                final Map<String, db.Course> uniqueByName = {};
                for (var c in courses) {
                  final key = c.name.trim().toLowerCase();
                  if (!uniqueByName.containsKey(key)) {
                    uniqueByName[key] = c;
                  }
                }
                
                final filtered = uniqueByName.values.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                
                if (filtered.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No courses match your search')));
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(c.location, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
                      onTap: () => widget.onSelected(c),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    );
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
