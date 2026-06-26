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

class CompetitionDetailScreen extends ConsumerStatefulWidget {
  final String competitionId;
  const CompetitionDetailScreen({super.key, required this.competitionId});

  @override
  ConsumerState<CompetitionDetailScreen> createState() =>
      _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState
    extends ConsumerState<CompetitionDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final competitionAsync =
        ref.watch(competitionDetailProvider(widget.competitionId));
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final isAdmin =
        profile?.role == 'club_admin' || profile?.role == 'super_admin';

    return competitionAsync.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingSpinner(size: 60)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (competition) {
        if (competition == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Competition not found')),
          );
        }
        return DefaultTabController(
          length: 3,
          child: _CompetitionDetailBody(
            competition: competition,
            isAdmin: isAdmin,
            profile: profile,
          ),
        );
      },
    );
  }
}

class _CompetitionDetailBody extends ConsumerWidget {
  final Competition competition;
  final bool isAdmin;
  final dynamic profile;

  const _CompetitionDetailBody({
    required this.competition,
    required this.isAdmin,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.grey900,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              competition.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
              ),
            ),
            actions: const [],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    labelColor: AppColors.grey900,
                    unselectedLabelColor: AppColors.grey500,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Start Sheet'),
                      Tab(text: 'Results'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _OverviewTab(
                competition: competition,
                isAdmin: isAdmin,
                profile: profile),
            _StartingSheetTab(
                competition: competition, isAdmin: isAdmin),
            _LeaderboardTab(competition: competition),
          ],
        ),
      ),
    );
  }


}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  final Competition competition;
  final bool isAdmin;
  final dynamic profile;

  const _OverviewTab({
    required this.competition,
    required this.isAdmin,
    required this.profile,
  });

  Widget _buildPosterCard() {
    if (competition.posterUrl == null || competition.posterUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          competition.posterUrl!,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEntryAsync =
        ref.watch(myEntryProvider(competition.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image card
          _buildPosterCard(),

          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusBgColor(competition.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              competition.statusLabel.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: _statusTextColor(competition.status),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Key details
          _DetailCard(children: [
            _DetailRow(
                icon: LucideIcons.trophy,
                label: 'Format',
                value: competition.formatLabel),
            _DetailRow(
                icon: LucideIcons.calendar,
                label: 'Date',
                value:
                    DateFormat('EEEE, d MMMM y').format(competition.startDate)),
            if (competition.entryDeadline != null)
              _DetailRow(
                  icon: LucideIcons.clock,
                  label: 'Entry Deadline',
                  value: DateFormat('d MMM y, HH:mm')
                      .format(competition.entryDeadline!)),
            if (competition.entryFee > 0)
              _DetailRow(
                  icon: LucideIcons.banknote,
                  label: 'Entry Fee',
                  value:
                      '${competition.currency} ${competition.entryFee.toStringAsFixed(0)}'),
          ]),

          if (competition.description != null && competition.description!.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text('About',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: AppColors.grey900,
                    letterSpacing: -0.2)),
            const SizedBox(height: 10),
            Text(competition.description!,
                style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.grey600,
                    height: 1.6,
                    fontWeight: FontWeight.w500)),
          ],

          const SizedBox(height: 28),
          const Text('Rules',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: AppColors.grey900,
                  letterSpacing: -0.2)),
          const SizedBox(height: 10),
          _DetailCard(children: [
            _DetailRow(
                icon: LucideIcons.percent,
                label: 'Handicap Allowance',
                value:
                    '${competition.rulesConfig['handicap_allowance_pct'] ?? 100}%'),
            _DetailRow(
                icon: LucideIcons.gauge,
                label: 'Max Handicap',
                value:
                    '${competition.rulesConfig['max_handicap'] ?? 36}'),
            if (competition.rulesConfig['min_handicap'] != null)
              _DetailRow(
                  icon: LucideIcons.gauge,
                  label: 'Min Handicap',
                  value:
                      '${competition.rulesConfig['min_handicap']}'),
            _DetailRow(
                icon: LucideIcons.arrowDownUp,
                label: 'Tiebreaker',
                value:
                    '${competition.rulesConfig['tiebreaker'] ?? 'Countback'}'),
          ]),

          const SizedBox(height: 32),

          // Player entry action
          myEntryAsync.when(
            loading: () => const Center(child: LoadingSpinner(size: 40)),
            error: (e, _) => const SizedBox.shrink(),
            data: (entry) {
              if (entry != null) {
                return _EntryStatusBanner(entry: entry);
              }
              if (competition.isOpenForEntry) {
                return SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    icon: const Icon(LucideIcons.clipboardList,
                        color: Colors.white, size: 20),
                    label: const Text(
                      'Enter Competition',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showEntrySheet(context, ref),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'open_for_entry':
        return Colors.blue.withValues(alpha: 0.1);
      case 'in_progress':
        return AppColors.emerald700.withValues(alpha: 0.1);
      case 'completed':
        return AppColors.grey100;
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.1);
      default:
        return AppColors.grey50;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'open_for_entry':
        return Colors.blue.shade700;
      case 'in_progress':
        return AppColors.emerald700;
      case 'completed':
        return AppColors.grey500;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.grey500;
    }
  }

  void _showEntrySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => CompetitionEntrySheet(
        competition: competition,
        profile: profile,
      ),
    );
  }
}

