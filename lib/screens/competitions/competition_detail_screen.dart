import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/competition.dart';
import '../../providers/auth_providers.dart';
import '../../providers/competition_providers.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

enum _Tab { overview, sheet, results }

/// One competition: what it is and how to enter, the start sheet, and the
/// leaderboard.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  final String competitionId;
  const CompetitionDetailScreen({super.key, required this.competitionId});

  @override
  ConsumerState<CompetitionDetailScreen> createState() => _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends ConsumerState<CompetitionDetailScreen> {
  _Tab? _tab;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(competitionDetailProvider(widget.competitionId));
    final c = async.valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin = profile?.role == 'club_admin' || profile?.role == 'super_admin';
    final entry = ref.watch(myEntryProvider(widget.competitionId)).valueOrNull;

    // Open where it matters: results while it's on or done, the start sheet
    // once you're in, otherwise the overview.
    final tab = _tab ??
        (c == null
            ? _Tab.overview
            : (c.isInProgress || c.isCompleted)
                ? _Tab.results
                : _Tab.overview);

    Widget body;
    if (async.isLoading && c == null) {
      body = const Center(child: CupertinoActivityIndicator(color: Ob.lime));
    } else if (c == null) {
      body = Padding(
        padding: const EdgeInsets.all(20),
        child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ObGroup(children: [Padding(padding: const EdgeInsets.all(16), child: Text(async.hasError ? 'Couldn\'t load this competition. Go back and try again.' : 'This competition isn\'t there any more.', style: Ob.body(16, color: Ob.creamA(.6))))]),
          ),
      );
    } else {
      body = switch (tab) {
        _Tab.overview => _Overview(competition: c, entry: entry),
        _Tab.sheet => _StartSheet(competition: c, isAdmin: isAdmin),
        _Tab.results => _Results(competition: c),
      };
    }

    final showEnter = c != null && tab == _Tab.overview && c.isOpenForEntry && entry == null;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ObTopBar(c?.name ?? 'Competition', onBack: () => context.pop()),
            ),
            if (c != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ObGooSegmented<_Tab>(
                  options: const [(_Tab.overview, 'Overview'), (_Tab.sheet, 'Start sheet'), (_Tab.results, 'Results')],
                  selected: tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
              ),
            ],
            Expanded(child: body),
            if (showEnter) _EnterBar(competition: c, profile: profile),
          ]),
        ),
      ),
    );
  }
}

String _money(Competition c) => '${c.currency} ${NumberFormat.decimalPattern().format(c.entryFee)}';

num _allowance(Competition c) => (c.rulesConfig['handicap_allowance_pct'] as num?) ?? 100;

/// Playing handicap from a handicap index at the competition's allowance.
/// The club's start sheet has the exact figure for the tee played.
int _playingHandicap(double index, Competition c) => (index * _allowance(c) / 100).round();

// ─── Overview ────────────────────────────────────────────────────────────────

class _Overview extends ConsumerWidget {
  const _Overview({required this.competition, required this.entry});
  final Competition competition;
  final CompetitionEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = competition;
    final hi = ref.watch(userProfileProvider).valueOrNull?.handicap;
    final rules = c.rulesConfig;
    final (String status, bool _) = switch (c.status) {
      'open_for_entry' => ('Open for entry', true),
      'in_progress' => ('Live now', true),
      'upcoming' => ('Coming up', false),
      'cancelled' => ('Cancelled', false),
      _ => ('Finished', false),
    };
    final lines = <(String, String)>[
      ('Format', c.formatLabel),
      ('Handicap allowance', '${_allowance(c)}%'),
      if (rules['min_handicap'] != null || rules['max_handicap'] != null) ('Handicap range', '${rules['min_handicap'] ?? 0} to ${rules['max_handicap'] ?? 54}'),
      ('Tie-break', '${rules['tiebreaker'] ?? 'Countback'}'),
      if (c.endDate != null && !DateUtils.isSameDay(c.endDate, c.startDate)) ('Ends', DateFormat('EEE d MMM').format(c.endDate!)),
    ];

