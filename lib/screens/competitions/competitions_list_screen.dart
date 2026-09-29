import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/competition.dart';
import '../../providers/auth_providers.dart';
import '../../providers/competition_providers.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_widgets.dart';

/// The home club's competitions: live, open for entry, coming up, finished.
class CompetitionsListScreen extends ConsumerWidget {
  const CompetitionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final clubIdAsync = ref.watch(playerHomeClubIdProvider);
    final clubId = clubIdAsync.valueOrNull;
    final compsAsync = clubId == null ? null : ref.watch(competitionsForClubProvider(clubId));
    final comps = compsAsync?.valueOrNull ?? const <Competition>[];

    final live = comps.where((c) => c.status == 'in_progress').toList();
    final open = comps.where((c) => c.status == 'open_for_entry').toList();
    final soon = comps.where((c) => c.status == 'upcoming').toList();
    final past = comps.where((c) => const {'completed', 'closed', 'cancelled'}.contains(c.status)).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    for (final l in [live, open, soon]) {
      l.sort((a, b) => a.startDate.compareTo(b.startDate));
    }

    final loading = clubIdAsync.isLoading || (compsAsync?.isLoading ?? false) && comps.isEmpty;
    final error = clubIdAsync.hasError || (compsAsync?.hasError ?? false) && comps.isEmpty;

    Widget section(Widget eyebrow, List<Competition> list) => Padding(
          padding: const EdgeInsets.only(top: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            eyebrow,
            const SizedBox(height: 10),
            for (final (i, c) in list.indexed) Padding(padding: const EdgeInsets.only(bottom: 10), child: CompetitionRow(competition: c).rise(i)),
          ]),
        );

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Ob.ink,
            backgroundColor: Ob.lime,
            onRefresh: () async {
              if (clubId != null) ref.invalidate(competitionsForClubProvider(clubId));
            },
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
              children: [
                ObTopBar('Competitions', onBack: context.canPop() ? () => context.pop() : null),
                if (profile?.homeCourseName != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    ObCrest(profile!.homeCourseName!, size: 40),
                    const SizedBox(width: 12),
                    Expanded(child: Text(profile.homeCourseName!, style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.72)))),
                  ]),
                ],
                if (loading)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
                else if (error)
                  _Note(bot: ObBot.ball.sleep, text: 'Couldn\'t load competitions. Pull down to try again.')
                else if (clubId == null)
                  _Note(bot: ObBot.ball.idle, text: 'Join a club to see its competitions. Pick your home club under Profile, Clubs.')
                else if (comps.isEmpty)
                  _Note(bot: ObBot.ball.sleep, text: 'No competitions yet. When your club posts one, it shows up here.')
                else ...[
                  if (live.isNotEmpty)
                    section(
                      Row(children: [
                        const _Ping(),
                        const SizedBox(width: 8),
                        Text('LIVE NOW', style: Ob.eyebrow()),
                      ]),
                      live,
                    ),
                  if (open.isNotEmpty) section(const ObEyebrow('Open for entry'), open),
                  if (soon.isNotEmpty) section(const ObEyebrow('Coming up'), soon),
                  if (past.isNotEmpty) section(const ObEyebrow('Finished'), past),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.bot, required this.text});
  final String bot;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: ObCard(padding: const EdgeInsets.all(18), child: ObGuideRow(botAsset: bot, botLabel: 'Your golf-ball avatar', text: text, size: 72, fontSize: 16)),
      );
}

/// A lime dot that fades in and out: something is happening now. No halo:
/// the design keeps glow off cards and buttons.
class _Ping extends StatefulWidget {
  const _Ping();

  @override
  State<_Ping> createState() => _PingState();
}

class _PingState extends State<_Ping> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(width: 8, height: 8, decoration: const BoxDecoration(color: Ob.lime, shape: BoxShape.circle));
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: .35 + .65 * (1 - (2 * _c.value - 1).abs()),
        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Ob.lime, shape: BoxShape.circle)),
      ),
    );
  }
}

/// One competition: a date tile, the name and what's next, and a tag.
class CompetitionRow extends ConsumerWidget {
  const CompetitionRow({super.key, required this.competition});
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = competition;
    final entered = ref.watch(myEntryProvider(c.id)).valueOrNull != null;
    final live = c.status == 'in_progress';

    final (String tag, Color tagColor) = switch (c.status) {
      'in_progress' => ('Live', Ob.lime),
      'open_for_entry' => entered ? ('Entered', Ob.lime) : ('Enter', Ob.cream),
      'upcoming' => entered ? ('Entered', Ob.lime) : ('Soon', Ob.creamA(.5)),
      'cancelled' => ('Cancelled', Ob.warn),
      _ => ('Results', Ob.creamA(.5)),
    };

    final meta = [
      c.formatLabel,
      if (c.status == 'open_for_entry' && c.entryDeadline != null) 'closes ${DateFormat('EEE d').format(c.entryDeadline!)}',
      if (c.status == 'upcoming') DateFormat('EEE d MMM').format(c.startDate),
      if (c.entryCount != null && c.entryCount! > 0) '${c.entryCount} in',
      if (c.entryFee > 0 && c.status == 'open_for_entry') '${c.currency} ${NumberFormat.decimalPattern().format(c.entryFee)}',
    ].join(' · ');

    return Semantics(
      button: true,
      label: '${c.name}, $tag',
      child: GestureDetector(
        onTap: () => context.push('/competitions/${c.id}'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(24), border: Border.all(color: Ob.creamA(.06))),
          child: Row(children: [
            Container(
              width: 54,
              height: 60,
              decoration: BoxDecoration(color: live ? Ob.lime : Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(DateFormat('MMM').format(c.startDate).toUpperCase(), style: Ob.body(11, weight: FontWeight.w800, color: live ? Ob.ink : Ob.lime)),
                Text('${c.startDate.day}', style: Ob.display(25, height: 1, color: live ? Ob.ink : Ob.lime)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(12, color: Ob.creamA(.58))),
              ]),
            ),
            const SizedBox(width: 8),
            Text(tag, style: Ob.body(12, weight: FontWeight.w800, color: tagColor)),
          ]),
        ),
      ),
    );
  }
}