class _EntryStatusBanner extends StatelessWidget {
  final CompetitionEntry entry;
  const _EntryStatusBanner({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPending = entry.entryStatus == 'pending';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.amber.withValues(alpha: 0.1)
            : AppColors.emerald700.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending ? Colors.amber : AppColors.emerald700,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? LucideIcons.clock : LucideIcons.checkCircle2,
            color: isPending ? Colors.amber.shade700 : AppColors.emerald700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'Entry Pending Confirmation' : 'Entry Confirmed',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isPending
                        ? Colors.amber.shade700
                        : AppColors.emerald700,
                  ),
                ),
                if (entry.playingHandicap != null)
                  Text(
                    'Playing HC: ${entry.playingHandicap!.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.grey500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Starting Sheet Tab ───────────────────────────────────────────────────────
class _StartingSheetTab extends ConsumerWidget {
  final Competition competition;
  final bool isAdmin;

  const _StartingSheetTab({required this.competition, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync =
        ref.watch(startingSheetProvider(competition.id));

    return sheetAsync.when(
      loading: () => const Center(child: LoadingSpinner(size: 60)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.calendarDays,
                    size: 48, color: AppColors.grey200),
                SizedBox(height: 12),
                Text('Starting sheet not published yet',
                    style: TextStyle(color: AppColors.grey400)),
              ],
            ),
          );
        }

        // Group by tee time
        final grouped = <DateTime, List<StartingSheetRow>>{};
        for (final row in rows) {
          final key = DateTime(row.teeTime.year, row.teeTime.month,
              row.teeTime.day, row.teeTime.hour, row.teeTime.minute);
          grouped.putIfAbsent(key, () => []).add(row);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries.map((e) {
            final teeTime = e.key;
            final group = e.value;
            return _TeeTimeGroup(teeTime: teeTime, players: group, isAdmin: isAdmin);
          }).toList(),
        );
      },
    );
  }
}

class _TeeTimeGroup extends StatelessWidget {
  final DateTime teeTime;
  final List<StartingSheetRow> players;
  final bool isAdmin;

  const _TeeTimeGroup({required this.teeTime, required this.players, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8, top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.clock,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                DateFormat('HH:mm').format(teeTime),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                'Hole ${players.first.teeNumber}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        ...players.map((p) => _SheetPlayerTile(row: p, isAdmin: isAdmin)),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SheetPlayerTile extends StatelessWidget {
  final StartingSheetRow row;
  final bool isAdmin;
  const _SheetPlayerTile({required this.row, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            row.playerName ?? 'Unknown Player',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.grey900),
          ),
          const Spacer(),
          Text(
            'HC: ${row.playingHandicap?.toStringAsFixed(1) ?? "-"}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.grey500),
          ),
          if (row.teeColor != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _teeColor(row.teeColor!),
                shape: BoxShape.circle,
              ),
            ),
          ],
          if (isAdmin) ...[
            const SizedBox(width: 12),
            IconButton(
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              icon: const Icon(
                LucideIcons.camera,
                color: AppColors.emerald700,
                size: 20,
              ),
              onPressed: () {
                context.push('/competitions/${row.competitionId}/scan/${row.entryId}');
              },
            ),
          ],
        ],
      ),
    );
  }

  Color _teeColor(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.grey.shade300;
      default:
        return Colors.green;
    }
  }
}

// ─── Leaderboard Tab ─────────────────────────────────────────────────────────
class _LeaderboardTab extends ConsumerWidget {
  final Competition competition;

