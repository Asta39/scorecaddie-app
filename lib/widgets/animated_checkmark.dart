import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Success checkmark that draws itself in and pulses a ring outward —
/// built natively (no Lottie asset) so there's nothing external to fetch
/// or that can go missing; same polished feel as a Lottie success sticker.
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Color backgroundColor;

  const AnimatedCheckmark({
    super.key,
    this.size = 72,
    this.color = AppColors.emerald600,
    this.backgroundColor = AppColors.emerald50,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleIn;
  late final Animation<double> _checkProgress;
  late final Animation<double> _ringProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleIn = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack));
    _checkProgress = CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.75, curve: Curves.easeOut));
    _ringProgress = CurvedAnimation(parent: _controller, curve: const Interval(0.15, 1.0, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.6,
      height: widget.size * 1.6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - _ringProgress.value).clamp(0.0, 1.0),
                child: Container(
                  width: widget.size * (1 + _ringProgress.value * 0.6),
                  height: widget.size * (1 + _ringProgress.value * 0.6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color.withValues(alpha: 0.5), width: 2.5),
                  ),
                ),
              ),
              Transform.scale(
                scale: _scaleIn.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: widget.backgroundColor, shape: BoxShape.circle),
                  child: CustomPaint(
                    painter: _CheckPainter(progress: _checkProgress.value, color: widget.color),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final start = Offset(size.width * 0.28, size.height * 0.52);
    final mid = Offset(size.width * 0.44, size.height * 0.68);
    final end = Offset(size.width * 0.74, size.height * 0.34);

    final firstLegLength = (mid - start).distance;
    final totalLength = firstLegLength + (end - mid).distance;
    final drawLength = totalLength * progress.clamp(0.0, 1.0);

    final path = Path()..moveTo(start.dx, start.dy);
    if (drawLength <= firstLegLength) {
      final t = firstLegLength == 0 ? 0 : drawLength / firstLegLength;
      path.lineTo(start.dx + (mid.dx - start.dx) * t, start.dy + (mid.dy - start.dy) * t);
    } else {
      path.lineTo(mid.dx, mid.dy);
      final remaining = drawLength - firstLegLength;
      final secondLegLength = (end - mid).distance;
      final t = secondLegLength == 0 ? 0 : remaining / secondLegLength;
      path.lineTo(mid.dx + (end.dx - mid.dx) * t, mid.dy + (end.dy - mid.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => oldDelegate.progress != progress;
}
