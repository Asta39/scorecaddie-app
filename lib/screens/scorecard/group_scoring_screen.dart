import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/cloud/group_sync_service.dart';

class GroupScoringScreen extends ConsumerStatefulWidget {
  final int courseId;
  final String groupRoundId;
  final String mode; 

  const GroupScoringScreen({
    super.key,
    required this.courseId,
    required this.groupRoundId,
    required this.mode,
  });

  @override
  ConsumerState<GroupScoringScreen> createState() => _GroupScoringScreenState();
}

class _GroupScoringScreenState extends ConsumerState<GroupScoringScreen> {
  late PageController _pageController;
  int _currentHoleIndex = 0;
  String? _expandedParticipantId;

  // ignore: unused_field — stored for future course-header display in scorecard
  Course? _course;
  List<int> _holePars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    final db = ref.read(databaseProvider);
    List<int> pars = List.filled(18, 4);
    Course? course;

    try {
      course = await db.getCourse(widget.courseId);
      final dynamic raw = jsonDecode(course.holePars);
      if (raw is List && raw.isNotEmpty) {
        pars = raw.map((e) => int.tryParse(e.toString()) ?? 4).toList();
      }
    } catch (e) {
      debugPrint('Error loading course data: $e');
    }

    if (mounted) {
      setState(() {
        _course = course;
        _holePars = pars;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.emerald700)));

