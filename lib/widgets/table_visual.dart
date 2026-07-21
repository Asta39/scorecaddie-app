import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Near-3D rendering of a single restaurant table with its seats, drawn in
/// code (no external art assets) — shaded top surface, soft drop shadow, and
/// seat pucks arranged evenly around the rim. Greys out entirely when the
/// table is already booked for the selected slot.
class TableVisual extends StatelessWidget {
  final String shape;
  final int seatCount;
  final bool isBooked;
  final bool isSelected;

  const TableVisual({
    super.key,
    required this.shape,
    required this.seatCount,
    this.isBooked = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: shape == 'round' ? 1 : 1.5,
      child: CustomPaint(
        painter: _TablePainter(
          shape: shape,
          seatCount: seatCount,
          isBooked: isBooked,
          isSelected: isSelected,
        ),
      ),
    );
  }
}

class _TablePainter extends CustomPainter {
  final String shape;
  final int seatCount;
  final bool isBooked;
  final bool isSelected;

  _TablePainter({
    required this.shape,
    required this.seatCount,
    required this.isBooked,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final seatRadius = size.shortestSide * 0.11;
    final tableInset = seatRadius * 2.2;

    final Color surfaceLight;
    final Color surfaceDark;
    final Color seatColor;
    final Color rimColor;

    if (isBooked) {
      surfaceLight = AppColors.grey300;
      surfaceDark = AppColors.grey400;
      seatColor = AppColors.grey300;
      rimColor = AppColors.grey400;
    } else if (isSelected) {
      surfaceLight = AppColors.emerald300;
      surfaceDark = AppColors.emerald600;
      seatColor = AppColors.emerald700;
      rimColor = AppColors.emerald700;
    } else {
      surfaceLight = const Color(0xFFE8D9C4);
      surfaceDark = AppColors.golfBrown;
      seatColor = AppColors.grey700;
      rimColor = const Color(0xFF6B4A2E);
    }

    final tableRect = Rect.fromLTWH(
      tableInset,
      tableInset,
      size.width - tableInset * 2,
      size.height - tableInset * 2,
    );

    // Drop shadow.
    final shadowPath = shape == 'round'
        ? (Path()..addOval(tableRect.shift(const Offset(0, 5))))
        : (Path()
          ..addRRect(RRect.fromRectAndRadius(
            tableRect.shift(const Offset(0, 5)),
            Radius.circular(size.shortestSide * 0.12),
          )));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: isBooked ? 0.08 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Table surface with radial gradient for a subtle 3D dome/sheen.
    final surfacePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [surfaceLight, surfaceDark],
      ).createShader(tableRect);

    if (shape == 'round') {
      canvas.drawOval(tableRect, surfacePaint);
      canvas.drawOval(
        tableRect,
        Paint()
          ..color = rimColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else {
      final rrect = RRect.fromRectAndRadius(tableRect, Radius.circular(size.shortestSide * 0.12));
      canvas.drawRRect(rrect, surfacePaint);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = rimColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Seats arranged evenly around the table's perimeter.
    for (int i = 0; i < seatCount; i++) {
      final angle = (2 * math.pi * i / seatCount) - math.pi / 2;
      final seatCenter = _seatPosition(center, tableRect, angle, seatRadius);

      canvas.drawCircle(
        seatCenter.translate(0, 2),
        seatRadius,
        Paint()..color = Colors.black.withValues(alpha: isBooked ? 0.05 : 0.12),
      );
      canvas.drawCircle(
        seatCenter,
        seatRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [seatColor.withValues(alpha: 0.85), seatColor],
          ).createShader(Rect.fromCircle(center: seatCenter, radius: seatRadius)),
      );
    }
  }

  Offset _seatPosition(Offset center, Rect tableRect, double angle, double seatRadius) {
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    if (shape == 'round') {
      final r = tableRect.width / 2 + seatRadius * 1.3;
      return center + Offset(dx * r, dy * r * (tableRect.height / tableRect.width));
    } else {
      // Project onto the rounded-rect perimeter roughly by scaling to the
      // larger half-extent along the ray direction.
      final halfW = tableRect.width / 2 + seatRadius * 1.3;
      final halfH = tableRect.height / 2 + seatRadius * 1.3;
      final scale = math.max(dx.abs() / halfW, dy.abs() / halfH);
      final t = scale == 0 ? 0 : 1 / scale;
      return center + Offset(dx * t, dy * t);
    }
  }

  @override
  bool shouldRepaint(covariant _TablePainter oldDelegate) =>
      oldDelegate.isBooked != isBooked || oldDelegate.isSelected != isSelected || oldDelegate.seatCount != seatCount;
}
