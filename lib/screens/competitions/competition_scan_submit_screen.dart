import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/database/database.dart' as db;
import '../../core/models/scanned_round_result.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/competition_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/scorecard_scanner_provider.dart';
import '../../widgets/loading_spinner.dart';

/// Admin-only screen: scan a player's paper scorecard and submit / certify it
/// for a formal competition. Reuses the existing Gemini AI scanner pipeline.
class CompetitionScanSubmitScreen extends ConsumerStatefulWidget {
  final String competitionId;
  final String entryId;

  const CompetitionScanSubmitScreen({
    super.key,
    required this.competitionId,
    required this.entryId,
  });

  @override
  ConsumerState<CompetitionScanSubmitScreen> createState() =>
      _CompetitionScanSubmitScreenState();
}

class _CompetitionScanSubmitScreenState
    extends ConsumerState<CompetitionScanSubmitScreen> {
  bool _isSubmitting = false;
  bool _certifyNow = true;
  bool _isLoadingEntry = true;
  bool _hasAutoLaunchedCamera = false;
  String _playerName = '';
  double _playingHandicap = 0;
  String? _playerId;
  List<Map<String, dynamic>> _courseHoles = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final scanner = ref.read(scorecardScannerProvider.notifier);
      scanner.reset();
      scanner.setCompetitionMode(true);
      _fetchEntryDetails();
    });
  }

  Future<void> _fetchEntryDetails() async {
    try {
      final entryRow = await Supabase.instance.client
          .from('competition_entries')
          .select()
          .eq('id', widget.entryId)
          .maybeSingle();

      if (entryRow != null && mounted) {
        final playerId = entryRow['player_id'] as String;
        final userRow = await Supabase.instance.client
            .from('User')
            .select()
            .eq('id', playerId)
            .maybeSingle();

        // Also fetch the competition to get the club_id (course ID)
        final compRow = await Supabase.instance.client
            .from('competitions')
            .select()
            .eq('id', widget.competitionId)
            .maybeSingle();

        List<Map<String, dynamic>> holesList = [];
        if (compRow != null) {
          final clubId = compRow['club_id'] as String?;
          if (clubId != null) {
            // Fetch CourseHole details for this course
            final holesData = await Supabase.instance.client
                .from('CourseHole')
                .select()
                .eq('courseId', clubId)
                .order('holeNumber');
            if (holesData.isNotEmpty) {
              holesList = List<Map<String, dynamic>>.from(holesData);
            }

            final dbInstance = ref.read(databaseProvider);
            db.Course? course = await dbInstance.getCourseBySupabaseId(clubId);
            
            if (course == null) {
              // Try fetching from Supabase Course table and inserting locally
              final courseRow = await Supabase.instance.client
                  .from('Course')
                  .select()
                  .eq('id', clubId)
                  .maybeSingle();
              if (courseRow != null) {
                await dbInstance.upsertCourse(db.CoursesCompanion.insert(
                  supabaseId: drift.Value(clubId),
                  name: courseRow['name'] as String,
                  location: drift.Value(courseRow['location'] as String? ?? ''),
                  city: drift.Value(courseRow['city'] as String?),
                  region: drift.Value(courseRow['region'] as String?),
                  totalHoles: drift.Value(courseRow['holesCount'] as int? ?? 18),
                  par18: drift.Value(courseRow['par18'] as int?),
                ));
                course = await dbInstance.getCourseBySupabaseId(clubId);
              }
            }

            if (course != null) {
              ref.read(scorecardScannerProvider.notifier).setCourse(course);
            }
          }
        }

        setState(() {
          _playerId = playerId;
          _playingHandicap =
              (entryRow['playing_handicap'] as num?)?.toDouble() ?? 0;
          _playerName =
              userRow?['name'] ?? userRow?['email'] ?? 'Unknown Player';
          _courseHoles = holesList;
          _isLoadingEntry = false;
        });

        // Pass course holes and player name to the scanner provider so it can
        // override AI-returned par values with authoritative DB values after scan.
        if (mounted) {
          final scanner = ref.read(scorecardScannerProvider.notifier);
          if (holesList.isNotEmpty) {
            scanner.setCourseHoles(holesList);
          }
          scanner.setPlayerName(
            userRow?['name'] ?? userRow?['email'] ?? 'Unknown Player',
          );

          // Auto-launch camera immediately so the admin doesn't have to
          // tap an extra button — mirrors the player app's scan flow.
          if (!_hasAutoLaunchedCamera) {
            _hasAutoLaunchedCamera = true;
            // Use addPostFrameCallback to ensure the widget is fully built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  ref.read(scorecardScannerProvider).scanResult == null) {
                context.push(
                  '/scanner/camera',
                  extra: {'competitionEntryId': widget.entryId},
                );
              }
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoadingEntry = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEntry = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scorecardScannerProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scan Scorecard',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.grey900,
          ),
        ),
      ),
      body: _isLoadingEntry
          ? const Center(child: LoadingSpinner())
          : scanState.scanResult == null
              ? _ScanStep(
                  entryId: widget.entryId,
                  playerName: _playerName,
                  playingHandicap: _playingHandicap,
                  isLoading: scanState.isLoading,
                  errorMessage: scanState.errorMessage,
                )
              : _ReviewStep(
                  scanResult: scanState.scanResult!,
                  entryId: widget.entryId,
                  competitionId: widget.competitionId,
                  playerName: _playerName,
                  playingHandicap: _playingHandicap,
                  certifyNow: _certifyNow,
                  isSubmitting: _isSubmitting,
                  onCertifyToggle: (val) => setState(() => _certifyNow = val),
                  onSubmit: () => _submit(context, scanState.scanResult!),
                  onRescan: () =>
                      ref.read(scorecardScannerProvider.notifier).resetForRescan(),
                ),
    );
  }

  Future<void> _submit(BuildContext context, ScannedRoundResult result) async {
    final grossScore = result.grossTotal ?? 0;

    // Validation
    final unreadable = result.holes.where((h) => h.score == null).length;
    if (unreadable > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$unreadable hole(s) are missing scores. Please edit them before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (grossScore <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gross score must be greater than 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_playerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player not found. Cannot submit.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Convert scanned holes to scorecard JSON
    final scorecard = result.holes
        .map((h) => {
              'hole': h.hole,
              'par': h.par,
              'strokes': h.score,
            })
        .toList();

    final netScore = grossScore - _playingHandicap;

    // Stableford or Bogey points calculation
    int? stablefordPoints;
    final competition = await ref
        .read(competitionDetailProvider(widget.competitionId).future);
    if (competition?.competitionType == 'stableford' || competition?.competitionType == 'betterball') {
      stablefordPoints = _calculateStableford(result, _playingHandicap);
    } else if (competition?.competitionType == 'bogey') {
      stablefordPoints = _calculateBogey(result, _playingHandicap);
    }

    final profile = ref.read(userProfileProvider).valueOrNull;

    final success =
        await ref.read(competitionActionsProvider.notifier).submitResult(
              competitionId: widget.competitionId,
              entryId: widget.entryId,
              playerId: _playerId!,
              grossScore: grossScore,
              netScore: netScore,
              stablefordPoints: stablefordPoints,
              scorecard: scorecard,
              certified: _certifyNow,
              certifiedBy: _certifyNow ? profile?.uid : null,
            );

    if (mounted) setState(() => _isSubmitting = false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? _certifyNow
                  ? 'Scorecard certified and saved to leaderboard!'
                  : 'Scorecard saved as draft.'
              : 'Failed to save. Please try again.'),
          backgroundColor: success ? AppColors.emerald700 : Colors.red,
        ),
      );
      if (success) context.pop();
    }
  }

  int _calculateStableford(ScannedRoundResult result, double handicap) {
    int hc = handicap.round();
    int total = 0;

    final bool isPlusHandicap = hc < 0;
    final int absHc = hc.abs();
    final int baseStrokes = absHc ~/ 18;
    final int extraStrokes = absHc % 18;

    for (final hole in result.holes) {
      if (hole.score == null) continue;

      // Find handicapIndex for this hole
      final holeInfo = _courseHoles.firstWhere(
        (ch) => ch['holeNumber'] == hole.hole,
        orElse: () => {'handicapIndex': hole.hole, 'par': hole.par},
      );
      final int handicapIndex = holeInfo['handicapIndex'] as int? ?? hole.hole;

      int strokesReceived = 0;
      if (!isPlusHandicap) {
        strokesReceived = baseStrokes;
        if (handicapIndex <= extraStrokes) strokesReceived++;
      } else {
        int strokesSubtracted = baseStrokes;
        if ((19 - handicapIndex) <= extraStrokes) strokesSubtracted++;
        strokesReceived = -strokesSubtracted;
      }

      int netScore = hole.score! - strokesReceived;
      int diff = hole.par - netScore;

      // Stableford points: 2 points for net par, +1 for each stroke under par
      int points = 2 + diff;
      if (points < 0) points = 0;
      total += points;
    }
    return total;
  }

  int _calculateBogey(ScannedRoundResult result, double handicap) {
    int hc = handicap.round();
    int total = 0;

    final bool isPlusHandicap = hc < 0;
    final int absHc = hc.abs();
    final int baseStrokes = absHc ~/ 18;
    final int extraStrokes = absHc % 18;

    for (final hole in result.holes) {
      if (hole.score == null) continue;

      // Find handicapIndex for this hole
      final holeInfo = _courseHoles.firstWhere(
        (ch) => ch['holeNumber'] == hole.hole,
        orElse: () => {'handicapIndex': hole.hole, 'par': hole.par},
      );
      final int handicapIndex = holeInfo['handicapIndex'] as int? ?? hole.hole;

      int strokesReceived = 0;
      if (!isPlusHandicap) {
        strokesReceived = baseStrokes;
        if (handicapIndex <= extraStrokes) strokesReceived++;
      } else {
        int strokesSubtracted = baseStrokes;
        if ((19 - handicapIndex) <= extraStrokes) strokesSubtracted++;
        strokesReceived = -strokesSubtracted;
      }

      int netScore = hole.score! - strokesReceived;

      // Bogey/Par points: Net Birdie or better (+1), Net Par (0), Net Bogey or worse (-1)
      if (netScore < hole.par) {
        total += 1;
      } else if (netScore > hole.par) {
        total -= 1;
      }
    }
    return total;
  }
}