    final ph = hi == null ? null : _playingHandicap(hi, c);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text(
          [DateFormat('EEE d MMM').format(c.startDate), if (c.startDate.hour != 0 || c.startDate.minute != 0) 'from ${DateFormat.Hm().format(c.startDate)}', c.formatLabel, status].join(' · '),
          style: Ob.body(15, color: Ob.creamA(.6)),
        ),
        const SizedBox(height: 14),
        ObGroup(children: [
          ObRow('Entry', value: c.entryFee > 0 ? _money(c) : 'Free'),
          if (c.entryDeadline != null) ObRow('Entries close', value: DateFormat('EEE d MMM').format(c.entryDeadline!)),
          if (c.entryCount != null) ObRow('Entered', value: '${c.entryCount}'),
          if (entry != null)
            ObRow(
              entry!.isPending ? 'Your entry is waiting for the club' : 'You’re in',
              titleColor: entry!.isPending ? Ob.warn : Ob.lime,
              subtitle: [
                if (entry!.teeColor != null) '${_cap(entry!.teeColor!)} tees',
                if (entry!.flightName != null) '${entry!.flightName} flight',
              ].join(' · ').ifEmpty(null),
              value: entry!.playingHandicap == null ? null : 'HC ${entry!.playingHandicap!.round()}',
            )
          else if (ph != null && (c.isOpenForEntry || c.status == 'upcoming'))
            ObRow('Your playing handicap', subtitle: '${_allowance(c)}% of $hi', value: '$ph'),
        ]),
        if (c.posterUrl != null && c.posterUrl!.isNotEmpty) ...[
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ColoredBox(
                color: Ob.cardFill,
                child: Center(child: Image.network(c.posterUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink())),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        ObGroup(header: 'Rules', children: [for (final l in lines) ObRow(l.$1, value: l.$2)]),
        if (c.description != null && c.description!.trim().isNotEmpty) ...[
          const SizedBox(height: 22),
          ObGroup(header: 'About', children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(c.description!.trim(), style: Ob.body(16, height: 1.45)),
            ),
          ]),
        ],
      ],
    );
  }
}

