import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/utils/whs_engine.dart';
import '../../core/models/achievement_model.dart';
import '../../widgets/achievement_dialog.dart';
import '../../widgets/top_notification.dart';
import '../../widgets/certification_signature_dialog.dart';
import '../../widgets/gps_yardage_card.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int holesPlayed;
  final int? teeId;
  final int courseHandicap;
  final String? markerName;
  final String? markerId;

  const ScoringScreen({
    super.key,
    required this.courseId,
    required this.holesPlayed,
    this.teeId,
    required this.courseHandicap,
    this.markerName,
    this.markerId,
  });

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  late PageController _pageController;
  int _currentHoleIndex = 0;
  
  // State for the round
  Course? _course;
  List<CourseHole> _masterHoles = [];
  /// Nine-hole stroke index per active hole; null for 18-hole rounds.
  List<int>? _nineHoleSI;

  bool get _isNineHoleRound => widget.holesPlayed.abs() == 9;
  List<int> _holeScores = [];
  
  // Advanced Stats
  List<int?> _holePutts = [];
  List<String?> _holeFairways = [];
  List<int?> _holePenalties = [];
  List<bool> _holeGIRs = [];

  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    final db = ref.read(databaseProvider);
    final course = await db.getCourse(widget.courseId);
    final holes = await db.getHolesForCourse(widget.courseId, teeId: widget.teeId);
    
    // Handle Front 9 vs Back 9 vs 18
    List<CourseHole> activeHoles = [];
    if (widget.holesPlayed == 9) {
      activeHoles = holes.where((h) => h.holeNumber <= 9).toList();
    } else if (widget.holesPlayed == -9) {
      activeHoles = holes.where((h) => h.holeNumber > 9).toList();
    } else {
      activeHoles = holes; 
    }

    // Fallback if no holes in DB
    if (activeHoles.isEmpty) {
       int startNum = widget.holesPlayed == -9 ? 10 : 1;
       activeHoles = List.generate(widget.holesPlayed.abs(), (i) => CourseHole(
         id: i, 
         courseId: widget.courseId, 
         holeNumber: startNum + i, 
         par: 4,
         handicapIndex: i + 1
       ));
    }

    setState(() {
      _course = course;
      _masterHoles = activeHoles;
      _nineHoleSI = _isNineHoleRound
          ? WHSEngine.nineHoleStrokeIndexes(
              activeHoles.map((h) => h.nineHoleIndex).toList(),
              activeHoles.map((h) => h.handicapIndex).toList(),
            )
          : null;
      _holeScores = List.filled(activeHoles.length, 0); // Initialize with 0 for unplayed
      _holePutts = List.filled(activeHoles.length, null);
      _holeFairways = List.filled(activeHoles.length, null);
      _holePenalties = List.filled(activeHoles.length, null);
      _holeGIRs = List.filled(activeHoles.length, false);

      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _calculateESCCap(int holeIndex) {
    final hole = _masterHoles[holeIndex];
    final nineSI = _nineHoleSI;
    if (nineSI != null) {
      return WHSEngine.calculateESCCapNine(hole.par, widget.courseHandicap, nineSI[holeIndex]);
    }
    return WHSEngine.calculateESCCap(
      hole.par, 
      widget.courseHandicap, 
      hole.handicapIndex ?? (holeIndex + 1)
    );
  }

  Future<void> _finishRound({bool useForAnalytics = true}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      final user = ref.read(authStateProvider).valueOrNull;
      
      if (useForAnalytics) {
        final profile = ref.read(userProfileProvider).valueOrNull;
        final playerName = profile?.name ?? 'Player';
        final markerName = widget.markerName ?? 'Marker';

        final certified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => CertificationSignatureDialog(
            playerName: playerName,
            markerName: markerName,
          ),
        );

        if (certified != true) {
          setState(() => _isSaving = false);
          return;
        }
      }

      // 1. Calculate ESC Adjusted Gross Score
      int adjustedGross = 0;
      for (int i = 0; i < _holeScores.length; i++) {
        final cap = _calculateESCCap(i);
        adjustedGross += _holeScores[i] > cap ? cap : _holeScores[i];
      }

      // 2. Fetch Tee Ratings for Differential
      double cRating = 72.0;
      int sRating = 113;
      double? specificCR;
      int? specificSlope;

      if (widget.teeId != null) {
        final tees = await db.getTeesForCourse(widget.courseId);
        final matches = tees.where((t) => t.id == widget.teeId);
        
        if (matches.isNotEmpty) {
          final selectedTee = matches.first;
          cRating = selectedTee.courseRating;
          sRating = selectedTee.slopeRating;
          
          final isFront9 = widget.holesPlayed == 9;
          specificCR = isFront9 ? selectedTee.courseRatingFront : selectedTee.courseRatingBack;
          specificSlope = isFront9 ? selectedTee.slopeRatingFront : selectedTee.slopeRatingBack;
        }
      }

      // FIX: Calculate coursePar from the ACTUAL holes played, not the tee's 18-hole par.
      // This fixes the "-37 To Par" bug for 9-hole rounds.
      final int actualCoursePar = _masterHoles.map((h) => h.par).reduce((a, b) => a + b);

      // 3. Calculate Differential
      final handicapStatus = ref.read(handicapProvider).valueOrNull;
      final playerHI = handicapStatus?.currentIndex ?? 36.0;

      double differential;
      if (widget.holesPlayed.abs() == 9) {
        // WHS 2024: Use specific 9-hole ratings if available, otherwise fallback to half of 18-hole
        final nineHoleCR = specificCR ?? (cRating / 2);
        final nineHoleSlope = specificSlope ?? sRating;
        
        differential = WHSEngine.calculate9HoleTotalDifferential(
          nineHoleAdjustedGrossScore: adjustedGross,
          nineHoleCourseRating: nineHoleCR,
          nineHoleSlopeRating: nineHoleSlope,
          playerHandicapIndex: playerHI,
        );
      } else {
        differential = WHSEngine.calculateScoreDifferential(
          adjustedGrossScore: adjustedGross, 
          courseRating: cRating, 
          slopeRating: sRating
        );
      }

      final int playedHolesCount = useForAnalytics ? _holeScores.length : _currentHoleIndex + 1;
      final totalScore = _holeScores.take(playedHolesCount).reduce((a, b) => a + b);
      final supabaseId = const Uuid().v4();


      // FIX: Calculate front9/back9 scores for ALL round types (not just 9-hole)
      int? front9 = widget.holesPlayed == 9 ? totalScore : null;
      int? back9 = widget.holesPlayed == -9 ? totalScore : null;
      if (widget.holesPlayed.abs() == 18) {
        front9 = 0;
        back9 = 0;
        for (int i = 0; i < _holeScores.length; i++) {
          if (_masterHoles[i].holeNumber <= 9) {
            front9 = front9! + _holeScores[i];
          } else {
            back9 = back9! + _holeScores[i];
          }
        }
      }

      // Capture current HI as handicapBefore for WHS tracking
      final double? handicapBefore = handicapStatus?.currentIndex;

      // 4. Save Round
      final roundId = await db.into(db.rounds).insert(
        RoundsCompanion.insert(
          supabaseId: drift.Value(supabaseId),
          courseId: widget.courseId,
          useForAnalytics: drift.Value(useForAnalytics),
          teeId: drift.Value(widget.teeId),
          courseName: drift.Value(_course?.name ?? 'Unknown'),
          holesPlayed: drift.Value(useForAnalytics ? widget.holesPlayed.abs() : _currentHoleIndex + 1),
          totalScore: totalScore,
          totalNet: drift.Value(totalScore - widget.courseHandicap),
          adjustedGrossScore: drift.Value(adjustedGross),
          coursePar: actualCoursePar,
          scoreVsPar: totalScore - actualCoursePar,
          scoreDifferential: drift.Value(differential),
          handicapBefore: drift.Value(handicapBefore),
          front9Score: drift.Value(front9),
          back9Score: drift.Value(back9),
          playedAt: drift.Value(DateTime.now()),
          userId: drift.Value(user?.uid),
        ),
      );

      // 5. Save Hole Scores
      final List<HoleScoresCompanion> holeCompanions = [];
      
      for (int i = 0; i < _holeScores.length; i++) {
        final isPlayed = i < playedHolesCount;
        holeCompanions.add(HoleScoresCompanion.insert(
          roundId: roundId,
          holeNumber: _masterHoles[i].holeNumber,
          par: _masterHoles[i].par,
          score: isPlayed ? _holeScores[i] : 0, // Zero out unplayed holes
          putts: drift.Value(_holePutts[i]),
          fairwayHit: drift.Value(_holeFairways[i]),
          penalties: drift.Value(_holePenalties[i]),
          gir: drift.Value(_holeGIRs[i]),
        ));
      }
      await db.insertHoleScores(holeCompanions);


      // 6. Refresh UI & Sync
      ref.invalidate(roundsProvider);
      
      // Check achievements and show dialogs
      List<Achievement> newlyEarned = [];
      if (user != null) {
        newlyEarned = await ref.read(achievementServiceProvider).checkAllAchievements(user.id);
      }

      // Sync in background
      Future.microtask(() async {
        final savedRound = await db.getRound(roundId);
        final savedHoles = await db.getHoleScoresForRound(roundId);
        await ref.read(syncServiceProvider).syncRound(savedRound, savedHoles);
      });

      if (!mounted) return;

      // Show achievement dialogs sequentially
      for (var achievement in newlyEarned) {
        if (mounted) {
          await AchievementDialog.show(context, achievement);
        }
      }

      // Prompt for round notes
      if (mounted) {
        final notes = await _showNotesPrompt();
        if (notes != null && notes.isNotEmpty) {
          await (db.update(db.rounds)..where((r) => r.id.equals(roundId))).write(
            RoundsCompanion(notes: drift.Value(notes)),
          );
        }
      }

      if (mounted) {
        context.go('/');
        TopNotification.showSuccess(context, 'Round saved! WHS Differential calculated.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        TopNotification.showError(context, 'Error: $e');
      }
    }
  }

  /// Relative-to-par over the holes that have a score so far.
  (int strokes, int toPar, int played) _running() {
    var strokes = 0, par = 0, played = 0;
    for (var i = 0; i < _holeScores.length; i++) {
      if (_holeScores[i] == 0) continue;
      strokes += _holeScores[i];
      par += _masterHoles[i].par;
      played++;
    }
    return (strokes, strokes - par, played);
  }

  static String toParLabel(int toPar) => toPar == 0 ? 'E' : (toPar > 0 ? '+$toPar' : '$toPar');

  Color _scoreColor(int score, int par) {
    if (score == 0) return Ob.creamA(.25);
    if (score <= par - 2) return const Color(0xFFF5C531);
    if (score == par - 1) return Ob.lime;
    if (score == par) return Ob.cream;
    if (score == par + 1) return const Color(0xFF7DD3FC);
    return Ob.warn;
  }

  String _scoreName(int score, int par) {
    if (score == 0) return 'Tap + to start at par';
    if (score == 1) return 'Hole in one!';
    return switch (score - par) {
      <= -3 => 'Albatross',
      -2 => 'Eagle',
      -1 => 'Birdie',
      0 => 'Par',
      1 => 'Bogey',
      2 => 'Double bogey',
      _ => '+${score - par}',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Ob.bg, body: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    final (strokes, toPar, played) = _running();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(children: [
                  ObIconButton(icon: LucideIcons.x, label: 'Quit round', onPressed: _showQuitDialog),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_course?.name ?? 'Course', maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w800)),
                      Text(
                        played == 0 ? 'You get ${widget.courseHandicap} strokes' : '$strokes through $played · ${toParLabel(toPar)}',
                        style: Ob.body(12, weight: FontWeight.w700, color: Ob.lime),
                      ),
                    ]),
                  ),
                  GestureDetector(
                    onTap: _showFinishEarlyDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(999)),
                      child: Text('Finish', style: Ob.body(13, weight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
              _buildHoleProgressDots(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentHoleIndex = idx),
                  itemCount: _holeScores.length,
                  itemBuilder: (context, index) => _buildHoleView(index),
                ),
              ),
              _buildBottomActionBar(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHoleProgressDots() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _holeScores.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemBuilder: (context, i) {
          final active = i == _currentHoleIndex;
          final score = _holeScores[i];
          final par = _masterHoles[i].par;
          return Semantics(
            button: true,
            label: 'Hole ${_masterHoles[i].holeNumber}${score > 0 ? ', $score' : ''}',
            child: GestureDetector(
              onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 36,
                decoration: BoxDecoration(
                  color: active ? Ob.lime : (score > 0 ? Ob.roleFill : Ob.cardFill),
                  shape: BoxShape.circle,
                  border: Border.all(color: score > 0 && !active ? _scoreColor(score, par).withValues(alpha: .6) : Colors.transparent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  score > 0 && !active ? '$score' : '${_masterHoles[i].holeNumber}',
                  style: Ob.body(13, weight: FontWeight.w800, color: active ? Ob.ink : (score > 0 ? _scoreColor(score, par) : Ob.creamA(.55))),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHoleView(int index) {
    final hole = _masterHoles[index];
    final score = _holeScores[index];
    final cap = _calculateESCCap(index);
    final si = _nineHoleSI != null && index < _nineHoleSI!.length ? _nineHoleSI![index] : hole.handicapIndex;
    final color = _scoreColor(score, hole.par);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Hole ${hole.holeNumber}', style: Ob.display(34, height: 1)),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Par ${hole.par}  ·  SI ${si ?? '–'}', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.7))),
          ),
          const Spacer(),
          ObChip('Max $cap', on: true, color: Ob.warn),
        ]),
        const SizedBox(height: 14),
        GPSYardageCard(
          courseLatitude: _course?.latitude,
          courseLongitude: _course?.longitude,
          holeNumber: hole.holeNumber,
          par: hole.par,
          teeDistance: hole.distance,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: Ob.cardFill,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: score == 0 ? Colors.transparent : color.withValues(alpha: .35), width: 1.5),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _StepperBtn(
                icon: LucideIcons.minus,
                label: 'One less',
                onTap: () {
                  if (_holeScores[index] == 0) return;
                  _updateScore(-1, index);
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Text(score == 0 ? '–' : '$score', key: ValueKey(score), style: Ob.display(96, color: color, height: 1)),
              ),
              _StepperBtn(
                icon: LucideIcons.plus,
                label: 'One more',
                primary: true,
                onTap: () {
                  if (_holeScores[index] == 0) {
                    setState(() => _holeScores[index] = hole.par);
                    HapticFeedback.lightImpact();
                  } else {
                    _updateScore(1, index);
                  }
                },
              ),
            ]),
            const SizedBox(height: 6),
            Text(_scoreName(score, hole.par), style: Ob.body(14, weight: FontWeight.w800, color: score == 0 ? Ob.creamA(.5) : color)),
          ]),
        ),
        const SizedBox(height: 14),
        _buildHoleStats(index),
      ],
    );
  }

  void _updateScore(int delta, int index) {
    setState(() {
      final newScore = _holeScores[index] + delta;
      if (newScore >= 1) _holeScores[index] = newScore;
    });
    HapticFeedback.lightImpact();
  }

  void _updateGIR(int index) {
    setState(() => _holeGIRs[index] = !_holeGIRs[index]);
    HapticFeedback.selectionClick();
  }

  Widget _buildHoleStats(int index) {
    final isPar3 = _masterHoles[index].par == 3;
    return ObCard(
      child: Column(children: [
        _StatRow(label: 'Putts', value: _holePutts[index]?.toString(), options: const ['1', '2', '3', '4'], onSelect: (v) => setState(() => _holePutts[index] = int.parse(v))),
        if (!isPar3) ...[
          const SizedBox(height: 12),
          _StatRow(label: 'Fairway', value: _holeFairways[index], options: const ['Left', 'Hit', 'Right'], onSelect: (v) => setState(() => _holeFairways[index] = v)),
        ],
        const SizedBox(height: 12),
        _StatRow(label: 'Penalties', value: _holePenalties[index]?.toString(), options: const ['0', '1', '2'], onSelect: (v) => setState(() => _holePenalties[index] = int.parse(v))),
        const SizedBox(height: 12),
        _GIRRow(isSelected: _holeGIRs[index], onTap: () => _updateGIR(index)),
      ]),
    );
  }

  Widget _buildBottomActionBar() {
    final isLast = _currentHoleIndex == _holeScores.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 14 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        width: double.infinity,
        child: ObButton(
          tone: isLast ? ObButtonTone.lime : ObButtonTone.dark,
          onPressed: _isSaving
              ? null
              : () => isLast
                  ? _finishRound(useForAnalytics: true)
                  : _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          child: Text(
            _isSaving ? 'Saving…' : (isLast ? 'Finish round' : 'Next hole  →'),
            style: Ob.label(17, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  Future<String?> _showNotesPrompt() async {
    final controller = TextEditingController();
    try {
      return await showObSheet<String>(
        context,
        (ctx) => ObSheet(
          title: 'Any notes on the round?',
          subtitle: 'Optional. You\'ll see them on the round later.',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: controller,
              maxLines: 4,
              cursorColor: Ob.lime,
              style: Ob.body(15, weight: FontWeight.w600),
              decoration: obInput(null, hint: 'Driving was strong, putting let me down…'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx), child: Text('Skip', style: Ob.label(15, weight: FontWeight.w800)))),
              const SizedBox(width: 10),
              Expanded(child: ObButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text('Save notes', style: Ob.label(15, weight: FontWeight.w800)))),
            ]),
          ]),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirm(String title, String body, String yes, {bool danger = false}) async {
    final ok = await showObSheet<bool>(
      context,
      (ctx) => ObSheet(
        title: title,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(body, style: Ob.body(14, height: 1.5, color: Ob.creamA(.75))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Keep playing', style: Ob.label(15, weight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(
              child: ObButton(
                tone: danger ? ObButtonTone.light : ObButtonTone.lime,
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(yes, style: Ob.label(15, weight: FontWeight.w800).copyWith(color: danger ? Ob.warn : null)),
              ),
            ),
          ]),
        ]),
      ),
    );
    return ok == true;
  }

  Future<void> _showFinishEarlyDialog() async {
    final ok = await _confirm(
      'Finish early?',
      'Your scores are saved, but a round with holes missing won\'t count towards your handicap or your stats.',
      'Finish & save',
    );
    if (ok) _finishRound(useForAnalytics: false);
  }

  Future<void> _showQuitDialog() async {
    final ok = await _confirm('Quit this round?', 'Nothing from this round will be saved.', 'Quit', danger: true);
    if (ok && mounted) Navigator.pop(context);
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _StepperBtn({required this.icon, required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: primary ? Ob.lime : Ob.creamA(.08), shape: BoxShape.circle),
          child: Icon(icon, color: primary ? Ob.ink : Ob.cream, size: 28),
        ),
      ),
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
    return Row(children: [
      Expanded(child: Text(label, style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.75)))),
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(o);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minWidth: 42),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: value == o ? Ob.lime : Ob.creamA(.07), borderRadius: BorderRadius.circular(12)),
              child: Text(o, style: Ob.body(13, weight: FontWeight.w800, color: value == o ? Ob.ink : Ob.cream)),
            ),
          ),
        ),
    ]);
  }
}

class _GIRRow extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _GIRRow({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text('Green in regulation', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.75)))),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: isSelected ? Ob.lime : Ob.creamA(.07), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (isSelected) ...[const Icon(LucideIcons.check, color: Ob.ink, size: 15), const SizedBox(width: 6)],
            Text(isSelected ? 'Yes' : 'No', style: Ob.body(13, weight: FontWeight.w800, color: isSelected ? Ob.ink : Ob.cream)),
          ]),
        ),
      ),
    ]);
  }
}
