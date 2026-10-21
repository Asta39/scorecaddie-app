import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ob_glass.dart';

/// Design tokens for the onboarding flow (splash → intro → sign-in → setup).
///
/// Apple light, as in the "ScoreCaddie Utility Redesign" mockups: grouped grey
/// page, white cells, the platform font with even digits, and brand green
/// reserved for actions and "you".
class Ob {
  Ob._();

  // ── colour ────────────────────────────────────────────────────────────
  // Apple light (iOS grouped style): a light grey page, white cells, black
  // labels with grey secondary text. The brand green replaces the old lime
  // so it reads as text on white (5:1) and carries white text as a fill.
  static const bg = Color(0xFFF2F2F7); // systemGroupedBackground
  static const cream = Color(0xFF000000); // label
  static const lime = Color(0xFF3F7D0F); // brand green, AA on white
  static const ink = Color(0xFFFFFFFF); // text on brand green
  static const warn = Color(0xFFC2410C); // orange that reads on white
  static const dotGrey = Color(0xFFC7C7CC);
  static const roleFill = Color(0xFFFFFFFF); // hero cards are plain white
  static const cardFill = Color(0xFFFFFFFF); // secondarySystemGroupedBackground
  static const field = Color(0x0F767680); // tertiarySystemFill
  static const fieldBorder = Color(0x1F3C3C43);
  static const hairline = Color(0x2E3C3C43); // separator

  /// Secondary text and tints: iOS label colours are black at reduced opacity.
  static Color creamA(double a) => const Color(0xFF3C3C43).withValues(alpha: (a * 1.05).clamp(0, 1));

  /// The platform UI font: Roboto on Android; iOS has no Roboto, so it falls
  /// back to the system font (SF Pro). Named so tests can load a stand-in.
  static const sys = 'Roboto';

  /// Even-width digits so scores and handicaps line up in columns.
  static const _numbers = [FontFeature.tabularFigures()];

  // ── type ──────────────────────────────────────────────────────────────
  /// Headings and numbers, in the platform font (SF Pro on iPhone, Roboto
  /// on Android): bold, slightly tightened as it grows, with even digits.
  static TextStyle display(double size, {Color color = cream, double? height}) => TextStyle(
        fontFamily: sys,
        fontSize: size,
        height: height,
        color: color,
        fontWeight: FontWeight.w700,
        fontFeatures: _numbers,
        letterSpacing: size >= 20 ? -0.02 * size : 0,
      );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color color = cream, double? height, double? letterSpacing}) => TextStyle(
        fontFamily: sys,
        fontSize: size,
        height: height,
        color: color,
        // The old Manrope weights run heavy; the system font reads a step lighter.
        fontWeight: weight == FontWeight.w800 ? FontWeight.w700 : (weight == FontWeight.w500 ? FontWeight.w400 : weight),
        fontFeatures: _numbers,
        letterSpacing: letterSpacing ?? (size <= 12 ? 0.1 : -0.01 * size / 4),
      );

  /// A button label: no colour, so [ObButton] sets white on green, black on glass.
  static TextStyle label(double size, {FontWeight weight = FontWeight.w700}) => TextStyle(
        fontFamily: sys,
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  /// Root text style for these screens.
  static const textBase = TextStyle(
    fontFamily: sys,
    fontSize: 15,
    color: cream,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  /// Section headers: grey capitals, as in iOS grouped lists.
  static TextStyle eyebrow() => body(13, weight: FontWeight.w400, color: creamA(.6), letterSpacing: 0.2);

  static const overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: bg,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}

/// The prototype's easing curves, by name.
class ObCurves {
  ObCurves._();
  static const rise = Cubic(.2, .8, .2, 1); // content entering
  static const bubbleGrow = Cubic(.3, 1.45, .5, 1);
  static const drop1 = Cubic(.35, 1.3, .5, 1);
  static const segFill = Cubic(.34, 1.56, .64, 1);
  static const roleBlob = Cubic(.4, 1.3, .5, 1);
  static const roleDrop = Cubic(.4, 1.2, .4, 1);
  static const split = Cubic(.16, 1, .3, 1);
  static const swapOut = Cubic(.5, 0, .75, 0);
  static const swapBlob = Cubic(.45, 0, .2, 1);
  static const swapDrop = Cubic(.3, .6, .3, 1);
  static const swapIn = Cubic(.34, 1.56, .64, 1);
  static const digit = Cubic(.22, .8, .24, 1);
  static const springOut = Cubic(.34, 1.45, .5, 1); // splash mark, cast
  static const letter = Cubic(.34, 1.5, .5, 1);
  static const gravityIn = Cubic(.55, 0, 1, .45); // falling
  static const gravityOut = Cubic(0, .55, .45, 1); // rising
  static const roll = Cubic(.45, 0, .55, 1);
  static const ballRoll = Cubic(.3, .7, .3, 1);
}

/// A damped spring integrated by hand, exactly as the prototype does:
/// a = w²(target − x) − 2·z·w·v, four semi-implicit Euler substeps per frame.
/// z = 1 is critically damped (no overshoot); z < 1 wobbles.
class ObSpring {
  ObSpring(double value, {required this.w, required this.z})
      : x = value,
        target = value;

  double x;
  double v = 0;
  double target;
  double w;
  double z;

  bool get settled => (target - x).abs() < 0.02 && v.abs() < 0.5;

  /// Advances by [dt] seconds; returns true while still moving.
  bool step(double dt) {
    const steps = 4;
    final h = dt / steps;
    for (var i = 0; i < steps; i++) {
      final a = w * w * (target - x) - 2 * z * w * v;
      v += a * h;
      x += v * h;
    }
    if (settled) {
      x = target;
      v = 0;
      return false;
    }
    return true;
  }
}

enum ObButtonTone { lime, dark, light }

/// The tactile button finish from the reference: a vertical gradient in the
/// button's own colour, a slightly darker 1px edge, a highlight along the top
/// and a dark drop shadow (never a coloured glow). Pressing flips the
/// gradient and sinks the shadow.
class ObButton extends StatefulWidget {
  const ObButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tone = ObButtonTone.lime,
    this.height = 56,
    this.radius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 26),
    this.selected = false,
    this.width,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ObButtonTone tone;
  final double height;
  final double radius;
  final EdgeInsets padding;

  /// Dark buttons only: a lime edge marks the "on" state.
  final bool selected;
  final double? width;
  final String? semanticLabel;

  @override
  State<ObButton> createState() => _ObButtonState();
}

