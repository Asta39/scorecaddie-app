import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/database/database.dart' as db;
import '../../core/models/scanned_round_result.dart';
import '../../core/utils/whs_engine.dart';
import '../../providers/app_providers.dart';
import '../../providers/scorecard_scanner_provider.dart';
import '../../widgets/loading_spinner.dart';

class ScannerReviewScreen extends ConsumerStatefulWidget {
  const ScannerReviewScreen({super.key});

  @override
  ConsumerState<ScannerReviewScreen> createState() => _ScannerReviewScreenState();
}

class _ScannerReviewScreenState extends ConsumerState<ScannerReviewScreen> {
  List<db.CourseHole> _officialHoles = [];
  bool _loadingHoles = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOfficialHoles();
  }

  Future<void> _loadOfficialHoles() async {
    final state = ref.read(scorecardScannerProvider);
    if (state.course == null) return;

    try {
      final database = ref.read(databaseProvider);
      final holes = await database.getHolesForCourse(
        state.course!.id,
        teeId: state.tee?.id,
      );
      setState(() {
        _officialHoles = holes;
        _loadingHoles = false;
      });
    } catch (e) {
      debugPrint('Error loading official holes: $e');
      setState(() => _loadingHoles = false);
    }
  }

  // Calculate ESC Cap for hole
  int _calculateESCCap(int par, int holeNumber) {
    final state = ref.read(scorecardScannerProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final hIndex = profile?.handicap ?? 0.0;
    
    final int courseHandicap = state.tee != null
        ? WHSEngine.calculateCourseHandicap(
            handicapIndex: hIndex,
            slopeRating: state.tee!.slopeRating,
            courseRating: state.tee!.courseRating,
            par: state.tee!.par ?? 72,
          )
        : 0;

    final officialHole = _officialHoles.firstWhere(
      (h) => h.holeNumber == holeNumber,
      orElse: () => db.CourseHole(
        id: 0,
        courseId: state.course!.id,
        holeNumber: holeNumber,
        par: par,
        handicapIndex: holeNumber,
      ),
    );

    return WHSEngine.calculateESCCap(
      par,
      courseHandicap,
      officialHole.handicapIndex ?? holeNumber,
    );
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    final state = ref.read(scorecardScannerProvider);
    if (state.scanResult == null || state.course == null) return;

    // Check for duplicate rounds on the same course on the same day
    final database = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final existingRounds = await database.getAllRounds(user.uid);
      final duplicate = existingRounds.where((r) =>
          r.courseId == state.course!.id &&
          r.playedAt.year == state.date.year &&
          r.playedAt.month == state.date.month &&
          r.playedAt.day == state.date.day).firstOrNull;

      if (duplicate != null) {
        if (mounted) {
          final confirmSave = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Duplicate Round Detected'),
              content: Text(
                'You already have a saved round at ${state.course!.name} on '
                '${DateFormat('MMM d, yyyy').format(state.date)}. Do you want to save this round anyway?',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Save Anyway'),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (confirmSave != true) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      await _executeSaveRound();
    } catch (e) {
      debugPrint('Save error: $e');
      setState(() => _isSaving = false);
    }
  }

  Future<void> _executeSaveRound() async {
    final state = ref.read(scorecardScannerProvider);
    final database = ref.read(databaseProvider);
    final user = ref.read(authStateProvider).valueOrNull;
    final profile = ref.read(userProfileProvider).valueOrNull;
    
    if (user == null || state.scanResult == null) return;

    final holesList = state.scanResult!.holes;
    final int holesPlayed = state.scanResult!.roundType == 'front_9'
        ? 9
        : (state.scanResult!.roundType == 'back_9' ? -9 : 18);

    // Calculate ESC capped adjusted gross score
    int totalScore = 0;
    int adjustedGross = 0;
    int actualCoursePar = 0;

    for (final hole in holesList) {
      if (hole.score == null) continue; // Skip unplayed/unreadable holes

      final scoreVal = hole.score!;
      totalScore += scoreVal;
      actualCoursePar += hole.par;

      final cap = _calculateESCCap(hole.par, hole.hole);
      adjustedGross += scoreVal > cap ? cap : scoreVal;
    }

    // WHS parameters
    double cRating = 72.0;
    int sRating = 113;
    double? specificCR;
    int? specificSlope;

    if (state.tee != null) {
      cRating = state.tee!.courseRating;
      sRating = state.tee!.slopeRating;
      
      final isFront9 = holesPlayed == 9;
      specificCR = isFront9 ? state.tee!.courseRatingFront : state.tee!.courseRatingBack;
      specificSlope = isFront9 ? state.tee!.slopeRatingFront : state.tee!.slopeRatingBack;
    }

    final double playerHI = profile?.handicap ?? 36.0;
    final int courseHandicap = state.tee != null
        ? WHSEngine.calculateCourseHandicap(
            handicapIndex: playerHI,
            slopeRating: state.tee!.slopeRating,
            courseRating: state.tee!.courseRating,
            par: state.tee!.par ?? 72,
          )
        : 0;

    double differential;
    if (holesPlayed.abs() == 9) {
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
        slopeRating: sRating,
      );
    }

    final supabaseId = const Uuid().v4();
    String? finalImageUrl;

    // Upload image to Supabase if exists
    if (state.imagePath != null) {
      final imageFile = File(state.imagePath!);
      if (await imageFile.exists()) {
        final storageService = ref.read(supabaseStorageServiceProvider);
        finalImageUrl = await storageService.uploadScorecardImage(
          user.uid,
          supabaseId,
          imageFile,
        );
      }
    }

    // Recalculate front9/back9 totals locally from valid scores
    int? front9 = 0;
    int? back9 = 0;
    for (final hole in holesList) {
      if (hole.score == null) continue;
      if (hole.hole <= 9) {
        front9 = front9! + hole.score!;
      } else {
        back9 = back9! + hole.score!;
      }
    }
    if (holesPlayed == 9) back9 = null;
    if (holesPlayed == -9) front9 = null;

    // Insert round companion
    final roundId = await database.into(database.rounds).insert(
      db.RoundsCompanion.insert(
        supabaseId: drift.Value(supabaseId),
        courseId: state.course!.id,
        useForAnalytics: const drift.Value(true),
        teeId: drift.Value(state.tee?.id),
        courseName: drift.Value(state.course!.name),
        holesPlayed: drift.Value(holesPlayed.abs()),
        totalScore: totalScore,
        totalNet: drift.Value(totalScore - courseHandicap),
        adjustedGrossScore: drift.Value(adjustedGross),
        coursePar: actualCoursePar,
        scoreVsPar: totalScore - actualCoursePar,
        scoreDifferential: drift.Value(differential),
        handicapBefore: drift.Value(profile?.handicap),
        front9Score: drift.Value(front9),
        back9Score: drift.Value(back9),
        playedAt: drift.Value(state.date),
        userId: drift.Value(user.uid),
        // Scanned round columns
        source: const drift.Value('scanned'),
        scorecardImageUrl: drift.Value(finalImageUrl),
        scannerConfidence: drift.Value(state.scanResult!.confidence),
        scannerPlayerSlot: drift.Value(state.scanResult!.playerSlot),
      ),
    );

    // Save hole scores
    final List<db.HoleScoresCompanion> holeCompanions = [];
    for (final hole in holesList) {
      holeCompanions.add(db.HoleScoresCompanion.insert(
        roundId: roundId,
        holeNumber: hole.hole,
        par: hole.par,
        score: hole.score ?? 0, // 0 means unplayed hole
        putts: const drift.Value(null),
        fairwayHit: const drift.Value(null),
        penalties: const drift.Value(null),
        gir: const drift.Value(null),
      ));
    }
    await database.insertHoleScores(holeCompanions);

    // Sync in background (will pull/push all pending including this round)
    ref.read(syncControllerProvider.notifier).syncNow();

    // Refresh rounds list and profile
    ref.invalidate(roundsProvider);
    ref.invalidate(userProfileProvider);

    // Complete navigation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Round successfully scanned and saved!'),
          backgroundColor: AppColors.emerald700,
        ),
      );
      context.go('/');
    }
  }

  void _showScoreEditSheet(ScannedHole hole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
              children: [
                Text(
                  'Hole ${hole.hole} (Par ${hole.par})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.grey900),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(scorecardScannerProvider.notifier).updateHoleScore(hole.hole, null);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Clear / Unreadable', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 24),
            const Text('SELECT SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(10, (index) {
                final scoreVal = index + 1;
                final isSelected = hole.score == scoreVal;
                return InkWell(
                  onTap: () {
                    ref.read(scorecardScannerProvider.notifier).updateHoleScore(hole.hole, scoreVal);
                    Navigator.pop(sheetContext);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.grey900 : AppColors.grey50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.grey900 : AppColors.grey200,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$scoreVal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : AppColors.grey800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scorecardScannerProvider);
    if (state.scanResult == null || _loadingHoles) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: LoadingSpinner(size: 80),
      );
    }

    final result = state.scanResult!;
    final confidence = result.confidence;

    // Determine confidence styling
    Color confColor = AppColors.emerald700;
    String confText = 'High Confidence';
    IconData confIcon = LucideIcons.checkCircle2;
    if (confidence < 0.4) {
      confColor = Colors.redAccent;
      confText = 'Low Confidence — Verify scores';
      confIcon = LucideIcons.alertTriangle;
    } else if (confidence < 0.75) {
      confColor = Colors.amber;
      confText = 'Medium Confidence';
      confIcon = LucideIcons.helpCircle;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Verify Round Scores',
          style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header metadata info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.grey25,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.grey100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 16, color: AppColors.grey400),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.course!.name,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.grey900),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.tag, size: 14, color: AppColors.grey400),
                                  const SizedBox(width: 6),
                                  Text(
                                    state.tee?.name ?? 'No Tee Selected',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.grey600),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  const Icon(LucideIcons.calendar, size: 14, color: AppColors.grey400),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(state.date),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.grey600),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confidence card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: confColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: confColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(confIcon, color: confColor, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              confText,
                              style: TextStyle(color: confColor == Colors.amber ? Colors.orange.shade800 : confColor, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                          Text(
                            '${(confidence * 100).toInt()}% match',
                            style: TextStyle(color: confColor == Colors.amber ? Colors.orange.shade800 : confColor, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text('HOLE BY HOLE SCORES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
                    const SizedBox(height: 12),

                    // Hole grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: result.holes.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final hole = result.holes[index];
                        final official = _officialHoles.firstWhere((h) => h.holeNumber == hole.hole, orElse: () => _officialHoles.first);
                        final isMismatch = hole.par != official.par;

                        return InkWell(
                          onTap: () => _showScoreEditSheet(hole),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: hole.isFlagged ? Colors.amber.withValues(alpha: 0.06) : AppColors.grey25,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: hole.isFlagged
                                    ? Colors.amber.shade300
                                    : (isMismatch ? Colors.redAccent.shade100 : AppColors.grey200),
                                width: (hole.isFlagged || isMismatch) ? 1.5 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'H${hole.hole}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.grey400),
                                    ),
                                    Text(
                                      'Par ${isMismatch ? official.par : hole.par}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isMismatch ? Colors.redAccent : AppColors.grey500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      hole.score != null ? '${hole.score}' : '—',
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: hole.score == null
                                            ? Colors.amber.shade800
                                            : AppColors.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Running totals
                    const Text('SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.grey25,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.grey100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTotalColumn('FRONT 9', result.front9Total != null ? '${result.front9Total}' : '—'),
                          Container(width: 1, height: 40, color: AppColors.grey200),
                          _buildTotalColumn('BACK 9', result.back9Total != null ? '${result.back9Total}' : '—'),
                          Container(width: 1, height: 40, color: AppColors.grey200),
                          _buildTotalColumn('GROSS', result.grossTotal != null ? '${result.grossTotal}' : '—', isHighlight: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          // Retake photo: pop back to Camera screen
                          ref.read(scorecardScannerProvider.notifier).reset();
                          context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.grey200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'RETAKE PHOTO',
                          style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _onSavePressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.grey900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isSaving
                            ? const CupertinoActivityIndicator(color: Colors.white)
                            : const Text(
                                'SAVE ROUND',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalColumn(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.grey400, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 22 : 18,
            fontWeight: FontWeight.w900,
            color: isHighlight ? AppColors.emerald700 : AppColors.grey900,
          ),
        ),
      ],
    );
  }
}
