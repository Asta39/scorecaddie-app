import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'voice_orb_visualizer.dart' show OrbState;

/// Sound-reactive glow along the bottom edge of the screen.
///
/// A Flutter port of the `voice-glow` web component (libraries.dev),
/// using its "mobile" preset and "colorful" dark palette: seven coloured
/// lobes centred on the bottom edge that rise and bloom with the voice,
/// slide sideways while sound is heard, breathe gently when silent, and
/// gather into one sweeping beam while something is being processed.
///
/// The lobe layout, palettes and tuning values are taken from voice-glow
/// 0.2.1: Copyright (c) 2026 Jakub Antalik, MIT License.
///
/// Drive it with [state] and, while listening, the microphone [level]
/// (0–1). While Daniel speaks there is no amplitude feed from the audio
/// player, so a speech-like level is synthesised, the same way the web
/// component synthesises bands from a manual level.
class VoiceBeam extends StatefulWidget {
  final OrbState state;

  /// Live input level, 0–1. Used while [state] is [OrbState.listening].
  final double level;

  /// Visual size multiplier on top of the mobile preset.
  final double scale;

  const VoiceBeam({
    super.key,
    required this.state,
    this.level = 0,
    this.scale = 1,
  });

  @override
  State<VoiceBeam> createState() => _VoiceBeamState();
}

// ── Tuning (voice-glow defaults + its "mobile" preset) ─────────────────────

/// Lobe layout: resting x offset, width and height (px), and which band
/// (0 low, 1 mid, 2 high) moves it.
const _lobes = <({double x, double w, double h, int band})>[
  (x: 0, w: 74, h: 46, band: 0),
  (x: -36, w: 54, h: 40, band: 1),
  (x: 36, w: 54, h: 40, band: 1),
  (x: -72, w: 48, h: 32, band: 2),
  (x: 72, w: 48, h: 32, band: 2),
  (x: -108, w: 42, h: 26, band: 1),
  (x: 108, w: 42, h: 26, band: 1),
];

/// "colorful" palette, dark theme.
const _palette = <Color>[
  Color.fromRGBO(255, 70, 120, 1),
  Color.fromRGBO(60, 190, 255, 1),
  Color.fromRGBO(175, 70, 255, 1),
  Color.fromRGBO(60, 220, 130, 1),
  Color.fromRGBO(255, 150, 40, 1),
  Color.fromRGBO(90, 100, 255, 1),
  Color.fromRGBO(40, 200, 190, 1),
];

/// Band line colours (dark): above, mid, below the edge; white core.
const _bandAbove = Color.fromRGBO(255, 70, 80, 1);
const _bandMid = Color.fromRGBO(90, 255, 150, 1);
const _bandBelow = Color.fromRGBO(80, 140, 255, 1);

const _presetScale = 1.25;
const _glowWidth = 1.15;
const _glowHeight = 2.1;
const _lobeSpacing = 1.35;
const _reach = 3.0; // height multiple at full level
const _spread = 0.45; // width growth at full level
const _flow = 60.0; // px/s sideways at full level
const _bend = 70.0; // how far the band line lifts at full level
const _idle = 0.23;
const _breathe = 5.2; // s
const _attack = 0.325; // s
const _release = 0.86; // s
const _threshold = 0.015;
const _processingDuration = 1.05; // s per pass
const _processingLevel = 0.35;
const _processingEase = 0.6; // s
const _processingCurve = 2.1;
const _hueRange = 20.0; // degrees of slow drift
const _hueDuration = 11.0; // s
const _brightness = 1.2;
const _saturation = 1.5;