extension on String {
  String? ifEmpty(String? other) => isEmpty ? other : this;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _EnterBar extends StatelessWidget {
  const _EnterBar({required this.competition, required this.profile});
  final Competition competition;
  final dynamic profile;

  @override
  Widget build(BuildContext context) {
    final c = competition;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: Ob.bg, border: Border(top: BorderSide(color: Ob.creamA(.06)))),
      child: Row(children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.entryFee > 0 ? _money(c) : 'Free', style: Ob.display(24, height: 1)),
          Text(c.entryFee > 0 ? 'Pay by M-Pesa' : 'No entry fee', style: Ob.body(11, color: Ob.creamA(.55))),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: ObButton(
            onPressed: () => showObSheet(context, (_) => CompetitionEntrySheet(competition: c, profile: profile)),
            child: Text('Enter', style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

// ─── Start sheet ─────────────────────────────────────────────────────────────

class _StartSheet extends ConsumerWidget {
  const _StartSheet({required this.competition, required this.isAdmin});
  final Competition competition;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = competition;
    final async = ref.watch(startingSheetProvider(c.id));
    final rows = async.valueOrNull ?? const <StartingSheetRow>[];
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final entry = ref.watch(myEntryProvider(c.id)).valueOrNull;
    final registered = entry != null && entry.isConfirmed;
    final lockHours = (c.rulesConfig['tee_time_lock_hours'] as int?) ?? 24;
    final locked = DateTime.now().isAfter(c.startDate.subtract(Duration(hours: lockHours)));
    final myRow = rows.where((r) => r.playerId != null && r.playerId == me).firstOrNull;

    final groups = <DateTime, List<StartingSheetRow>>{};
    for (final r in rows) {
      final k = DateTime(r.teeTime.year, r.teeTime.month, r.teeTime.day, r.teeTime.hour, r.teeTime.minute);
      groups.putIfAbsent(k, () => []).add(r);
    }
    final keys = groups.keys.toList()..sort();

    return RefreshIndicator(
      color: Ob.ink,
      backgroundColor: Ob.lime,
      onRefresh: () async => ref.invalidate(startingSheetProvider(c.id)),
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          if (async.isLoading && rows.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
          else if (rows.isEmpty)
            Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ObGroup(children: [Padding(padding: const EdgeInsets.all(16), child: Text(async.hasError ? 'Couldn\'t load the start sheet. Pull down to try again.' : 'The start sheet isn\'t out yet. The club publishes it before the day.', style: Ob.body(16, color: Ob.creamA(.6))))]),
          )
          else ...[
            Row(children: [
              Expanded(child: Text(DateFormat('EEE d MMM').format(c.startDate), style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.7)))),
              if (myRow != null) const ObChip('You\'re in', on: true),
            ]),
            const SizedBox(height: 6),
            if (registered)
              Text(
                locked
                    ? 'Tee times are locked now.'
                    : myRow != null
                        ? 'You tee off at ${DateFormat.Hm().format(myRow.teeTime)} from hole ${myRow.teeNumber}. Move to an open slot or swap with someone.'
                        : 'Pick an open slot to claim your tee time.',
                style: Ob.body(13, color: Ob.creamA(.6)),
              ),
            const SizedBox(height: 12),
            for (final k in keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Group(
                  time: k,
                  rows: groups[k]!,
                  me: me,
                  myRow: myRow,
                  canMove: registered && !locked,
                  isAdmin: isAdmin,
                  competition: c,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({required this.time, required this.rows, required this.me, required this.myRow, required this.canMove, required this.isAdmin, required this.competition});
  final DateTime time;
  final List<StartingSheetRow> rows;
  final String? me;
  final StartingSheetRow? myRow;
  final bool canMove;
  final bool isAdmin;
  final Competition competition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = rows.any((r) => r.playerId != null && r.playerId == me);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
      decoration: BoxDecoration(
        color: Ob.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: mine ? Border.all(color: Ob.lime, width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(DateFormat.Hm().format(time), style: Ob.display(24, height: 1)),
          const Spacer(),
          Text('Hole ${rows.first.teeNumber}', style: Ob.body(12, weight: FontWeight.w700, color: Ob.creamA(.55))),
          const SizedBox(width: 4),
        ]),
        const SizedBox(height: 6),
        for (final r in rows) _slot(context, ref, r),
      ]),
    );
  }

  Widget _slot(BuildContext context, WidgetRef ref, StartingSheetRow r) {
    final vacant = r.playerId == null;
    final isMe = !vacant && r.playerId == me;
    final name = r.playerName ?? 'Golfer';
    final ini = name.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(children: [
        if (vacant)
          Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Ob.creamA(.2), width: 2)))
        else
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isMe ? Ob.lime : Ob.roleFill),
            child: Text(ini, style: Ob.body(12, weight: FontWeight.w800, color: isMe ? Ob.ink : Ob.lime)),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: vacant
              ? Text('Open slot', style: Ob.body(14, color: Ob.creamA(.5)))
              : Text(isMe ? '$name (you)' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(14, weight: FontWeight.w700)),
        ),
        if (!vacant) ...[
          if (r.teeColor != null) ...[
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _teeColor(r.teeColor!), shape: BoxShape.circle, border: Border.all(color: Ob.creamA(.3)))),
            const SizedBox(width: 8),
          ],
          Text('HC ${r.playingHandicap?.round() ?? '–'}', style: Ob.body(12, color: Ob.creamA(.55))),
        ],
        if (vacant && canMove)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ObButton(
              tone: ObButtonTone.dark,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onPressed: () => _move(context, ref, r),
              child: Text(myRow == null ? 'Claim' : 'Move here', style: Ob.label(13, weight: FontWeight.w800)),
            ),
          ),
        if (!vacant && !isMe && canMove && myRow != null)
          IconButton(
            tooltip: 'Swap with $name',
            onPressed: () => _swap(context, ref, r),
            icon: Icon(LucideIcons.arrowRightLeft, size: 18, color: Ob.creamA(.6)),
          ),
        if (!vacant && isAdmin && r.entryId != null)
          IconButton(
            tooltip: 'Scan $name\'s card',
            onPressed: () => context.push('/competitions/${r.competitionId}/scan/${r.entryId}'),
            icon: const Icon(LucideIcons.camera, size: 18, color: Ob.lime),
          ),
      ]),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String yes) async {
    final ok = await showObSheet<bool>(
      context,
      (ctx) => ObSheet(
        title: title,
        subtitle: body,
        child: Row(children: [
          Expanded(child: ObButton(tone: ObButtonTone.dark, onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: Ob.label(15, weight: FontWeight.w800)))),
          const SizedBox(width: 10),
          Expanded(child: ObButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes, style: Ob.label(15, weight: FontWeight.w800)))),
        ]),
      ),
    );
    return ok == true;
  }

  Future<void> _move(BuildContext context, WidgetRef ref, StartingSheetRow r) async {
    final at = DateFormat.Hm().format(r.teeTime);
    if (!await _confirm(context, myRow == null ? 'Take the $at slot?' : 'Move to $at?',
        myRow == null ? 'You\'ll tee off at $at from hole ${r.teeNumber}.' : 'Your ${DateFormat.Hm().format(myRow!.teeTime)} slot opens up for someone else.', myRow == null ? 'Claim' : 'Move')) {
      return;
    }
    final ok = await ref.read(competitionActionsProvider.notifier).moveTeeTimeSlot(competitionId: competition.id, oldStartingSheetId: myRow?.id, newStartingSheetId: r.id);
    ref.invalidate(startingSheetProvider(competition.id));
    if (!context.mounted) return;
    ok ? TopNotification.showSuccess(context, 'You tee off at $at') : TopNotification.showError(context, 'Couldn\'t move you. Someone may have taken it; pull down to refresh.');
  }

  Future<void> _swap(BuildContext context, WidgetRef ref, StartingSheetRow r) async {
    final name = (r.playerName ?? 'them').split(' ').first;
    if (!await _confirm(context, 'Swap with $name?', 'You take ${DateFormat.Hm().format(r.teeTime)} and $name takes ${DateFormat.Hm().format(myRow!.teeTime)}.', 'Swap')) return;
    final ok = await ref.read(competitionActionsProvider.notifier).swapTeeTimeSlot(competitionId: competition.id, myStartingSheetId: myRow!.id, targetStartingSheetId: r.id);
    ref.invalidate(startingSheetProvider(competition.id));
    if (!context.mounted) return;
    ok ? TopNotification.showSuccess(context, 'Swapped with $name') : TopNotification.showError(context, 'Couldn\'t swap. Pull down to refresh and try again.');
  }
}