  const _LeaderboardTab({required this.competition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(leaderboardProvider(competition.id));
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return lbAsync.when(
      loading: () => const Center(child: LoadingSpinner(size: 60)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.barChart2,
                    size: 48, color: AppColors.grey200),
                const SizedBox(height: 12),
                Text(
                  competition.isInProgress || competition.isCompleted
                      ? 'No results submitted yet'
                      : 'Results appear when the competition starts',
                  style: const TextStyle(color: AppColors.grey400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final row = rows[i];
            final isMe = row.playerId == profile?.uid;
            return _LeaderboardTile(row: row, isMe: isMe);
          },
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardRow row;
  final bool isMe;

  const _LeaderboardTile({required this.row, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final pos = row.position;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.emerald700.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(
                color: AppColors.emerald700.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 32,
            child: Text(
              pos != null ? '#$pos' : '-',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: pos == 1
                    ? Colors.amber
                    : pos == 2
                        ? Colors.blueGrey
                        : pos == 3
                            ? Colors.brown
                            : AppColors.grey400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      row.fullName ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey900),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.emerald700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                Text(
                  'HC: ${row.playingHandicap?.toStringAsFixed(1) ?? "-"}  •  Gross: ${row.grossScore ?? "-"}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.displayScore,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.grey900),
              ),
              if (row.certified)
                const Icon(LucideIcons.badgeCheck,
                    size: 14, color: AppColors.emerald700),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Detail helpers ───────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey400),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: AppColors.grey500,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.grey900)),
        ],
      ),
    );
  }
}

// ─── Entry bottom sheet (exported for use in overview tab) ───────────────────
class CompetitionEntrySheet extends ConsumerStatefulWidget {
  final Competition competition;
  final dynamic profile;

  const CompetitionEntrySheet(
      {super.key, required this.competition, required this.profile});

  @override
  ConsumerState<CompetitionEntrySheet> createState() =>
      _CompetitionEntrySheetState();
}

class _CompetitionEntrySheetState
    extends ConsumerState<CompetitionEntrySheet> {
  String _selectedTee = 'white';
  bool _isSubmitting = false;
  final TextEditingController _mpesaPhoneController = TextEditingController();
  late TextEditingController _handicapController;

  final _teeOptions = ['white', 'yellow', 'blue', 'red'];

  @override
  void initState() {
    super.initState();
    final initialHc = widget.profile?.handicap ?? 0.0;
    _handicapController = TextEditingController(text: initialHc.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _mpesaPhoneController.dispose();
    _handicapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.competition.name,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.grey900,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            widget.competition.formatLabel,
            style:
                const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          // Handicap input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.gauge,
                    size: 18, color: AppColors.grey400),
                const SizedBox(width: 10),
                const Text('Playing Handicap',
                    style: TextStyle(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                SizedBox(
                  width: 80,
                  height: 36,
                  child: TextField(
                    controller: _handicapController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.grey900),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tee Selection',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey700)),
          const SizedBox(height: 10),
          Row(
            children: _teeOptions.map((tee) {
              final selected = _selectedTee == tee;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTee = tee),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.grey900 : AppColors.grey50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.grey900
                            : AppColors.grey200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _teeColorValue(tee),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.grey300, width: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tee[0].toUpperCase() + tee.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : AppColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.competition.entryFee > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.banknote,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Entry fee: ${widget.competition.currency} ${widget.competition.entryFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.grey800,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter M-Pesa Phone Number for STK Push',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mpesaPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. 0712345678',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.emerald500, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isSubmitting ? null : () => _submit(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const LoadingSpinner(size: 24)
                  : Text(
                      widget.competition.entryFee > 0 ? 'Pay & Enter' : 'Confirm Entry',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (widget.competition.entryFee > 0 && _mpesaPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your M-Pesa phone number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final hc = double.tryParse(_handicapController.text) ?? widget.profile?.handicap ?? 0.0;
    final success = await ref
        .read(competitionActionsProvider.notifier)
        .enterCompetition(
          competitionId: widget.competition.id,
          playingHandicap: hc,
          entryFee: widget.competition.entryFee,
          mpesaPhone: _mpesaPhoneController.text.trim(),
          teeColor: _selectedTee,
        );
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Entry submitted! Awaiting club confirmation.'
              : 'Failed to submit entry. Please try again.'),
          backgroundColor: success ? AppColors.emerald700 : Colors.red,
        ),
      );
    }
  }

  Color _teeColorValue(String color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.yellow.shade700;
      case 'blue':
        return Colors.blue;
      case 'black':
        return Colors.black87;
      default:
        return Colors.grey.shade400;
    }
  }
}


