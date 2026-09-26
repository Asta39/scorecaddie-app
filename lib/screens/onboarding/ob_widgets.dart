import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'ob_goo.dart';
import 'ob_style.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Bots
// ═══════════════════════════════════════════════════════════════════════════

/// The characters, rendered from bot-avatars (MIT, libraries.dev) into
/// looping animated WebP: an idle look-around, an excited hop, and asleep.
enum ObBot {
  clover('clover', Ob.lime, 'Daniel the clover'),
  ball('ball', Color(0xFFF2F5EE), 'your golf-ball avatar'),
  star('star', Color(0xFFF5C531), 'your star coach avatar');

  const ObBot(this.file, this.color, this.label);
  final String file;
  final Color color;
  final String label;

  String get idle => 'assets/bots/${file}_idle.webp';
  String get happy => 'assets/bots/${file}_happy.webp';
  String get sleep => 'assets/bots/${file}_sleep.webp';

  static ObBot forRole(String? role) => switch (role) {
        'player' => ObBot.ball,
        'coach' => ObBot.star,
        _ => ObBot.clover,
      };
}

class BotImage extends StatelessWidget {
  const BotImage(this.asset, {super.key, required this.size, this.semanticLabel});
  final String asset;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: size,
        height: size,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Entrance: content rises 18px while fading in (.55s), staggered by 60ms
// ═══════════════════════════════════════════════════════════════════════════

extension ObRise on Widget {
  Widget rise([int step = 0]) => animate(delay: Duration(milliseconds: 60 * step))
      .fadeIn(duration: 550.ms, curve: ObCurves.rise)
      .moveY(begin: 18, end: 0, duration: 550.ms, curve: ObCurves.rise);
}

// ═══════════════════════════════════════════════════════════════════════════
// Speech bubble: two droplets drip out of the guide and swell into the bubble
// ═══════════════════════════════════════════════════════════════════════════

class ObBubble extends StatefulWidget {
  const ObBubble({super.key, required this.child, this.maxWidth, this.padding = const EdgeInsets.fromLTRB(18, 14, 18, 14)});
  final Widget child;
  final double? maxWidth;
  final EdgeInsets padding;

  @override
  State<ObBubble> createState() => _ObBubbleState();
}

class _ObBubbleState extends State<ObBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Timings in seconds from the prototype, over a 1s controller.
    final grow = CurvedAnimation(parent: _c, curve: const Interval(.12, .87, curve: ObCurves.bubbleGrow));
    final d1 = CurvedAnimation(parent: _c, curve: const Interval(0, .70, curve: ObCurves.drop1));
    final d2 = CurvedAnimation(parent: _c, curve: const Interval(0, .95, curve: ObCurves.drop1));
    final text = CurvedAnimation(parent: _c, curve: const Interval(.45, .80, curve: Curves.ease));

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.maxWidth != null) {
      content = ConstrainedBox(constraints: BoxConstraints(maxWidth: widget.maxWidth!), child: content);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _BubblePainter(_c, grow, d1, d2)),
        ),
        FadeTransition(opacity: text, child: content),
      ],
    );
  }
}

class _BubblePainter extends GooPainter {
  _BubblePainter(Listenable repaint, this.grow, this.d1, this.d2) : super(sigma: 6, repaint: repaint);
  final Animation<double> grow, d1, d2;

  @override
  EdgeInsets get overflow => const EdgeInsets.fromLTRB(70, 24, 24, 24);

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.cream;
    // Body grows from its bottom-left corner, from 6% × 12% to full size.
    final g = grow.value;
    final sx = .06 + (1 - .06) * g, sy = .12 + (1 - .12) * g;
    c.save();
    c.translate(0, s.height);
    c.scale(sx, sy);
    c.translate(0, -s.height);
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(22)), p);
    c.restore();

    void drop(Offset centre, double r, Offset from, double fromScale, double t) {
      final k = fromScale + (1 - fromScale) * t;
      final o = Offset.lerp(from, Offset.zero, t)!;
      c.drawCircle(centre + o, r * k, p);
    }

    drop(Offset(2, s.height * .86), 9, const Offset(-46, 6), .3, d1.value);
    drop(Offset(-15, s.height * .97), 5, const Offset(-30, 4), .2, d2.value);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Guide row: the bot and its bubble, with the melt-and-reform role swap