class _ObButtonState extends State<ObButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final r = BorderRadius.circular(widget.radius);

    late final List<Color> grad; // bottom → top
    late final Color edge;
    late final Color highlight;
    late final Color textColor;
    switch (widget.tone) {
      case ObButtonTone.lime:
        grad = const [Color(0xFF36700B), Color(0xFF4A8A14)];
        edge = const Color(0xFF326A0A);
        highlight = Colors.white.withValues(alpha: 0.25);
        textColor = Ob.ink;
      case ObButtonTone.dark:
        grad = const [Color(0xFFFFFFFF), Color(0xFFF2F2F7)];
        edge = widget.selected ? Ob.lime : const Color(0xFF2F4A39);
        highlight = Colors.white.withValues(alpha: 0.08);
        textColor = widget.selected ? Ob.lime : Ob.cream;
      case ObButtonTone.light:
        grad = const [Color(0xFFF7F9F5), Color(0xFFD7DDD2)];
        edge = const Color(0xFFC3CABD);
        highlight = Colors.white.withValues(alpha: 0.9);
        textColor = Ob.ink;
    }

    final Decoration decoration;
    if (!enabled && widget.tone == ObButtonTone.lime) {
      // Disabled primary actions stay flat.
      decoration = BoxDecoration(
        color: const Color(0x14767680),
        border: Border.all(color: const Color(0x0A000000)),
        borderRadius: r,
      );
    } else {
      final colors = _down ? grad : grad.reversed.toList();
      decoration = BoxDecoration(
        borderRadius: r,
        border: Border.all(color: edge, width: widget.tone == ObButtonTone.dark && widget.selected ? 1.5 : 1),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: Offset(0, _down ? 3 : 8),
            blurRadius: _down ? 8 : 18,
            spreadRadius: _down ? -4 : -8,
          ),
        ],
      );
    }

    final fg = !enabled && widget.tone == ObButtonTone.lime ? Ob.creamA(0.4) : textColor;

    Widget body = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: widget.height,
      width: widget.width,
      padding: widget.padding,
      decoration: decoration,
      foregroundDecoration: (!enabled && widget.tone == ObButtonTone.lime) || _down
          ? null
          : _TopHighlight(radius: widget.radius, color: highlight, bottomShade: widget.tone == ObButtonTone.lime),
      // Hugs its label unless given a width or stretched by its parent, as
      // the prototype's pills do.
      child: Center(
        widthFactor: 1,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: IconTheme.merge(data: IconThemeData(color: fg), child: widget.child),
        ),
      ),
    );

    if (widget.tone == ObButtonTone.dark) {
      // Secondary and icon buttons are Opaline liquid glass (see ob_glass.dart);
      // "on" is marked with a solid lime edge, never a glow.
      body = ObGlass(
        radius: widget.radius,
        shadow: !_down,
        tint: _down ? const Color(0xE6E5E5EA) : null,
        child: Container(
          height: widget.height,
          width: widget.width,
          padding: widget.padding,
          foregroundDecoration: widget.selected ? BoxDecoration(borderRadius: r, border: Border.all(color: Ob.lime, width: 1.5)) : null,
          child: Center(
            widthFactor: 1,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg),
              child: IconTheme.merge(data: IconThemeData(color: fg), child: widget.child),
            ),
          ),
        ),
      );
    }

    if (!enabled && widget.tone != ObButtonTone.lime) {
      body = Opacity(opacity: 0.55, child: body);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: body,
        ),
      ),
    );
  }
}

/// Inset 1px top highlight (and, for lime, a faint 2px bottom shade), drawn
/// over the button like the reference's inset box-shadows.
class _TopHighlight extends Decoration {
  const _TopHighlight({required this.radius, required this.color, required this.bottomShade});
  final double radius;
  final Color color;
  final bool bottomShade;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _TopHighlightPainter(this);
}

class _TopHighlightPainter extends BoxPainter {
  _TopHighlightPainter(this.d);
  final _TopHighlight d;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final rect = offset & size;
    final r = RRect.fromRectAndRadius(rect.deflate(1), Radius.circular((d.radius - 1).clamp(0, size.height / 2)));
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top + 1, rect.width, 1), Paint()..color = d.color);
    if (d.bottomShade) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.bottom - 3, rect.width, 2),
        Paint()..color = const Color(0x1A000000),
      );
    }
    canvas.restore();
  }
}

/// A round dark icon button (back, − and +).
class ObIconButton extends StatelessWidget {
  const ObIconButton({super.key, required this.icon, required this.onPressed, required this.label, this.size = 44});
  final IconData icon;
  final VoidCallback? onPressed;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => ObButton(
        onPressed: onPressed,
        tone: ObButtonTone.dark,
        height: size,
        width: size,
        padding: EdgeInsets.zero,
        semanticLabel: label,
        child: Icon(icon, size: 20),
      );
}
