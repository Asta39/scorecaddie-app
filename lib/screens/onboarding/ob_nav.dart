import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'ob_goo.dart';
import 'ob_style.dart';

/// The app's tab bar: a dark textured pill where the selected tab sits on a
/// liquid blob. Switching tabs, the blob springs across and a droplet trails
/// it on a softer spring, so the two stretch and snap together (goo).
class ObGooNavBar extends StatefulWidget {
  const ObGooNavBar({
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
  State<ObGooNavBar> createState() => _ObGooNavBarState();
}

class _ObGooNavBarState extends State<ObGooNavBar> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ObSpring _blob = ObSpring(widget.currentIndex.toDouble(), w: 18, z: 0.62);
  late final ObSpring _drop = ObSpring(widget.currentIndex.toDouble(), w: 9, z: 0.8);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didUpdateWidget(ObGooNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _blob.target = widget.currentIndex.toDouble();
      _drop.target = widget.currentIndex.toDouble();
      if (MediaQuery.of(context).disableAnimations) {
        _blob.x = _blob.target;
        _drop.x = _drop.target;
        setState(() {});
      } else if (!_ticker.isActive) {
        _last = Duration.zero;
        _ticker.start();
      }
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    final a = _blob.step(dt), b = _drop.step(dt);
    setState(() {});
    if (!a && !b) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF0B160F), Color(0xFF1F3326)]),
        border: Border.all(color: const Color(0xFF2F4A39)),
        boxShadow: const [BoxShadow(color: Color(0xCC000000), blurRadius: 18, offset: Offset(0, 8), spreadRadius: -8)],
      ),
      child: LayoutBuilder(builder: (context, box) {
        final step = box.maxWidth / n;
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _NavBlobPainter(_blob.x, _drop.x, step, widget.accent))),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == widget.currentIndex,
                      label: widget.items[i].$1,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onTap(i);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.items[i].$2, size: 21, color: i == widget.currentIndex ? Ob.ink : Ob.creamA(.6)),
                            const SizedBox(height: 7),
                            Text(widget.items[i].$1,
                                maxLines: 1,
                                style: Ob.label(10).copyWith(color: i == widget.currentIndex ? widget.accent : Ob.creamA(.55))),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _NavBlobPainter extends GooPainter {
  _NavBlobPainter(this.blob, this.drop, this.step, this.color) : super(sigma: 6);
  final double blob, drop, step;
  final Color color;

  @override
  EdgeInsets get overflow => const EdgeInsets.all(20);

  @override
  void paintShapes(Canvas c, Size s) {
    final p = Paint()..color = color;
    // Sits behind the icon: 44×32 pill centred in the tab, 21pt from the top.
    final cx = blob * step + step / 2;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, 21), width: 44, height: 32), const Radius.circular(16)), p);
    c.drawCircle(Offset(drop * step + step / 2, 21), 12, p);
  }

  @override
  bool shouldRepaint(covariant _NavBlobPainter old) => old.blob != blob || old.drop != drop || old.step != step || old.color != color;
}
