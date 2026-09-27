import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../core/cloud/group_sync_service.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

class GroupCertificationScreen extends ConsumerStatefulWidget {
  final String groupRoundId;
  const GroupCertificationScreen({super.key, required this.groupRoundId});

  @override
  ConsumerState<GroupCertificationScreen> createState() => _GroupCertificationScreenState();
}

class _GroupCertificationScreenState extends ConsumerState<GroupCertificationScreen> {
  // Subscribed once; building them in build() re-subscribed on every frame.
  late final Stream<Map<String, dynamic>> _round = ref.read(groupSyncServiceProvider).watchGroupRound(widget.groupRoundId);
  late final Stream<List<Map<String, dynamic>>> _players = ref.read(groupSyncServiceProvider).watchParticipants(widget.groupRoundId);
  late final Stream<List<Map<String, dynamic>>> _scores = ref.read(groupSyncServiceProvider).watchAllScores(widget.groupRoundId);
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<Map<String, dynamic>>(
            stream: _round,
            builder: (context, rSnap) => StreamBuilder<List<Map<String, dynamic>>>(
              stream: _players,
              builder: (context, pSnap) => StreamBuilder<List<Map<String, dynamic>>>(
                stream: _scores,
                builder: (context, sSnap) {
                  if (!rSnap.hasData) return const Center(child: CupertinoActivityIndicator(color: Ob.lime));
                  final round = rSnap.data!;
                  final players = pSnap.data ?? const [];
                  final scores = sSnap.data ?? const [];
                  final keeper = round['captainId'] == me?.id;
                  final mine = players.where((p) => p['userId'] == me?.id).firstOrNull;
                  final holes = scores.map((s) => s['holeNumber'] as int).fold<int>(0, (a, b) => a > b ? a : b);
                  final holeCount = holes <= 9 ? 9 : 18;

                  return Column(children: [
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          ObTopBar('Sign off', eyebrow: round['courseName']?.toString(), onBack: () => context.pop()),
                          const SizedBox(height: 16),
                          Text(
                            keeper ? 'Check everyone\'s card, then send it for them to sign.' : 'Check your scores. Sign if they\'re right, or flag what\'s wrong.',
                            style: Ob.body(14, height: 1.45, color: Ob.creamA(.75)),
                          ),
                          const SizedBox(height: 16),
                          for (final p in players) Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(p, scores, holeCount)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
                      child: _actions(keeper, mine),
                    ),
                  ]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> p, List<Map<String, dynamic>> scores, int holeCount) {
    final byHole = {for (final s in scores.where((s) => s['participantId'] == p['id'])) s['holeNumber'] as int: s['strokes'] as int?};
    final total = byHole.values.whereType<int>().fold(0, (a, b) => a + b);
    final signed = p['certifiedAt'] != null;
    final disputed = p['disputed'] == true;
    Widget nine(int from) => Row(children: [
          for (var h = from; h < from + 9; h++)
            Expanded(
              child: Column(children: [
                Text('$h', style: Ob.body(10, color: Ob.creamA(.45))),
                const SizedBox(height: 2),
                Text(byHole[h]?.toString() ?? '·', style: Ob.body(13, weight: FontWeight.w800, color: byHole[h] == null ? Ob.creamA(.3) : Ob.cream)),
              ]),
            ),
        ]);
    return ObCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ProfileImage(url: p['user']?['avatarUrl'], name: p['user']?['name'], size: 38, isCircle: true),
          const SizedBox(width: 10),
          Expanded(child: Text('${p['user']?['name'] ?? 'Golfer'}', style: Ob.body(15, weight: FontWeight.w800))),
          if (disputed)
            const ObChip('Flagged', on: true, color: Ob.warn)
          else if (signed)
            const ObChip('Signed', on: true)
          else
            const ObChip('To sign'),
          const SizedBox(width: 10),
          Text('$total', style: Ob.display(24)),
        ]),
        const SizedBox(height: 12),
        nine(1),
        if (holeCount > 9) ...[const SizedBox(height: 10), nine(10)],
      ]),
    );
  }

  Widget _actions(bool keeper, Map<String, dynamic>? mine) {
    if (keeper) {
      return SizedBox(
        width: double.infinity,
        child: ObButton(
          onPressed: _busy ? null : _submitRound,
          child: Text(_busy ? 'Sending…' : 'Send for signing', style: Ob.label(16, weight: FontWeight.w800)),
        ),
      );
    }
    if (mine == null) return Text('You\'re not on this card.', textAlign: TextAlign.center, style: Ob.body(14, color: Ob.creamA(.6)));
    if (mine['disputed'] == true) {
      return Text('You flagged this card. The scorekeeper will sort it.', textAlign: TextAlign.center, style: Ob.body(14, weight: FontWeight.w700, color: Ob.warn));
    }
    if (mine['certifiedAt'] != null) {
      return Text('You\'ve signed this card.', textAlign: TextAlign.center, style: Ob.body(15, weight: FontWeight.w800, color: Ob.lime));
    }
    return Row(children: [
      Expanded(
        child: ObButton(
          tone: ObButtonTone.dark,
          onPressed: _busy ? null : () => _showDisputeDialog(mine['id']),
          child: Text('Something\'s wrong', style: Ob.label(15, weight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ObButton(onPressed: _busy ? null : () => _certify(mine['id']), child: Text('Sign', style: Ob.label(15, weight: FontWeight.w800))),
      ),
    ]);
  }

  Future<void> _submitRound() async {
    setState(() => _busy = true);
    try {
      await ref.read(groupSyncServiceProvider).finalizeRound(widget.groupRoundId);
      if (!mounted) return;
      TopNotification.showSuccess(context, 'Sent. Everyone gets a nudge to sign.');
      context.go('/');
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t send it: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _certify(String pId) async {
    setState(() => _busy = true);
    try {
      await ref.read(groupSyncServiceProvider).certifyParticipant(pId);
      if (mounted) TopNotification.showSuccess(context, 'Signed');
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t sign: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDisputeDialog(String pId) {
    final controller = TextEditingController();
    showObSheet(
      context,
      (ctx) => ObSheet(
        title: 'What\'s wrong?',
        subtitle: 'The scorekeeper sees your note.',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            cursorColor: Ob.lime,
            style: Ob.body(15, weight: FontWeight.w600),
            decoration: obInput(null, hint: 'I had a 5 on 7, not a 6'),
          ),
          const SizedBox(height: 16),
          ObButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(groupSyncServiceProvider).certifyParticipant(pId, dispute: true, note: controller.text);
                if (mounted) TopNotification.showSuccess(context, 'Flagged for the scorekeeper');
              } catch (e) {
                if (mounted) TopNotification.showError(context, 'Couldn\'t send that: $e');
              }
            },
            child: Text('Send', style: Ob.label(16, weight: FontWeight.w800)),
          ),
        ]),
      ),
    ).whenComplete(controller.dispose);
  }
}
