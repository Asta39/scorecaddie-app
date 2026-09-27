import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../widgets/profile_image.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
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
  // Subscribed once; building them in build() re-subscribed on every swipe.
  late final Stream<Map<String, dynamic>> _round = ref.read(groupSyncServiceProvider).watchGroupRound(widget.groupRoundId);
  late final Stream<List<Map<String, dynamic>>> _players = ref.read(groupSyncServiceProvider).watchParticipants(widget.groupRoundId);
  late final Stream<List<Map<String, dynamic>>> _scores = ref.read(groupSyncServiceProvider).watchAllScores(widget.groupRoundId);

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

  Widget _shell(Widget child) => Scaffold(backgroundColor: Ob.bg, body: DefaultTextStyle(style: Ob.textBase, child: SafeArea(bottom: false, child: child)));

  Widget _waiting(String text) => _shell(Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: ObTopBar('Group round', onBack: () => context.pop())),
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CupertinoActivityIndicator(color: Ob.lime),
              const SizedBox(height: 10),
              Text(text, style: Ob.body(14, color: Ob.creamA(.65))),
            ]),
          ),
        ),
      ]));

  int _toPar(String pId, List<Map<String, dynamic>> allScores) {
    var t = 0;
    for (final s in allScores.where((s) => s['participantId'] == pId)) {
      final h = s['holeNumber'] as int;
      if (h >= 1 && h <= _holePars.length) t += (s['strokes'] as int) - _holePars[h - 1];
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _waiting('Loading the course…');
    final user = ref.watch(authStateProvider).valueOrNull;

    return StreamBuilder<Map<String, dynamic>>(
      stream: _round,
      builder: (context, roundSnap) {
        if (!roundSnap.hasData) return _waiting(roundSnap.connectionState == ConnectionState.waiting ? 'Joining the round…' : 'Round not found');
        final roundData = roundSnap.data!;
        final isKeeper = roundData['captainId'] == user?.id;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _players,
          builder: (context, pSnap) {
            final participants = pSnap.data ?? const [];
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _scores,
              builder: (context, sSnap) {
                final allScores = sSnap.data ?? const [];
                if (participants.isEmpty) return _waiting('Waiting for players…');
                return _shell(Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(children: [
                      ObIconButton(icon: LucideIcons.chevronLeft, label: 'Back', onPressed: () => context.pop()),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(roundData['courseName']?.toString() ?? 'Group round', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w800)),
                          Text(isKeeper ? 'You\'re keeping score' : 'The captain is keeping score', style: Ob.body(12, weight: FontWeight.w700, color: Ob.lime)),
                        ]),
                      ),
                      if (isKeeper)
                        GestureDetector(
                          onTap: () => _showFinishEarlyDialog(allScores),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(999)),
                            child: Text('Finish', style: Ob.body(13, weight: FontWeight.w800)),
                          ),
                        ),
                    ]),
                  ),
                  _buildLeaderboardStrip(participants, allScores),
                  _buildHoleNavigation(allScores),
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
                ]));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardStrip(List<Map<String, dynamic>> participants, List<Map<String, dynamic>> allScores) {
    final ranked = [...participants]..sort((a, b) => _toPar(a['id'], allScores).compareTo(_toPar(b['id'], allScores)));
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: ranked.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = ranked[i];
          final t = _toPar(p['id'], allScores);
          final name = ((p['user']?['name'] ?? 'Golfer') as String).split(' ').first;
          return ObChip('${i + 1}. $name ${t == 0 ? 'E' : (t > 0 ? '+$t' : '$t')}', on: i == 0 && allScores.isNotEmpty);
        },
      ),
    );
  }

  Widget _buildHoleNavigation(List<Map<String, dynamic>> allScores) {
    final scored = allScores.map((s) => s['holeNumber']).toSet();
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _holePars.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, i) {
          final active = i == _currentHoleIndex;
          final done = scored.contains(i + 1);
          return GestureDetector(
            onTap: () => _pageController.jumpToPage(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 36,
              decoration: BoxDecoration(color: active ? Ob.lime : (done ? Ob.roleFill : Ob.cardFill), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${i + 1}', style: Ob.body(12, weight: FontWeight.w800, color: active ? Ob.ink : (done ? Ob.lime : Ob.creamA(.55)))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHolePanel(int holeIdx, List<Map<String, dynamic>> participants, bool isKeeper, List<Map<String, dynamic>> allScores) {
    final par = _holePars[holeIdx];
    final holeNumber = holeIdx + 1;
    final scoresMap = {for (final s in allScores.where((s) => s['holeNumber'] == holeNumber)) s['participantId']: s};
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Hole $holeNumber', style: Ob.display(34, height: 1)),
          const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('Par $par', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.7)))),
        ]),
        const SizedBox(height: 14),
        for (final p in participants) _buildPlayerCard(p, scoresMap[p['id']], par, isKeeper),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> p, Map<String, dynamic>? score, int par, bool isKeeper) {
    final String pId = p['id'];
    final expanded = _expandedParticipantId == pId;
    final int strokes = score?['strokes'] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(22)),
        child: Column(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expandedParticipantId = expanded ? null : pId),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(children: [
                ProfileImage(url: p['user']?['avatarUrl'], name: p['user']?['name'], size: 38, isCircle: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${p['user']?['name'] ?? 'Golfer'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w800)),
                    Text(expanded ? 'Hide stats' : 'Putts, fairway…', style: Ob.body(11, color: Ob.creamA(.5))),
                  ]),
                ),
                _buildPillButtons(pId, strokes, par, isKeeper, p, score),
              ]),
            ),
          ),
          if (expanded) _buildStatsExpansion(p, score, isKeeper),
        ]),
      ),
    );
  }

  Widget _buildPillButtons(String pId, int currentStrokes, int par, bool isKeeper, Map<String, dynamic> p, Map<String, dynamic>? score) {
    final options = [par - 1, par, par + 1, par + 2];
    final custom = currentStrokes != 0 && !options.contains(currentStrokes);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final v in options)
        GestureDetector(
          onTap: isKeeper
              ? () {
                  HapticFeedback.selectionClick();
                  _updateScore(pId, p['userId'], v, score);
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(left: 5),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: currentStrokes == v ? Ob.lime : Ob.creamA(.07), borderRadius: BorderRadius.circular(11)),
            child: Text('$v', style: Ob.body(13, weight: FontWeight.w800, color: currentStrokes == v ? Ob.ink : Ob.cream)),
          ),
        ),
      IconButton(
        tooltip: 'Other score',
        onPressed: isKeeper ? () => _showManualStepper(pId, p['userId'], currentStrokes == 0 ? par : currentStrokes, score) : null,
        icon: custom
            ? Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Ob.lime, borderRadius: BorderRadius.circular(11)),
                child: Text('$currentStrokes', style: Ob.body(13, weight: FontWeight.w800, color: Ob.ink)),
              )
            : Icon(LucideIcons.ellipsis, size: 18, color: Ob.creamA(.55)),
      ),
    ]);
  }

  Widget _buildStatsExpansion(Map<String, dynamic> p, Map<String, dynamic>? score, bool isKeeper) {
    void set(Map<String, dynamic> patch) => _updateScore(p['id'], p['userId'], score?['strokes'] ?? 0, {...?score, ...patch});
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(children: [
        const ObHair(),
        const SizedBox(height: 10),
        _StatRow(label: 'Putts', value: score?['putts']?.toString(), options: const ['1', '2', '3'], onSelect: (v) => set({'putts': int.parse(v)})),
        const SizedBox(height: 10),
        _StatRow(label: 'Fairway', value: score?['fairwayHit'], options: const ['Left', 'Hit', 'Right'], onSelect: (v) => set({'fairwayHit': v})),
        const SizedBox(height: 10),
        _StatRow(label: 'Penalties', value: score?['penalties']?.toString(), options: const ['0', '1', '2'], onSelect: (v) => set({'penalties': int.parse(v)})),
        const SizedBox(height: 10),
        _GIRRow(isSelected: score?['gir'] ?? false, onTap: isKeeper ? () => set({'gir': !(score?['gir'] ?? false)}) : () {}),
      ]),
    );
  }

  Widget _buildBottomBar(List<Map<String, dynamic>> participants, bool isKeeper, List<Map<String, dynamic>> allScores) {
    final isLastHole = _currentHoleIndex == _holePars.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 14 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ObButton(
          tone: isLastHole ? ObButtonTone.lime : ObButtonTone.dark,
          onPressed: isKeeper ? (isLastHole ? () => _showFinishEarlyDialog(allScores) : _handleNextHole) : null,
          child: Text(isKeeper ? (isLastHole ? 'Finish round' : 'Next hole  →') : 'Captain keeps score', style: Ob.label(17, weight: FontWeight.w800)),
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

  Future<void> _showFinishEarlyDialog(List<Map<String, dynamic>> allScores) async {
    final holes = allScores.map((s) => s['holeNumber']).toSet().length;
    final partial = holes < _holePars.length;
    final ok = await showObSheet<bool>(
      context,
      (ctx) => ObSheet(
        title: partial ? 'Finish early?' : 'Finish the round?',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            partial
                ? 'Only $holes of ${_holePars.length} holes have scores. An early finish won\'t count towards anyone\'s handicap or stats.'
                : 'This locks the scores for everyone and moves you all to sign-off.',
            style: Ob.body(14, height: 1.5, color: Ob.creamA(.75)),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Keep playing', style: Ob.label(15, weight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(child: ObButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Finish', style: Ob.label(15, weight: FontWeight.w800)))),
          ]),
        ]),
      ),
    );
    if (ok == true) _handleFinishRound(holes, useForAnalytics: !partial);
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
    var value = current.clamp(1, 15);
    showObSheet(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void step(int d) {
            setSheet(() => value = (value + d).clamp(1, 15));
            HapticFeedback.selectionClick();
          }

          return ObSheet(
            title: 'Other score',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _StepperBtn(icon: LucideIcons.minus, onTap: () => step(-1)),
                SizedBox(width: 120, child: Text('$value', textAlign: TextAlign.center, style: Ob.display(64))),
                _StepperBtn(icon: LucideIcons.plus, onTap: () => step(1)),
              ]),
              const SizedBox(height: 18),
              ObButton(
                onPressed: () {
                  _updateScore(pId, userId, value, score);
                  Navigator.pop(ctx);
                },
                child: Text('Save $value', style: Ob.label(16, weight: FontWeight.w800)),
              ),
            ]),
          );
        },
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
    return Row(children: [
      Expanded(child: Text('Green in regulation', style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.75)))),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isSelected ? Ob.lime : Ob.creamA(.07), borderRadius: BorderRadius.circular(11)),
          child: Text(isSelected ? 'Yes' : 'No', style: Ob.body(13, weight: FontWeight.w800, color: isSelected ? Ob.ink : Ob.cream)),
        ),
      ),
    ]);
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
    return Row(children: [
      Expanded(child: Text(label, style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.75)))),
      for (final o in options)
        GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            margin: const EdgeInsets.only(left: 5),
            constraints: const BoxConstraints(minWidth: 38),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: value == o ? Ob.lime : Ob.creamA(.07), borderRadius: BorderRadius.circular(11)),
            child: Text(o, style: Ob.body(12, weight: FontWeight.w800, color: value == o ? Ob.ink : Ob.cream)),
          ),
        ),
    ]);
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: Ob.creamA(.08), shape: BoxShape.circle),
        child: Icon(icon, color: Ob.cream, size: 26),
      ),
    );
  }
}
