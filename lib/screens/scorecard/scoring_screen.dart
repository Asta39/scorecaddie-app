import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/utils/whs_engine.dart';
import '../../core/models/achievement_model.dart';
import '../../widgets/achievement_dialog.dart';
import '../../widgets/top_notification.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int holesPlayed;
  final int? teeId;
  final int courseHandicap;

  const ScoringScreen({
    super.key,
    required this.courseId,
    required this.holesPlayed,
    this.teeId,
    required this.courseHandicap,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CupertinoActivityIndicator()));

    int currentTotal = _holeScores.take(_currentHoleIndex + 1).reduce((a, b) => a + b);
    int parSoFar = _masterHoles.take(_currentHoleIndex + 1).map((h) => h.par).reduce((a, b) => a + b);
    int toPar = currentTotal - parSoFar;
    String toParText = toPar == 0 ? 'E' : (toPar > 0 ? '+$toPar' : '$toPar');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: Icon(LucideIcons.x, color: isDark ? Colors.white : AppColors.grey900), onPressed: _showQuitDialog),
            title: Column(
              children: [
                Text(_course?.name ?? 'Course', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : AppColors.grey900)),
                Text('Score: $toParText • CH: ${widget.courseHandicap}', style: const TextStyle(color: AppColors.emerald700, fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _showFinishEarlyDialog,
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
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
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
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildHoleProgressDots() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _holeScores.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, i) {
          final isActive = i == _currentHoleIndex;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 32,
              decoration: BoxDecoration(
                color: isActive ? AppColors.grey900 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? AppColors.grey900 : AppColors.grey200),
              ),
              alignment: Alignment.center,
              child: Text('${_masterHoles[i].holeNumber}', style: TextStyle(color: isActive ? Colors.white : AppColors.grey400, fontWeight: FontWeight.w800, fontSize: 12)),
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

    Color scoreColor = AppColors.grey900;
    if (score < hole.par) {
      scoreColor = AppColors.emerald500;
    } else if (score > hole.par) {
      scoreColor = AppColors.grey400;
    }
    if (score >= hole.par + 2) {
      scoreColor = AppColors.doubleBogey;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOLE ${hole.holeNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.grey400, letterSpacing: 1.5)),
                  Text('PAR ${hole.par} • SI ${hole.handicapIndex}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.grey900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.doubleBogey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('MAX: $cap', style: const TextStyle(color: AppColors.doubleBogey, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const Spacer(),
          
          // SMART STEPPER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StepperBtn(
                  icon: LucideIcons.minus, 
                  onTap: () {
                    if (_holeScores[index] == 0) return;
                    _updateScore(-1, index);
                  }
                ),
                Text(
                  score == 0 ? '-' : '$score', 
                  style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: score == 0 ? AppColors.grey200 : scoreColor, letterSpacing: -5)
                ),
                _StepperBtn(
                  icon: LucideIcons.plus, 
                  onTap: () {
                    if (_holeScores[index] == 0) {
                      setState(() => _holeScores[index] = hole.par);
                    } else {
                      _updateScore(1, index);
                    }
                  }
                ),
              ],
            ),
          ),
          
          const Spacer(),
          _buildHoleStats(index),
          const Spacer(),
        ],
      ),
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
    setState(() {
      _holeGIRs[index] = !_holeGIRs[index];
    });
    HapticFeedback.selectionClick();
  }


  Widget _buildHoleStats(int index) {
    final isPar3 = _masterHoles[index].par == 3;
    return Column(
      children: [
        _StatRow(label: 'PUTTS', value: _holePutts[index]?.toString(), options: ['1','2','3'], onSelect: (v) => setState(() => _holePutts[index] = int.parse(v))),
        if (!isPar3) ...[
          const SizedBox(height: 16),
          _StatRow(label: 'FAIRWAY', value: _holeFairways[index], options: ['Left','Hit','Right'], onSelect: (v) => setState(() => _holeFairways[index] = v)),
        ],
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        _StatRow(label: 'PENALTIES', value: _holePenalties[index]?.toString(), options: ['0','1','2'], onSelect: (v) => setState(() => _holePenalties[index] = int.parse(v))),
        const SizedBox(height: 16),
        _GIRRow(isSelected: _holeGIRs[index], onTap: () => _updateGIR(index)),
      ],
    );

  }

  Widget _buildBottomActionBar() {
    final isLast = _currentHoleIndex == _holeScores.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: FilledButton(
          onPressed: _isSaving ? null : () => isLast ? _finishRound(useForAnalytics: true) : _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
          style: FilledButton.styleFrom(backgroundColor: isLast ? AppColors.emerald700 : AppColors.grey900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          child: _isSaving ? const CupertinoActivityIndicator(color: Colors.white) : Text(isLast ? 'FINISH ROUND' : 'NEXT HOLE', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ),
    );
  }

  Future<String?> _showNotesPrompt() async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Add Round Notes?'),
        content: const Text('Would you like to add notes about this round?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('No Thanks'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add Notes'),
          ),
        ],
      ),
    );
    if (shouldAdd != true || !mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const Text('Round Notes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                const Text('How did you play today?', style: TextStyle(color: AppColors.grey500)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g. Strong driving today, struggled with putting...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, controller.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.grey900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save Notes', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFinishEarlyDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Finish Early?'),
        content: const Text(
          'Ending the round now will save your progress, but because you haven\'t completed all holes, this round will NOT be used for your WHS handicap or performance analytics.\n\nAre you sure you want to finish now?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _finishRound(useForAnalytics: false);
            },
            child: const Text('Finish & Save'),
          ),
        ],
      ),
    );
  }

  void _showQuitDialog() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Quit Round?'),
        content: const Text('Progress will be lost.'),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Quit'), onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.grey900, size: 28),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
        Row(
          children: options.map((opt) {
            final isSelected = value == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: isSelected ? AppColors.emerald700 : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.emerald700 : AppColors.grey100)),
                child: Text(opt, style: TextStyle(color: isSelected ? Colors.white : AppColors.grey900, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            );
          }).toList(),
        ),
      ],
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