Color _teeColor(String color) => switch (color.toLowerCase()) {
      'red' => const Color(0xFFEF4444),
      'yellow' => const Color(0xFFFACC15),
      'blue' => const Color(0xFF3B82F6),
      'black' => const Color(0xFF111111),
      'white' => const Color(0xFFF4F4F4),
      'gold' => const Color(0xFFB7791F),
      _ => const Color(0xFF22C55E),
    };

// ─── Results ─────────────────────────────────────────────────────────────────

enum _Measure { net, gross }

class _Results extends ConsumerStatefulWidget {
  const _Results({required this.competition});
  final Competition competition;

  @override
  ConsumerState<_Results> createState() => _ResultsState();
}

class _ResultsState extends ConsumerState<_Results> {
  _Measure _measure = _Measure.net;
  String? _flight;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Live competitions refresh on their own while this is open.
    if (widget.competition.isInProgress) {
      _poll = Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidate(leaderboardProvider(widget.competition.id)));
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.competition;
    final async = ref.watch(leaderboardProvider(c.id));
    final all = async.valueOrNull ?? const <LeaderboardRow>[];
    final me = ref.watch(authStateProvider).valueOrNull?.id;
    final points = const {'stableford', 'betterball', 'bogey'}.contains(c.competitionType);
    final flights = {for (final r in all) if (r.flightName != null && r.flightName!.isNotEmpty) r.flightName!}.toList()..sort();

    final rows = all.where((r) => _flight == null || r.flightName == _flight).toList();
    if (!points && _measure == _Measure.gross) {
      rows.sort((a, b) => (a.grossScore ?? 9999).compareTo(b.grossScore ?? 9999));
    }
    final certified = all.where((r) => r.certified).length;

