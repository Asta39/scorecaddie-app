import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../widgets/loading_spinner.dart';

class RoundsHistoryScreen extends ConsumerWidget {
  const RoundsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundsAsync = ref.watch(roundsProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text('Round History', style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 20)),
      ),
      body: roundsAsync.when(
        loading: () => const LoadingSpinner(),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (rounds) {
          if (rounds.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: rounds.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => _HistoryRoundCard(round: rounds[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.flag, size: 48, color: AppColors.grey200),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Rounds Yet',
            style: TextStyle(color: AppColors.grey900, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your scoring history will appear here.',
            style: TextStyle(color: AppColors.grey500, fontSize: 16),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.push('/select-course'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Start First Round', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HistoryRoundCard extends StatelessWidget {
  final Round round;
  const _HistoryRoundCard({required this.round});

  @override
  Widget build(BuildContext context) {
    final scoreVsPar = round.totalScore - round.coursePar;
    final badgeColor = scoreVsPar < 0 ? AppColors.birdie
        : scoreVsPar == 0 ? AppColors.par
        : scoreVsPar <= 2 ? AppColors.bogey 
        : AppColors.doubleBogey;
    final badgeText = scoreVsPar == 0 ? 'E' : scoreVsPar > 0 ? '+$scoreVsPar' : '$scoreVsPar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/round/${round.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round.courseName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.grey900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(round.playedAt),
                      style: const TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (round.notes.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(LucideIcons.fileText, size: 14, color: AppColors.grey400),
                        ),
                      Text(
                        '${round.totalScore}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.grey900),
                      ),
                    ],
                  ),
                  Text(
                    '${round.holesPlayed} Holes',
                    style: const TextStyle(color: AppColors.grey400, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.grey300),
            ],
          ),
        ),
      ),
    );
  }
}
