import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// A frosted glass card widget used for stat cards and accent elements.
/// Provides a translucent emerald-tinted glassmorphism effect.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? tintColor;
  final double tintOpacity;
  final bool useBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.blur = 20,
    this.tintColor,
    this.tintOpacity = 0.08,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = tintColor ?? AppColors.emerald500;

    final container = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: tintOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (!useBlur) return container;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}

/// A frosted glass bottom navigation bar.
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.grey200.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
          ),
        ),
      ),
    );
  }
}