    String score(LeaderboardRow r) {
      if (r.resultStatus != 'active') return r.displayScore;
      if (points) return r.stablefordPoints?.toString() ?? '–';
      return _measure == _Measure.gross ? (r.grossScore?.toString() ?? '–') : (r.netScore?.round().toString() ?? '–');
    }

    return RefreshIndicator(
      color: Ob.ink,
      backgroundColor: Ob.lime,
      onRefresh: () async => ref.invalidate(leaderboardProvider(c.id)),
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          if (async.isLoading && all.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CupertinoActivityIndicator(color: Ob.lime)))
          else if (all.isEmpty)
            Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ObGroup(children: [Padding(padding: const EdgeInsets.all(16), child: Text(async.hasError
                    ? 'Couldn\'t load the results. Pull down to try again.'
                    : c.isInProgress
                        ? 'No cards in yet. Scores show here as players hand them in.'
                        : 'Results appear once play starts.', style: Ob.body(16, color: Ob.creamA(.6))))]),
          )
          else ...[
            Text(
              [if (c.isInProgress) 'Live', '$certified of ${all.length} cards certified', if (points) 'Stableford points'].join(' · '),
              style: Ob.body(13, weight: FontWeight.w700, color: Ob.creamA(.65)),
            ),
            if (!points) ...[
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 240,
                  child: ObGooSegmented<_Measure>(
                    options: const [(_Measure.net, 'Net'), (_Measure.gross, 'Gross')],
                    selected: _measure,
                    onChanged: (m) => setState(() => _measure = m),
                    height: 38,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            if (flights.length > 1) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in [null, ...flights])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _flight = f),
                        child: ObChip(f == null ? 'All flights' : '$f flight', on: _flight == f),
                      ),
                    ),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            ObCard(
              radius: 12,
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (i, r) in rows.indexed) ...[
                  if (i > 0) const ObHair(),
                  _ResultRow(pos: _flight == null && (points || _measure == _Measure.net) ? (r.position ?? i + 1) : i + 1, row: r, score: score(r), isMe: r.playerId == me, first: i == 0),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.pos, required this.row, required this.score, required this.isMe, required this.first});
  final int pos;
  final LeaderboardRow row;
  final String score;
  final bool isMe;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final sub = [
      if (row.playingHandicap != null) 'HC ${row.playingHandicap!.round()}',
      if (row.flightName != null && row.flightName!.isNotEmpty) '${row.flightName} flight',
      if (!row.certified) 'Not certified',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(width: 28, child: Text('$pos', style: Ob.display(16, color: Ob.creamA(.55)))),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '${row.fullName ?? 'You'} (you)' : (row.fullName ?? 'Golfer'), maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w700, color: isMe ? Ob.lime : Ob.cream)),
            if (sub.isNotEmpty) Text(sub, style: Ob.body(12, color: Ob.creamA(.55))),
          ]),
        ),
        if (row.certified) ...[Icon(LucideIcons.badgeCheck, size: 14, color: Ob.creamA(.45)), const SizedBox(width: 8)],
        Text(score, style: Ob.display(22, color: first ? _gold : (isMe ? Ob.lime : Ob.cream))),
      ]),
    );
  }
}

const _gold = Color(0xFFB7791F);

// ─── Entry ───────────────────────────────────────────────────────────────────

/// Enter a competition: tees, preferred start and payment.
class CompetitionEntrySheet extends ConsumerStatefulWidget {
  final Competition competition;
  final dynamic profile;

  const CompetitionEntrySheet({super.key, required this.competition, required this.profile});

  @override
  ConsumerState<CompetitionEntrySheet> createState() => _CompetitionEntrySheetState();
}

class _CompetitionEntrySheetState extends ConsumerState<CompetitionEntrySheet> {
  String _tee = 'white';
  String _window = 'morning';
  bool _paying = false;
  late final _phone = TextEditingController();
  late int _ph = _playingHandicap((widget.profile?.handicap as double?) ?? 0, widget.competition);

