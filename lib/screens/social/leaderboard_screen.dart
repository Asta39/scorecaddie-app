import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/app_providers.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/database/database.dart' as db;
import '../../widgets/profile_image.dart';
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
    final params = LeaderboardParams(tab: _activeTab, period: _period, scoring: _scoring, courseId: _selectedCourseId);
    final async = ref.watch(leaderboardStreamProvider(params));
    final entries = async.valueOrNull ?? const <LeaderboardEntry>[];
    final myUid = ref.read(authStateProvider).valueOrNull?.id;
    final mine = entries.indexWhere((e) => e.userId == myUid);
    final myEntry = mine == -1 ? null : entries[mine];
    final myRank = myEntry == null ? 0 : (myEntry.rank ?? mine + 1);
    final top = entries.where((e) => (e.rank ?? 0) <= 50).take(50).toList();

    final scope = switch (_activeTab) {
      LeaderboardTab.friends => 'among your friends',
      LeaderboardTab.course => 'at ${_selectedCourseName ?? 'this course'}',
      _ => 'in Kenya',
    };
    final when = switch (_period) { TimePeriod.thisWeek => 'this week', TimePeriod.thisMonth => 'this month', _ => 'of all time' };
    final what = _scoring == ScoringType.net ? 'net' : 'gross';

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Ob.ink,
            backgroundColor: Ob.lime,
            onRefresh: () async => ConnectionGuard.run(context, () async => ref.invalidate(leaderboardStreamProvider(params))),
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
              children: [
                const ObTabHeader('Leaderboard'),
                const SizedBox(height: 12),
                ObGooSegmented<LeaderboardTab>(
                  options: const [(LeaderboardTab.friends, 'Friends'), (LeaderboardTab.course, 'Course'), (LeaderboardTab.global, 'Kenya')],
                  selected: _activeTab,
                  onChanged: (t) {
                    setState(() => _activeTab = t);
                    if (t == LeaderboardTab.course && _selectedCourseId == null) _showCoursePicker();
                  },
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: ObGooSegmented<TimePeriod>(
                      options: const [(TimePeriod.thisWeek, 'Week'), (TimePeriod.thisMonth, 'Month'), (TimePeriod.allTime, 'All time')],
                      selected: _period,
                      onChanged: (v) => setState(() => _period = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ObGooSegmented<ScoringType>(
                      options: const [(ScoringType.gross, 'Gross'), (ScoringType.net, 'Net')],
                      selected: _scoring,
                      onChanged: (v) => setState(() => _scoring = v),
                    ),
                  ),
                ]),
                if (_activeTab == LeaderboardTab.course) ...[
                  const SizedBox(height: 14),
                  ObGroup(children: [
                    ObRow('Course', value: _selectedCourseName ?? 'Choose', onTap: _showCoursePicker),
                    if (_selectedCourse != null)
                      ObRow('Course details', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseProfileScreen(course: _selectedCourse!)))),
                  ]),
                ],
                const SizedBox(height: 16),
                Text('Best $what scores $scope, $when.', style: Ob.body(15, color: Ob.creamA(.6))),
                const SizedBox(height: 10),
                if (async.isLoading && entries.isEmpty)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
                else if (async.hasError && entries.isEmpty)
                  ObGroup(children: [const ObRow('Couldn’t load the rankings', subtitle: 'Pull down to try again')])
                else if (top.isEmpty)
                  ObGroup(children: [
                    ObRow(
                      'No scores yet',
                      subtitle: _activeTab == LeaderboardTab.friends ? 'Add friends to compare rounds' : 'Rounds played here show up as they’re saved',
                    ),
                  ])
                else ...[
                  ObGroup(children: [for (final (i, e) in top.indexed) _row(e.rank ?? i + 1, e, e.userId == myUid)]),
                  if (myEntry != null && myRank > 50) ...[
                    const SizedBox(height: 22),
                    ObGroup(header: 'You', children: [_row(myRank, myEntry, true)]),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(int rank, LeaderboardEntry e, bool me) {
    final medal = switch (rank) { 1 => const Color(0xFFB7791F), 2 => const Color(0xFF8E8E93), 3 => const Color(0xFFA0522D), _ => null };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        SizedBox(width: 30, child: Text('$rank', style: Ob.body(16, weight: FontWeight.w600, color: medal ?? Ob.creamA(.6)))),
        ProfileImage(url: e.avatarUrl, name: e.displayName, size: 36, isCircle: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(me ? '${e.displayName} (you)' : e.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(17, weight: FontWeight.w400, color: me ? Ob.lime : Ob.cream)),
            Text('HC ${e.handicap.toStringAsFixed(1)}', style: Ob.body(13, color: Ob.creamA(.6))),
          ]),
        ),
        Text('${e.score.toInt()}', style: Ob.display(20)),
      ]),
    );
  }

  void _showCoursePicker() {
    showObSheet(
      context,
      (sheet) => _CoursePickerSheet(
        onSelected: (course) {
          setState(() {
            _selectedCourse = course;
            _selectedCourseId = course.supabaseId;
            _selectedCourseName = course.name;
          });
          Navigator.pop(sheet);
        },
      ),
    );
  }
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
    
    return ObSheet(
      title: 'Choose a course',
      height: MediaQuery.of(context).size.height * 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            cursorColor: Ob.lime,
            style: Ob.body(17, weight: FontWeight.w400),
            decoration: obInput(null, hint: 'Search courses', prefix: const Icon(LucideIcons.search, size: 18)),
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
                
                if (filtered.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No courses match', style: Ob.body(15, color: Ob.creamA(.6)))));
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    return ObRow(c.name, subtitle: c.location, onTap: () => widget.onSelected(c));
                  },
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
              error: (err, _) => Center(child: Text('Couldn’t load courses.', style: Ob.body(15, color: Ob.creamA(.6)))),
            ),
          ),
        ],
      ),
    );
  }
}
