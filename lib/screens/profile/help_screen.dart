import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

class HelpScreen extends StatefulWidget {
  final String? role;
  const HelpScreen({super.key, this.role});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _open = 0;

  static const _player = [
    ('How is my handicap index worked out?',
        'It\'s the average of your best 8 score differentials from your last 20 rounds, under the World Handicap System. Each differential compares your score with the course rating and slope of the tees you played.'),
    ('Why does my round need a marker?',
        'For a round to count towards your index, another golfer has to sign your card. Pick them in round setup and they sign when you finish.'),
    ('Can I scan a paper card?', 'Yes. From Start a round, choose Scan a scorecard. Daniel reads every hole and flags any he isn\'t sure of.'),
    ('How do I add friends?', 'Open Friends from your profile. Search by name, scan their QR code, or share yours from the QR button on your profile.'),
    ('How do I book a caddie or coach?', 'Open the Caddie tab, pick someone, and message, call or WhatsApp them. Coaches also list sessions you can book in the app.'),
  ];

  static const _coach = [
    ('How do players find me?', 'Keep "Taking bookings" on from your Home and fill in your bio and specialities. Complete profiles show up higher.'),
    ('How do payments work?', 'Players pay you directly by M-Pesa, cash or bank. Record each payment on the Payments tab so you both know who owes what.'),
    ('Can I send drills to players?', 'Yes. Build a drill on the Drills tab, then open a student and tap Assign drill.'),
  ];

  static const _caddie = [
    ('How do I show I\'m available?', 'Your availability decides whether you appear in the Caddie tab. Switch it on when you\'re ready for bookings.'),
    ('How do I get more reviews?', 'Players are asked to rate you after a round. Good yardages and green reads earn five stars.'),
    ('Who sets my fee?', 'Caddie fees are set by your home club. Change your home club in Settings if you move.'),
  ];

  Future<void> _chat() async {
    final url = Uri.parse('https://wa.me/254115706542');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final faqs = switch (widget.role) { 'coach' => _coach, 'caddie' => _caddie, _ => _player };

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
            children: [
              ObTopBar('Help', onBack: () => context.pop()),
              const SizedBox(height: 16),
              ObGuideRow(botAsset: ObBot.clover.idle, botLabel: 'Daniel the clover', text: 'Stuck? Most answers are below. If not, a real person is a tap away.', size: 84, fontSize: 17).rise(),
              const SizedBox(height: 22),
              const ObEyebrow('Common questions'),
              const SizedBox(height: 10),
              for (final (i, f) in faqs.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: _open == i ? Ob.roleFill : Ob.cardFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _open == i ? Ob.lime.withValues(alpha: .25) : Ob.creamA(.06)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Semantics(
                        button: true,
                        expanded: _open == i,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _open = _open == i ? -1 : i),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Expanded(child: Text(f.$1, style: Ob.body(15, weight: FontWeight.w700))),
                              AnimatedRotation(
                                turns: _open == i ? .125 : 0,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.elasticOut,
                                child: Icon(LucideIcons.plus, size: 18, color: _open == i ? Ob.lime : Ob.creamA(.5)),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: _open == i
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(f.$2, style: Ob.body(14, height: 1.55, color: Ob.creamA(.75))),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Ob.roleFill, borderRadius: BorderRadius.circular(26), border: Border.all(color: Ob.lime.withValues(alpha: .2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Still need a hand?', style: Ob.display(22)),
                  const SizedBox(height: 6),
                  Text('Our team answers every day, usually within the hour.', style: Ob.body(14, height: 1.5, color: Ob.creamA(.7))),
                  const SizedBox(height: 14),
                  ObButton(
                    onPressed: _chat,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.messageCircle, size: 18, color: Ob.ink),
                      const SizedBox(width: 8),
                      Text('Chat with us', style: Ob.label(15, weight: FontWeight.w800)),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
