import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../profile_image.dart';

/// Shared visual language for every shareable highlight card (rounds,
/// analytics, practice, practice analytics). Framer-SaaS-template move: a
/// soft neutral canvas with the actual content floating as a shadowed white
/// card, rather than the flat edge-to-edge white sheet the first pass used —
/// that flatness was reading as a generic dashboard export, not a product
/// artifact. No gradients, no icon-per-stat clutter, one accent spent on one
/// solid-fill badge per card.
class HighlightCardKit {
  static const double width = 1080;
  static const double height = 1920;
  static const double outerPadding = 48;
  static const double cardPadding = 64;

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle eyebrow({Color color = AppColors.grey500}) => GoogleFonts.inter(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.4,
      );

  static TextStyle title({Color color = AppColors.grey900, double size = 52}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.1,
        height: 1.05,
      );

  static TextStyle hero({Color color = AppColors.grey900, double size = 208}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -5,
        height: 0.92,
        fontFeatures: tabular,
      );

  static TextStyle statValue({Color color = AppColors.grey900}) => GoogleFonts.inter(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.4,
        fontFeatures: tabular,
      );

  static TextStyle statLabel({Color color = AppColors.grey500}) => GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle body({Color color = AppColors.grey600, double size = 25}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
      );
}

/// Soft grey canvas + floating shadowed white card — the Framer-template
/// signature. Everything else renders inside [child].
class HighlightCardCanvas extends StatelessWidget {
  final Widget child;

  const HighlightCardCanvas({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HighlightCardKit.width,
      height: HighlightCardKit.height,
      color: const Color(0xFFF0F1EC), // warm-neutral grey, not stark white
      padding: const EdgeInsets.all(HighlightCardKit.outerPadding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 60, offset: Offset(0, 24)),
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
          HighlightCardKit.cardPadding,
          HighlightCardKit.cardPadding,
          HighlightCardKit.cardPadding,
          48,
        ),
        child: child,
      ),
    );
  }
}

/// Small wordmark chip + eyebrow/title header — the badge is the one
/// distinctive top-of-card move every card shares.
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.flag, size: 16, color: AppColors.emerald700),
                  const SizedBox(width: 8),
                  Text('SCORECADDIE', style: HighlightCardKit.eyebrow(color: AppColors.emerald700)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(eyebrow, style: HighlightCardKit.eyebrow()),
        const SizedBox(height: 10),
        Text(title, style: HighlightCardKit.title()),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: HighlightCardKit.body()),
        ],
      ],
    );
  }
}

/// Solid-fill accent badge — the one deliberate spend of color per card
/// (to-par score, a headline metric, etc). Filled, not outlined: outlined
/// pills read as a wireframe; a filled pill reads as a real product badge.
class HighlightAccentBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const HighlightAccentBadge({
    super.key,
    required this.label,
    this.background = AppColors.grey900,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: HighlightCardKit.statValue(color: foreground).copyWith(fontSize: 32),
      ),
    );
  }
}

/// Plain stat grid — no icons, no dividers, no per-tile boxes. Just number
/// and label with generous whitespace, the way a real product stat block
/// reads rather than a dashboard-template grid.
class HighlightStatRow extends StatelessWidget {
  final List<HighlightStat> stats;

  const HighlightStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 40),
          Expanded(child: _StatCell(stat: stats[i])),
        ],
      ],
    );
  }
}

class HighlightStat {
  final String label;
  final String value;

  const HighlightStat({required this.label, required this.value});
}

class _StatCell extends StatelessWidget {
  final HighlightStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(stat.value, style: HighlightCardKit.statValue()),
        const SizedBox(height: 6),
        Text(stat.label, style: HighlightCardKit.statLabel()),
      ],
    );
  }
}

/// Identity footer: avatar, name, a thin top rule separating it from
/// content above — no icon burst, no colored border box.
class HighlightCardFooter extends StatelessWidget {
  final String? userName;
  final String? avatarUrl;

  const HighlightCardFooter({super.key, this.userName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final name = (userName == null || userName!.trim().isEmpty) ? 'Golfer' : userName!;

    return Container(
      padding: const EdgeInsets.only(top: 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: ProfileImage(url: avatarUrl, size: 72, name: name, isCircle: true),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: HighlightCardKit.title(size: 28)),
                const SizedBox(height: 2),
                Text('scorecaddie.app', style: HighlightCardKit.statLabel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