// ═══════════════════════════════════════════════════════════════════════════

class ObGuide extends StatefulWidget {
  const ObGuide({
    super.key,
    required this.botAsset,
    required this.botLabel,
    required this.text,
    this.swapFrom,
    this.swapColor,
    this.swapNonce = 0,
  });

  final String botAsset;
  final String botLabel;
  final String text;

  /// When set, the guide melts from this image into [botAsset].
  final String? swapFrom;
  final Color? swapColor;
  final int swapNonce;

  @override
  State<ObGuide> createState() => _ObGuideState();
}

class _ObGuideState extends State<ObGuide> with SingleTickerProviderStateMixin {
  late final AnimationController _swap;

  @override
  void initState() {
    super.initState();
    _swap = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (widget.swapFrom != null) _swap.forward(from: 0);
  }

  @override
  void didUpdateWidget(ObGuide old) {
    super.didUpdateWidget(old);
    if (widget.swapFrom != null && widget.swapNonce != old.swapNonce) _swap.forward(from: 0);
  }

  @override
  void dispose() {
    _swap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 112.0;
    final swapping = widget.swapFrom != null;

    Widget bot;
    if (!swapping) {
      bot = BotImage(widget.botAsset, size: size, semanticLabel: widget.botLabel);
    } else {
      // Old guide: .3s shrink to 20% and fade (origin 50% 60%).
      final out = CurvedAnimation(parent: _swap, curve: const Interval(0, .3, curve: ObCurves.swapOut));
      // New avatar: from .36s, .6s spring in.
      final inn = CurvedAnimation(parent: _swap, curve: const Interval(.36, .96, curve: ObCurves.swapIn));
      bot = AnimatedBuilder(
        animation: _swap,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            if (out.value < 1)
              Opacity(
                opacity: (1 - out.value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 - .8 * out.value,
                  alignment: const Alignment(0, .2),
                  child: BotImage(widget.swapFrom!, size: size),
                ),
              ),
            CustomPaint(size: const Size(size, size), painter: _SwapBlobPainter(_swap.value, widget.swapColor ?? Ob.lime)),
            Opacity(
              opacity: inn.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: .2 + .8 * inn.value,
                alignment: const Alignment(0, .2),
                child: BotImage(widget.botAsset, size: size, semanticLabel: widget.botLabel),
              ),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: size),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // margin-left: -10px
          SizedBox(
            width: size - 10,
            height: size,
            child: OverflowBox(
              alignment: Alignment.centerRight,
              maxWidth: size,
              minWidth: size,
              child: SizedBox(width: size, height: size, child: bot),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ObBubble(
                  key: ValueKey(widget.text),
                  maxWidth: 230,
                  child: Text(widget.text, style: Ob.display(23, color: Ob.ink, height: 1.15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The swap's liquid: a blob swells and collapses while three droplets fling
/// out, all through the goo filter so they pinch off the blob.
class _SwapBlobPainter extends GooPainter {
  _SwapBlobPainter(this.t, this.color) : super(sigma: 6);
  final double t; // 0..1 over 1s
  final Color color;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(70);

  /// Keyframes eased per segment with the given curve, as CSS applies an
  /// element's timing function between each pair of keyframes.
  static double keyframes(double t, List<double> at, List<double> v, Curve curve) {
    if (t <= at.first) return v.first;
    for (var i = 1; i < at.length; i++) {
      if (t <= at[i]) {
        final local = (t - at[i - 1]) / (at[i] - at[i - 1]);
        return v[i - 1] + (v[i] - v[i - 1]) * curve.transform(local.clamp(0, 1));
      }
    }
    return v.last;
  }

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = color;
    const centre = Offset(56, 62);
    // Blob: .8s, scale 0 → 1.06 (38%) → .94 (58%) → 0.
    final bt = (t / .8).clamp(0.0, 1.0);
    final blobScale = keyframes(bt, const [0, .38, .58, 1], const [0, 1.06, .94, 0], ObCurves.swapBlob);
    if (blobScale > 0) c.drawCircle(centre, 34 * blobScale, p);

    // Droplets: .8s each, starting at .12/.16/.2s; 35% at full size in place,
    // then fly to their offset while shrinking to nothing.
    void drop(double delay, double r, Offset to) {
      final dt = ((t - delay) / .8).clamp(0.0, 1.0);
      if (dt <= 0) return;
      final scale = dt < .35
          ? ObCurves.swapDrop.transform((dt / .35).clamp(0.0, 1.0))
          : 1 - ObCurves.swapDrop.transform(((dt - .35) / .65).clamp(0.0, 1.0));
      final move = dt < .35 ? 0.0 : ObCurves.swapDrop.transform(((dt - .35) / .65).clamp(0.0, 1.0));
      if (scale <= 0) return;
      c.drawCircle(centre + to * move, r * scale, p);
    }

    drop(.12, 10, const Offset(-50, -26));
    drop(.16, 9, const Offset(8, -58));
    drop(.20, 10, const Offset(52, -18));
  }

  @override
  bool shouldRepaint(covariant _SwapBlobPainter old) => old.t != t || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
// Page dots: worm indicator on two critically damped springs
// ═══════════════════════════════════════════════════════════════════════════

class ObWormDots extends StatefulWidget {
  const ObWormDots({super.key, required this.index, this.count = 3});
  final int index;
  final int count;

  @override
  State<ObWormDots> createState() => _ObWormDotsState();
}

class _ObWormDotsState extends State<ObWormDots> with SingleTickerProviderStateMixin {
  static const pitch = 24.0, first = 12.0, half = 12.0;
  late final ObSpring _l = ObSpring(first - half, w: 14, z: 1);
  late final ObSpring _r = ObSpring(first + half, w: 14, z: 1);
  // Created up front: a lazy ticker would first be created in dispose().
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  double _centre(int i) => first + i * pitch;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    final c = _centre(widget.index);
    _l.x = _l.target = c - half;
    _r.x = _r.target = c + half;
  }

  @override
  void didUpdateWidget(ObWormDots old) {
    super.didUpdateWidget(old);
    if (widget.index == old.index) return;
    final c = _centre(widget.index);
    final forward = c - half > _l.target;
    // The leading end is stiffer: the pill stretches ahead, then contracts.
    (forward ? _r : _l).w = 26;
    (forward ? _l : _r).w = 13;
    _l.target = c - half;
    _r.target = c + half;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final a = _l.step(dt), b = _r.step(dt);
    setState(() {});
    if (!a && !b) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Slide ${widget.index + 1} of ${widget.count}',
        child: CustomPaint(
          size: Size(first * 2 + pitch * (widget.count - 1), 24),
          painter: _WormPainter(_l.x, _r.x, widget.count),
        ),
      );
}

class _WormPainter extends GooPainter {
  _WormPainter(this.left, this.right, this.count) : super(sigma: 1.5);
  final double left, right;
  final int count;

  RRect get _pill => RRect.fromLTRBR(left, 8, math.max(left + 8, right), 16, const Radius.circular(4));

  @override
  EdgeInsets get overflow => const EdgeInsets.all(12);

  // A lime silhouette under the crisp dots: it bridges to a dot only once the
  // gap drops below ~2px, so the pill visibly reaches for the next dot.
  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.lime;
    for (var i = 0; i < count; i++) {
      c.drawCircle(Offset(12 + 24.0 * i, 12), 4, p);
    }
    c.drawRRect(_pill, p);
  }

  @override
  void paintCrisp(Canvas c, Size s) {
    final grey = Paint()..color = Ob.dotGrey;
    for (var i = 0; i < count; i++) {
      c.drawCircle(Offset(12 + 24.0 * i, 12), 4, grey);
    }
    c.drawRRect(_pill, Paint()..color = Ob.lime);
  }

  @override
  bool shouldRepaint(covariant _WormPainter old) => old.left != left || old.right != right;
}

// ═══════════════════════════════════════════════════════════════════════════
// Setup progress: four segments that fill like liquid and bridge on overshoot
// ═══════════════════════════════════════════════════════════════════════════

class ObGooProgress extends StatefulWidget {
  const ObGooProgress({super.key, required this.step, this.total = 4});
  final int step; // 1-based
  final int total;

  @override
  State<ObGooProgress> createState() => _ObGooProgressState();
}

class _ObGooProgressState extends State<ObGooProgress> with TickerProviderStateMixin {
  late List<AnimationController> _c = _make();

  List<AnimationController> _make() => List.generate(
        widget.total,
        (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 700), value: i < widget.step ? 1 : 0),
      );

  @override
  void didUpdateWidget(ObGooProgress old) {
    super.didUpdateWidget(old);
    if (widget.total != old.total) {
      // Switching between the player and coach paths changes the length.
      for (final c in _c) {
        c.dispose();
      }
      _c = _make();
      return;
    }
    for (var i = 0; i < widget.total; i++) {
      final on = i < widget.step;
      if (on && _c[i].value < 1 && _c[i].status != AnimationStatus.forward) _c[i].forward();
      if (!on && _c[i].value > 0) _c[i].reverse();
    }
  }

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = _c.map((c) => CurvedAnimation(parent: c, curve: ObCurves.segFill, reverseCurve: Curves.easeIn)).toList();
    return Semantics(
      label: 'Setup progress, step ${widget.step} of ${widget.total}',
      child: CustomPaint(
        size: const Size(234, 6),
        painter: _ProgressPainter(Listenable.merge(_c), curved, widget.total),
      ),
    );
  }
}

class _ProgressPainter extends GooPainter {
  _ProgressPainter(Listenable repaint, this.fills, this.total) : super(sigma: 1.2, repaint: repaint);
  final List<Animation<double>> fills;
  final int total;

  static const gap = 6.0;
  double segW(Size s) => (s.width - gap * (total - 1)) / total;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(8);

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()..color = Colors.white.withValues(alpha: .14);
    final w = segW(size);
    for (var i = 0; i < total; i++) {
      canvas.drawRRect(RRect.fromLTRBR(i * (w + gap), 0, i * (w + gap) + w, 6, const Radius.circular(3)), track);
    }
    super.paint(canvas, size);
  }

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.lime;
    final w = segW(s);
    for (var i = 0; i < total && i < fills.length; i++) {
      final k = fills[i].value;
      if (k <= 0) continue;
      final x = i * (w + gap);
      // Grows from the left edge; the overshoot reaches into the gap.
      c.drawRRect(RRect.fromLTRBR(x, 0, x + w * k, 6, const Radius.circular(3)), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Liquid slider (liquid-gooey's "move"): the knob tracks the finger exactly;
// the lime mass chases it on an under-damped spring, stretches with speed
// while keeping its area, and trails a droplet on a softer spring.
// ═══════════════════════════════════════════════════════════════════════════

class ObLiquidSlider extends StatefulWidget {
  const ObLiquidSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 54,
    this.onDragChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min, max;
  final ValueChanged<bool>? onDragChanged;

  @override
  State<ObLiquidSlider> createState() => _ObLiquidSliderState();
}

class _ObLiquidSliderState extends State<ObLiquidSlider> with SingleTickerProviderStateMixin {
  static const pad = 17.0;
  double _width = 342;
  late final ObSpring _blob = ObSpring(0, w: 20, z: .5);
  late final ObSpring _drop = ObSpring(0, w: 9, z: .72);
  // Created up front: a lazy ticker would first be created in dispose().
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _placed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  double get _span => _width - pad * 2;
  double _xFor(double v) => pad + (v - widget.min) / (widget.max - widget.min) * _span;

  void _retarget() {
    final x = _xFor(widget.value);
    if (!_placed) {
      _blob.x = _blob.target = x;
      _drop.x = _drop.target = x;
      _placed = true;
      return;
    }
    _blob.target = x;
    _drop.target = x;
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(ObLiquidSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _retarget();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : math.min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final a = _blob.step(dt), b = _drop.step(dt);
    setState(() {});
    if (!a && !b) _ticker.stop();
  }

  void _setFromDx(double dx) {
    final t = ((dx - pad) / _span).clamp(0.0, 1.0);
    final v = (widget.min + t * (widget.max - widget.min));
    final rounded = (v * 10).round() / 10;
    if (rounded != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(rounded);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth != _width || !_placed) {
        _width = box.maxWidth;
        _placed = false;
        _retarget();
      }
      final step = (widget.value * 10).round() / 10;
      return Semantics(
        slider: true,
        label: 'Handicap index',
        value: step.toStringAsFixed(1),
        increasedValue: math.min(widget.max, step + .1).toStringAsFixed(1),
        decreasedValue: math.max(widget.min, step - .1).toStringAsFixed(1),
        onIncrease: () => widget.onChanged(math.min(widget.max, ((step + .1) * 10).round() / 10)),
        onDecrease: () => widget.onChanged(math.max(widget.min, ((step - .1) * 10).round() / 10)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _setFromDx(d.localPosition.dx),
          onHorizontalDragStart: (d) {
            widget.onDragChanged?.call(true);
            _setFromDx(d.localPosition.dx);
          },
          onHorizontalDragUpdate: (d) => _setFromDx(d.localPosition.dx),
          onHorizontalDragEnd: (_) => widget.onDragChanged?.call(false),
          onHorizontalDragCancel: () => widget.onDragChanged?.call(false),
          child: CustomPaint(
            size: Size(_width, 64),
            painter: _SliderPainter(
              blobX: _blob.x,
              blobV: _blob.v,
              dropX: _drop.x,
              thumbX: _xFor(widget.value),
              span: _span,
            ),
          ),
        ),
      );
    });
  }
}

class _SliderPainter extends GooPainter {
  _SliderPainter({required this.blobX, required this.blobV, required this.dropX, required this.thumbX, required this.span}) : super(sigma: 6);
  final double blobX, blobV, dropX, thumbX, span;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(30);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromLTRBR(0, 25, size.width, 31, const Radius.circular(3)), Paint()..color = Colors.white.withValues(alpha: .14));
    canvas.drawRRect(RRect.fromLTRBR(0, 25, math.max(0, blobX), 31, const Radius.circular(3)), Paint()..color = Ob.lime);
    super.paint(canvas, size);
  }

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.lime;
    // Speed stretches the mass along x while its area stays the same.
    final double stretch = 1 + .36 * math.min(1.0, blobV.abs() / 900);
    c.drawOval(Rect.fromCenter(center: Offset(blobX, 28), width: 34 * stretch, height: 34 / stretch), p);
    final double dropR = 7 + 3 * math.min(1.0, (blobX - dropX).abs() / 60);
    c.drawCircle(Offset(dropX, 28), dropR, p);
  }

  @override
  void paintCrisp(Canvas c, Size s) {
    c.drawCircle(Offset(thumbX, 28), 11, Paint()..color = Ob.cream);
    for (final (i, label) in const ['0', '18', '36', '54'].indexed) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: Ob.body(11, weight: FontWeight.w700, color: Ob.creamA(.45))),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = 17 + span * i / 3;
      tp.paint(c, Offset(x - tp.width / 2, 60 - tp.height * .8));
    }
  }

  @override
  bool shouldRepaint(covariant _SliderPainter old) =>
      old.blobX != blobX || old.dropX != dropX || old.thumbX != thumbX || old.blobV != blobV;
}

// ═══════════════════════════════════════════════════════════════════════════
// Rolling digits (the NumberFlow flip): each digit is a reel of 0-9 three
// times over; only changed digits move, up when the value rises and down
// when it falls, with a plain ease-out. No overshoot, fade or resizing.
// ═══════════════════════════════════════════════════════════════════════════

class ObRollingNumber extends StatefulWidget {
  const ObRollingNumber({super.key, required this.value, required this.fontSize, this.dragging = false, this.unknown = false});

