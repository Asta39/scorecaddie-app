import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../../core/cloud/group_sync_service.dart';
import '../../widgets/profile_image.dart';
import '../../widgets/top_notification.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

class GroupRoundLobbyScreen extends ConsumerStatefulWidget {
  final String roundId;
  const GroupRoundLobbyScreen({super.key, required this.roundId});

  @override
  ConsumerState<GroupRoundLobbyScreen> createState() => _GroupRoundLobbyScreenState();
}

class _GroupRoundLobbyScreenState extends ConsumerState<GroupRoundLobbyScreen> {
  // Subscribed once; building them in build() re-subscribed on every frame.
  late final Stream<Map<String, dynamic>> _round = ref.read(groupSyncServiceProvider).watchGroupRound(widget.roundId);
  late final Stream<List<Map<String, dynamic>>> _players = ref.read(groupSyncServiceProvider).watchParticipants(widget.roundId);
  bool _starting = false;
  bool _left = false;

  void _goScore(Map<String, dynamic> data) {
    if (_left || !mounted) return;
    _left = true;
    context.pushReplacement('/scoring', extra: {
      'courseId': data['courseId'],
      'groupRoundId': widget.roundId,
      'mode': data['scoringMode'],
    });
  }

  Future<void> _startRound(Map<String, dynamic> data) async {
    setState(() => _starting = true);
    try {
      await Supabase.instance.client.from('GroupRound').update({
        'status': 'IN_PROGRESS',
        'updatedAt': DateTime.now().toIso8601String(),
      }).eq('id', widget.roundId);
      _goScore(data);
    } catch (e) {
      if (mounted) TopNotification.showError(context, 'Couldn\'t start the round: $e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

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
            builder: (context, snap) {
              if (!snap.hasData) {
                return Column(children: [
                  Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: ObTopBar('Lobby', onBack: () => context.pop())),
                  const Expanded(child: Center(child: CupertinoActivityIndicator(color: Ob.lime))),
                ]);
              }
              final data = snap.data!;
              final captain = data['captainId'] == me?.id;
              final code = data['roundCode'] as String? ?? '——';
              // Players who joined get moved on when the captain starts.
              if (!captain && data['status'] == 'IN_PROGRESS') {
                scheduleMicrotask(() => _goScore(data));
              }

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _players,
                builder: (context, pSnap) {
                  final players = pSnap.data ?? const [];
                  return Column(children: [
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          ObTopBar('Lobby', eyebrow: 'Group round', onBack: () => context.pop()),
                          const SizedBox(height: 16),
                          Row(children: [
                            ObCrest(data['courseName']?.toString() ?? 'Course', size: 52),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(data['courseName']?.toString() ?? 'Course', style: Ob.display(22, height: 1.05)),
                                Text(
                                  data['scoringMode'] == 'INDIVIDUAL_DEVICES' ? 'Everyone scores on their own phone' : 'One phone scores for the group',
                                  style: Ob.body(12, color: Ob.creamA(.6)),
                                ),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 18),
                          ObHeroCard(
                            child: Column(children: [
                              Text('FRIENDS SCAN THIS TO JOIN', style: Ob.eyebrow()),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Ob.cream, borderRadius: BorderRadius.circular(22)),
                                child: QrImageView(
                                  data: 'scorecaddie://round/join/$code',
                                  version: QrVersions.auto,
                                  size: 190,
                                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Ob.ink),
                                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Ob.ink),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  TopNotification.showSuccess(context, 'Code copied');
                                },
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text(code, style: Ob.display(30, color: Ob.lime).copyWith(letterSpacing: 5)),
                                  const SizedBox(width: 8),
                                  Icon(LucideIcons.copy, size: 16, color: Ob.creamA(.6)),
                                ]),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 22),
                          ObEyebrow('In the lobby · ${players.length}/8'),
                          const SizedBox(height: 10),
                          ObCard(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(children: [
                              if (players.isEmpty)
                                Padding(padding: const EdgeInsets.all(16), child: Text('Waiting for players…', style: Ob.body(13, color: Ob.creamA(.6)))),
                              for (final (i, p) in players.indexed) ...[
                                if (i > 0) const ObHair(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                  child: Row(children: [
                                    ProfileImage(url: (p['user'] as Map?)?['avatarUrl'], name: (p['user'] as Map?)?['name'], size: 36, isCircle: true),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text('${(p['user'] as Map?)?['name'] ?? 'Golfer'}', style: Ob.body(14, weight: FontWeight.w700))),
                                    if (p['role'] == 'CAPTAIN') const ObChip('Captain', on: true, color: Color(0xFFF5C531)),
                                  ]),
                                ),
                              ],
                            ]),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + MediaQuery.of(context).padding.bottom),
                      child: captain
                          ? SizedBox(
                              width: double.infinity,
                              child: ObButton(
                                onPressed: players.isEmpty || _starting ? null : () => _startRound(data),
                                child: Text(_starting ? 'Starting…' : 'Start the round', style: Ob.label(17, weight: FontWeight.w800)),
                              ),
                            )
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const CupertinoActivityIndicator(color: Ob.lime),
                              const SizedBox(width: 10),
                              Text('Waiting for the captain to start', style: Ob.body(14, weight: FontWeight.w700, color: Ob.creamA(.7))),
                            ]),
                    ),
                  ]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