class _VoiceBeamState extends State<VoiceBeam> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _BeamFrame _frame = _BeamFrame();
  Duration _last = Duration.zero;
  final math.Random _rng = math.Random();

  // Synthesised speech envelope while Daniel talks.
  double _speechTarget = 0;
  double _speechTimer = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    final t = elapsed.inMicroseconds / 1e6;
    final f = _frame;
    f.time = t;

    // Target level for the current state.
    double target;
    switch (widget.state) {
      case OrbState.listening:
        final raw = widget.level.clamp(0.0, 1.0);
        target = raw < _threshold ? 0 : raw;
        break;
      case OrbState.speaking:
        // Syllable-rate bursts with pauses between words.
        _speechTimer -= dt;
        if (_speechTimer <= 0) {
          final pause = _rng.nextDouble() < 0.18;
          _speechTarget = pause ? 0.05 : 0.35 + _rng.nextDouble() * 0.6;
          _speechTimer = pause ? 0.12 + _rng.nextDouble() * 0.2 : 0.07 + _rng.nextDouble() * 0.12;
        }
        target = _speechTarget;
        break;
      case OrbState.thinking:
        target = _processingLevel;
        break;
      default:
        target = 0;
    }

    // Attack / release smoothing.
    final tau = target > f.level ? _attack : _release;
    f.level += (target - f.level) * (1 - math.exp(-dt / (tau / 3)));

    // Processing morph.
    final pTarget = widget.state == OrbState.thinking ? 1.0 : 0.0;
    f.processing += (pTarget - f.processing) * (1 - math.exp(-dt / (_processingEase / 3)));

    // Idle breathing keeps the beam present while silent.
    final breath = _idle * (0.65 + 0.35 * (0.5 - 0.5 * math.cos(2 * math.pi * t / _breathe)));
    f.glow = math.max(breath, f.level);

    // Bands: synthesised from the level so the lobes move independently.
    final l = f.level;
    f.bands[0] = (l * (0.85 + 0.15 * math.sin(t * 5.3))).clamp(0.0, 1.0);
    f.bands[1] = (l * (0.8 + 0.2 * math.sin(t * 7.9 + 1.1))).clamp(0.0, 1.0);
    f.bands[2] = (l * (0.7 + 0.3 * math.sin(t * 11.3 + 2.4))).clamp(0.0, 1.0);

    // Lobes slide sideways while sound is heard, and rest when it stops.
    f.flowOffset += _flow * f.level * (1 - f.processing) * dt;

    f.hue = _hueRange * math.sin(2 * math.pi * t / _hueDuration);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _VoiceBeamPainter(_frame, widget.scale),
        size: Size.infinite,
      ),
    );
  }
}

class _BeamFrame {
  double time = 0;
  double level = 0;
  double glow = 0;
  double processing = 0;
  double flowOffset = 0;
  double hue = 0;
  final List<double> bands = [0, 0, 0];
}

class _VoiceBeamPainter extends CustomPainter {
  final _BeamFrame f;
  final double userScale;

  _VoiceBeamPainter(this.f, this.userScale);

  static final List<Color> _tuned = _palette.map(_tune).toList();

