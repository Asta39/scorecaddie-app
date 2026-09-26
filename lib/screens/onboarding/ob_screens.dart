import 'package:flutter/material.dart';

import 'ob_style.dart';
import 'ob_widgets.dart';

/// A home-club card for the club step's two-column grid.
class ObClubTile extends StatelessWidget {
  const ObClubTile({super.key, required this.name, required this.town, required this.selected, required this.onTap, this.logoUrl, this.highlightTown = false});

  final String name, town;
  final String? logoUrl;
  final bool selected;

  /// Lime town line, used for "On your club's roster".
  final bool highlightTown;
  final VoidCallback onTap;

  static TextStyle get _nameStyle => Ob.body(13, weight: FontWeight.w700, height: 1.25);
  static TextStyle get _townStyle => Ob.body(11);

  /// Row height for the grid. The prototype's cards are at least 132pt and
  /// grow to fit; every card here is sized for a two-line name so rows line
  /// up and nothing clips (larger text sizes included).
  static double extent(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    double lineHeight(TextStyle style, int lines) => (TextPainter(
      text: TextSpan(text: List.filled(lines, 'Ag').join('\n'), style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout()).height;
    final h = 4 + 28 + 56 + 8 + lineHeight(_nameStyle, 2) + 8 + lineHeight(_townStyle, 1);
    return h.ceilToDouble().clamp(132.0, double.infinity);
  }

  /// Club crests already bundled with the app, by a word in the club's name.
  static const _crests = {
    'muthaiga': 'assets/images/muthaiga golf club.jpeg',
    'karen': 'assets/images/Karen country club.jpeg',
    'royal': 'assets/images/royal golf club.jpeg',
    'limuru': 'assets/images/Limuru country club.jpeg',
    'sigona': 'assets/images/sigona golf club.jpeg',
    'windsor': 'assets/images/Windsor.jpeg',
    'vipingo': 'assets/images/vipingo ridge.jpeg',
    'nyali': 'assets/images/nyali golf.jpeg',
    'eldoret': 'assets/images/Eldoret club.jpeg',
    'nyanza': 'assets/images/Nyanza club.jpeg',
    'thika': 'assets/images/Thika greens.jpeg',
    'railway': 'assets/images/kenya railways golf club.jpeg',
    'machakos': 'assets/images/machakos golf club.jpeg',
    'mombasa': 'assets/images/mombasa golf club.jpeg',
    'nandi': 'assets/images/nandi bears.jpeg',
    'ruiru': 'assets/images/ruiru sportd club.jpeg',
    'vet lab': 'assets/images/vet lab.jpeg',
  };

  Widget _initial() => Center(
    child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: Ob.display(26, color: Ob.ink)),
  );

  Widget _crest() {
    // The club's own logo first, then a bundled crest, then its initial.
    final asset = _crests.entries.where((e) => name.toLowerCase().contains(e.key)).map((e) => e.value).firstOrNull;
    final Widget img;
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      img = Image.network(logoUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => _initial());
    } else if (asset != null) {
      img = Image.asset(asset, fit: BoxFit.contain);
    } else {
      img = _initial();
    }
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: town.isEmpty ? name : '$name, $town',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: Ob.field,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? Ob.lime : Ob.hairline, width: 2),
          ),
          child: Column(
            children: [
              _crest(),
              const SizedBox(height: 8),
              Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: _nameStyle),
              const SizedBox(height: 8),
              Text(
                town,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _townStyle.copyWith(color: highlightTown ? Ob.lime : Ob.creamA(.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last screen: the user's avatar celebrates, a ball drops into the cup,
/// and one liquid mass pinches into two summary cards.
class ObWelcome extends StatelessWidget {
  const ObWelcome({
    super.key,
    required this.bot,
    required this.username,
    required this.leftLabel,
    required this.leftValue,
    required this.clubName,
    required this.onTeeOff,
    this.saving = false,
  });

  final ObBot bot;
  final String username, leftLabel, leftValue, clubName;
  final VoidCallback onTeeOff;
  final bool saving;

  // Content is centred in the 88pt card: the prototype's 16pt vertical
  // padding holds for one-line values, and a two-line club name still fits.
  Widget _card(String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Ob.body(12, weight: FontWeight.w600, color: Ob.creamA(.6)),
        ),
        const SizedBox(height: 6),
        value,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 44),
          BotImage(bot.happy, size: 240, semanticLabel: '${bot.label}, hopping with excitement'),
          // Pulled up under the avatar (margin-top: -18 in the prototype).
          Transform.translate(offset: const Offset(0, -18), child: const ObHoleOut()),
          Text('YOU\u2019RE ALL SET', style: Ob.eyebrow()).rise(),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text('Welcome to the clubhouse, @$username', textAlign: TextAlign.center, style: Ob.display(40, height: 1.05)),
          ).rise(1),
          const SizedBox(height: 24),
          ObSplitCards(
            left: _card(leftLabel, Text(leftValue, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(30, height: 1))),
            right: _card('Home club', Text(clubName, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.display(19, height: 1.1))),
          ),
          const Spacer(),
          ObButton(
            width: double.infinity,
            onPressed: saving ? null : onTeeOff,
            child: saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Ob.ink))
                : Text('Tee off', style: Ob.label(16, weight: FontWeight.w800)),
          ).rise(3),
        ],
      ),
    );
  }
}

/// The welcome's golf ball: rolls in from the left and drops into the hole.
class ObHoleOut extends StatefulWidget {
  const ObHoleOut({super.key});

  @override
  State<ObHoleOut> createState() => _ObHoleOutState();
}

class _ObHoleOutState extends State<ObHoleOut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 24,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // 1.8s from .4s: roll in (0–85%, spinning), fade in over the first
          // 15%, then drop 10px and shrink into the hole (85–100%).
          final p = ((_c.value * 2.2 - .4) / 1.8).clamp(0.0, 1.0);
          final roll = ObCurves.ballRoll.transform((p / .85).clamp(0.0, 1.0));
          final sink = p > .85 ? ObCurves.ballRoll.transform(((p - .85) / .15).clamp(0.0, 1.0)) : 0.0;
          final opacity = p < .15 ? ObCurves.ballRoll.transform((p / .15).clamp(0.0, 1.0)) : (p > .85 ? 1 - sink : 1.0);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 34,
                height: 10,
                decoration: const BoxDecoration(color: Colors.black, borderRadius: BorderRadius.all(Radius.elliptical(17, 5))),
              ),
              Positioned(
                bottom: 6 - 10 * sink,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(-150 * (1 - roll), 0),
                    child: Transform.rotate(
                      angle: -2 * 3.14159265 * (1 - roll),
                      child: Transform.scale(
                        scale: 1 - .4 * sink,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment(-.3, -.4),
                              colors: [Colors.white, Color(0xFFE6EBE3), Color(0xFFC3CBBF)],
                              stops: [0, .55, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
