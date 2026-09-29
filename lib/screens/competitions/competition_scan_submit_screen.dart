import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/database/database.dart' as db;
import '../../core/models/scanned_round_result.dart';
import '../../providers/auth_providers.dart';
import '../../providers/competition_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/scorecard_scanner_provider.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

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
            .from('UserPublic')
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
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ObTopBar('Hand in the card', onBack: () => context.pop()),
            ),
            Expanded(
              child: _isLoadingEntry
                  ? const Center(child: CupertinoActivityIndicator(color: Ob.lime))
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
                          onRescan: () => ref.read(scorecardScannerProvider.notifier).resetForRescan(),
                        ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, ScannedRoundResult result) async {
    final grossScore = result.grossTotal ?? 0;

    // Validation
    final unreadable = result.holes.where((h) => h.score == null).length;
    if (unreadable > 0) {
      TopNotification.showError(context, '$unreadable hole${unreadable == 1 ? '' : 's'} still need a score. Tap them to fill in.');
      return;
    }

    if (grossScore <= 0) {
      TopNotification.showError(context, 'The card adds up to 0. Rescan it or fill in the holes.');
      return;
    }

    if (_playerId == null) {
      TopNotification.showError(context, 'Couldn\'t find this player\'s entry. Go back and open it again.');
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
      if (success) {
        TopNotification.showSuccess(context, _certifyNow ? 'Card certified. It\'s on the leaderboard.' : 'Card saved. Certify it to publish.');
        ref.invalidate(leaderboardProvider(widget.competitionId));
        context.pop();
      } else {
        TopNotification.showError(context, 'Couldn\'t save the card. Try again.');
      }
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
    final first = playerName.split(' ').first;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        ObGuideRow(
          botAsset: isLoading ? ObBot.clover.happy : ObBot.clover.idle,
          botLabel: 'Daniel the clover',
          text: isLoading ? 'Reading $first\'s card…' : 'Snap $first\'s card and I\'ll read every hole.',
          size: 84,
          fontSize: 17,
        ),
        const SizedBox(height: 18),
        ObCard(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Text(playerName.isEmpty ? 'Player' : playerName, style: Ob.body(16, weight: FontWeight.w800))),
            ObChip('Playing HC ${playingHandicap.round()}', on: true),
          ]),
        ),
        if (errorMessage != null && !isLoading) ...[
          const SizedBox(height: 12),
          _Banner(color: Ob.warn, icon: LucideIcons.alertCircle, text: errorMessage!),
        ],
        const SizedBox(height: 18),
        if (isLoading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CupertinoActivityIndicator(color: Ob.lime, radius: 14)))
        else
          ObButton(
            onPressed: () => context.push('/scanner/camera', extra: {'competitionEntryId': entryId}),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.camera, size: 18, color: Ob.ink),
              const SizedBox(width: 8),
              Text(errorMessage == null ? 'Open the camera' : 'Try again', style: Ob.label(16, weight: FontWeight.w800)),
            ]),
          ),
        const SizedBox(height: 12),
        Text('Lay the card flat on something dark, in good light.', textAlign: TextAlign.center, style: Ob.body(12, color: Ob.creamA(.5))),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text, this.child});
  final Color color;
  final IconData icon;
  final String text;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withValues(alpha: .4))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: Ob.body(14, weight: FontWeight.w700)),
              if (child != null) child!,
            ]),
          ),
        ]),
      );
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
    final missing = scanResult.holes.where((h) => h.score == null).length;
    final first = playerName.split(' ').first;

    return Column(children: [
      Expanded(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            ObGuideRow(
              botAsset: missing > 0 ? ObBot.clover.idle : ObBot.clover.happy,
              botLabel: 'Daniel the clover',
              text: missing > 0
                  ? 'I couldn\'t read $missing hole${missing == 1 ? '' : 's'}. Tap ${missing == 1 ? 'it' : 'them'} to fill in.'
                  : 'Read it: $gross gross for $first. Check it, then certify.',
              size: 80,
              fontSize: 16,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ObCard(padding: const EdgeInsets.all(14), child: ObStat('Front 9', '$front9', valueSize: 26))),
              const SizedBox(width: 10),
              Expanded(child: ObCard(padding: const EdgeInsets.all(14), child: ObStat('Back 9', '$back9', valueSize: 26))),
              const SizedBox(width: 10),
              Expanded(child: ObCard(padding: const EdgeInsets.all(14), child: ObStat('Gross', '$gross', valueSize: 26, valueColor: Ob.lime))),
            ]),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Banner(
                color: Ob.warn,
                icon: LucideIcons.alertTriangle,
                text: 'Check these',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final w in warnings) Padding(padding: const EdgeInsets.only(top: 4), child: Text(w, style: Ob.body(13, color: Ob.creamA(.7)))),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            ObEyebrow('Hole by hole', trailing: Text('Tap to edit', style: Ob.body(12, color: Ob.creamA(.5)))),
            const SizedBox(height: 10),
            ObCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (final (i, h) in scanResult.holes.indexed) ...[
                  if (i > 0) const ObHair(),
                  _HoleRow(hole: h, onTap: () => _edit(context, ref, h)),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            ObCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Certify and publish', style: Ob.body(15, weight: FontWeight.w800)),
                    Text('Certified cards go straight onto the leaderboard.', style: Ob.body(12, color: Ob.creamA(.6))),
                  ]),
                ),
                CupertinoSwitch(value: certifyNow, onChanged: onCertifyToggle, activeTrackColor: Ob.lime),
              ]),
            ),
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(color: Ob.bg, border: Border(top: BorderSide(color: Ob.creamA(.06)))),
        child: Row(children: [
          ObButton(
            tone: ObButtonTone.dark,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            onPressed: isSubmitting ? null : onRescan,
            child: Text('Rescan', style: Ob.label(15, weight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ObButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: Text(isSubmitting ? 'Saving…' : (certifyNow ? 'Certify and publish' : 'Save for later'), style: Ob.label(16, weight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    ]);
  }

  void _edit(BuildContext context, WidgetRef ref, ScannedHole hole) {
    final controller = TextEditingController(text: hole.score?.toString() ?? '');
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'Hole ${hole.hole}',
        subtitle: 'Par ${hole.par}. How many strokes?',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            cursorColor: Ob.lime,
            textAlign: TextAlign.center,
            style: Ob.display(36),
            decoration: obInput(null, hint: '${hole.par}'),
          ),
          const SizedBox(height: 14),
          ObButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v > 0) ref.read(scorecardScannerProvider.notifier).updateHoleScore(hole.hole, v);
              Navigator.pop(ctx);
            },
            child: Text('Save', style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ]),
      ),
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
    final color = diff == null
        ? Ob.warn
        : diff <= -2
            ? const Color(0xFFF5C531)
            : diff == -1
                ? Ob.lime
                : diff == 0
                    ? Ob.cream
                    : diff == 1
                        ? Ob.creamA(.75)
                        : Ob.warn;

    return Semantics(
      button: true,
      label: 'Hole ${hole.hole}, ${score == null ? 'no score' : '$score strokes'}',
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: score == null ? Ob.warn.withValues(alpha: .08) : (hole.isFlagged ? Ob.warn.withValues(alpha: .05) : null),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${hole.hole}', style: Ob.display(16, color: Ob.creamA(.6)))),
            Text('Par ${hole.par}', style: Ob.body(13, color: Ob.creamA(.55))),
            const Spacer(),
            if (score == null || hole.isFlagged) ...[Icon(score == null ? LucideIcons.pencil : LucideIcons.alertTriangle, size: 14, color: Ob.warn), const SizedBox(width: 8)],
            Text(score?.toString() ?? 'Add', style: score == null ? Ob.body(14, weight: FontWeight.w800, color: Ob.warn) : Ob.display(20, color: color)),
            if (diff != null) SizedBox(width: 30, child: Text(diff == 0 ? '' : (diff > 0 ? '+$diff' : '$diff'), textAlign: TextAlign.right, style: Ob.body(11, weight: FontWeight.w700, color: color))),
          ]),
        ),
      ),
    );
  }
}

