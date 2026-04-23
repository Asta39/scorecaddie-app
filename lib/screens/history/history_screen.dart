import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundsAsync = ref.watch(roundsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Text('Round History', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 26, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: roundsAsync.when(
              data: (rounds) {
                if (rounds.isEmpty) {
                  return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.history, size: 64, color: AppColors.grey300),
                    const SizedBox(height: 16),
                    Text('No rounds yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.grey500)),
                  ]));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: rounds.length,
                  itemBuilder: (ctx, i) {
                    final r = rounds[i];
                    final vsPar = r.totalScore - r.coursePar;
                    final badgeColor = vsPar < 0 ? AppColors.birdie : vsPar == 0 ? AppColors.par
                        : vsPar <= 2 ? AppColors.bogey : AppColors.doubleBogey;
                    final badge = vsPar == 0 ? 'E' : vsPar > 0 ? '+$vsPar' : '$vsPar';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/round/${r.id}'),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.grey200)),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.courseName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${r.holesPlayed == -9 ? 'Back 9' : '${r.holesPlayed} holes'} • ${r.playedAt.day}/${r.playedAt.month}/${r.playedAt.year}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.grey500)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('${r.totalScore}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                child: Text(badge, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ]),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ]),
      ),
    );
  }
}
