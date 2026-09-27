import 'package:flutter/material.dart';

import '../../core/utils/course_logo_helper.dart';
import 'ob_goo.dart';
import 'ob_style.dart';
import 'ob_widgets.dart';

/// Building blocks for the in-app screens, matching the design canvas.

/// Standard card: #142519, radius 24, a faint hairline.
class ObCard extends StatelessWidget {
  const ObCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 24, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(radius), border: Border.all(color: const Color(0x0FFFFFFF))),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

/// The greener hero card with a faint lime edge, for the screen's key number.
class ObHeroCard extends StatelessWidget {
  const ObHeroCard({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18), this.onTap, this.edge});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? edge;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Ob.roleFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: edge ?? Ob.lime.withValues(alpha: .18), width: edge == null ? 1 : 2),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: card);
  }
}

/// Small lime capitals heading a section, with an optional action on the right.
class ObEyebrow extends StatelessWidget {
  const ObEyebrow(this.text, {super.key, this.action, this.onAction, this.trailing});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: Text(text.toUpperCase(), style: Ob.eyebrow()))),
        ?trailing,
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(action!, style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.62)))),
          ),
      ],
    );
  }
}

/// A mascot beside a goo speech bubble: the app's way of talking to you.
class ObGuideRow extends StatelessWidget {
  const ObGuideRow({super.key, required this.botAsset, required this.botLabel, required this.text, this.size = 88, this.fontSize = 19, this.maxBubble = 236});
  final String botAsset, botLabel, text;
  final double size, fontSize, maxBubble;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.translate(offset: const Offset(-8, 0), child: BotImage(botAsset, size: size, semanticLabel: botLabel)),
        const SizedBox(width: 0),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: ObBubble(
              maxWidth: maxBubble,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(text, style: Ob.display(fontSize, color: Ob.ink, height: 1.15)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Screen title row for a tab: display title, optional actions.
class ObTabHeader extends StatelessWidget {
  const ObTabHeader(this.title, {super.key, this.actions = const []});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: Ob.display(34, height: 1.05)))),
          for (final a in actions) Padding(padding: const EdgeInsets.only(left: 10), child: a),
        ],
      ),
    );
  }
}

/// A pill chip: lime-tinted when [on], otherwise a quiet grey.
class ObChip extends StatelessWidget {
  const ObChip(this.text, {super.key, this.on = false, this.color});
  final String text;
  final bool on;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (on ? Ob.lime : Ob.creamA(.78));
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on || color != null ? c.withValues(alpha: .14) : Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Ob.label(12).copyWith(color: c)),
    );
  }
}

/// A club crest on white: the bundled logo if we have one, else an initial.
class ObCrest extends StatelessWidget {
  const ObCrest(this.courseName, {super.key, this.size = 48, this.radius = 14, this.logoUrl});
  final String courseName;
  final double size, radius;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final asset = CourseLogoHelper.getLogoAssetPath(courseName);
    final initial = Center(child: Text(courseName.isEmpty ? '?' : courseName[0].toUpperCase(), style: Ob.display(size * .45, color: Ob.ink)));
    Widget img;
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      img = Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => initial);
    } else if (asset != null) {
      img = Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, _, _) => initial);
    } else {
      img = initial;
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .07),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      child: img,
    );
  }
}

/// A 1px separator inset from the card's edges.
class ObHair extends StatelessWidget {
  const ObHair({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0x0FFFFFFF));
}

/// Label over a value, for split cards and stat tiles.
class ObStat extends StatelessWidget {
  const ObStat(this.label, this.value, {super.key, this.valueSize = 30, this.valueColor, this.valueWidget});
  final String label, value;
  final double valueSize;
  final Color? valueColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Ob.body(12, weight: FontWeight.w600, color: Ob.creamA(.6))),
          const SizedBox(height: 6),
          valueWidget ?? Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(valueSize, height: 1, color: valueColor ?? Ob.cream)),
        ],
      ),
    );
  }
}

/// This week, Monday to Sunday. Days you played are lime and consecutive ones
/// melt into one liquid bar; today is a dashed lime ring.
class ObWeekDots extends StatelessWidget {
  const ObWeekDots({super.key, required this.played, required this.today});

  /// Seven flags, Monday first.
  final List<bool> played;

  /// 0 = Monday.
  final int today;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = [for (var i = 0; i < 7; i++) if (played[i]) labels[i]];
    return Semantics(
      label: days.isEmpty ? 'No rounds yet this week' : 'Played this week on ${days.length} day${days.length == 1 ? '' : 's'}',
      child: SizedBox(
        height: 64,
        child: CustomPaint(painter: _WeekPainter(played, today), child: const SizedBox.expand()),
      ),
    );
  }
}

