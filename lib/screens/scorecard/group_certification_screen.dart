import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/cloud/group_sync_service.dart';
import '../../widgets/top_notification.dart';

class GroupCertificationScreen extends ConsumerStatefulWidget {
  final String groupRoundId;
  const GroupCertificationScreen({super.key, required this.groupRoundId});

  @override
  ConsumerState<GroupCertificationScreen> createState() => _GroupCertificationScreenState();
}

class _GroupCertificationScreenState extends ConsumerState<GroupCertificationScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final groupSync = ref.read(groupSyncServiceProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return StreamBuilder<Map<String, dynamic>>(
      stream: groupSync.watchGroupRound(widget.groupRoundId),
      builder: (ctx, roundSnapshot) {
        if (!roundSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final roundData = roundSnapshot.data!;
        final isKeeper = roundData['captainId'] == user?.id;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: groupSync.watchParticipants(widget.groupRoundId),
          builder: (ctx, participantsSnapshot) {
            final participants = participantsSnapshot.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: groupSync.watchAllScores(widget.groupRoundId),
              builder: (ctx, scoresSnapshot) {
                final allScores = scoresSnapshot.data ?? [];
                
                return Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    title: const Text('Review & Certify', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900)),
                    leading: IconButton(icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900), onPressed: () => context.pop()),
                  ),
                  body: Column(
                    children: [
                      Expanded(child: _buildScorecardTable(participants, allScores)),
                      _buildActionBar(participants, isKeeper, user?.id),
                    ],
                  ),
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildScorecardTable(List<Map<String, dynamic>> participants, List<Map<String, dynamic>> allScores) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 48,
          columnSpacing: 24,
          columns: [
            const DataColumn(label: Text('HOLE', style: TextStyle(fontWeight: FontWeight.bold))),
            ...participants.map((p) => DataColumn(label: Text(p['user']?['name']?.split(' ')[0] ?? 'Golfer', style: const TextStyle(fontWeight: FontWeight.bold)))),
          ],
          rows: List.generate(18, (holeIdx) {
            final holeNum = holeIdx + 1;
            return DataRow(cells: [
              DataCell(Text('$holeNum', style: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.bold))),
              ...participants.map((p) {
                final score = allScores.firstWhere((s) => s['participantId'] == p['id'] && s['holeNumber'] == holeNum, orElse: () => {});
                return DataCell(Text(score['strokes']?.toString() ?? '-'));
              }),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildActionBar(List<Map<String, dynamic>> participants, bool isKeeper, String? myUid) {
    final myParticipant = participants.firstWhere((p) => p['userId'] == myUid, orElse: () => {});
    final isCertified = myParticipant['certifiedAt'] != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)]),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isKeeper) ...[
              const Text('As scorekeeper, please submit the final scores for review.', style: TextStyle(color: AppColors.grey500), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitRound,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT & NOTIFY PLAYERS', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ] else ...[
              Text(isCertified ? '✓ YOU HAVE CERTIFIED THIS ROUND' : 'Review your scores and certify the round.', style: TextStyle(color: isCertified ? AppColors.emerald700 : AppColors.grey500, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isCertified ? null : () => _showDisputeDialog(myParticipant['id']),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('DISPUTE', style: TextStyle(color: AppColors.doubleBogey, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isCertified ? null : () => _certify(myParticipant['id']),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.emerald700, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('CERTIFY SCORE', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitRound() async {
    setState(() => _isSubmitting = true);
    await ref.read(groupSyncServiceProvider).finalizeRound(widget.groupRoundId);
    if (mounted) {
       TopNotification.showSuccess(context, 'Round submitted! Players notified for certification.');
       context.go('/');
    }
  }

  void _certify(String pId) async {
    await ref.read(groupSyncServiceProvider).certifyParticipant(pId);
    if (mounted) {
       TopNotification.showSuccess(context, 'Round certified!');
    }
  }

  void _showDisputeDialog(String pId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispute Scores'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter reason for dispute...'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref.read(groupSyncServiceProvider).certifyParticipant(pId, dispute: true, note: controller.text);
              Navigator.pop(ctx);
              TopNotification.showSuccess(context, 'Dispute submitted.');
            },
            child: const Text('Submit Dispute'),
          ),
        ],
      ),
    );
  }
}