  /// The component's brightness/saturation filter, applied once.
  static Color _tune(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation * _saturation).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * _brightness).clamp(0.0, 0.92))
        .toColor();
  }

  Color _hueShift(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + f.hue) % 360).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = _presetScale * userScale;
    final cx = size.width / 2;
    final bottom = size.height;
    final spacing = _lobeSpacing * s;
    final ring = 36 * spacing * _lobes.length; // one full turn of the flow
    final halfRing = ring / 2;

    // Processing beam: sweeps left↔right, eased into each turn.
    final phase = (f.time / _processingDuration) % 2;
    final tri = phase < 1 ? phase : 2 - phase; // 0..1..0
    final eased = _easeInOut(tri, _processingCurve);
    final beamX = (eased * 2 - 1) * halfRing * 0.9;
    final p = f.processing;

    // Stay inside the beam's own box; the blur would otherwise spill up the
    // screen.
    canvas.clipRect(Offset.zero & size);

    // Screen rather than plus: overlapping lobes brighten without adding up
    // to flat white.
    final bloom = Paint()..blendMode = BlendMode.screen;
    final inner = Paint()..blendMode = BlendMode.screen;

    for (var i = 0; i < _lobes.length; i++) {
      final lobe = _lobes[i];
      final band = f.bands[lobe.band];
      final color = _hueShift(_tuned[i]);

      // Position on the flowing ring, wrapped around the centre.
      var x = lobe.x * spacing * (1 + _spread * 0.5 * f.level) + f.flowOffset * s;
      x = ((x + halfRing) % ring + ring) % ring - halfRing;
      // Gather into the travelling beam while processing.
      // Keep a little of each lobe's spread so the beam stays colourful
      // instead of stacking every colour on one spot.
      x = x + (beamX - x) * p * 0.72;

      final grow = 1 + (_reach - 1) * band;
      final w = lobe.w * _glowWidth * s * (1 + _spread * band) * (1 - 0.45 * p);
      // Never taller than the box, so the blurred bloom fades out before
      // the clip edge instead of being cut flat.
      final h = math.min(lobe.h * _glowHeight * s * grow, size.height * 0.78);

      // Fade lobes as they reach the ends of the ring so wrapping is invisible.
      final edgeFade = (1 - math.pow((x.abs() / halfRing).clamp(0.0, 1.0), 3)).toDouble();
      final alpha = (f.glow * edgeFade).clamp(0.0, 1.0);
      if (alpha <= 0.002) continue;

      final center = Offset(cx + x, bottom);

      // Bloom: the tall blurred halo.
      // w and h are radii, as in the web component.
      final bloomRect = Rect.fromCenter(center: center, width: w * 2.3, height: h * 2.5);
      bloom
        ..shader = ui.Gradient.radial(
          center, 1, [color.withValues(alpha: 0.5 * alpha), color.withValues(alpha: 0)], [0, 1],
          TileMode.clamp, _ellipse(center, bloomRect.width / 2, bloomRect.height / 2),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * s);
      canvas.drawOval(bloomRect, bloom);

      // Inner body: tighter and more saturated.
      final innerRect = Rect.fromCenter(center: center, width: w * 1.5, height: h * 1.7);
      inner
        ..shader = ui.Gradient.radial(
          center, 1, [color.withValues(alpha: 0.85 * alpha), color.withValues(alpha: 0.3 * alpha), color.withValues(alpha: 0)], [0, 0.45, 1],
          TileMode.clamp, _ellipse(center, innerRect.width / 2, innerRect.height / 2),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * s);
      canvas.drawOval(innerRect, inner);
    }

    // White core where the voice is loudest.
    final coreX = cx + beamX * p;
    final coreCenter = Offset(coreX, bottom);
    final coreW = 60 * s * (1 + _spread * f.level) * (1 - 0.3 * p);
    final coreH = 40 * s * (1 + (_reach - 1) * f.level * 0.6);
    final coreAlpha = (0.12 + 0.5 * f.level).clamp(0.0, 1.0) * (1 - 0.6 * p) * (f.glow > 0 ? 1 : 0);
    canvas.drawOval(
      Rect.fromCenter(center: coreCenter, width: coreW * 2, height: coreH * 2),
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.radial(
          coreCenter, 1,
          [Colors.white.withValues(alpha: coreAlpha), Colors.white.withValues(alpha: coreAlpha * 0.3), Colors.white.withValues(alpha: 0)],
          [0, 0.4, 1], TileMode.clamp, _ellipse(coreCenter, coreW, coreH),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * s),
    );

    _paintBand(canvas, size, s, coreX);
  }

  /// The bright contour along the bottom edge that lifts into a curve under
  /// the glow as the voice gets louder.
  void _paintBand(Canvas canvas, Size size, double s, double peakX) {
    final bottom = size.height - 1;
    final lift = (_bend * s * 0.25) * (0.15 + 0.85 * f.glow);
    final width = 150 * s * (1 + _spread * f.level);
    final path = Path()..moveTo(0, bottom);
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final d = (x - peakX) / width;
      final y = bottom - lift * math.exp(-d * d * 2.2);
      path.lineTo(x, y);
    }

    final fade = f.glow.clamp(0.0, 1.0);
    final shader = ui.Gradient.linear(
      Offset(peakX - width * 1.6, 0),
      Offset(peakX + width * 1.6, 0),
      [
        _bandBelow.withValues(alpha: 0),
        _hueShift(_bandBelow).withValues(alpha: 0.9 * fade),
        _hueShift(_bandMid).withValues(alpha: fade),
        _hueShift(_bandAbove).withValues(alpha: 0.9 * fade),
        _bandAbove.withValues(alpha: 0),
      ],
      const [0, 0.25, 0.5, 0.75, 1],
    );

    // Halo, then the crisp line, then a white hot spot at the peak.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..blendMode = BlendMode.plus
        ..shader = shader
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * s),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus
        ..shader = shader,
    );
  }

  static Float64List _ellipse(Offset c, double rx, double ry) {
    // Maps the unit circle of the radial gradient onto an ellipse.
    return Float64List.fromList([
      rx, 0, 0, 0,
      0, ry, 0, 0,
      0, 0, 1, 0,
      c.dx - c.dx * rx, c.dy - c.dy * ry, 0, 1,
    ]);
  }

  static double _easeInOut(double x, double k) {
    final a = math.pow(x, k).toDouble();
    final b = math.pow(1 - x, k).toDouble();
    return a / (a + b);
  }

  @override
  bool shouldRepaint(covariant _VoiceBeamPainter old) => true;
}