// ─── Step 1: Scan ─────────────────────────────────────────────────────────────
class _ScanStep extends ConsumerWidget {
  final String entryId;
  final String playerName;
  final double playingHandicap;
  final bool isLoading;
  final String? errorMessage;

  const _ScanStep({
    required this.entryId,
    required this.playerName,
    required this.playingHandicap,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.emerald700.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.scanLine,
                    size: 36,
                    color: AppColors.emerald700,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  playerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey900,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Playing Handicap: ${playingHandicap.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: AppColors.emerald700,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Take a clear photo of the completed paper scorecard. The AI will extract all hole scores automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.grey500,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            const Column(
              children: [
                LoadingSpinner(size: 60),
                SizedBox(height: 16),
                Text(
                  'Analysing scorecard...',
                  style: TextStyle(
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else ...[
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                icon: const Icon(LucideIcons.camera, color: Colors.white),
                label: const Text(
                  'Open Camera',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.push(
                  '/scanner/camera',
                  extra: {'competitionEntryId': entryId},
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Tip: Lay the scorecard flat on a dark surface in good lighting for the best results.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.grey400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 2: Review scanned scores & submit ────────────────────────────────
class _ReviewStep extends ConsumerWidget {
  final ScannedRoundResult scanResult;
  final String entryId;
  final String competitionId;
  final String playerName;
  final double playingHandicap;
  final bool certifyNow;
  final bool isSubmitting;
  final ValueChanged<bool> onCertifyToggle;
  final VoidCallback onSubmit;
  final VoidCallback onRescan;

  const _ReviewStep({
    required this.scanResult,
    required this.entryId,
    required this.competitionId,
    required this.playerName,
    required this.playingHandicap,
    required this.certifyNow,
    required this.isSubmitting,
    required this.onCertifyToggle,
    required this.onSubmit,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gross = scanResult.grossTotal ?? 0;
    final front9 = scanResult.front9Total ?? 0;
    final back9 = scanResult.back9Total ?? 0;
    final warnings = scanResult.warnings;
    final unreadableCount = scanResult.holes.where((h) => h.score == null).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Info Header
          Row(
            children: [
              const Icon(LucideIcons.user, color: AppColors.emerald700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  playerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.grey900),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald700.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'HC: ${playingHandicap.toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: AppColors.emerald700,
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScoreStat(label: 'Front 9', value: '$front9'),
                Container(width: 1, height: 40, color: AppColors.grey100),
                _ScoreStat(label: 'Back 9', value: '$back9'),
                Container(width: 1, height: 40, color: AppColors.grey100),
                _ScoreStat(
                    label: 'Gross',
                    value: '$gross',
                    large: true,
                    highlight: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Unreadable Error
          if (unreadableCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$unreadableCount hole(s) missing scores. Tap to edit.',
                      style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Warnings
          if (warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.alertTriangle,
                          size: 14, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        'Review Flagged Holes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  ...warnings.map((w) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $w',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey600),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Hole-by-hole grid
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hole Scores',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.grey900),
              ),
              Text(
                'Tap any score to edit',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: AppColors.grey400),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...scanResult.holes.map((h) => _HoleRow(
                hole: h,
                onTap: () => _showEditDialog(context, ref, h),
              )),

          const SizedBox(height: 20),

          // Certify toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Certify & Publish',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey900),
                      ),
                      const Text(
                        'Certified results appear on the live leaderboard immediately.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: certifyNow,
                  onChanged: onCertifyToggle,
                  activeThumbColor: AppColors.emerald700,
                  activeTrackColor: AppColors.emerald700.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  label: const Text('Rescan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.grey700,
                    side: const BorderSide(color: AppColors.grey200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onRescan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: Icon(
                    certifyNow ? LucideIcons.badgeCheck : LucideIcons.save,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    certifyNow ? 'Certify & Submit' : 'Save Draft',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: certifyNow
                        ? AppColors.emerald700
                        : AppColors.grey700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isSubmitting ? null : onSubmit,
                ),
              ),
            ],
          ),
          if (isSubmitting) ...[
            const SizedBox(height: 12),
            const Center(child: LoadingSpinner(size: 40)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ScannedHole hole) {
    final controller = TextEditingController(text: hole.score?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Hole ${hole.hole}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Score (Par ${hole.par})',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newScore = int.tryParse(controller.text);
                if (newScore != null && newScore > 0) {
                  ref
                      .read(scorecardScannerProvider.notifier)
                      .updateHoleScore(hole.hole, newScore);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _HoleRow extends StatelessWidget {
  final ScannedHole hole;
  final VoidCallback onTap;

  const _HoleRow({required this.hole, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = hole.score;
    final diff = score != null ? score - hole.par : null;
    Color scoreColor = AppColors.grey900;
    if (diff != null) {
      if (diff <= -2) scoreColor = Colors.amber;
      if (diff == -1) scoreColor = AppColors.emerald700;
      if (diff == 1) scoreColor = Colors.orange;
      if (diff >= 2) scoreColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hole.score == null
              ? Colors.red.withValues(alpha: 0.08)
              : hole.isFlagged
                  ? Colors.amber.withValues(alpha: 0.06)
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: hole.score == null
              ? Border.all(color: Colors.red.withValues(alpha: 0.4))
              : hole.isFlagged
                  ? Border.all(color: Colors.amber.withValues(alpha: 0.4))
                  : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                'H${hole.hole}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey500,
                    fontSize: 13),
              ),
            ),
            Text('Par ${hole.par}',
                style: const TextStyle(color: AppColors.grey400, fontSize: 12)),
            const Spacer(),
            if (hole.score == null)
              const Icon(LucideIcons.edit3, size: 14, color: Colors.red)
            else if (hole.isFlagged)
              const Icon(LucideIcons.alertTriangle,
                  size: 14, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              score?.toString() ?? 'Edit',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: score == null ? 14 : 18,
                  color: score == null ? Colors.red : scoreColor),
            ),
            if (diff != null) ...[
              const SizedBox(width: 6),
              Text(
                diff > 0 ? '+$diff' : '$diff',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scoreColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final bool large;
  final bool highlight;

  const _ScoreStat({
    required this.label,
    required this.value,
    this.large = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: large ? 28 : 20,
            color: highlight ? AppColors.grey900 : AppColors.grey700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey400,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

