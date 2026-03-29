import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/highlights/practice_highlight_card_widget.dart';
import '../../core/services/highlight_card_service.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import '../../core/utils/unit_formatter.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final int sessionId;

  const SessionSummaryScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Session Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => context.go('/practice'),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadSummaryData(db),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!;
          final session = data['session'] as PracticeSession;
          final shots = data['shots'] as List<PracticeShot>;
          final drill = data['drill'] as Drill?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(session, drill),
                const SizedBox(height: 32),
                const Text('QUALITY BREAKDOWN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.grey500)),
                const SizedBox(height: 16),
                _buildQualityGrid(shots),
                const SizedBox(height: 32),
                const Text('CLUB PERFORMANCE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.grey500)),
                const SizedBox(height: 16),
                _buildClubList(data['clubStats'] as List<Map<String, dynamic>>),
                const SizedBox(height: 32),
                
                if (shots.any((s) => s.videoUrl != null)) ...[
                  const Text('RECORDED SWINGS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.grey500)),
                  const SizedBox(height: 16),
                  _buildVideoGallery(context, shots.where((s) => s.videoUrl != null).toList(), data['clubs'] as List<Club>, ref),
                  const SizedBox(height: 32),
                ],
                
                _buildFocusArea(data['insights'] as String),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareHighlight(context, ref, session, shots, drill, data['clubs'] as List<Club>),
                    icon: const Icon(LucideIcons.share2),
                    label: const Text('Share Highlight Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey900,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadSummaryData(AppDatabase db) async {
    debugPrint('SUMMARY: Loading data for sessionId: $sessionId');
    final session = await (db.select(db.practiceSessions)..where((s) => s.id.equals(sessionId))).get().then((list) => list.first);
    final shots = await (db.select(db.practiceShots)..where((s) => s.sessionId.equals(sessionId))).get();
    
    debugPrint('SUMMARY: Found ${shots.length} shots for session $sessionId');
    
    Drill? drill;
    if (session.drillId != null) {
      drill = await (db.select(db.drills)..where((d) => d.id.equals(session.drillId!))).get().then((rows) => rows.firstOrNull);
    }

    // Calculate quality breakdown
    final Map<String, int> counts = {'GREAT': 0, 'GOOD': 0, 'OKAY': 0, 'MISS': 0};
    for (var s in shots) {
      if (s.quality != null) counts[s.quality!] = (counts[s.quality!] ?? 0) + 1;
    }

    // Club stats
    final Map<int, List<String>> clubQualities = {};
    for (var s in shots) {
      clubQualities.putIfAbsent(s.clubId, () => []).add(s.quality ?? 'OKAY');
    }

    final List<Map<String, dynamic>> clubStats = [];
    final clubs = await db.select(db.clubs).get();
    for (var clubId in clubQualities.keys) {
      final clubList = clubs.where((c) => c.id == clubId).toList();
      final clubName = clubList.isNotEmpty ? clubList.first.type : 'Unknown Club';
      final qs = clubQualities[clubId]!;
      final greatPct = (qs.where((q) => q == 'GREAT').length / qs.length * 100).round();
      clubStats.add({
        'name': clubName,
        'count': qs.length,
        'greatPct': greatPct,
      });
    }

    final insights = _generateInsights(shots, clubStats);

    return {
      'session': session,
      'shots': shots,
      'drill': drill,
      'counts': counts,
      'clubStats': clubStats,
      'clubs': clubs,
      'insights': insights,
    };
  }

  String _generateInsights(List<PracticeShot> shots, List<Map<String, dynamic>> clubStats) {
    if (shots.isEmpty) return 'No shots recorded. Start hitting to get AI insights!';

    final totalShots = shots.length;
    final successShots = shots.where((s) => s.quality == 'GREAT' || s.quality == 'GOOD').length;
    final successPct = (successShots / totalShots * 100).round();

    String mainNote = '';
    if (successPct >= 75) {
      mainNote = 'Outstanding consistency! You hit $successPct% quality shots today.';
    } else if (successPct >= 50) {
      mainNote = 'Solid session. You were locked in for $successPct% of your shots.';
    } else {
      mainNote = 'A bit inconsistent today ($successPct%). Focus on your setup and tempo.';
    }

    // Find best/worst club
    if (clubStats.isNotEmpty) {
      clubStats.sort((a, b) => (b['greatPct'] as int).compareTo(a['greatPct'] as int));
      final bestClub = clubStats.first;
      final worstClub = clubStats.last;

      if (bestClub['count'] >= 3 && (bestClub['greatPct'] as int) > 60) {
        mainNote += ' Your ${bestClub['name']} was pure today.';
      }
      
      if (worstClub['count'] >= 3 && (worstClub['greatPct'] as int) < 40) {
        mainNote += ' Your ${worstClub['name']} needs some attention in the next session.';
      }
    }

    // Advice based on drill
    mainNote += ' Keep grinding!';
    
    return mainNote;
  }

  Widget _buildVideoGallery(BuildContext context, List<PracticeShot> videoShots, List<Club> clubs, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider);
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: videoShots.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final shot = videoShots[index];
          final clubList = clubs.where((c) => c.id == shot.clubId).toList();
          final clubName = clubList.isNotEmpty ? clubList.first.type : 'Unknown';
          
          return GestureDetector(
            onTap: () => _showVideoPlayer(context, shot.videoUrl!),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(shot.quality == 'GREAT' ? LucideIcons.sparkles : LucideIcons.play, color: Colors.white.withValues(alpha: 0.5), size: 32)),
                  const Center(child: Icon(LucideIcons.playCircle, color: Colors.white, size: 24)),
                  Positioned(
                    bottom: 8, left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clubName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text(formatter.formatDistance(shot.distance ?? 0), style: const TextStyle(color: Colors.white70, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => _VideoPlayerModal(url: url),
    );
  }

  Widget _buildHeader(PracticeSession session, Drill? drill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          drill?.name ?? '${session.sessionType} Session',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.calendar, size: 14, color: AppColors.grey500),
            const SizedBox(width: 4),
            Text(
              '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}',
              style: TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.target, size: 14, color: AppColors.grey500),
            const SizedBox(width: 4),
            Text(
              '${session.totalBalls} Balls',
              style: TextStyle(color: AppColors.grey500, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityGrid(List<PracticeShot> shots) {
    if (shots.isEmpty) return const SizedBox();
    final Map<String, int> counts = {'GREAT': 0, 'GOOD': 0, 'OKAY': 0, 'MISS': 0};
    for (var s in shots) {
      if (s.quality != null) counts[s.quality!] = (counts[s.quality!] ?? 0) + 1;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildQualityCard('GREAT', counts['GREAT']!, AppColors.emerald500),
        _buildQualityCard('GOOD', counts['GOOD']!, AppColors.birdie),
        _buildQualityCard('OKAY', counts['OKAY']!, AppColors.bogey),
        _buildQualityCard('MISS', counts['MISS']!, AppColors.doubleBogey),
      ],
    );
  }

  Widget _buildQualityCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          const Spacer(),
          Text('$count', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildClubList(List<Map<String, dynamic>> clubStats) {
    return Column(
      children: clubStats.map((stat) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              child: const Icon(LucideIcons.utilityPole, size: 16, color: AppColors.grey600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${stat['count']} balls hit', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${stat['greatPct']}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald600)),
                const Text('Greatness', style: TextStyle(fontSize: 10, color: AppColors.grey500)),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _shareHighlight(BuildContext context, WidgetRef ref, PracticeSession session, List<PracticeShot> shots, Drill? drill, List<Club> clubs) {
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
            const Text('Generate a professional summary of your practice session.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500)),
            const SizedBox(height: 24),
            
            // Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 240,
                height: 426, // 1080x1920 scaled down
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Screenshot(
                    controller: service.controller,
                    child: PracticeHighlightCardWidget(
                      session: session,
                      shots: shots,
                      drill: drill,
                      userName: user?.displayName ?? 'GOLFER',
                      clubs: clubs,
                      formatter: ref.read(unitFormatterProvider),
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
                  backgroundColor: AppColors.golfLime,
                  foregroundColor: AppColors.grey900,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  service.shareHighlight(
                    cardWidget: PracticeHighlightCardWidget(
                      session: session,
                      shots: shots,
                      drill: drill,
                      userName: user?.displayName ?? 'GOLFER',
                      clubs: clubs,
                      formatter: ref.read(unitFormatterProvider),
                    ),
                    context: context,
                    text: 'Just finished a ${drill?.name ?? 'practice'} session on ScoreCaddie! 🏌️‍♂️⛳ #GolfLife #ScoreCaddie',
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

  Widget _buildFocusArea(String insightText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.birdie.withValues(alpha: 0.1), AppColors.emerald500.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.birdie.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppColors.birdie, size: 20),
              SizedBox(width: 8),
              Text('AI INSIGHTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insightText,
            style: const TextStyle(color: AppColors.grey700, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerModal extends StatefulWidget {
  final String url;
  const _VideoPlayerModal({required this.url});

  @override
  State<_VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<_VideoPlayerModal> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _initialized = true);
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Stack(
        children: [
          if (_initialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          Positioned(
            top: 16, right: 16,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white, size: 32,
                  ),
                  onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
