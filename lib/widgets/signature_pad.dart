import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';

class SignaturePad extends StatefulWidget {
  final String label;
  final String name;
  final Function(List<Offset?>) onSigned;
  final VoidCallback onClear;

  const SignaturePad({
    super.key,
    required this.label,
    required this.name,
    required this.onSigned,
    required this.onClear,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.grey400,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey900,
                  ),
                ),
              ],
            ),
            if (_points.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _points.clear();
                  });
                  widget.onClear();
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 14, color: Colors.red),
                label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onPanUpdate: (details) {
                // Adjust position relative to the container rather than the parent column
                final containerBox = context.findRenderObject() as RenderBox;
                final containerOffset = containerBox.localToGlobal(Offset.zero);
                final adjustedX = details.globalPosition.dx - containerOffset.dx;
                final adjustedY = details.globalPosition.dy - containerOffset.dy - 28; // offset title/label space

                setState(() {
                  _points.add(Offset(adjustedX, adjustedY));
                });
                widget.onSigned(_points);
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(null);
                });
                widget.onSigned(_points);
              },
              child: CustomPaint(
                painter: SignaturePainter(_points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey900
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Bounds check to ensure drawing stays inside signature box
        if (points[i]!.dx >= 0 && points[i]!.dx <= size.width &&
            points[i]!.dy >= 0 && points[i]!.dy <= size.height &&
            points[i + 1]!.dx >= 0 && points[i + 1]!.dx <= size.width &&
            points[i + 1]!.dy >= 0 && points[i + 1]!.dy <= size.height) {
          canvas.drawLine(points[i]!, points[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}
