import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/club_feed_provider.dart';
import '../../widgets/post_card.dart';
import '../../widgets/pill.dart';
import '../../widgets/member_glass_card.dart';
import 'components/overview_tab.dart';

class ClubCommunityScreen extends ConsumerStatefulWidget {
  const ClubCommunityScreen({super.key});

  @override
  ConsumerState<ClubCommunityScreen> createState() => _ClubCommunityScreenState();
}

class _ClubCommunityScreenState extends ConsumerState<ClubCommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ('Overview', LucideIcons.layoutGrid),
    ('Feed', LucideIcons.radio),
    ('Events', LucideIcons.trophy),
    ('Members', LucideIcons.users),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Consumer(
          builder: (context, ref, child) {
            final activeClub = ref.watch(activeClubProvider);
            final membershipsAsync = ref.watch(userClubMembershipsProvider);
            
            return GestureDetector(
              onTap: () {
                if (membershipsAsync.valueOrNull == null) return;
                final memberships = membershipsAsync.valueOrNull!;
                
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppColors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Switch Club', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.grey900)),
                          ),
                          ...memberships.map((m) => ListTile(
                            title: Text(m.clubName, style: TextStyle(fontWeight: m.clubId == activeClub?.clubId ? FontWeight.bold : FontWeight.normal)),
                            trailing: m.clubId == activeClub?.clubId ? const Icon(LucideIcons.check, color: AppColors.golfLime) : null,
                            onTap: () {
                              ref.read(activeClubIdProvider.notifier).state = m.clubId;
                              Navigator.pop(context);
                            },
                          )),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Row(
                children: [
                  Text(
                    activeClub?.clubName ?? 'Club Community',
                    style: const TextStyle(
                      color: AppColors.grey900,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.chevronDown, color: AppColors.grey900, size: 20),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, color: AppColors.grey900),
            onPressed: () {
              // TODO: Search for new clubs to join
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.golfLime,
          unselectedLabelColor: AppColors.grey400,
          indicatorColor: AppColors.golfLime,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppTypeScale.meta),
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ClubOverviewTab(),
          _FeedTab(),
          _EventsTab(),
          _MembersTab(),
        ],
      ),
    );
  }
}



