import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../core/theme/app_theme.dart';

enum OrbState {
  idle,       // gentle breathing, cool greens
  listening,  // user speaking — reactive pulses, bright lime
  thinking,   // Groq processing — slow spin, amber glow
  speaking,   // Daniel speaking — flowing waves, warm white-green
  done,       // fade out
}

class CaddieOrbWidget extends StatefulWidget {
  final OrbState state;
  final double size;
  final double audioLevel; 

  const CaddieOrbWidget({
    super.key,
    required this.state,
    this.size = 220,
    this.audioLevel = 0.0,
  });

  @override
  State<CaddieOrbWidget> createState() => _CaddieOrbWidgetState();
}

class _CaddieOrbWidgetState extends State<CaddieOrbWidget>
    with TickerProviderStateMixin {

  late final Ticker _ticker;
  double _elapsed = 0.0;
  double _smoothedAudio = 0.0;

  late AnimationController _stateController;
  late Animation<double> _stateProgress;
  OrbState _previousState = OrbState.idle;
  OrbState _currentState = OrbState.idle;

  final _random = math.Random(42);
  late List<_GrainParticle> _grainParticles;

  @override
  void initState() {
    super.initState();

    _grainParticles = List.generate(280, (i) => _GrainParticle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 1.2 + 0.3,
      opacity: _random.nextDouble() * 0.18 + 0.04,
      speed: _random.nextDouble() * 0.3 + 0.05,
      angle: _random.nextDouble() * math.pi * 2,
    ));

    _stateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _stateProgress = CurvedAnimation(
      parent: _stateController,
      curve: Curves.easeInOut,
    );

    _ticker = createTicker((elapsed) {
      final dt = elapsed.inMicroseconds / 1e6;
      _elapsed = dt;
      _smoothedAudio = _smoothedAudio * 0.75 + widget.audioLevel * 0.25;
      if (mounted) setState(() {}); 
    });
    _ticker.start();
  }

  @override
  void didUpdateWidget(CaddieOrbWidget old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      _previousState = _currentState;
      _currentState = widget.state;
      _stateController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stateController.dispose();
    super.dispose();
  }

  List<Color> _colorsForState(OrbState s) {
    switch (s) {
      case OrbState.idle:
        return [
          const Color(0xFF0D2B0F),
          const Color(0xFF1A4D1C),
          AppColors.emerald700,
          AppColors.golfLime,
          const Color(0xFF1A3D1B),
        ];
      case OrbState.listening:
        return [
          const Color(0xFF1A3A00),
          const Color(0xFF4A7A00),
          AppColors.golfLime,
          const Color(0xFFADE05A),
          const Color(0xFF5A9A28),
        ];
      case OrbState.thinking:
        return [
          const Color(0xFF2A1A00),
          const Color(0xFF5A3A00),
          const Color(0xFFC9A94B),
          const Color(0xFFE8C96A),
          const Color(0xFF7A5A20),
        ];
      case OrbState.speaking:
        return [
          const Color(0xFF0A1F0A),
          const Color(0xFF1A4020),
          const Color(0xFF2D7A3E),
          const Color(0xFFE8F5E8),
          const Color(0xFF4AAA60),
        ];
      case OrbState.done:
        return [
          const Color(0xFF050D05),
          const Color(0xFF0D1A0D),
          const Color(0xFF162A16),
          const Color(0xFF1A3A1A),
          const Color(0xFF0D1A0D),
        ];
    }
  }

  List<Color> _lerpColorList(List<Color> a, List<Color> b, double t) {
    return List.generate(
      math.min(a.length, b.length),
      (i) => Color.lerp(a[i], b[i], t)!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _stateProgress.value;
    final prevC = _colorsForState(_previousState);
    final currC = _colorsForState(_currentState);
    final colors = _lerpColorList(prevC, currC, t);

    double speedMult;
    switch (widget.state) {
      case OrbState.idle: speedMult = 0.4; break;
      case OrbState.listening: speedMult = 1.2 + _smoothedAudio * 2.0; break;
      case OrbState.thinking: speedMult = 0.7; break;
      case OrbState.speaking: speedMult = 0.9; break;
      case OrbState.done: speedMult = 0.2; break;
    }

    double scalePulse = 1.0;
    if (widget.state == OrbState.listening) {
      scalePulse = 1.0 + _smoothedAudio * 0.12;
    } else if (widget.state == OrbState.speaking) {
      scalePulse = 1.0 + math.sin(_elapsed * 3.0) * 0.03;
    } else {
      scalePulse = 1.0 + math.sin(_elapsed * 0.8) * 0.015;
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          _OuterGlow(
            size: widget.size,
            colors: colors,
            elapsed: _elapsed,
            state: widget.state,
            audio: _smoothedAudio,
          ),

          // Main orb
          Transform.scale(
            scale: scalePulse,
            child: ClipOval(
              child: SizedBox(
                width: widget.size * 0.72,
                height: widget.size * 0.72,
                child: CustomPaint(
                  painter: _OrbPainter(
                    elapsed: _elapsed,
                    colors: colors,
                    state: widget.state,
                    audioLevel: _smoothedAudio,
                    speedMult: speedMult,
                    grainParticles: _grainParticles,
                  ),
                ),
              ),
            ),
          ),

          // Glass lens highlight
          _InnerHighlight(
            size: widget.size * 0.72,
            elapsed: _elapsed,
            state: widget.state,
          ),
        ],
      ),
    );
  }
}

class _OuterGlow extends StatelessWidget {
  final double size;
  final List<Color> colors;
  final double elapsed;
  final OrbState state;
  final double audio;

