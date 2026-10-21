import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../onboarding/ob_app.dart';
import '../onboarding/ob_style.dart';

/// The Play tab: every way to get out and play, in one grouped list.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(Color c, IconData icon, String title, String sub, VoidCallback onTap) => Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7)),
                    child: Icon(icon, size: 17, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: Ob.body(17, weight: FontWeight.w500)),
                      Text(sub, style: Ob.body(13, color: Ob.creamA(.6))),
                    ]),
                  ),
                  Icon(LucideIcons.chevronRight, size: 18, color: Ob.creamA(.3)),
                ]),
              ),
            ),
          ),
        );

    Widget group(List<Widget> rows) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Ob.cardFill,
            child: Column(children: [
              for (final (i, r) in rows.indexed) ...[
                if (i > 0) Padding(padding: const EdgeInsets.only(left: 60), child: Container(height: .5, color: Ob.hairline)),
                r,
              ],
            ]),
          ),
        );

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            children: [
              const ObTabHeader('Play'),
              const SizedBox(height: 4),
              Text('What are you up to?', style: Ob.body(15, color: Ob.creamA(.6))),
              const SizedBox(height: 18),
              group([
                row(const Color(0xFF34C759), LucideIcons.flag, 'Start a round', 'Pick a course and tees', () => context.push('/select-course')),
                row(const Color(0xFF0A84FF), LucideIcons.calendarPlus, 'Book a tee time', 'At your home club', () => context.push('/book-tee-time')),
                row(const Color(0xFF5E5CE6), LucideIcons.calendarDays, 'My tee times', 'Coming up and past', () => context.push('/tee-times')),
              ]),
              const SizedBox(height: 22),
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('PRACTICE', style: Ob.eyebrow())),
              group([
                row(const Color(0xFFFF9F0A), LucideIcons.target, 'Range session', 'Log balls and accuracy by club', () => context.push('/range')),
                row(const Color(0xFF30B0C7), LucideIcons.barChart3, 'Practice stats', 'How your clubs are trending', () => context.push('/practice/analytics')),
              ]),
              const SizedBox(height: 22),
              Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text('ROUNDS', style: Ob.eyebrow())),
              group([
                row(const Color(0xFF8E8E93), LucideIcons.history, 'Round history', 'Every round you\'ve played', () => context.push('/rounds-history')),
                row(const Color(0xFFFF375F), LucideIcons.scanLine, 'Scan a paper card', 'Daniel reads it for you', () => context.push('/scanner/camera')),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
