import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/utils/handicap.dart';
import 'player_profile_screen.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:math' as math;
import 'dart:io';
import 'package:go_router/go_router.dart';

// Filter Class for the Provider
class LeaderboardFilter {
  final String type;
  final String timePeriod;
  final String metric;
  final int? courseId;

  LeaderboardFilter({required this.type, required this.timePeriod, required this.metric, this.courseId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          timePeriod == other.timePeriod &&
          metric == other.metric &&
          courseId == other.courseId;

  @override
  int get hashCode => type.hashCode ^ timePeriod.hashCode ^ metric.hashCode ^ courseId.hashCode;
}

// Real Data Provider for Leaderboards
final leaderboardDataProvider = FutureProvider.family<List<Map<String, dynamic>>, LeaderboardFilter>((ref, filter) async {
  final db = ref.read(databaseProvider);
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) return [];

  DateTime? startDate;
  final now = DateTime.now();
  if (filter.timePeriod == 'Today') {
    startDate = DateTime(now.year, now.month, now.day);
  } else if (filter.timePeriod == 'This Week') {
    startDate = now.subtract(Duration(days: now.weekday - 1));
    startDate = DateTime(startDate.year, startDate.month, startDate.day);
  } else if (filter.timePeriod == 'This Month') {
    startDate = DateTime(now.year, now.month, 1);
  }

  final friendIds = (await db.getFriends(user.uid)).map((f) => f.friendId).toList();
  final allowedIds = filter.type == 'Friends' ? [user.uid, ...friendIds] : null;

  final query = db.select(db.rounds).join([
    drift.innerJoin(db.userProfiles, db.userProfiles.firebaseUid.equalsExp(db.rounds.userId)),
  ]);

  if (startDate != null) {
    query.where(db.rounds.playedAt.isBiggerOrEqualValue(startDate));
  }
  if (allowedIds != null) {
    query.where(db.rounds.userId.isIn(allowedIds));
  }
  if (filter.type == 'Course' && filter.courseId != null) {
    query.where(db.rounds.courseId.equals(filter.courseId!));
  }

  // Sorting by metric
  if (filter.metric == 'Low Gross') {
    query.orderBy([drift.OrderingTerm.asc(db.rounds.totalScore)]);
  } else {
    query.orderBy([drift.OrderingTerm.asc(db.rounds.totalScore)]);
  }

  final results = await query.get();
  
  final Map<String, Map<String, dynamic>> bestPerPlayer = {};
  
  for (final row in results) {
    final r = row.readTable(db.rounds);
    final p = row.readTable(db.userProfiles);
    final userId = r.userId ?? '';
    
    final hcp = p.handicap ?? 0.0;
    final netScore = r.totalScore - hcp;
    
    final currentScore = filter.metric == 'Net Score' ? netScore : r.totalScore.toDouble();
    
    if (!bestPerPlayer.containsKey(userId) || (filter.metric == 'Handicap Index' ? hcp < bestPerPlayer[userId]!['score'] : currentScore < bestPerPlayer[userId]!['score'])) {
      bestPerPlayer[userId] = {
        'userId': userId,
        'name': p.name,
        'avatarUrl': p.avatarUrl,
        'hcp': p.handicap ?? 18.0,
        'score': filter.metric == 'Handicap Index' ? p.handicap : (filter.metric == 'Net Score' ? netScore : r.totalScore),
        'isUser': userId == user.uid,
        'trend': 'stable',
        'course': r.courseName,
        'privacy': p.privacyLevel,
      };
    }
  }

  final sortedList = bestPerPlayer.values.toList();
  if (filter.metric == 'Handicap Index') {
    sortedList.sort((a, b) => (a['hcp'] as double).compareTo(b['hcp'] as double));
  } else {
    sortedList.sort((a, b) => (a['score'] as num).compareTo(b['score'] as num));
  }

  return sortedList.asMap().entries.map((e) {
    final item = Map<String, dynamic>.from(e.value);
    item['rank'] = e.key + 1;
    return item;
  }).toList();
});

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTime = 'This Week';
  String _selectedMetric = 'Low Gross';
  int? _selectedCourseId;
  String? _selectedCourseName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFFF2F2F7),
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text('Leaderboards', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppColors.grey900, letterSpacing: -0.5)),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.bell, color: AppColors.grey900),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildFilters(),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: AppColors.emerald700,
                unselectedLabelColor: AppColors.grey400,
                indicatorColor: AppColors.emerald700,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.2),
                tabs: const [
                  Tab(text: 'Global'),
                  Tab(text: 'Friends'),
                  Tab(text: 'Course'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboardList('Global'),
            _buildLeaderboardList('Friends'),
            _buildLeaderboardList('Course'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final bool isCourseTab = _tabController.index == 2;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          _FilterChip(
            label: _selectedTime,
            onTap: () => _showFilterPicker('Time Period', ['Today', 'This Week', 'This Month', 'All Time'], (val) => setState(() => _selectedTime = val)),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: _selectedMetric,
            onTap: () => _showFilterPicker('Metric', ['Low Gross', 'Net Score', 'Handicap Index'], (val) => setState(() => _selectedMetric = val)),
          ),
          if (isCourseTab) ...[
            const SizedBox(width: 12),
            _FilterChip(
              label: _selectedCourseName ?? 'Select Course',
              onTap: _showCoursePicker,
            ),
          ],
        ],
      ),
    );
  }

  void _showCoursePicker() async {
    final courses = await ref.read(databaseProvider).getAllCourses(null);
    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Course', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.grey100)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(courses[i].name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      onTap: () {
                        setState(() {
                          _selectedCourseId = courses[i].id;
                          _selectedCourseName = courses[i].name;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String type) {
    final filter = LeaderboardFilter(
      type: type,
      timePeriod: _selectedTime,
      metric: _selectedMetric,
      courseId: type == 'Course' ? _selectedCourseId : null,
    );
    final dataAsync = ref.watch(leaderboardDataProvider(filter));

    return dataAsync.when(
      data: (players) {
        if (type == 'Course' && _selectedCourseId == null) {
          return _buildEmptySelectCourse();
        }

        if (players.isEmpty) {
          return _buildEmptyData(type);
        }

        final userPlayer = players.firstWhere((p) => p['isUser'] == true, orElse: () => {});
        final isUserInTop10 = userPlayer.isNotEmpty && (userPlayer['rank'] as int) <= 10;

        return Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: _buildPodium(players),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        const skip = 3;
                        if (index + skip >= players.length) return null;
                        final player = players[index + skip];
                        final isFirst = index == 0;
                        final isLast = index + skip == players.length - 1;
                        return _buildLeaderboardRow(player, isFirst, isLast);
                      },
                      childCount: math.max(0, players.length - 3),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 160)),
              ],
            ),
            if (userPlayer.isNotEmpty && !isUserInTop10)
              Positioned(left: 0, right: 0, bottom: 0, child: _buildYourRankSticky(userPlayer)),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptySelectCourse() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(LucideIcons.mapPin, size: 48, color: AppColors.grey200),
          ),
          const SizedBox(height: 24),
          const Text('Select a Course', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Pick a course to see who\'s on top.', style: TextStyle(color: AppColors.grey500, fontSize: 14)),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: FilledButton(
              onPressed: _showCoursePicker,
              style: FilledButton.styleFrom(backgroundColor: AppColors.grey900, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('Pick Course', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyData(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.frown, size: 64, color: AppColors.grey200),
          const SizedBox(height: 16),
          Text('No rounds found for $type yet', style: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildYourRankSticky(Map<String, dynamic> userPlayer) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.emerald700, borderRadius: BorderRadius.circular(10)),
            child: Text('#${userPlayer['rank']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 16),
          _buildAvatar(userPlayer['avatarUrl'], userPlayer['name'], size: 40),
          const SizedBox(width: 12),
          const Text('YOUR RANKING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${userPlayer['score']}', style: const TextStyle(color: AppColors.golfLime, fontWeight: FontWeight.w900, fontSize: 22)),
              Text(_selectedMetric.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> players) {
    final p1 = players.isNotEmpty ? players[0] : null;
    final p2 = players.length > 1 ? players[1] : null;
    final p3 = players.length > 2 ? players[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _PodiumCard(player: p2, rank: 2, height: 160),
        _PodiumCard(player: p1, rank: 1, height: 200),
        _PodiumCard(player: p3, rank: 3, height: 140),
      ],
    );
  }

  Widget _buildLeaderboardRow(Map<String, dynamic> player, bool isFirst, bool isLast) {
    final isUser = player['isUser'] as bool;
    final rank = player['rank'] as int;
    
    return Container(
      decoration: BoxDecoration(
        color: isUser ? AppColors.emerald700.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(28) : Radius.zero,
          bottom: isLast ? const Radius.circular(28) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.push('/player/${player['userId']}?name=${Uri.encodeComponent(player['name'])}'),
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(28) : Radius.zero,
              bottom: isLast ? const Radius.circular(28) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(width: 32, child: _buildRankBadge(rank, isUser)),
                  const SizedBox(width: 8),
                  _buildAvatar(player['avatarUrl'], player['name'], size: 44),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
                        Text('HCP: ${HandicapCalculator.format(player['hcp'])}', style: const TextStyle(color: AppColors.grey400, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${player['score']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.grey900, letterSpacing: -0.5)),
                      Text(_selectedMetric == 'Net Score' ? 'NET' : (_selectedMetric == 'Handicap Index' ? 'INDEX' : 'GROSS'), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.grey300, letterSpacing: 0.5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 100),
              child: Divider(height: 1, color: AppColors.grey100.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank, bool isUser) {
    if (rank <= 3) {
      final color = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
      return Icon(LucideIcons.award, color: color, size: 22);
    }
    return Text('#$rank', style: TextStyle(fontWeight: FontWeight.w900, color: isUser ? AppColors.emerald700 : AppColors.grey300, fontSize: 13));
  }

  Widget _buildAvatar(String? url, String name, {required double size}) {
    ImageProvider? imageProvider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        imageProvider = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) imageProvider = FileImage(file);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey100, width: 1),
        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
      ),
      child: imageProvider == null 
          ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * 0.4, color: AppColors.grey300)))
          : null,
    );
  }

  void _showFilterPicker(String title, List<String> options, Function(String) onSelect) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: options.map((o) => CupertinoActionSheetAction(
          onPressed: () {
            onSelect(o);
            Navigator.pop(context);
          },
          child: Text(o, style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w600)),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic>? player;
  final int rank;
  final double height;
  const _PodiumCard({required this.player, required this.rank, required this.height});

  @override
  Widget build(BuildContext context) {
    final medalColor = rank == 1 ? const Color(0xFFFFD700) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    final hasPlayer = player != null;
    
    return GestureDetector(
      onTap: hasPlayer ? () => context.push('/player/${player!['userId']}?name=${Uri.encodeComponent(player!['name'])}') : null,
      child: Column(
        children: [
          if (rank == 1) 
            const Icon(LucideIcons.crown, color: Color(0xFFFFD700), size: 28),
          const SizedBox(height: 8),
          Container(
            width: 105,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: BoxDecoration(
              color: hasPlayer ? Colors.white : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(28),
              boxShadow: hasPlayer 
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildAvatar(hasPlayer ? player!['avatarUrl'] : null, hasPlayer ? player!['name'] : '?', size: 44, medalColor: medalColor),
                const SizedBox(height: 12),
                Text(
                  hasPlayer ? player!['name'] : 'Empty',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: hasPlayer ? AppColors.grey900 : AppColors.grey200,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (hasPlayer) ...[
                  Text('${player!['score']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: medalColor, letterSpacing: -0.5)),
                  Text('HCP ${HandicapCalculator.format(player!['hcp'])}', style: const TextStyle(fontSize: 9, color: AppColors.grey400, fontWeight: FontWeight.w700)),
                ] else
                  const Text('—', style: TextStyle(color: AppColors.grey100, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name, {required double size, required Color medalColor}) {
    ImageProvider? imageProvider;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        imageProvider = NetworkImage(url);
      } else {
        final file = File(url);
        if (file.existsSync()) imageProvider = FileImage(file);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        shape: BoxShape.circle,
        border: Border.all(color: medalColor.withValues(alpha: 0.3), width: 3),
        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
      ),
      child: imageProvider == null 
          ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: size * 0.4, color: AppColors.grey300)))
          : null,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.grey900)),
            const SizedBox(width: 6),
            const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F2F7), 
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
