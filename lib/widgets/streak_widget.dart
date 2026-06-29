import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/streak_provider.dart';
import '../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'streak/streak_bottom_sheet.dart';
import 'loading_spinner.dart';

class StreakWidget extends ConsumerStatefulWidget {
  const StreakWidget({super.key});

  @override
  ConsumerState<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends ConsumerState<StreakWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      data: (info) => _buildContent(info),
      loading: () => const SizedBox(height: 80, child: LoadingSpinner(size: 60)),
      error: (e, s) {
        debugPrint('StreakWidget Error: $e');
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(StreakInfo info) {
    Color accentColor;
    String title;
    String subtitle;
    bool isPulsing;
    Color? flameColorFilter;

    switch (info.status) {
      case StreakStatus.noRounds:
        accentColor = AppColors.grey400;
        title = "Start your streak";
        subtitle = "Play your first round to begin";
        isPulsing = false;
        flameColorFilter = AppColors.grey400;
        break;
      case StreakStatus.broken:
        accentColor = AppColors.doubleBogey;
        title = "Streak ended";
        subtitle = info.lastPlayed != null 
            ? "Last played ${DateFormat('MMM d').format(info.lastPlayed!)}"
            : "No recent activity";
        isPulsing = false;
        flameColorFilter = AppColors.doubleBogey;
        break;
      case StreakStatus.active:
        accentColor = AppColors.golfLime;
        title = "${info.count} Week Streak!";
        subtitle = "Play this week to stay safe";
        isPulsing = false;
        flameColorFilter = AppColors.golfLime;
        break;
      case StreakStatus.safe:
        accentColor = AppColors.golfLime;
        title = "${info.count} Week Streak!";
        subtitle = "You're safe for this week";
        isPulsing = false;
        flameColorFilter = AppColors.golfLime;
        break;
      case StreakStatus.atRisk:
        accentColor = AppColors.golfLime;
        title = "${info.count} Week Streak";
        subtitle = "Play by Sunday to keep it!";
        isPulsing = true;
        flameColorFilter = AppColors.golfLime;
        break;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = isPulsing ? _pulseController.value : 0.0;

        return GestureDetector(
          onTap: () => StreakBottomSheet.show(context, info),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isPulsing 
                    ? Color.lerp(accentColor, AppColors.golfLime, pulseValue)!.withValues(alpha: 0.6)
                    : Theme.of(context).dividerColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    LucideIcons.flame,
                    color: flameColorFilter ?? AppColors.grey400,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (info.status == StreakStatus.safe)
                  _buildBadge("SAFE", AppColors.golfLime)
                else if (info.status == StreakStatus.atRisk)
                  _buildBadge("AT RISK", AppColors.golfLime),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
