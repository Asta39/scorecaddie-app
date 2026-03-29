import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_analyzer_service.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import 'widgets/swing_coach_bot.dart';

class ShotSummaryScreen extends ConsumerStatefulWidget {
  final AIShotAnalysis analysis;
  final String videoPath;
  final int clubId;

  final int? shotId;
  final int? sessionId;

  const ShotSummaryScreen({
    super.key,
    required this.analysis,
    required this.videoPath,
    required this.clubId,
    this.shotId,
    this.sessionId,
  });

  @override
  ConsumerState<ShotSummaryScreen> createState() => _ShotSummaryScreenState();
}

class _ShotSummaryScreenState extends ConsumerState<ShotSummaryScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _videoController.setLooping(true);
        _videoController.play();
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('SHOT SUMMARY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
        leading: IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildVideoTraceSection(),
            _buildStatsGrid(),
            _buildBiomechanicsSection(),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Divider(),
            ),
            _buildActionButtons(),
            const SizedBox(height: 20),
            SwingCoachBot(analysis: widget.analysis),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTraceSection() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isInitialized) VideoPlayer(_videoController),
          // Trace Overlay (Simplified representation)
          CustomPaint(
            painter: TrajectoryPainter(trajectory: widget.analysis.trajectory),
            size: const Size(double.infinity, 250),
          ),
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.golfLime, borderRadius: BorderRadius.circular(12)),
              child: Text(widget.analysis.swingQuality, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.grey900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('CARRY', '${widget.analysis.carry.toInt()}y', LucideIcons.wind),
              const SizedBox(width: 12),
              _buildStatCard('TOTAL', '${widget.analysis.totalDistance.toInt()}y', LucideIcons.map),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('BALL SPEED', '${widget.analysis.ballSpeed.toInt()} mph', LucideIcons.zap),
              const SizedBox(width: 12),
              _buildStatCard('LAUNCH', '${widget.analysis.launchAngle.toStringAsFixed(1)}°', LucideIcons.arrowUpRight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppColors.grey400),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.grey900)),
          ],
        ),
      ),
    );
  }
  Widget _buildBiomechanicsSection() {
    final metrics = widget.analysis.poseMetrics;
    if (metrics == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BIOMECHANICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.grey400, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricTile('HEAD STABILITY', '${((metrics['headStability'] as double) * 100).round()}%', LucideIcons.focus),
              const SizedBox(width: 12),
              _buildMetricTile('SHOULDER TURN', '${(metrics['shoulderTurn'] as double).round()}°', LucideIcons.refreshCw),
              const SizedBox(width: 12),
              _buildMetricTile('SPINE ANGLE', '${(metrics['spineAngle'] as double).round()}°', LucideIcons.accessibility),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey100),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppColors.emerald700),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grey900)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: AppColors.grey400)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(), // Back to AI Analysis
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Next Shot', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          if (widget.sessionId != null)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _endSession(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grey900,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('End Session', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _endSession() async {
    if (widget.sessionId == null) return;
    
    final db = ref.read(databaseProvider);
    await (db.update(db.practiceSessions)..where((s) => s.id.equals(widget.sessionId!)))
        .write(PracticeSessionsCompanion(endTime: drift.Value(DateTime.now())));
        
    if (mounted) {
      context.pushReplacement('/practice/summary/${widget.sessionId}');
    }
  }
}

class TrajectoryPainter extends CustomPainter {
  final List<Offset> trajectory;
  TrajectoryPainter({required this.trajectory});

  @override
  void paint(Canvas canvas, Size size) {
    if (trajectory.isEmpty) return;
    
    final paint = Paint()
      ..color = AppColors.golfLime.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Normalize and scale trajectory points to screen size
    final startX = size.width * 0.2;
    final startY = size.height * 0.8;
    
    path.moveTo(startX, startY);
    
    for (var point in trajectory) {
      // Very simplified mapping
      final px = startX + (point.dx * 2.0);
      final py = startY - (point.dy * 2.5);
      if (px < size.width && py > 0) {
        path.lineTo(px, py);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw ball at end
    final endPoint = trajectory.last;
    final endX = startX + (endPoint.dx * 2.0);
    final endY = startY - (endPoint.dy * 2.5);
    if (endX < size.width && endY > 0) {
      canvas.drawCircle(Offset(endX, endY), 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
