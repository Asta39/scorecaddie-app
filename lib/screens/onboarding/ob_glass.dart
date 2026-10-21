import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ob_style.dart';

/// Liquid glass, ported from Opaline's LiquidGlass (the React component the
/// Stripped storefront uses for its header and dock; vendored there from
/// https://opaline.buildlab.in).
///
/// Phones get Opaline's frosted path: the backdrop is blurred and saturated,
/// a tint keeps labels legible, a bright inner rim catches the light on the
/// top-left edge, a hairline holds the edge, and a soft shadow lifts it.
/// Opaline's SVG refraction only runs in Chromium, so this is the same look
/// iPhone Safari shows.
///
/// With High Contrast or Reduce Transparency the surface turns solid with a
/// defined edge (HIG: never rely on glass alone for legibility).
class ObGlass extends StatelessWidget {
  const ObGlass({
    super.key,
    required this.child,
    this.radius = 999,
    this.frosted = true,
    this.tint,
    this.shadow = true,
    this.blur = 16,
    this.saturation = 1.5,
  });

  final Widget child;
  final double radius;

  /// Frosted adds a stronger tint for text on top; clear is for the moving bubble.
  final bool frosted;
  final Color? tint;
  final bool shadow;
  final double blur;
  final double saturation;

  static const _tintClear = Color(0x40FFFFFF); // light glass
  static const _tintFrosted = Color(0xB8F9F9F9); // ~72% white, keeps labels at 4.5:1

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final solid = MediaQuery.maybeHighContrastOf(context) ?? false;

    final surface = solid
        ? DecoratedBox(
            decoration: BoxDecoration(color: Ob.cardFill, borderRadius: r, border: Border.all(color: Ob.creamA(.28))),
            child: child,
          )
        : ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.compose(outer: _saturate(saturation), inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur)),
              child: DecoratedBox(
                decoration: BoxDecoration(color: tint ?? (frosted ? _tintFrosted : _tintClear), borderRadius: r),
                position: DecorationPosition.background,
                child: CustomPaint(foregroundPainter: _GlassRim(radius), child: child),
              ),
            ),
          );

    if (!shadow) return surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x38000000), blurRadius: 32, offset: Offset(0, 10), spreadRadius: -8),
        ],
      ),
      child: surface,
    );
  }

  static ColorFilter _saturate(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    final i = 1 - s;
    return ColorFilter.matrix(<double>[
      r * i + s, g * i, b * i, 0, 0, //
      r * i, g * i + s, b * i, 0, 0,
      r * i, g * i, b * i + s, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}

/// Opaline's `--glass-rim` (light theme): bright top-left inner edge, dimmer
/// bottom-right inner edge, a 0.5px hairline and a faint inner glow.
class _GlassRim extends CustomPainter {
  _GlassRim(this.radius);
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius.clamp(0, size.shortestSide / 2)));
    canvas.save();
    canvas.clipRRect(rr);

    // Inner glow.
    canvas.drawRRect(
      rr.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white.withValues(alpha: .05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Light catches the top-left edge, less so the bottom-right.
    canvas.drawRRect(
      rr.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: .95), Colors.white.withValues(alpha: .3), Colors.white.withValues(alpha: .6)],
          stops: const [0, .5, 1],
        ).createShader(rect),
    );
    // Hairline.
    canvas.drawRRect(
      rr.deflate(.25),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5
        ..color = Colors.black.withValues(alpha: .06),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassRim old) => old.radius != radius;
}

/// Opaline's dock spring, `cubic-bezier(0.34, 1.3, 0.64, 1)`: a slight overshoot
/// as the bubble lands, because the tap moved it.
const obDockCurve = Cubic(0.34, 1.3, 0.64, 1);

/// The app's tab bar: a floating glass pill; a clear glass bubble slides to
/// the selected tab. Every label stays at full strength (HIG); the bubble and
/// weight mark the current tab.
class ObGlassDock extends StatelessWidget {
  const ObGlassDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.accent = Ob.lime,
  });

  /// (label, icon) per tab.
  final List<(String, IconData)> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Lime for players, the star's gold for coaches.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final reduce = MediaQuery.of(context).disableAnimations;
    return ObGlass(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: 58,
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth / n;
            return Stack(children: [
              AnimatedPositioned(
                duration: reduce ? Duration.zero : const Duration(milliseconds: 500),
                curve: obDockCurve,
                left: currentIndex * w,
                top: 0,
                bottom: 0,
                width: w,
                child: const ObGlass(frosted: false, shadow: false, tint: Color(0xD9FFFFFF), child: SizedBox.expand()),
              ),
              Row(children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == currentIndex,
                      label: items[i].$1,
                      excludeSemantics: true,
                      child: _DockTab(
                        label: items[i].$1,
                        icon: items[i].$2,
                        active: i == currentIndex,
                        accent: accent,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                      ),
                    ),
                  ),
              ]),
            ]);
          }),
        ),
      ),
    );
  }
}

class _DockTab extends StatefulWidget {
  const _DockTab({required this.label, required this.icon, required this.active, required this.accent, required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_DockTab> createState() => _DockTabState();
}

class _DockTabState extends State<_DockTab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? widget.accent : Ob.cream;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .95 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(widget.icon, size: 23, color: color, weight: widget.active ? 700 : 400),
          const SizedBox(height: 3),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Ob.body(11, weight: widget.active ? FontWeight.w700 : FontWeight.w500, color: color).copyWith(letterSpacing: .1),
          ),
        ]),
      ),
    );
  }
}
