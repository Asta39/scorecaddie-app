import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:score_caddie/screens/onboarding/ob_goo.dart';

class _Pair extends GooPainter {
  _Pair(this.gap) : super(sigma: 6);
  final double gap;
  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFA3E635);
    c.drawCircle(const Offset(60, 60), 20, p);
    c.drawCircle(Offset(60 + 40 + gap, 60), 20, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

Future<ui.Image> _render(WidgetTester t, CustomPainter p) async {
  final key = GlobalKey();
  await t.pumpWidget(Center(child: RepaintBoundary(key: key, child: CustomPaint(size: const Size(200, 120), painter: p))));
  final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  late ui.Image img;
  await t.runAsync(() async => img = await ro.toImage());
  return img;
}

Future<int> _alpha(WidgetTester t, ui.Image img, int x, int y) async {
  late ByteData data;
  await t.runAsync(() async => data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!);
  return data.getUint8((y * img.width + x) * 4 + 3);
}

void main() {
  testWidgets('goo keeps a shape its true size', (t) async {
    final img = await _render(t, _Pair(60)); // far apart
    expect(await _alpha(t, img, 60, 60), greaterThan(250), reason: 'centre solid');
    expect(await _alpha(t, img, 60 + 17, 60), greaterThan(200), reason: 'just inside the edge');
    expect(await _alpha(t, img, 60 + 24, 60), lessThan(20), reason: 'just outside the edge');
  });

  testWidgets('goo bridges close shapes and not distant ones', (t) async {
    final close = await _render(t, _Pair(4)); // 4px gap < 1.35 x sigma
    expect(await _alpha(t, close, 60 + 22, 60), greaterThan(200), reason: 'bridged');
    final far = await _render(t, _Pair(16)); // 16px gap > 1.35 x sigma
    expect(await _alpha(t, far, 60 + 28, 60), lessThan(20), reason: 'separate');
  });
}
