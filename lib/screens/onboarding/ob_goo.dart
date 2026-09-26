import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The liquid ("goo") layer, as in liquid-gooey and the prototype.
///
/// Shapes are drawn into an offscreen layer that is blurred by [sigma] and
/// then passed through an alpha threshold. The threshold's slope is k = 24
/// and its offset 0.5(1 − k), so the edge lands at alpha 0.5: a lone shape
/// keeps its true size, and two shapes bridge only when the gap between them
/// is under about 1.35 × sigma. Content that must stay crisp (text, knobs,
/// icons) is painted outside this layer, on top.
class Goo {
  Goo._();

  static const double _k = 24;

  static ui.ImageFilter filter(double sigma) {
    // Flutter's colour matrix takes its translation column in 0..255.
    const offset = 0.5 * (1 - _k) * 255;
    const threshold = ui.ColorFilter.matrix(<double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, _k, offset,
    ]);
    return ui.ImageFilter.compose(
      outer: threshold,
      inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal),
    );
  }

  /// Runs [draw] inside a goo layer covering [bounds] (inflated so the blur
  /// has room to spread).
  static void paint(Canvas canvas, Rect bounds, double sigma, void Function(Canvas c) draw) {
    canvas.saveLayer(bounds.inflate(sigma * 4), Paint()..imageFilter = filter(sigma));
    draw(canvas);
    canvas.restore();
  }
}

/// A CustomPainter whose shapes are drawn through a goo layer.
abstract class GooPainter extends CustomPainter {
  GooPainter({required this.sigma, super.repaint});

  final double sigma;

  /// Extra room around the widget's box the shapes may reach into.
  EdgeInsets get overflow => EdgeInsets.zero;

  void paintShapes(Canvas canvas, Size size);

  /// Crisp content painted after the goo layer (optional).
  void paintCrisp(Canvas canvas, Size size) {}

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = overflow.inflateRect(Offset.zero & size);
    Goo.paint(canvas, bounds, sigma, (c) => paintShapes(c, size));
    paintCrisp(canvas, size);
  }
}