class _WeekPainter extends GooPainter {
  _WeekPainter(this.played, this.today) : super(sigma: 6);
  final List<bool> played;
  final int today;

  double _cx(Size s, int i) => 20 + i * ((s.width - 40) / 6);

  @override
  EdgeInsets get overflow => const EdgeInsets.all(12);

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = Ob.lime;
    for (var i = 0; i < 7; i++) {
      if (played[i]) c.drawCircle(Offset(_cx(s, i), 20), 19, p);
    }
  }

  @override
  void paintCrisp(Canvas c, Size s) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (var i = 0; i < 7; i++) {
      final cx = _cx(s, i);
      if (played[i]) {
        final tick = Path()..moveTo(cx - 6, 20.5)..lineTo(cx - 2, 24.5)..lineTo(cx + 6, 15.5);
        c.drawPath(tick, Paint()..color = Ob.ink..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
      } else if (i == today) {
        final ring = Paint()..color = Ob.lime..style = PaintingStyle.stroke..strokeWidth = 2;
        const dashes = 12;
        for (var d = 0; d < dashes; d++) {
          final a0 = d * 2 * 3.14159265 / dashes;
          c.drawArc(Rect.fromCircle(center: Offset(cx, 20), radius: 18), a0, 3.14159265 / dashes, false, ring);
        }
      } else {
        c.drawCircle(Offset(cx, 20), 18, Paint()..color = const Color(0x0AFFFFFF));
        c.drawCircle(Offset(cx, 20), 18, Paint()..color = const Color(0x1AFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: Ob.label(11).copyWith(color: i == today ? Ob.lime : Ob.creamA(.5))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(cx - tp.width / 2, 50));
    }
  }

  @override
  bool shouldRepaint(covariant _WeekPainter old) => old.today != today || old.played.join() != played.join();
}

/// A pill switch whose lime selection flows between options like liquid: the
/// pill springs across and a droplet trails it, pinching off as it settles.
class ObGooSegmented<T> extends StatefulWidget {
  const ObGooSegmented({super.key, required this.options, required this.selected, required this.onChanged, this.height = 44, this.fontSize = 14, this.accent = Ob.lime});
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height, fontSize;
  final Color accent;

  @override
  State<ObGooSegmented<T>> createState() => _ObGooSegmentedState<T>();
}

class _ObGooSegmentedState<T> extends State<ObGooSegmented<T>> with SingleTickerProviderStateMixin {
  late final ObSpring _pill = ObSpring(_index.toDouble(), w: 18, z: .62);
  late final ObSpring _drop = ObSpring(_index.toDouble(), w: 9, z: .8);
  late final AnimationController _loop = AnimationController.unbounded(vsync: this)..addListener(_tick);
  Duration _last = Duration.zero;

  int get _index => widget.options.indexWhere((o) => o.$1 == widget.selected).clamp(0, widget.options.length - 1);

  @override
  void didUpdateWidget(ObGooSegmented<T> old) {
    super.didUpdateWidget(old);
    final i = _index.toDouble();
    if (_pill.target != i) {
      _pill.target = i;
      _drop.target = i;
      if (MediaQuery.of(context).disableAnimations) {
        _pill.x = i;
        _drop.x = i;
      } else {
        _last = Duration.zero;
        _loop.repeat(min: 0, max: 1, period: const Duration(seconds: 1));
      }
    }
  }

  void _tick() {
    final now = _loop.lastElapsedDuration ?? Duration.zero;
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final a = _pill.step(dt), b = _drop.step(dt);
    setState(() {});
    if (!a && !b) _loop.stop();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.options.length;
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: LayoutBuilder(builder: (context, box) {
        final step = box.maxWidth / n;
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _SegPainter(_pill.x, _drop.x, step, widget.height - 2, widget.accent))),
          Row(children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == _index,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onChanged(widget.options[i].$1),
                    child: Center(
                      child: Text(widget.options[i].$2,
                          maxLines: 1,
                          style: Ob.label(widget.fontSize, weight: FontWeight.w800).copyWith(color: i == _index ? Ob.ink : Ob.creamA(.72))),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }
}

class _SegPainter extends GooPainter {
  _SegPainter(this.pill, this.drop, this.step, this.h, this.color) : super(sigma: 6);
  final double pill, drop, step, h;
  final Color color;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(16);

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = color;
    final bw = step - 8, bh = h - 8;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pill * step + 4, 4, bw, bh), Radius.circular(bh / 2)), p);
    c.drawCircle(Offset(drop * step + step / 2, h / 2), bh / 2 - 3, p);
  }

  @override
  bool shouldRepaint(covariant _SegPainter old) => old.pill != pill || old.drop != drop || old.step != step || old.color != color;
}