  /// One decimal place, 0 … 99.9.
  final double value;
  final double fontSize;
  final bool dragging;
  final bool unknown;

  @override
  State<ObRollingNumber> createState() => _ObRollingNumberState();
}

class _ObRollingNumberState extends State<ObRollingNumber> {
  late List<int> _pos = _reels(widget.value); // tens, ones, tenths
  late double _last = widget.value;
  bool _snap = false;
  int _generation = 0;

  static List<int> _digits(double v) {
    final t = (v * 10).round();
    return [(t ~/ 100) % 10, (t ~/ 10) % 10, t % 10];
  }

  // Reel position = 10 + digit: the middle copy, with room either side.
  static List<int> _reels(double v) => _digits(v).map((d) => 10 + d).toList();

  @override
  void didUpdateWidget(ObRollingNumber old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (v == _last) return;
    final up = v > _last;
    final a = _digits(_last), b = _digits(v);
    _pos = [
      for (var i = 0; i < 3; i++)
        if (a[i] == b[i])
          _pos[i]
        else
          () {
            // Forward when rising, backward when falling, however it wraps.
            final steps = up ? (b[i] - a[i] + 10) % 10 : -((a[i] - b[i] + 10) % 10);
            final p = _pos[i] + steps;
            return (p < 0 || p > 29) ? 10 + b[i] : p;
          }(),
    ];
    _last = v;
    _snap = false;
    // Once it settles, re-centre every reel on its middle copy, invisibly.
    final gen = ++_generation;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || gen != _generation) return;
      setState(() {
        _pos = _reels(_last);
        _snap = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final em = widget.fontSize;
    final style = Ob.display(em, height: 1.2);
    if (widget.unknown) {
      return SizedBox(height: em * 1.2, child: Center(child: Text('—', style: style.copyWith(color: Ob.creamA(.35)))));
    }
    final duration = _snap ? Duration.zero : Duration(milliseconds: widget.dragging ? 160 : 420);
    return Semantics(
      label: 'Handicap index ${widget.value.toStringAsFixed(1)}',
      excludeSemantics: true,
      child: SizedBox(
        height: em * 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.value >= 10) _Reel(position: _pos[0], em: em, style: style, duration: duration) else const SizedBox.shrink(),
            _Reel(position: _pos[1], em: em, style: style, duration: duration),
            SizedBox(width: em * .248, child: Text('.', textAlign: TextAlign.center, style: style)),
            _Reel(position: _pos[2], em: em, style: style, duration: duration),
          ],
        ),
      ),
    );
  }
}

