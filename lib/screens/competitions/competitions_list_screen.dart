import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/competition.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';
import '../../providers/competition_providers.dart';
import '../../widgets/loading_spinner.dart';

class CompetitionsListScreen extends ConsumerWidget {
  const CompetitionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final clubIdAsync = ref.watch(playerHomeClubIdProvider);

    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: SafeArea(
        child: clubIdAsync.when(
          loading: () => const Center(child: LoadingSpinner(size: 60)),
          error: (e, _) => _ErrorView(message: e.toString()),
          data: (clubId) {
            if (clubId == null) {
              return const _NoClubView();
            }
            return _CompetitionsBody(
              clubId: clubId,
              profile: profile,
            );
          },
        ),
      ),
    );
  }
}

class _CompetitionsBody extends ConsumerWidget {
  final String clubId;
  final dynamic profile;

  const _CompetitionsBody({
    required this.clubId,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionsAsync = ref.watch(competitionsForClubProvider(clubId));

    return competitionsAsync.when(
      loading: () => const Center(child: LoadingSpinner(size: 60)),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (competitions) {
        final inProgress = competitions
            .where((c) => c.status == 'in_progress')
            .toList();
        final openForEntry = competitions
            .where((c) => c.status == 'open_for_entry')
            .toList();
        final upcoming = competitions
            .where((c) => c.status == 'upcoming')
            .toList();
        final completed = competitions
            .where((c) => c.status == 'completed' || c.status == 'closed' || c.status == 'cancelled')
            .toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Competitions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.grey900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (profile?.homeCourseName != null)
                    Text(
                      profile!.homeCourseName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (competitions.isEmpty)
              const SliverFillRemaining(
                child: _EmptyCompetitionsView(),
              )
            else ...[
              if (inProgress.isNotEmpty)
                _SectionSliver(
                  title: '🟢 In Progress',
                  competitions: inProgress,
                ),
              if (openForEntry.isNotEmpty)
                _SectionSliver(
                  title: '📋 Open for Entry',
                  competitions: openForEntry,
                ),
              if (upcoming.isNotEmpty)
                _SectionSliver(
                  title: '📅 Upcoming',
                  competitions: upcoming,
                ),
              if (completed.isNotEmpty)
                _SectionSliver(
                  title: '✅ Past',
                  competitions: completed,
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionSliver extends StatelessWidget {
  final String title;
  final List<Competition> competitions;

  const _SectionSliver({required this.title, required this.competitions});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.grey500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...competitions.map((c) => _CompetitionCard(competition: c)),
        ]),
      ),
    );
  }
}

class _CompetitionCard extends ConsumerWidget {
  final Competition competition;

  const _CompetitionCard({required this.competition});

  Color _statusColor(String status) {
    switch (status) {
      case 'open_for_entry':
      case 'in_progress':
        return AppColors.golfLime;
      case 'completed':
        return AppColors.grey400;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.grey300;
    }
  }

  Color _statusTextColor(String status, {required bool isSolidBg}) {
    switch (status) {
      case 'open_for_entry':
      case 'in_progress':
        return AppColors.grey900;
      case 'completed':
        return isSolidBg ? Colors.white : AppColors.grey600;
      case 'cancelled':
        return isSolidBg ? Colors.white : Colors.red;
      default:
        return isSolidBg ? Colors.white : AppColors.grey500;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEntryAsync = ref.watch(myEntryProvider(competition.id));
    final hasEntry = myEntryAsync.valueOrNull != null;
    final hasPoster = competition.posterUrl != null && competition.posterUrl!.isNotEmpty;

    if (hasPoster) {
      return GestureDetector(
        onTap: () => context.push('/competitions/${competition.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      competition.posterUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: AppColors.grey100,
                        child: const Center(
                          child: Icon(LucideIcons.image, color: AppColors.grey300, size: 36),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _Chip(
                        label: competition.statusLabel,
                        color: _statusColor(competition.status) == AppColors.golfLime
                            ? AppColors.golfLime
                            : _statusColor(competition.status).withValues(alpha: 0.9),
                        textColor: _statusTextColor(competition.status, isSolidBg: true),
                      ),
                    ),
                    if (hasEntry)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emerald700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Entered',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Chip(
                            label: competition.formatLabel,
                            color: AppColors.grey100,
                            textColor: AppColors.grey600,
                          ),
                          const Spacer(),
                          const Icon(LucideIcons.calendar, size: 13, color: AppColors.grey400),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('d MMM y').format(competition.startDate),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        competition.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.grey900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (competition.entryFee > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(LucideIcons.banknote, size: 13, color: AppColors.grey400),
                            const SizedBox(width: 4),
                            Text(
                              '${competition.currency} ${competition.entryFee.toStringAsFixed(0)} entry fee',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.grey600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push('/competitions/${competition.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    competition.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.grey900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasEntry)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emerald700.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Entered',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(
                  label: competition.formatLabel,
                  color: AppColors.grey100,
                  textColor: AppColors.grey600,
                ),
                const SizedBox(width: 6),
                _Chip(
                  label: competition.statusLabel,
                  color: _statusColor(competition.status) == AppColors.golfLime
                      ? AppColors.golfLime
                      : _statusColor(competition.status).withValues(alpha: 0.12),
                  textColor: _statusTextColor(competition.status, isSolidBg: _statusColor(competition.status) == AppColors.golfLime),
                ),
                const Spacer(),
                const Icon(LucideIcons.calendar,
                    size: 13, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM y').format(competition.startDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (competition.entryFee > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.banknote,
                      size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    '${competition.currency} ${competition.entryFee.toStringAsFixed(0)} entry fee',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w500,
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
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _NoClubView extends StatelessWidget {
  const _NoClubView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.building2,
                size: 56, color: AppColors.grey300),
            const SizedBox(height: 20),
            const Text(
              'No Club Membership',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need to be a member of a club to see competitions. Contact your club administrator.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompetitionsView extends StatelessWidget {
  const _EmptyCompetitionsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.trophy, size: 56, color: AppColors.grey200),
            const SizedBox(height: 20),
            const Text(
              'No Competitions Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your club hasn\'t created any competitions yet. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
