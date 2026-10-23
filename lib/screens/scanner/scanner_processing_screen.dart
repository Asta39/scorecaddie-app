import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/scorecard_scanner_provider.dart';

class ScannerProcessingScreen extends ConsumerStatefulWidget {
  const ScannerProcessingScreen({super.key});

  @override
  ConsumerState<ScannerProcessingScreen> createState() => _ScannerProcessingScreenState();
}

class _ScannerProcessingScreenState extends ConsumerState<ScannerProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    Future.microtask(() {
      ref.read(scorecardScannerProvider.notifier).runScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scorecardScannerProvider);

    // Listen for scan success/failure to navigate.
    // In competition mode the scan was launched from CompetitionScanSubmitScreen;
    // pop back to it so it can show its own review step.
    // In personal mode push the standard review screen.
    ref.listen(scorecardScannerProvider, (previous, next) {
      if (next.scanResult != null && !next.isLoading) {
        if (next.isCompetitionMode) {
          context.pop();
        } else {
          context.pushReplacement('/scanner/review');
        }
      }
    });

    final isError = state.errorMessage != null && !state.isLoading;
    final who = state.playerName.isNotEmpty ? state.playerName : 'you';
    final where = state.course?.name ?? 'your course';

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: isError
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    ObTopBar('Scan a card', onBack: _cancel),
                    const Spacer(),
                    Icon(LucideIcons.alertCircle, size: 44, color: Ob.warn),
                    const SizedBox(height: 16),
                    Text('Couldn’t read the card', textAlign: TextAlign.center, style: Ob.display(24)),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!.replaceAll('Exception:', '').replaceAll('FormatException:', '').trim(),
                      textAlign: TextAlign.center,
                      style: Ob.body(15, height: 1.4, color: Ob.creamA(.6)),
                    ),
                    const Spacer(),
                    ObButton(height: 54, radius: 14, onPressed: _startScan, child: Text('Try again', style: Ob.label(17))),
                    const SizedBox(height: 8),
                    CupertinoButton(onPressed: _cancel, child: Text('Retake photo', style: Ob.body(17, color: Ob.lime))),
                  ])
                : Column(children: [
                    const Spacer(),
                    const CupertinoActivityIndicator(radius: 16, color: Ob.lime),
                    const SizedBox(height: 20),
                    Text('Reading your card', style: Ob.display(24)),
                    const SizedBox(height: 8),
                    Text(
                      'Scores for $who at $where. This takes a few seconds.',
                      textAlign: TextAlign.center,
                      style: Ob.body(15, height: 1.4, color: Ob.creamA(.6)),
                    ),
                    const Spacer(),
                  ]),
          ),
        ),
      ),
    );
  }

  void _cancel() {
    ref.read(scorecardScannerProvider.notifier).reset();
    context.pop();
  }
}