class _FeedTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activeClubFeedProvider).when(
      data: (posts) {
        final feedPosts = posts.where((p) => p.postType != 'competition').toList();
        if (feedPosts.isEmpty) return const Center(child: Text('No recent posts from your clubs.'));
        
        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
          itemCount: feedPosts.length,
          itemBuilder: (context, index) {
            final post = feedPosts[index];
            return PostCard(
              type: post.postType,
              title: post.title,
              content: post.content,
              timeAgo: formatTimeAgo(post.createdAt),
              author: post.authorName,
              imageUrl: post.imageUrl,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading feed: $e')),
    );
  }
}

class _EventsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  String _viewType = 'list'; // 'list' or 'diary'
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  int _daysInMonth(DateTime date) {
    var firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);
    return firstDayOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  int _firstWeekdayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(activeClubFeedProvider).when(
      data: (posts) {
        final compPosts = posts.where((p) => p.postType == 'fixture' || p.postType == 'result' || p.postType == 'competition').toList();
        
        return Column(
          children: [
            // View Toggle
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewType = 'list'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: _viewType == 'list' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _viewType == 'list'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'List View',
                            style: TextStyle(
                              fontSize: AppTypeScale.meta,
                              fontWeight: _viewType == 'list' ? FontWeight.w800 : FontWeight.w600,
                              color: _viewType == 'list' ? AppColors.grey900 : AppColors.grey500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewType = 'diary'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: _viewType == 'diary' ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _viewType == 'diary'
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Club Diary',
                            style: TextStyle(
                              fontSize: AppTypeScale.meta,
                              fontWeight: _viewType == 'diary' ? FontWeight.w800 : FontWeight.w600,
                              color: _viewType == 'diary' ? AppColors.grey900 : AppColors.grey500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: _viewType == 'list'
                  ? _buildListView(compPosts)
                  : _buildDiaryCalendarView(compPosts),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading events: $e')),
    );
  }

  Widget _buildListView(List<ClubPost> compPosts) {
    if (compPosts.isEmpty) {
      return const Center(child: Text('No upcoming events from your clubs.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 90),
      itemCount: compPosts.length,
      itemBuilder: (context, index) {
        final post = compPosts[index];
        return PostCard(
          type: post.postType,
          title: post.title,
          content: post.content,
          timeAgo: formatTimeAgo(post.createdAt),
          author: post.authorName,
          imageUrl: post.imageUrl,
          actionText: post.postType == 'fixture' || post.postType == 'competition' ? 'Register Now' : null,
          onAction: post.postType == 'fixture' || post.postType == 'competition'
              ? () => context.push('/competitions/${post.id}')
              : null,
        );
      },
    );
  }

  Widget _buildDiaryCalendarView(List<ClubPost> compPosts) {
    final daysInMonth = _daysInMonth(_focusedMonth);
    final firstWeekday = _firstWeekdayOfMonth(_focusedMonth);
    
    // Total cells in grid (including padding)
    final int paddingCells = firstWeekday - 1;
    final int totalCells = daysInMonth + paddingCells;
    final int gridRows = (totalCells / 7).ceil();
    final int totalGridCells = gridRows * 7;

    // Format header month name
    final monthName = DateFormat('MMMM yyyy').format(_focusedMonth);
    
    // Filter events matching selected day
    final selectedDayEvents = compPosts.where((p) => _isSameDay(p.createdAt, _selectedDate)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        children: [
          // Month Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
                  onPressed: _previousMonth,
                ),
                Text(
                  monthName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey900),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight, color: AppColors.grey900),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Weekday Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WeekdayHeader(label: 'M'),
                _WeekdayHeader(label: 'T'),
                _WeekdayHeader(label: 'W'),
                _WeekdayHeader(label: 'T'),
                _WeekdayHeader(label: 'F'),
                _WeekdayHeader(label: 'S'),
                _WeekdayHeader(label: 'S'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Calendar Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: totalGridCells,
              itemBuilder: (context, index) {
                final int day = index - paddingCells + 1;
                if (day <= 0 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                final isSelected = _isSameDay(cellDate, _selectedDate);
                final hasEvents = compPosts.any((p) => _isSameDay(p.createdAt, cellDate));
                final isToday = _isSameDay(cellDate, DateTime.now());

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = cellDate;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.grey900
                          : (isToday ? AppColors.golfLime.withValues(alpha: 0.2) : Colors.transparent),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.grey900 : (isToday ? AppColors.golfLime : Colors.transparent),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? AppColors.grey900 : AppColors.grey700),
                          ),
                        ),
                        if (hasEvents) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.golfLime : AppColors.grey900,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: AppColors.grey200),
          const SizedBox(height: 16),
          // Day events list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Events for ${DateFormat('EEEE, d MMMM').format(_selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.grey900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (selectedDayEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No events scheduled for this day.',
                style: TextStyle(color: AppColors.grey400, fontSize: 13),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: selectedDayEvents.length,
              itemBuilder: (context, index) {
                final post = selectedDayEvents[index];
                return PostCard(
                  type: post.postType,
                  title: post.title,
                  content: post.content,
                  timeAgo: formatTimeAgo(post.createdAt),
                  author: post.authorName,
                  imageUrl: post.imageUrl,
                  actionText: post.postType == 'fixture' || post.postType == 'competition' ? 'Register Now' : null,
                  onAction: post.postType == 'fixture' || post.postType == 'competition'
                      ? () => context.push('/competitions/${post.id}')
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.grey400,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab> {
  String _searchQuery = '';

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(activeClubMembersListProvider).when(
      data: (members) {
        final activeMembers = members.where((m) => m.status == 'active').toList();
        final filteredMembers = activeMembers.where((m) {
          return m.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: AppColors.grey900, fontSize: AppTypeScale.body),
                decoration: InputDecoration(
                  hintText: 'Search members by name...',
                  hintStyle: const TextStyle(color: AppColors.grey500, fontSize: AppTypeScale.body),
                  prefixIcon: const Icon(LucideIcons.search, color: AppColors.grey500, size: 22),
                  filled: true,
                  fillColor: AppColors.grey50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.golfLime, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            Expanded(
              child: filteredMembers.isEmpty
                  ? const Center(child: Text('No members found.', style: TextStyle(color: AppColors.grey500)))
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 90),
                      itemCount: filteredMembers.length,
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        final isPublic = member.privacyLevel == 'Public';
                        final mockPhone = '+2547${(member.playerId.hashCode % 100000000).toString().padLeft(8, '0')}';

                        return MemberGlassCard(
                          name: member.name,
                          avatarUrl: member.avatarUrl,
                          handicap: member.handicap,
                          status: member.status,
                          isPublic: isPublic,
                          onCall: () => _makeCall(mockPhone),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading members: $e')),
    );
  }
}
