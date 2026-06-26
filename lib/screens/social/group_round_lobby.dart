import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/cloud/group_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupRoundLobbyScreen extends ConsumerStatefulWidget {
  final String roundId;
  const GroupRoundLobbyScreen({super.key, required this.roundId});

  @override
  ConsumerState<GroupRoundLobbyScreen> createState() => _GroupRoundLobbyScreenState();
}

class _GroupRoundLobbyScreenState extends ConsumerState<GroupRoundLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final groupSync = ref.read(groupSyncServiceProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text('Group Lobby', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: groupSync.watchGroupRound(widget.roundId),
        builder: (context, roundSnapshot) {
          if (!roundSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.emerald700));
          }

          final roundData = roundSnapshot.data!;
          final isCaptain = roundData['captainId'] == user?.id;
          final roundCode = roundData['roundCode'] as String? ?? 'UNKNOWN';

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: groupSync.watchParticipants(widget.roundId),
            builder: (context, participantsSnapshot) {
              final participants = participantsSnapshot.data ?? [];
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildCourseInfo(roundData),
                    const SizedBox(height: 32),
                    _buildQrSection(roundCode),
                    const SizedBox(height: 32),
                    _buildParticipantsList(participants),
                    const SizedBox(height: 40),
                    if (isCaptain)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: participants.isNotEmpty ? () => _startRound(roundData) : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.emerald700,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Start Round', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                      )
                    else
                      const Text('Waiting for captain to start...', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.emerald700.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.mapPin, color: AppColors.emerald700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['courseName'] ?? 'Selected Course', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text(data['scoringMode'] == 'INDIVIDUAL_DEVICES' ? 'Individual Scoring' : 'Shared Device Scoring', 
                     style: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(String roundCode) {
    return Column(
      children: [
        const Text('Scan to Join Round', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: QrImageView(
            data: 'scorecaddie://round/join/$roundCode',
            version: QrVersions.auto,
            size: 200.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: AppColors.grey900),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: AppColors.grey900),
          ),
        ),
        const SizedBox(height: 12),
        Text('ROUND CODE: $roundCode', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2, color: AppColors.emerald700)),
      ],
    );
  }

  Widget _buildParticipantsList(List participants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Participants (${participants.length}/8)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Icon(LucideIcons.users, color: AppColors.grey400, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        ...participants.map((p) {
          final userData = p['user'] as Map<String, dynamic>?;
          final name = userData?['name'] ?? 'Golfer';
          final avatar = userData?['avatarUrl'];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.grey100,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null ? const Icon(LucideIcons.user, size: 20, color: AppColors.grey400) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(p['role'] == 'CAPTAIN' ? 'Captain' : 'Player', style: const TextStyle(color: AppColors.grey500, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (p['role'] == 'CAPTAIN')
                  const Icon(LucideIcons.crown, color: Color(0xFFFFD700), size: 16),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _startRound(Map<String, dynamic> data) async {
    // 1. Update status to IN_PROGRESS in Supabase
    await Supabase.instance.client.from('GroupRound').update({
      'status': 'IN_PROGRESS',
      'updatedAt': DateTime.now().toIso8601String(),
    }).eq('id', widget.roundId);

    // 2. Navigate to scoring
    if (mounted) {
      context.pushReplacement('/scoring', extra: {
        'courseId': data['courseId'],
        'groupRoundId': widget.roundId,
        'mode': data['scoringMode'],
      });
    }
  }
}