    final groupSync = ref.read(groupSyncServiceProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return StreamBuilder<Map<String, dynamic>>(
      stream: groupSync.watchGroupRound(widget.groupRoundId),
      builder: (context, roundSnapshot) {
        if (roundSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!roundSnapshot.hasData) return const Scaffold(body: Center(child: Text('Round not found')));
        
        final roundData = roundSnapshot.data!;
        final isKeeper = roundData['captainId'] == user?.id;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: groupSync.watchParticipants(widget.groupRoundId),
          builder: (context, participantsSnapshot) {
            if (participantsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final participants = participantsSnapshot.data ?? [];
            
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: groupSync.watchAllScores(widget.groupRoundId),
              builder: (context, scoresSnapshot) {
                final allScores = scoresSnapshot.data ?? [];
                
                return Scaffold(
                  backgroundColor: AppColors.grey50,
                  appBar: _buildCompactHeader(roundData, participants, allScores, isKeeper),
                  body: participants.isEmpty 
                    ? const Center(child: Text('Waiting for participants...'))
                    : Column(
                        children: [
                           _buildHoleNavigation(),
                           Expanded(
                             child: PageView.builder(
                               controller: _pageController,
                               onPageChanged: (idx) => setState(() {
                                 _currentHoleIndex = idx;
                                 _expandedParticipantId = null;
                               }),
                               itemCount: _holePars.length,
                               itemBuilder: (context, holeIdx) => _buildHolePanel(holeIdx, participants, isKeeper, allScores),
                             ),
                           ),
                           _buildBottomBar(participants, isKeeper, allScores),
                        ],
                      ),
                );
              }
            );
          }
        );
      }
    );
  }

  PreferredSizeWidget _buildCompactHeader(Map<String, dynamic> round, List<Map<String, dynamic>> participants, List<Map<String, dynamic>> allScores, bool isKeeper) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900), onPressed: () => context.pop()),
      title: Column(
        children: [
          Text(round['courseName'] ?? 'Round', style: const TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 14)),
          const SizedBox(height: 4),
          _buildLeaderboardStrip(participants, allScores),
        ],
      ),
      actions: [
        if (isKeeper)
          TextButton(
            onPressed: () => _showFinishEarlyDialog(allScores),
            child: const Text(
              'FINISH',
              style: TextStyle(
                color: AppColors.emerald700,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLeaderboardStrip(List<Map<String, dynamic>> participants, List<Map<String, dynamic>> allScores) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: participants.map((p) {
          final pId = p['id'];
          final name = (p['user']?['name'] ?? 'Golfer').split(' ')[0];
          
          final pScores = allScores.where((s) => s['participantId'] == pId).toList();
          int toPar = 0;
          for (var s in pScores) {
             final hNum = s['holeNumber'] as int;
             if (hNum <= _holePars.length) {
               toPar += ((s['strokes'] as int) - _holePars[hNum - 1]);
             }
          }

          final displayScore = toPar == 0 ? 'E' : (toPar > 0 ? '+$toPar' : '$toPar');
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$name $displayScore', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.emerald700)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHoleNavigation() {
    return Container(
      color: Colors.white,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _holePars.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, i) {
          final isActive = i == _currentHoleIndex;
          return GestureDetector(
            onTap: () => _pageController.jumpToPage(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              width: 24,
              decoration: BoxDecoration(
                color: isActive ? AppColors.grey900 : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${i+1}', style: TextStyle(color: isActive ? Colors.white : AppColors.grey400, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHolePanel(int holeIdx, List<Map<String, dynamic>> participants, bool isKeeper, List<Map<String, dynamic>> allScores) {
    final par = _holePars[holeIdx];
    final holeNumber = holeIdx + 1;
    final scoresMap = { for (var s in allScores.where((s) => s['holeNumber'] == holeNumber)) s['participantId']: s };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOLE $holeNumber', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey400, fontSize: 12, letterSpacing: 1.2)),
                Text('PAR $par • SI 12', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.grey900, fontSize: 18)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.doubleBogey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('MAX: ${par + 2}', style: const TextStyle(color: AppColors.doubleBogey, fontWeight: FontWeight.w900, fontSize: 10)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...participants.map((p) => _buildPlayerCard(p, scoresMap[p['id']], par, isKeeper)),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> p, Map<String, dynamic>? score, int par, bool isKeeper) {
    final String pId = p['id'];
    final bool isExpanded = _expandedParticipantId == pId;
    final int currentStrokes = score?['strokes'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expandedParticipantId = isExpanded ? null : pId),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.grey100,
              backgroundImage: p['user']?['avatarUrl'] != null ? NetworkImage(p['user']['avatarUrl']) : null,
              child: p['user']?['avatarUrl'] == null ? const Icon(LucideIcons.user, size: 20) : null,
            ),
            title: Text(p['user']?['name'] ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            trailing: _buildPillButtons(pId, currentStrokes, par, isKeeper, p, score),
          ),
          if (isExpanded) _buildStatsExpansion(p, score, isKeeper),
        ],
      ),
    );
  }

  Widget _buildPillButtons(String pId, int currentStrokes, int par, bool isKeeper, Map<String, dynamic> p, Map<String, dynamic>? score) {
    final options = [par - 1, par, par + 1, par + 2];
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...options.map((val) {
          final isSelected = currentStrokes == val;
          return GestureDetector(
            onTap: isKeeper ? () => _updateScore(pId, p['userId'], val, score) : null,
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.grey900 : AppColors.grey50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? AppColors.grey900 : AppColors.grey200),
              ),
              child: Center(
                child: Text('$val', style: TextStyle(color: isSelected ? Colors.white : AppColors.grey600, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: AppColors.grey400),
          onPressed: isKeeper ? () => _showManualStepper(pId, p['userId'], currentStrokes, score) : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildStatsExpansion(Map<String, dynamic> p, Map<String, dynamic>? score, bool isKeeper) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _StatRow(
            label: 'PUTTS', 
            value: score?['putts']?.toString(), 
            options: ['1','2','3'], 
            onSelect: (v) => _updateScore(p['id'], p['userId'], score?['strokes'] ?? 0, {...score ?? {}, 'putts': int.parse(v)})
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'FAIRWAY', 
            value: score?['fairwayHit'], 
            options: ['Left','Hit','Right'], 
            onSelect: (v) => _updateScore(p['id'], p['userId'], score?['strokes'] ?? 0, {...score ?? {}, 'fairwayHit': v})
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'PENALTIES', 
            value: score?['penalties']?.toString(), 
            options: ['0','1','2'], 
            onSelect: (v) => _updateScore(p['id'], p['userId'], score?['strokes'] ?? 0, {...score ?? {}, 'penalties': int.parse(v)})
          ),
          const SizedBox(height: 16),
          _GIRRow(
            isSelected: score?['gir'] ?? false,
            onTap: isKeeper ? () {
              _updateScore(p['id'], p['userId'], score?['strokes'] ?? 0, {...score ?? {}, 'gir': !(score?['gir'] ?? false)});
            } : () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(List<Map<String, dynamic>> participants, bool isKeeper, List<Map<String, dynamic>> allScores) {
    final isLastHole = _currentHoleIndex == _holePars.length - 1;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.grey100))),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: isKeeper ? (isLastHole ? () => _showFinishEarlyDialog(allScores) : _handleNextHole) : null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.grey900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Text(isLastHole ? 'FINISH ROUND' : 'CONFIRM & NEXT HOLE', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }

  void _updateScore(String pId, String userId, int strokes, Map<String, dynamic>? stats) {
    ref.read(groupSyncServiceProvider).updatePlayerScore(
      groupRoundId: widget.groupRoundId,
      participantId: pId,
      userId: userId,
      holeNumber: _currentHoleIndex + 1,
      strokes: strokes,
      putts: stats?['putts'],
      fairwayHit: stats?['fairwayHit'],
      penalties: stats?['penalties'],
      gir: stats?['gir'],
    );
  }

  void _handleNextHole() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _showFinishEarlyDialog(List<Map<String, dynamic>> allScores) {
    // Calculate how many holes have at least one score
    final uniqueHoles = allScores.map((s) => s['holeNumber']).toSet().length;
    final isPartial = uniqueHoles < _holePars.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isPartial ? LucideIcons.alertTriangle : LucideIcons.checkCircle2, color: isPartial ? Colors.orange : AppColors.emerald700),
            const SizedBox(width: 12),
            const Text('Finish Round', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          isPartial 
            ? 'You have only recorded $uniqueHoles holes. Ending early means this round won\'t be used for official analytics or handicap calculations.\n\nAre you sure?' 
            : 'Are you sure you want to finish and lock this round for all participants?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleFinishRound(uniqueHoles, useForAnalytics: !isPartial);
            },
            style: FilledButton.styleFrom(
              backgroundColor: isPartial ? Colors.orange : AppColors.emerald700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('FINISH', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _handleFinishRound(int actualHoles, {bool useForAnalytics = true}) async {
    await ref.read(groupSyncServiceProvider).finalizeRound(
      widget.groupRoundId, 
      actualHolesPlayed: actualHoles,
      useForAnalytics: useForAnalytics,
    );
    if (mounted) {
      context.push('/group/certification/${widget.groupRoundId}');
    }
  }

  void _showManualStepper(String pId, String userId, int current, Map<String, dynamic>? score) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Enter Custom Score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepperBtn(icon: LucideIcons.minus, onTap: () => _updateScore(pId, userId, (current - 1).clamp(1, 15), score)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text('$current', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                ),
                _StepperBtn(icon: LucideIcons.plus, onTap: () => _updateScore(pId, userId, (current + 1).clamp(1, 15), score)),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _GIRRow extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _GIRRow({required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('GREEN IN REGULATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.emerald700 : Colors.white, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: isSelected ? AppColors.emerald700 : AppColors.grey100)
            ),
            child: Row(
              children: [
                if (isSelected) const Icon(LucideIcons.check, color: Colors.white, size: 14),
                if (isSelected) const SizedBox(width: 6),
                Text(isSelected ? 'YES' : 'NO', style: TextStyle(color: isSelected ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w800, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final Function(String) onSelect;

  const _StatRow({required this.label, required this.value, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.grey400, letterSpacing: 1)),
        Row(
          children: options.map((opt) {
            final isSelected = value == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.grey200 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppColors.grey200 : AppColors.grey100),
                ),
                child: Text(opt, style: TextStyle(color: isSelected ? AppColors.grey900 : AppColors.grey400, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(backgroundColor: AppColors.grey100, padding: const EdgeInsets.all(12)),
      icon: Icon(icon, size: 20, color: AppColors.grey900),
    );
  }
}