  static const _tees = ['white', 'yellow', 'blue', 'red'];
  static const _windows = [('morning', '07:00 to 09:00'), ('midday', '09:00 to 12:00'), ('afternoon', 'After 12:00')];

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _paid => widget.competition.entryFee > 0;

  Future<void> _submit() async {
    final c = widget.competition;
    final phone = _phone.text.replaceAll(RegExp(r'\s'), '');
    if (_paid && !RegExp(r'^(\+?254|0)?[17]\d{8}$').hasMatch(phone)) {
      TopNotification.showError(context, 'Enter the M-Pesa number, like 0712 345 678.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _paying = true);
    final ok = await ref.read(competitionActionsProvider.notifier).enterCompetition(
          competitionId: c.id,
          playingHandicap: _ph.toDouble(),
          entryFee: c.entryFee,
          mpesaPhone: _paid ? phone : null,
          teeColor: _tee,
          preferredTimeWindow: _window,
        );
    if (!mounted) return;
    setState(() => _paying = false);
    if (ok) {
      ref.invalidate(myEntryProvider(c.id));
      ref.invalidate(competitionDetailProvider(c.id));
      Navigator.pop(context);
      TopNotification.showSuccess(context, 'You\'re in ${c.name}');
    } else {
      TopNotification.showError(context, _paid ? 'Payment didn\'t go through. Nothing was charged; try again.' : 'Couldn\'t enter you. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.competition;
    return ObSheet(
      title: 'Your entry',
      subtitle: c.name,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
              decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('PLAYING HANDICAP', style: Ob.eyebrow()),
                    Text('${_allowance(c)}% of your handicap. The club confirms it.', style: Ob.body(12, color: Ob.creamA(.6))),
                  ]),
                ),
                IconButton(onPressed: _ph > 0 ? () => setState(() => _ph--) : null, icon: Icon(LucideIcons.minus, color: Ob.creamA(.7)), tooltip: 'Lower'),
                SizedBox(
                  width: 52,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, a) => SlideTransition(position: Tween(begin: const Offset(0, .35), end: Offset.zero).animate(a), child: FadeTransition(opacity: a, child: child)),
                    child: Text('$_ph', key: ValueKey(_ph), textAlign: TextAlign.center, style: Ob.display(40, height: 1)),
                  ),
                ),
                IconButton(onPressed: _ph < 54 ? () => setState(() => _ph++) : null, icon: Icon(LucideIcons.plus, color: Ob.creamA(.7)), tooltip: 'Raise'),
              ]),
            ),
            const SizedBox(height: 16),
            const ObEyebrow('Tees'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in _tees)
                GestureDetector(
                  onTap: () => setState(() => _tee = t),
                  child: ObChip(_cap(t), on: _tee == t),
                ),
            ]),
            const SizedBox(height: 16),
            const ObEyebrow('When would you like to start?'),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final w in _windows)
                GestureDetector(onTap: () => setState(() => _window = w.$1), child: ObChip(w.$2, on: _window == w.$1)),
            ]),
            if (_paid) ...[
              const SizedBox(height: 16),
              ObCard(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Ob.lime.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(LucideIcons.smartphone, size: 18, color: Ob.lime),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Pay ${_money(c)} by M-Pesa', style: Ob.body(15, weight: FontWeight.w800)),
                        Text('We send a prompt to this phone', style: Ob.body(12, color: Ob.creamA(.58))),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    enabled: !_paying,
                    keyboardType: TextInputType.phone,
                    cursorColor: Ob.lime,
                    style: Ob.display(22),
                    decoration: obInput(null, hint: '0712 345 678'),
                  ),
                ]),
              ),
            ],
            if (_paying && _paid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(18), border: Border.all(color: Ob.lime, width: 1.5)),
                child: Row(children: [
                  const CupertinoActivityIndicator(color: Ob.lime, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Check your phone and enter your M-Pesa PIN', style: Ob.body(14, weight: FontWeight.w700))),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            ObButton(
              onPressed: _paying ? null : _submit,
              child: Text(
                _paying ? (_paid ? 'Waiting for M-Pesa…' : 'Entering…') : (_paid ? 'Pay and enter' : 'Enter'),
                style: Ob.label(16, weight: FontWeight.w800),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