  const _OuterGlow({
    required this.size,
    required this.colors,
    required this.elapsed,
    required this.state,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    double glowOpacity;
    double glowSize;

    switch (state) {
      case OrbState.idle:
        glowOpacity = 0.15 + math.sin(elapsed * 0.6) * 0.05;
        glowSize = size * 0.85;
        break;
      case OrbState.listening:
        glowOpacity = 0.25 + audio * 0.35;
        glowSize = size * (0.88 + audio * 0.1);
        break;
      case OrbState.thinking:
        glowOpacity = 0.20 + math.sin(elapsed * 1.2) * 0.08;
        glowSize = size * 0.87;
        break;
      case OrbState.speaking:
        glowOpacity = 0.22 + math.sin(elapsed * 2.5) * 0.1;
        glowSize = size * 0.9;
        break;
      case OrbState.done:
        glowOpacity = 0.05;
        glowSize = size * 0.75;
        break;
    }

    return Container(
      width: glowSize,
      height: glowSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (colors.length > 2 ? colors[2] : Colors.green).withValues(alpha: glowOpacity),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.02,
          ),
          BoxShadow(
            color: (colors.length > 3 ? colors[3] : Colors.lightGreen).withValues(alpha: glowOpacity * 0.5),
            blurRadius: size * 0.6,
          ),
        ],
      ),
    );
  }
}

class _InnerHighlight extends StatelessWidget {
  final double size;
  final double elapsed;
  final OrbState state;

  const _InnerHighlight({
    required this.size,
    required this.elapsed,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final shimmer = state == OrbState.speaking
        ? math.sin(elapsed * 4.0) * 0.08
        : 0.0;

    return Positioned(
      top: size * 0.08,
      left: size * 0.18,
      child: Container(
        width: size * 0.28,
        height: size * 0.18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size),
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.28 + shimmer),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrainParticle {
  double x, y, size, opacity, speed, angle;
  _GrainParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.angle,
  });
}

class _OrbPainter extends CustomPainter {
  final double elapsed;
  final List<Color> colors;
  final OrbState state;
  final double audioLevel;
  final double speedMult;
  final List<_GrainParticle> grainParticles;

  _OrbPainter({
    required this.elapsed,
    required this.colors,
    required this.state,
    required this.audioLevel,
    required this.speedMult,
    required this.grainParticles,
  });

  double _blobNoise(double seed, double t) {
    return math.sin(seed * 2.3 + t) * 0.5 +
           math.cos(seed * 3.7 + t * 0.7) * 0.3 +
           math.sin(seed * 1.1 + t * 1.4) * 0.2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final t = elapsed * speedMult;

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // 1. Deep base
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.2,
        colors: [
          colors[0],
          colors[1],
          colors[0],
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);

    // 2. Liquid blobs
    final blobs = [
      [1.0, 0.65, 0.7, 2],
      [2.5, 0.50, 0.5, 3],
      [4.1, 0.45, 0.4, 2],
      [6.7, 0.40, 0.35, 4],
      [8.3, 0.35, 0.3, 3],
    ];

    for (final b in blobs) {
      final seed = b[0] as double;
      final sizeRatio = b[1] as double;
      final opacity = b[2] as double;
      final cIdx = (b[3] as int).clamp(0, colors.length - 1);

      final nx = _blobNoise(seed, t) * 0.35;
      final ny = _blobNoise(seed + 5.0, t) * 0.35;

      final audioPush = state == OrbState.listening ? audioLevel * 0.15 : 0.0;
      final blobCenter = Offset(
        center.dx + nx * radius + audioPush * radius * math.cos(seed),
        center.dy + ny * radius + audioPush * radius * math.sin(seed),
      );

      final blobRadius = radius * sizeRatio * (1.0 + math.sin(t * 1.3 + seed) * 0.08);
      final blobOpacity = opacity * (0.85 + math.sin(t * 0.9 + seed * 2) * 0.15);

      canvas.drawCircle(
        blobCenter, 
        blobRadius, 
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            colors: [colors[cIdx].withValues(alpha: blobOpacity), colors[cIdx].withValues(alpha: 0.0)],
          ).createShader(Rect.fromCircle(center: blobCenter, radius: blobRadius))
      );
    }

    // 3. Distortion lines
    if (state == OrbState.speaking || state == OrbState.listening) {
      final lineCount = state == OrbState.listening ? 6 : 4;
      for (int i = 0; i < lineCount; i++) {
        final angle = (i / lineCount) * math.pi * 2 + t * 0.4;
        final amp = state == OrbState.listening ? 0.15 + audioLevel * 0.3 : 0.1 + math.sin(t * 2.0 + i) * 0.05;
        final lineLen = radius * (0.6 + amp);
        final path = Path();
        for (int s = 0; s <= 20; s++) {
          final frac = s / 20;
          final r = frac * lineLen;
          final wave = math.sin(frac * math.pi * 4 + t * 3.0 + i) * amp * radius * 0.12;
          final perpAngle = angle + math.pi / 2;
          final x = center.dx + math.cos(angle) * r + math.cos(perpAngle) * wave;
          final y = center.dy + math.sin(angle) * r + math.sin(perpAngle) * wave;
          s == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(path, Paint()..color = colors[3].withValues(alpha: 0.15)..strokeWidth = 1.2..style = PaintingStyle.stroke..blendMode = BlendMode.screen);
      }
    }

    // 4. Grain
    for (final g in grainParticles) {
      final driftX = math.cos(g.angle + t * g.speed) * 0.003;
      final driftY = math.sin(g.angle + t * g.speed * 0.7) * 0.003;
      g.x = (g.x + driftX) % 1.0;
      g.y = (g.y + driftY) % 1.0;
      canvas.drawCircle(Offset(g.x * size.width, g.y * size.height), g.size, Paint()..color = Colors.white.withValues(alpha: g.opacity)..blendMode = BlendMode.screen);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbPainter old) => true;
}