class _Reel extends StatelessWidget {
  const _Reel({required this.position, required this.em, required this.style, required this.duration});
  final int position;
  final double em;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final step = em * 1.2;
    return SizedBox(
      width: em * .6,
      height: step,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: step * 30,
          maxHeight: step * 30,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: -position * step),
            duration: duration,
            curve: ObCurves.digit,
            builder: (context, y, child) => Transform.translate(offset: Offset(0, y), child: child),
            child: Column(
              children: [
                for (var i = 0; i < 30; i++)
                  SizedBox(height: step, child: Center(child: Text('${i % 10}', style: style))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Welcome cards: one mass that pinches into two. The final 16px gap is well
// past the filter's ~8px bridging distance, so once apart they stay apart.
// ═══════════════════════════════════════════════════════════════════════════

class ObSplitCards extends StatefulWidget {
  const ObSplitCards({super.key, required this.left, required this.right});
  final Widget left, right;

  @override
  State<ObSplitCards> createState() => _ObSplitCardsState();
}

class _ObSplitCardsState extends State<ObSplitCards> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1550))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // .55s delay, 1s split; content fades in from 1.15s over .4s.
    final split = CurvedAnimation(parent: _c, curve: const Interval(.55 / 1.55, 1, curve: ObCurves.split));
    final fade = CurvedAnimation(parent: _c, curve: const Interval(1.15 / 1.55, 1, curve: Curves.ease));
    return SizedBox(
      height: 88,
      child: LayoutBuilder(builder: (context, box) {
        final w = (box.maxWidth - 16) / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _SplitPainter(split, w))),
            Row(
              children: [
                SizedBox(width: w, child: FadeTransition(opacity: fade, child: widget.left)),
                const SizedBox(width: 16),
                SizedBox(width: w, child: FadeTransition(opacity: fade, child: widget.right)),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _SplitPainter extends GooPainter {
  _SplitPainter(this.t, this.cardW) : super(sigma: 6, repaint: t);
  final Animation<double> t;
  final double cardW;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(30);

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.cardFill;
    final k = t.value;
    // From translateX(±88) scale(.4, .7) to rest.
    void card(double x, double dir) {
      final centre = Offset(x + cardW / 2, 44);
      final tx = dir * 88 * (1 - k);
      final sx = .4 + .6 * k, sy = .7 + .3 * k;
      c.save();
      c.translate(centre.dx + tx, centre.dy);
      c.scale(sx, sy);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: cardW, height: 88), const Radius.circular(20)), p);
      c.restore();
    }

    card(0, 1);
    card(cardW + 16, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
