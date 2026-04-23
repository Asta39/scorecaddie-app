import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../widgets/highlights/highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import 'package:screenshot/screenshot.dart';

class RoundDetailScreen extends ConsumerWidget {
  final int roundId;

  const RoundDetailScreen({super.key, required this.roundId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundAsync = ref.watch(singleRoundProvider(roundId));
    final scoresAsync = ref.watch(holeScoresProvider(roundId));

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Round Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: AppColors.white,
        scrolledUnderElevation: 0,
        actions: [
          roundAsync.when(
            data: (round) => scoresAsync.when(
              data: (scores) => IconButton(
                icon: const Icon(LucideIcons.share2, color: AppColors.emerald700),
                onPressed: () => _shareRoundHighlight(context, ref, round, scores),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: roundAsync.when(
        data: (round) => scoresAsync.when(
          data: (scores) => _buildBody(context, round, scores),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Round round, List<HoleScore> scores) {
    if (scores.isEmpty) return const Center(child: Text('No scores recorded.'));

    final DateFormat formatter = DateFormat('MMMM d, yyyy • h:mm a');
    final String formattedDate = formatter.format(round.playedAt);

    // Calculate advanced stats totals
    int totalPutts = 0;
    int totalPenalties = 0;
    int fairwaysHit = 0;
    int fairwaysPossible = 0;

    for (final s in scores) {
      if (s.putts != null) totalPutts += s.putts!;
      if (s.penalties != null) totalPenalties += s.penalties!;
      if (s.fairwayHit != null) {
        fairwaysPossible++;
        if (s.fairwayHit == 'Hit') fairwaysHit++;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(round.courseName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(formattedDate, style: const TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatBox('SCORE', round.totalScore.toString(), color: AppColors.grey900),
                    _buildStatBox('TO PAR', (round.totalScore - round.coursePar) == 0 ? 'E' : (round.totalScore - round.coursePar) > 0 ? '+${round.totalScore - round.coursePar}' : '${round.totalScore - round.coursePar}', color: _getScoreColor(round.totalScore - round.coursePar)),
                    _buildStatBox('HOLES', round.holesPlayed == -9 ? 'Back 9' : round.holesPlayed.toString()),
                  ],
                ),
                
                if (totalPutts > 0 || fairwaysPossible > 0) ...[
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.grey200),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (totalPutts > 0) _buildStatBox('PUTTS', '$totalPutts'),
                      if (fairwaysPossible > 0) _buildStatBox('FAIRWAYS', '$fairwaysHit/$fairwaysPossible'),
                      if (totalPenalties > 0) _buildStatBox('PENALTIES', '$totalPenalties', color: AppColors.doubleBogey),
                    ],
                  ),
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Scorecard Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Scorecard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.grey900)),
          ),
          const SizedBox(height: 12),
          
          // Scorecard DataTables
          _buildScorecardTables(scores, round),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, {Color color = AppColors.grey900}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.grey500, letterSpacing: 1)),
      ],
    );
  }

  Color _getScoreColor(int scoreVsPar) {
    if (scoreVsPar < 0) return AppColors.birdie;
    if (scoreVsPar > 0) return AppColors.bogey;
    return AppColors.par;
  }

  Widget _buildScorecardTables(List<HoleScore> scores, Round round) {
    final bool hasFront9 = scores.any((s) => s.holeNumber <= 9);
    final bool hasBack9 = scores.any((s) => s.holeNumber > 9);
    bool tracksPutts = scores.any((s) => s.putts != null);
    bool tracksFairway = scores.any((s) => s.fairwayHit != null);
    
    List<Widget> tables = [];
    
    if (hasFront9) {
      final front9 = scores.where((s) => s.holeNumber <= 9).toList();
      tables.add(_buildHalfTable('FRONT 9', front9, tracksPutts, tracksFairway));
    }
    
    if (hasBack9) {
      final back9 = scores.where((s) => s.holeNumber > 9).toList();
      tables.add(_buildHalfTable('BACK 9', back9, tracksPutts, tracksFairway));
    }
    
    return Column(children: tables);
  }
  
  Widget _buildHalfTable(String title, List<HoleScore> scores, bool tracksPutts, bool tracksFairway) {
    int parTotal = scores.fold(0, (sum, item) => sum + item.par);
    int scoreTotal = scores.fold(0, (sum, item) => sum + item.score);
    int puttsTotal = scores.fold(0, (sum, item) => sum + (item.putts ?? 0));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 48,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          columns: [
            DataColumn(label: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
            for (var s in scores) DataColumn(label: Text('${s.holeNumber}', style: const TextStyle(fontWeight: FontWeight.w700))),
            const DataColumn(label: Text('TOT', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: [
            DataRow(cells: [
              const DataCell(Text('Par', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600))),
              for (var s in scores) DataCell(Text('${s.par}', style: const TextStyle(color: AppColors.grey500))),
              DataCell(Text('$parTotal', style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            DataRow(cells: [
              const DataCell(Text('Score', style: TextStyle(fontWeight: FontWeight.w700))),
              for (var s in scores) DataCell(_scoreText(s.score, s.par)),
              DataCell(Text('$scoreTotal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            if (tracksPutts)
              DataRow(cells: [
                const DataCell(Text('Putts', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600))),
                for (var s in scores) DataCell(Text(s.putts?.toString() ?? '-', style: const TextStyle(color: AppColors.grey700))),
                DataCell(Text('$puttsTotal', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            if (tracksFairway)
              DataRow(cells: [
                const DataCell(Text('Fairway', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w600))),
                for (var s in scores) DataCell(_fairwayWidget(s.fairwayHit)),
                const DataCell(Text('-')),
              ]),
          ],
        ),
      ),
    );
  }
  
  Widget _scoreText(int score, int par) {
    final diff = score - par;
    Color c = AppColors.grey900;
    if (diff < 0) c = AppColors.birdie;
    if (diff > 0) c = diff > 1 ? AppColors.doubleBogey : AppColors.bogey;
    
    return Text('$score', style: TextStyle(fontWeight: FontWeight.w800, color: c, fontSize: 16));
  }
  
  Widget _fairwayWidget(String? hit) {
    if (hit == null) return const Text('-');
    if (hit == 'Hit') return const Icon(LucideIcons.checkCircle2, color: AppColors.emerald700, size: 18);
    if (hit == 'Left') return const Icon(LucideIcons.arrowDownLeft, color: AppColors.bogey, size: 18);
    if (hit == 'Right') return const Icon(LucideIcons.arrowDownRight, color: AppColors.bogey, size: 18);
    return Text(hit, style: const TextStyle(fontSize: 12));
  }

  void _shareRoundHighlight(BuildContext context, WidgetRef ref, Round round, List<HoleScore> scores) {
    final user = ref.read(authStateProvider).valueOrNull;
    final service = ref.read(highlightCardServiceProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share Highlight Card', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 8),
            const Text('Generate a beautiful summary of your round to share with friends.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500)),
            const SizedBox(height: 24),
            
            // Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 240,
                height: 300,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Screenshot(
                    controller: service.controller,
                    child: HighlightCardWidget(
                      round: round,
                      holeScores: scores,
                      userName: user?.displayName ?? 'GOLFER',
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(LucideIcons.share2),
                label: const Text('Share to Social Media', style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald700,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  service.shareHighlight(
                    cardWidget: HighlightCardWidget(
                      round: round,
                      holeScores: scores,
                      userName: user?.displayName ?? 'GOLFER',
                    ),
                    context: context,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: AppColors.grey500, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
