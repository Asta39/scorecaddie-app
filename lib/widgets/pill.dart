import 'package:flutter/material.dart';

/// A rounded, high-contrast pill badge — used everywhere a status, category,
/// or count needs to read at a glance without straining. Bigger text and
/// tighter icon spacing than the old inline-icon badges this replaces.
class Pill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool dense;
  final bool expand;

  const Pill({
    super.key,
    this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.dense = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: dense ? 6 : 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 13 : 15, color: foreground),
            SizedBox(width: dense ? 5 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 12.5 : 13.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Senior-friendly type scale for Club Life screens — noticeably larger than
/// the old ad hoc inline sizes (which ran as small as 9–12px for meaningful
/// content), while staying inside the existing Apple-calm/emerald visual
/// language, not a new one.
class AppTypeScale {
  static const double caption = 13; // was 9-11 in places
  static const double meta = 14; // author/timestamp lines, was 11-12
  static const double body = 16; // was 12-14
  static const double subtitle = 17;
  static const double title = 19; // was 14-16
  static const double headline = 22; // was 18-20

  /// Minimum comfortable tap target, matches platform accessibility guidance.
  static const double minTapTarget = 48;
}
