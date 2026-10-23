import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../widgets/top_notification.dart';
import '../../core/database/database.dart' as db;
import '../../core/models/scanned_round_result.dart';
import '../../core/utils/whs_engine.dart';
import '../../providers/app_providers.dart';
import '../../providers/scorecard_scanner_provider.dart';

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

  /// Strokes for this card: 9-hole cards get the 9-hole course handicap.
  int _courseHandicap(double hIndex) {
    final state = ref.read(scorecardScannerProvider);
    final t = state.tee;
    if (t == null) return 0;
    final type = state.scanResult?.roundType;
    if (type == 'front_9' || type == 'back_9') {
      final front = type == 'front_9';
      final holes = _officialHoles.where((h) => front ? h.holeNumber <= 9 : h.holeNumber > 9).toList();
      return WHSEngine.calculateNineHoleCourseHandicap(
        handicapIndex: hIndex,
        slopeRating: t.slopeRating,
        courseRating: t.courseRating,
        par: t.par ?? 72,
        nineSlopeRating: front ? t.slopeRatingFront : t.slopeRatingBack,
        nineCourseRating: front ? t.courseRatingFront : t.courseRatingBack,
        ninePar: holes.length == 9 ? holes.fold<int>(0, (a, h) => a + h.par) : null,
      );
    }
    return WHSEngine.calculateCourseHandicap(handicapIndex: hIndex, slopeRating: t.slopeRating, courseRating: t.courseRating, par: t.par ?? 72);
  }

  // Calculate ESC Cap for hole
  int _calculateESCCap(int par, int holeNumber) {
    final state = ref.read(scorecardScannerProvider);
    final profile = ref.read(userProfileProvider).valueOrNull;
    final hIndex = profile?.handicap ?? 0.0;
    
    final int courseHandicap = _courseHandicap(hIndex);

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

    final roundType = state.scanResult?.roundType;
    if (roundType == 'front_9' || roundType == 'back_9') {
      // Nine-hole round: strokes follow the nine-hole stroke index.
      final start = roundType == 'front_9' ? 1 : 10;
      final nine = List.generate(9, (i) => _officialHoles
          .where((h) => h.holeNumber == start + i)
          .cast<db.CourseHole?>()
          .firstWhere((_) => true, orElse: () => null));
      final nineSI = WHSEngine.nineHoleStrokeIndexes(
        nine.map((h) => h?.nineHoleIndex).toList(),
        nine.map((h) => h?.handicapIndex).toList(),
      );
      final pos = holeNumber - start;
      if (pos >= 0 && pos < 9) {
        return WHSEngine.calculateESCCapNine(par, courseHandicap, nineSI[pos]);
      }
    }

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
    final int courseHandicap = _courseHandicap(playerHI);

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
      TopNotification.showSuccess(context, 'Round saved');
      context.go('/');
    }
  }

  void _showScoreEditSheet(ScannedHole hole) {
    showObSheet(
      context,
      (sheetContext) => ObSheet(
        title: 'Hole ${hole.hole}',
        subtitle: 'Par ${hole.par}',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var v = 1; v <= 10; v++)
                Semantics(
                  button: true,
                  selected: hole.score == v,
                  label: 'Score $v',
                  child: GestureDetector(
                    onTap: () {
                      ref.read(scorecardScannerProvider.notifier).updateHoleScore(hole.hole, v);
                      Navigator.pop(sheetContext);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hole.score == v ? Ob.lime : Ob.cardFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$v', style: Ob.display(22, color: hole.score == v ? Ob.ink : Ob.cream)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: () {
              ref.read(scorecardScannerProvider.notifier).updateHoleScore(hole.hole, null);
              Navigator.pop(sheetContext);
            },
            child: Text('Mark as unreadable', style: Ob.body(17, color: Ob.warn)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scorecardScannerProvider);
    if (state.scanResult == null || _loadingHoles) {
      return const Scaffold(backgroundColor: Ob.bg, body: Center(child: CupertinoActivityIndicator(color: Ob.lime)));
    }

    final result = state.scanResult!;
    final confidence = result.confidence;
    final (String confText, Color confColor) = confidence < 0.4
        ? ('Low confidence. Check every hole.', Ob.warn)
        : confidence < 0.75
            ? ('Some holes may be misread.', const Color(0xFFB7791F))
            : ('Read cleanly.', Ob.lime);
    final missing = result.holes.where((h) => h.score == null).length;

    db.CourseHole officialFor(ScannedHole hole) => _officialHoles.firstWhere(
          (h) => h.holeNumber == hole.hole,
          orElse: () => db.CourseHole(id: 0, courseId: state.course!.id, holeNumber: hole.hole, par: hole.par, handicapIndex: hole.hole),
        );

    Widget holeRow(ScannedHole hole) {
      final official = officialFor(hole);
      final mismatch = hole.par != official.par;
      final flagged = hole.isFlagged || hole.score == null;
      return ObRow(
        'Hole ${hole.hole}',
        subtitle: mismatch ? 'Card says par ${hole.par}, course is par ${official.par}' : 'Par ${official.par}',
        value: hole.score?.toString() ?? 'Add',
        valueColor: hole.score == null ? Ob.warn : Ob.cream,
        leading: flagged ? const ObRowIcon(LucideIcons.alertTriangle, Color(0xFFB7791F)) : null,
        onTap: () => _showScoreEditSheet(hole),
      );
    }

    final front = result.holes.where((h) => h.hole <= 9).toList();
    final back = result.holes.where((h) => h.hole > 9).toList();

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          child: Column(children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  ObTopBar('Check scores', onBack: () => context.pop()),
                  const SizedBox(height: 4),
                  Text(
                    [state.course!.name, if (state.tee != null) state.tee!.name, DateFormat('d MMM y').format(state.date)].join(' · '),
                    style: Ob.body(15, color: Ob.creamA(.6)),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: confColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$confText ${missing > 0 ? '$missing ${missing == 1 ? 'hole' : 'holes'} unread.' : ''}', style: Ob.body(15))),
                    Text('${(confidence * 100).round()}%', style: Ob.body(15, color: Ob.creamA(.6))),
                  ]),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      _buildTotalColumn('Out', result.front9Total?.toString() ?? '—'),
                      _buildTotalColumn('In', result.back9Total?.toString() ?? '—'),
                      _buildTotalColumn('Total', result.grossTotal?.toString() ?? '—', isHighlight: true),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  if (front.isNotEmpty) ObGroup(header: 'Front nine', children: [for (final h in front) holeRow(h)]),
                  if (back.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    ObGroup(header: 'Back nine', children: [for (final h in back) holeRow(h)]),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text('Tap a hole to fix its score.', style: Ob.body(13, color: Ob.creamA(.6))),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ObButton(
                  height: 54,
                  radius: 14,
                  onPressed: _isSaving ? null : _onSavePressed,
                  child: _isSaving ? const CupertinoActivityIndicator(color: Ob.ink) : Text('Save round', style: Ob.label(17)),
                ),
                CupertinoButton(
                  onPressed: () {
                    ref.read(scorecardScannerProvider.notifier).reset();
                    context.pop();
                  },
                  child: Text('Retake photo', style: Ob.body(17, color: Ob.lime)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTotalColumn(String label, String value, {bool isHighlight = false}) {
    return Expanded(
      child: Column(children: [
        Text(label, style: Ob.body(13, color: Ob.creamA(.6))),
        Text(value, style: Ob.display(isHighlight ? 28 : 22, color: isHighlight ? Ob.lime : Ob.cream)),
      ]),
    );
  }
}
