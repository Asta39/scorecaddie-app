import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../profile_image.dart';

/// Shared visual language for every shareable highlight card (rounds,
/// analytics, practice, practice analytics). One calm system instead of each
/// card inventing its own canvas/color/decoration — flat white surface,
/// hairline dividers instead of boxed tiles, a single accent color spent on
/// one hero number per card, no gradients, no ghost-icon watermarks.
class HighlightCardKit {
  static const double width = 1080;
  static const double height = 1920;
  static const double margin = 72;

  static TextStyle eyebrow({Color color = AppColors.grey500}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.6,
      );

  static TextStyle title({Color color = AppColors.grey900, double size = 56}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.2,
        height: 1.05,
      );

  static TextStyle hero({Color color = AppColors.grey900, double size = 220}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -4,
        height: 0.95,
      );

  static TextStyle statValue({Color color = AppColors.grey900}) => GoogleFonts.inter(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle statLabel({Color color = AppColors.grey500}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle body({Color color = AppColors.grey700, double size = 26}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );
}

/// Full-bleed white canvas every card renders onto. Keeps a single hairline
/// accent bar at the top — the only "brand" gesture that doesn't depend on
/// a gradient or glow.
class HighlightCardCanvas extends StatelessWidget {
  final Widget child;

  const HighlightCardCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HighlightCardKit.width,
      height: HighlightCardKit.height,
      color: Colors.white,
      child: Column(
        children: [
          Container(height: 10, color: AppColors.golfLime),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                HighlightCardKit.margin,
                64,
                HighlightCardKit.margin,
                56,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eyebrow + title header used at the top of every card.
class HighlightCardHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;

  const HighlightCardHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: HighlightCardKit.eyebrow(color: AppColors.emerald700)),
        const SizedBox(height: 14),
        Text(title, style: HighlightCardKit.title()),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(subtitle!, style: HighlightCardKit.body()),
        ],
      ],
    );
  }
}

/// A row of stats separated by hairline dividers rather than individual
/// colored boxes — reads as one calm strip instead of a grid of cards.
class HighlightStatRow extends StatelessWidget {
  final List<HighlightStat> stats;

  const HighlightStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.grey200),
          bottom: BorderSide(color: AppColors.grey200),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 64, color: AppColors.grey200),
            Expanded(child: _StatCell(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

class HighlightStat {
  final String label;
  final String value;
  final IconData? icon;

  const HighlightStat({required this.label, required this.value, this.icon});
}

class _StatCell extends StatelessWidget {
  final HighlightStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stat.icon != null) ...[
            Icon(stat.icon, size: 26, color: AppColors.grey400),
            const SizedBox(height: 14),
          ],
          Text(stat.value, style: HighlightCardKit.statValue()),
          const SizedBox(height: 6),
          Text(stat.label, style: HighlightCardKit.statLabel()),
        ],
      ),
    );
  }
}

/// Identity footer shared by every card: avatar, name, wordmark. No colored
/// icon burst — a single small flag mark, same weight as the header accent.
class HighlightCardFooter extends StatelessWidget {
  final String? userName;
  final String? avatarUrl;

  const HighlightCardFooter({super.key, this.userName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final name = (userName == null || userName!.trim().isEmpty) ? 'Golfer' : userName!;

    return Row(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.antiAlias,
          child: ProfileImage(url: avatarUrl, size: 84, name: name, isCircle: true),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: HighlightCardKit.title(size: 32)),
              const SizedBox(height: 4),
              Text('ScoreCaddie', style: HighlightCardKit.statLabel()),
            ],
          ),
        ),
        Icon(LucideIcons.flag, color: AppColors.grey300, size: 40),
      ],
    );
  }
}
