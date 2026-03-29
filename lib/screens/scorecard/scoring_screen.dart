import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_card.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/cloud/sync_service.dart';

class ScoringScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int holesPlayed;
  final String tee;

  const ScoringScreen({
    super.key,
    required this.courseId,
    required this.holesPlayed,
    required this.tee,
  });

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  late PageController _pageController;
  int _currentHoleIndex = 0;
  
  // State for the round
  Course? _course;
  List<int> _holePars = [];
  List<int> _holeScores = [];
  List<int> _holeYardages = [];
  
  // Advanced Stats
  List<int?> _holePutts = [];
  List<String?> _holeFairways = [];
  List<int?> _holePenalties = [];
  
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
    
    // Parse hole pars if they exist, otherwise default to par 4
    List<int> pars = [];
    try {
      final List<dynamic> parsed = jsonDecode(course.holePars);
      pars = parsed.map((e) => e as int).toList();
    } catch (_) {}

    // Fill defaults if data is missing
    if (pars.length < 18) {
      pars = List.filled(18, 4);
    }
    
    // Handle Front 9 vs Back 9
    List<int> activePars = [];
    if (widget.holesPlayed == 9) {
      activePars = pars.sublist(0, 9);
    } else if (widget.holesPlayed == -9) {
      activePars = pars.sublist(9, 18);
    } else {
      activePars = pars; 
    }

    setState(() {
      _course = course;
      _holePars = activePars;
      // Default starting score for each hole is its par
      _holeScores = List.from(activePars);
      _holeYardages = List.filled(activePars.length, 0);
      _holePutts = List.filled(activePars.length, null);
      _holeFairways = List.filled(activePars.length, null);
      _holePenalties = List.filled(activePars.length, null);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishRound() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      
      // Calculate totals
      int totalScore = _holeScores.reduce((a, b) => a + b);
      int coursePar = _holePars.reduce((a, b) => a + b);
      int scoreVsPar = totalScore - coursePar;
      
      int? front9Score;
      int? back9Score;
      
      if (widget.holesPlayed == 18) {
        front9Score = _holeScores.sublist(0, 9).reduce((a, b) => a + b);
        back9Score = _holeScores.sublist(9, 18).reduce((a, b) => a + b);
      } else if (widget.holesPlayed == 9) {
        front9Score = totalScore;
      } else {
        back9Score = totalScore;
      }

      // Generate Firestore ID for Instant Sync
      final firestoreId = const Uuid().v4();

      // Insert Round
      final roundId = await db.into(db.rounds).insert(
        RoundsCompanion.insert(
          firestoreId: drift.Value(firestoreId),
          courseId: widget.courseId,
          courseName: drift.Value(_course?.name ?? 'Unknown'),
          holesPlayed: drift.Value(widget.holesPlayed.abs()),
          tee: drift.Value(widget.tee),
          totalScore: totalScore,
          coursePar: coursePar,
          scoreVsPar: scoreVsPar,
          front9Score: drift.Value(front9Score),
          back9Score: drift.Value(back9Score),
          playedAt: drift.Value(DateTime.now()),
          userId: drift.Value(ref.read(authStateProvider).valueOrNull?.uid),
        ),
      );

      // (Hole scores insertion logic remains the same, just set the roundId)
      final List<HoleScoresCompanion> holeCompanions = [];
      int startingHole = widget.holesPlayed == -9 ? 10 : 1;
      
      for (int i = 0; i < _holeScores.length; i++) {
        holeCompanions.add(
          HoleScoresCompanion.insert(
            roundId: roundId,
            holeNumber: startingHole + i,
            par: _holePars[i],
            score: _holeScores[i],
            yardage: drift.Value(_holeYardages[i] == 0 ? null : _holeYardages[i]),
            putts: drift.Value(_holePutts[i]),
            fairwayHit: drift.Value(_holeFairways[i]),
            penalties: drift.Value(_holePenalties[i]),
          )
        );
      }
      
      await db.insertHoleScores(holeCompanions);
      
      // Force refresh of the providers to show the new data on dashboard
      ref.invalidate(roundsProvider);
      ref.invalidate(recentRoundsProvider);
      ref.invalidate(totalRoundsProvider);
      ref.invalidate(averageScoreProvider);
      ref.invalidate(bestScoreProvider);
      
      // Update Master Course Pars if they changed
      if (_course != null) {
        try {
          List<int> masterPars = [];
          try {
            final List<dynamic> parsed = jsonDecode(_course!.holePars);
            masterPars = parsed.map((e) => e as int).toList();
          } catch (_) {
            masterPars = List.filled(18, 4);
          }

          bool changed = false;
          int offset = widget.holesPlayed == -9 ? 9 : 0;
          for (int i = 0; i < _holePars.length; i++) {
            if (masterPars[offset + i] != _holePars[i]) {
              masterPars[offset + i] = _holePars[i];
              changed = true;
            }
          }

          if (changed) {
            final updatedCourse = _course!.copyWith(
              holePars: jsonEncode(masterPars),
              par18: drift.Value(masterPars.reduce((a, b) => a + b)),
              isUserEdited: true,
            );
            await db.updateCourse(updatedCourse);
            
            // Sync updated course to cloud
            try {
              await ref.read(syncServiceProvider).syncCourse(updatedCourse);
            } catch (e) {
              debugPrint('Error syncing updated course: $e');
            }
          }
        } catch (e) {
          debugPrint('Error updating master course pars: $e');
        }
      }

      // Round sync is now handled by insertRoundWithSync helper
      // debugPrint('Successfully initiated instant sync for round $roundId');
      
      // Trigger cloud sync (fire-and-forget)
      Future.microtask(() async {
        try {
          final savedRound = await db.getRound(roundId);
          final savedHoles = await db.getHoleScoresForRound(roundId);
          await ref.read(syncServiceProvider).syncRound(savedRound, savedHoles);
          debugPrint('Successfully synced round to Firebase');
          
          // Trigger Achievement Check
          final uid = ref.read(authStateProvider).valueOrNull?.uid;
          if (uid != null) {
            await ref.read(achievementServiceProvider).checkAllAchievements(uid);
          }
        } catch (e) {
          debugPrint('Error syncing round or checking achievements: $e');
        }
      });

      if (!mounted) return;
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Round saved successfully!'), backgroundColor: AppColors.emerald700),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving round: $e'), backgroundColor: AppColors.doubleBogey),
        );
      }
    }
  }

  void _updateScore(int delta) {
    setState(() {
      int newScore = _holeScores[_currentHoleIndex] + delta;
      if (newScore >= 1) { // Minimum score is a hole in one
        _holeScores[_currentHoleIndex] = newScore;
      }
    });
  }

  // To allow users to edit par if it was missing/wrong
  void _updatePar(int delta) {
    setState(() {
      int newPar = _holePars[_currentHoleIndex] + delta;
      if (newPar >= 3 && newPar <= 6) { // restrict par from 3 to 6
        _holePars[_currentHoleIndex] = newPar;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.grey50,
        body: Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
      );
    }

    // Calc current match status
    int currentTotal = _holeScores.take(_currentHoleIndex + 1).reduce((a, b) => a + b);
    int parSoFar = _holePars.take(_currentHoleIndex + 1).reduce((a, b) => a + b);
    int currentToPar = currentTotal - parSoFar;
    String toParText = currentToPar == 0 ? 'E' : currentToPar > 0 ? '+$currentToPar' : currentToPar.toString();

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.grey50,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.grey900),
          onPressed: () => _showQuitDialog(),
        ),
        title: Column(
          children: [
            Text(
              _course?.name ?? 'Course',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
            ),
            Text(
              '${widget.tee} Tee • Score: $toParText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.emerald700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hole Navigation Dots
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _holeScores.length,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  final isActive = index == _currentHoleIndex;
                  final isCompleted = index < _currentHoleIndex; // Roughly speaking
                  final actualHole = (widget.holesPlayed == -9 ? 10 : 1) + index;
                  
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: isActive ? 40 : 36,
                      height: isActive ? 40 : 36,
                      decoration: BoxDecoration(
                        color: isActive 
                            ? AppColors.grey900 
                            : (isCompleted ? AppColors.emerald100 : AppColors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? AppColors.grey900 : AppColors.grey300,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$actualHole',
                        style: TextStyle(
                          color: isActive 
                              ? AppColors.white 
                              : (isCompleted ? AppColors.emerald700 : AppColors.grey500),
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          fontSize: isActive ? 16 : 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Main Scoring Area wrapper
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentHoleIndex = idx),
                itemCount: _holeScores.length,
                itemBuilder: (context, index) {
                  // We rebuild variables for the page being rendered
                  final pScore = _holeScores[index];
                  final pPar = _holePars[index];
                  final pHoleNum = (widget.holesPlayed == -9 ? 10 : 1) + index;
                  
                  return _buildHoleView(pHoleNum, pPar, pScore);
                },
              ),
            ),
            
            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: _isSaving ? null : () {
                    if (_currentHoleIndex < _holeScores.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishRound();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentHoleIndex < _holeScores.length - 1 
                        ? AppColors.grey900 
                        : AppColors.emerald700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                      : Text(
                          _currentHoleIndex < _holeScores.length - 1 ? 'Next Hole' : 'Finish Round',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoleView(int holeNum, int par, int score) {
    // Coloring logic for UI flair
    Color scoreColor = AppColors.grey900;
    if (score < par) scoreColor = AppColors.birdie; // Birdie or better
    if (score > par && score <= par + 2) scoreColor = AppColors.bogey; // Bogey / Double
    if (score > par + 2) scoreColor = AppColors.doubleBogey; // 3+ over
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'HOLE $holeNum',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppColors.grey400,
                ),
          ),
          const SizedBox(height: 8),
          
          // Editable Par Control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.minusCircle, color: AppColors.grey400),
                onPressed: () => _updatePar(-1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Text(
                  'Par $par',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.grey700),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plusCircle, color: AppColors.grey400),
                onPressed: () => _updatePar(1),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Big Score Editor
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            borderRadius: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Minus Button
                _ScoreAdjustButton(
                  icon: LucideIcons.minus,
                  onTap: () => _updateScore(-1),
                ),
                
                // Actual Score Number
                SizedBox(
                  width: 100,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '$score',
                        key: ValueKey<int>(score),
                        style: TextStyle(
                          fontSize: 100,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          color: scoreColor,
                          letterSpacing: -4,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Plus Button
                _ScoreAdjustButton(
                  icon: LucideIcons.plus,
                  onTap: () => _updateScore(1),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Stats Row
          _buildAdvancedStatsSelectors(holeNum - 1),
          
          const Spacer(),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedStatsSelectors(int holeIndex) {
    if (widget.holesPlayed != 18 && widget.holesPlayed != 9 && widget.holesPlayed != -9) {
      return const SizedBox.shrink(); // Fallback
    }
    
    // Par 3s don't have fairways hit trackable usually, but we'll include it or omit it conditionally
    final isPar3 = _holePars[holeIndex] == 3;

    return Column(
      children: [
        // Putts
        _buildStatRow(
          title: 'Putts',
          options: ['0', '1', '2', '3+'],
          selectedValue: _holePutts[holeIndex] == null ? null : _holePutts[holeIndex]! >= 3 ? '3+' : _holePutts[holeIndex].toString(),
          onSelect: (val) {
            setState(() {
              if (val == '3+') _holePutts[holeIndex] = 3;
              else _holePutts[holeIndex] = int.parse(val);
            });
          },
        ),
        
        if (!isPar3) const SizedBox(height: 16),
        if (!isPar3)
          // Fairway
          _buildStatRow(
            title: 'Fairway',
            options: ['Left', 'Hit', 'Right'],
            selectedValue: _holeFairways[holeIndex],
            onSelect: (val) => setState(() => _holeFairways[holeIndex] = val),
          ),
          
        const SizedBox(height: 16),
        // Penalties
        _buildStatRow(
          title: 'Penalties',
          options: ['0', '1', '2+'],
          selectedValue: _holePenalties[holeIndex] == null ? null : _holePenalties[holeIndex]! >= 2 ? '2+' : _holePenalties[holeIndex].toString(),
          onSelect: (val) {
            setState(() {
              if (val == '2+') _holePenalties[holeIndex] = 2;
              else _holePenalties[holeIndex] = int.parse(val);
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatRow({required String title, required List<String> options, required String? selectedValue, required Function(String) onSelect}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.grey500)),
        Row(
          children: options.map((opt) {
            final isSelected = opt == selectedValue;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.emerald700 : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.emerald700 : AppColors.grey200),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.grey700,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quit Round?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Your current progress will be lost. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Quit', style: TextStyle(color: AppColors.doubleBogey, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ScoreAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ScoreAdjustButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey100,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: AppColors.grey300,
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.grey200, width: 2),
          ),
          child: Icon(icon, size: 32, color: AppColors.grey700),
        ),
      ),
    );
  }
}
