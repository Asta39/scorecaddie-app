import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../onboarding/ob_goo.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

/// Splash: a lime line draws out from a cup, a golf ball drops in with real
/// bounces (restitution 0.45: each bounce e² as high and e as long), rolls
/// into the cup and splashes droplets out of the line. The mark rises out of
/// the hole, "ScoreCaddie" pops in letter by letter, and the cast peeks up.
///
/// Timeline and easings are the prototype's. Tap anywhere to skip.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  static const _total = 5.4; // seconds, then on to the app
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 5400));
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _leave();
    });
    // Signed-in users have seen the cast; move on once the name is up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final signedIn = ref.read(authStateProvider).valueOrNull != null;
      _c.forward();
      if (signedIn) {
        Future.delayed(const Duration(milliseconds: 3600), _leave);
      }
    });
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    context.go('/');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Progress 0..1 of a segment starting at [start]s lasting [dur]s.
  double _seg(double t, double start, double dur) => ((t - start) / dur).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _leave,
            child: Semantics(
              button: true,
              label: 'Skip intro animation',
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth, h = box.maxHeight;
                  final cx = w / 2;
                  // Vertical positions scale with the 844pt reference height.
                  final lineY = h * (599 / 844);
                  return AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final t = reduceMotion ? _total : _c.value * _total;
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned.fill(child: CustomPaint(painter: _GreenPainter(t, cx, lineY))),
                          _ball(t, cx, lineY),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: h * (232 / 844),
                            child: Column(
                              children: [
                                _mark(t),
                                const SizedBox(height: 22),
                                _wordmark(t),
                                const SizedBox(height: 22),
                                Opacity(
                                  opacity: Curves.ease.transform(_seg(t, 3.15, .5)),
                                  child: Text(
                                    'Every shot, counted.',
                                    style: Ob.body(15, weight: FontWeight.w600, color: Ob.creamA(.62)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(left: 0, right: 0, bottom: 0, height: 120, child: _cast(t, w)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ball(double t, double cx, double lineY) {
    // 1.65s from .35s.
    final p = ((t - .35) / 1.65).clamp(0.0, 1.0);
    double y;
    double x = -110;
    // Y: fall 600, bounce 122, bounce 25, roll, drop 12 into the cup.
    if (p < .2545) {
      y = -600 + 600 * ObCurves.gravityIn.transform((p / .2545).clamp(0.0, 1.0));
    } else if (p < .369) {
      y = -122 * ObCurves.gravityOut.transform(((p - .2545) / (.369 - .2545)).clamp(0.0, 1.0));
    } else if (p < .4836) {
      y = -122 + 122 * ObCurves.gravityIn.transform(((p - .369) / (.4836 - .369)).clamp(0.0, 1.0));
    } else if (p < .535) {
      y = -25 * ObCurves.gravityOut.transform(((p - .4836) / (.535 - .4836)).clamp(0.0, 1.0));
    } else if (p < .587) {
      y = -25 + 25 * ObCurves.gravityIn.transform(((p - .535) / (.587 - .535)).clamp(0.0, 1.0));
    } else if (p < .891) {
      y = 0;
    } else {
      y = 12 * ObCurves.gravityIn.transform(((p - .891) / (1 - .891)).clamp(0.0, 1.0));
    }
    if (p >= .587) x = p >= .891 ? 0 : -110 + 110 * ObCurves.roll.transform(((p - .587) / (.891 - .587)).clamp(0.0, 1.0));

    // Squash on each landing (origin: bottom centre), fade into the cup.
    double sx = 1, sy = 1, alpha = 1;
    void squash(double at, double peak, double back, double ax, double ay) {
      if (p >= at - .0045 && p < back) {
        final k = p < at ? (p - (at - .0045)) / .0045 : 1 - (p - at) / (back - at);
        sx = 1 + (ax - 1) * k;
        sy = 1 + (ay - 1) * k;
      }
    }

    squash(.2545, .2545, .276, 1.22, .74);
    squash(.4836, .4836, .50, 1.12, .86);
    squash(.587, .587, .60, 1.05, .93);
    if (p > .92) {
      final k = (p - .92) / .08;
      sx = sy = 1 - .45 * k;
      alpha = 1 - k;
    }
    if (p <= 0) alpha = t < .35 ? 0 : 1;

    return Positioned(
      left: cx - 8 + x,
      top: lineY - 16 + y,
      child: Opacity(
        opacity: alpha.clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(sx, sy, 1),
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(center: Alignment(-.3, -.4), colors: [Colors.white, Color(0xFFE6EBE3), Color(0xFFC3CBBF)], stops: [0, .55, 1]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mark(double t) {
    final k = ObCurves.springOut.transform(_seg(t, 2.2, .85));
    final a = _seg(t, 2.2, .85);
    return Opacity(
      opacity: Curves.easeOut.transform(a).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 230 * (1 - k)),
        child: Transform.scale(scale: .25 + .75 * k, child: Image.asset('assets/images/logo_mark.png', height: 150, excludeFromSemantics: true)),
      ),
    );
  }

  Widget _wordmark(double t) {
    const word = 'ScoreCaddie';
    return Semantics(
      header: true,
      label: word,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < word.length; i++)
              Builder(
                builder: (context) {
                  final s = _seg(t, 2.62 + i * .045, .5);
                  final k = ObCurves.letter.transform(s);
                  return Opacity(
                    opacity: s.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 26 * (1 - k)),
                      child: Transform.scale(
                        scale: .8 + .2 * k,
                        child: Text(word[i], style: Ob.display(50, height: 1)),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _cast(double t, double w) {
    // The caddie blob dozing, the player golf ball laughing, Daniel looking up
    // at the logo, the coach star showing off with flips. Sized for a 390pt
    // screen; narrower phones shrink the cast to fit.
    final k = math.min(1.0, w / 390);
    const cast = [('assets/bots/cast_blob.webp', 92.0, 3.25), ('assets/bots/cast_ball.webp', 92.0, 3.36), ('assets/bots/cast_clover.webp', 104.0, 3.30), ('assets/bots/cast_star.webp', 92.0, 3.46)];
    return ClipRect(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (asset, size, delay) in cast)
            Transform.translate(
              offset: Offset(0, 130 - (130 - 14) * ObCurves.springOut.transform(_seg(t, delay, .7))),
              child: BotImage(asset, size: size * k),
            ),
        ],
      ),
    );
  }
}

/// The lime line (drawing out from the cup), the splash droplets and the
/// cup, through the goo filter so droplets pinch off and land on the line.
class _GreenPainter extends GooPainter {
  _GreenPainter(this.t, this.cx, this.lineY) : super(sigma: 3.2);
  final double t, cx, lineY;

  // (delay, duration, radius, peak dx, peak dy, peak scale, landing dx)
  static const _drops = [
    (2.00, .80, 5.0, -30.0, -70.0, 1.0, -50.0),
    (2.02, .85, 6.0, -12.0, -112.0, 1.0, -20.0),
    (2.00, .90, 7.0, 2.0, -134.0, 1.1, 4.0),
    (2.04, .85, 6.0, 16.0, -96.0, 1.0, 28.0),
    (2.03, .80, 5.0, 32.0, -60.0, .9, 54.0),
  ];

  @override
  EdgeInsets get overflow => EdgeInsets.zero;

  @override
  void paint(Canvas canvas, Size size) {
    Goo.paint(canvas, Rect.fromLTRB(0, lineY - 180, size.width, lineY + 30), sigma, (c) => paintShapes(c, size));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, lineY + 2), width: 26, height: 9), Paint()..color = Colors.black);
  }

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.lime;
    final draw = ObCurves.split.transform((t / .5).clamp(0.0, 1.0));
    const segment = 142.0;
    // Left segment grows leftward from the cup, right one rightward.
    c.drawRRect(RRect.fromLTRBR(cx - 13 - segment * draw, lineY, cx - 13, lineY + 3, const Radius.circular(1.5)), p);
    c.drawRRect(RRect.fromLTRBR(cx + 13, lineY, cx + 13 + segment * draw, lineY + 3, const Radius.circular(1.5)), p);

    for (final (delay, dur, r, px, py, ps, lx) in _drops) {
      final k = (t - delay) / dur;
      if (k < 0) continue;
      final u = k.clamp(0.0, 1.0);
      double dx, dy, sc;
      if (u < .45) {
        final e = ObCurves.gravityOut.transform((u / .45).clamp(0.0, 1.0));
        dx = px * e;
        dy = py * e;
        sc = .5 + (ps - .5) * e;
      } else {
        final e = ObCurves.gravityIn.transform(((u - .45) / .55).clamp(0.0, 1.0));
        dx = px + (lx - px) * e;
        dy = py * (1 - e);
        sc = ps + (.5 - ps) * e;
      }
      c.drawCircle(Offset(cx + dx, lineY + 1 + dy), r * sc, p);
    }
  }

  @override
  bool shouldRepaint(covariant _GreenPainter old) => old.t != t || old.cx != cx || old.lineY != lineY;
}
