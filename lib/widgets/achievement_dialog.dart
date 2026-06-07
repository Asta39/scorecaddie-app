import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/models/achievement_model.dart';
import '../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AchievementDialog extends StatelessWidget {
  final Achievement achievement;
  final bool isEarned;

  const AchievementDialog({
    super.key,
    required this.achievement,
    this.isEarned = true,
  });

  static Future<void> show(BuildContext context, Achievement achievement, {bool isEarned = true}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementDialog(achievement: achievement, isEarned: isEarned),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('MMMM d, y').format(now);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Frosted Glass Card (Bottom Layer)
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEarned ? "NEW ACHIEVEMENT!" : "ACHIEVEMENT GOAL",
                      style: const TextStyle(
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      achievement.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.grey900,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievement.category.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.grey300,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isEarned)
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: AppColors.grey400,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.grey600,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.golfLime,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                             if (isEarned) BoxShadow(
                               color: AppColors.golfLime.withValues(alpha: 0.5), 
                               blurRadius: 20, 
                               offset: const Offset(0, 8)
                             )
                          ]
                        ),
                        child: const Center(
                          child: Text(
                            "Awesome",
                            style: TextStyle(
                              color: AppColors.grey900,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ).animate()
                     .scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ),
          ),

          // 2. Floating Circular Badge (Middle Layer)
          Positioned(
            top: -45,
            child: TweenAnimationBuilder<double>(
              duration: 800.ms,
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEarned ? AppColors.golfLime : AppColors.grey50,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: (isEarned ? AppColors.golfLime : AppColors.grey300).withValues(alpha: 0.6),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        achievement.icon,
                        size: 44,
                        color: isEarned ? AppColors.grey900 : AppColors.grey400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Confetti (Top Layer, bursts over everything)
          if (isEarned)
            Positioned(
              bottom: 0,
              child: IgnorePointer(
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_u4yrau.json', 
                  repeat: false,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PentagonBadgePainter extends CustomPainter {
  final Color color;
  PentagonBadgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0); 
    path.lineTo(w, h * 0.35); 
    path.lineTo(w * 0.8, h); 
    path.lineTo(w * 0.2, h); 
    path.lineTo(0, h * 0.35); 
    path.close();

    canvas.drawPath(path, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    final hPath = Path();
    hPath.moveTo(w * 0.5, 0);
    hPath.lineTo(w * 0.8, h * 0.2);
    hPath.lineTo(w * 0.2, h * 0.2);
    hPath.close();
    canvas.drawPath(hPath, highlightPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
