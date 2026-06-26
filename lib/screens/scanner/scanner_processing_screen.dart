import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/scorecard_scanner_provider.dart';
import '../../widgets/loading_spinner.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.isLoading) ...[
                  _buildAnimatedLoading(state.playerName, state.course?.name ?? 'Golf Club'),
                ] else if (isError) ...[
                  _buildErrorState(state.errorMessage!),
                ] else ...[
                  // Backup state in case scan finished but navigation hasn't fired yet
                  const LoadingSpinner(size: 80),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLoading(String playerName, String courseName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Replace custom pulsing visual with the app's well-sized LoadingSpinner Lottie animation
        const LoadingSpinner(size: 150),
        const SizedBox(height: 40),
        const Text(
          'Scanning Scorecard...',
          style: TextStyle(color: AppColors.grey900, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fadeIn(duration: 800.ms),
        const SizedBox(height: 16),
        Text(
          'Analyzing scores for ${playerName.isNotEmpty ? playerName : 'Golfer'} at $courseName using AI vision',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey500, fontSize: 15, height: 1.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 48),
        
        // Progress steps indicator (white theme style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.grey25,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grey100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.emerald700),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Reading columns & hole values...',
                style: TextStyle(color: AppColors.grey800, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(
            LucideIcons.alertCircle,
            color: Colors.redAccent,
            size: 40,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Scan Failed',
          style: TextStyle(color: AppColors.grey900, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            error.replaceAll('Exception:', '').replaceAll('FormatException:', '').trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey500, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: OutlinedButton(
                  onPressed: () {
                    // Reset scanner and go back to course select screen or cameras
                    ref.read(scorecardScannerProvider.notifier).reset();
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 60,
                child: FilledButton(
                  onPressed: () {
                    // Retry scan call
                    _startScan();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.golfLime,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'RETRY SCAN',
                    style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
