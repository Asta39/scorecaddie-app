import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';

class RoundsHistoryScreen extends ConsumerWidget {
  const RoundsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundsAsync = ref.watch(roundsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F0), // Warm off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Round History',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.grey900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: roundsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.emerald700)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (rounds) {
          if (rounds.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.flag, size: 48, color: AppColors.grey400),
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
          ElevatedButton(
            onPressed: () => context.push('/select-course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/round/${round.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.mapPin, color: AppColors.emerald700, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      round.courseName ?? 'Unknown Course',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppColors.grey900,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${round.holesPlayed} holes • ${_formatDate(round.playedAt)}',
                      style: const TextStyle(
                        color: AppColors.grey500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${round.totalScore}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: AppColors.grey900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
