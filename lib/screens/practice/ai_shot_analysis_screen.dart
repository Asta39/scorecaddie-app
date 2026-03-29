import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/camera_service.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/services/ai_analyzer_service.dart';

class AIShotAnalysisScreen extends ConsumerStatefulWidget {
  final int? sessionId;
  const AIShotAnalysisScreen({super.key, this.sessionId});

  @override
  ConsumerState<AIShotAnalysisScreen> createState() => _AIShotAnalysisScreenState();
}

class _AIShotAnalysisScreenState extends ConsumerState<AIShotAnalysisScreen> {
  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  int? _selectedClubId;
  List<Club> _clubs = [];
  int? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId;
    _initCamera();
    _loadClubs();
  }

  Future<void> _initCamera() async {
    final camera = ref.read(cameraServiceProvider);
    await camera.initialize();
    if (mounted) setState(() => _isCameraReady = camera.isInitialized);
  }

  Future<void> _loadClubs() async {
    final db = ref.read(databaseProvider);
    final clubs = await db.select(db.clubs).get();
    if (mounted) {
      setState(() {
        _clubs = clubs;
        if (clubs.isNotEmpty) _selectedClubId = clubs.first.id;
      });
    }
  }

  Future<void> _toggleRecording() async {
    final camera = ref.read(cameraServiceProvider);
    if (_isRecording) {
      _recordTimer?.cancel();
      final file = await camera.stopRecording();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isAnalyzing = true;
        });
      }
      
      if (file != null) {
        final analyzer = ref.read(aiAnalyzerServiceProvider);
        final db = ref.read(databaseProvider);
        final user = ref.read(authStateProvider).valueOrNull;
        
        final club = _clubs.firstWhere((c) => c.id == _selectedClubId).type;
        try {
          final result = await analyzer.analyzeShot(File(file.path), club);
          
          debugPrint('AI_SCREEN: Shoulder turn metric: ${result.poseMetrics?['shoulderTurn']}');

          // Validation Rule: Ensure golfer was detected and movement occurred
          if (result.poseMetrics == null || (result.poseMetrics!['shoulderTurn'] ?? 0) < 20) {
             throw VideoValidationException("No swing movement detected. Please align yourself and take a full swing.");
          }

          // Ensure we have a session
          if (_activeSessionId == null && user != null) {
            final firestoreId = const Uuid().v4();
            _activeSessionId = await db.into(db.practiceSessions).insert(
              PracticeSessionsCompanion.insert(
                userId: user.uid,
                firestoreId: drift.Value(firestoreId),
                startTime: drift.Value(DateTime.now()),
                sessionType: drift.Value('AI_ANALYSIS'),
              ),
            );
          }

          // Save Shot to DB
          int? shotId;
          if (_activeSessionId != null) {
            final shotFirestoreId = const Uuid().v4();
            shotId = await db.into(db.practiceShots).insert(
              PracticeShotsCompanion.insert(
                sessionId: _activeSessionId!,
                firestoreId: drift.Value(shotFirestoreId),
                clubId: _selectedClubId!,
                distance: drift.Value(result.totalDistance),
                quality: drift.Value(result.swingQuality),
                poseMetricsJson: drift.Value(jsonEncode(result.poseMetrics)),
                timestamp: drift.Value(DateTime.now()),
              ),
            );
            
            // Increment session ball count
            final session = await (db.select(db.practiceSessions)..where((s) => s.id.equals(_activeSessionId!))).getSingle();
            await (db.update(db.practiceSessions)..where((s) => s.id.equals(_activeSessionId!)))
                .write(PracticeSessionsCompanion(totalBalls: drift.Value(session.totalBalls + 1)));
          }

          if (mounted) {
            context.push('/practice/ai-summary', extra: {
              'analysis': result,
              'videoPath': file.path,
              'clubId': _selectedClubId,
              'shotId': shotId,
              'sessionId': _activeSessionId,
            });
          }
        } on VideoValidationException catch (e) {
          debugPrint('AI_SCREEN: Validation error: ${e.message}');
          if (mounted) _showErrorDialog(e.message);
        } catch (e) {
          debugPrint('AI_SCREEN: General error during analysis: $e');
          if (mounted) _showErrorDialog("Analysis failed. Please try again with a clearer video.");
        } finally {
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _recordSeconds = 0;
            });
          }
        }
      } else {
        setState(() {
          _isAnalyzing = false;
          _recordSeconds = 0;
        });
      }
    } else {
      await camera.startRecording();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _recordSeconds++);
      });
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    final camera = ref.read(cameraServiceProvider);
    if (camera.controller != null) {
       camera.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppColors.white)));
    }

    final camera = ref.read(cameraServiceProvider);
    final controller = camera.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized) 
            LayoutBuilder(
              builder: (context, constraints) {
                var scale = constraints.maxWidth / constraints.maxHeight * controller.value.aspectRatio;
                if (scale < 1) scale = 1 / scale;

                return Transform.scale(
                  scale: scale,
                  child: Center(
                    child: CameraPreview(controller),
                  ),
                );
              },
            ),
          
          // Overlays
          _buildGuidelineOverlay(),
          _buildTopBar(),
          _buildRecordUI(),
          _buildClubSelector(),
          
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.golfLime),
                    const SizedBox(height: 16),
                    Text('ANALYZING SHOT...', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text('Tracking trajectory & metrics', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuidelineOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.user, color: Colors.white24, size: 64),
              const SizedBox(height: 16),
              const Text('ALIGN GOLFER HERE', 
                style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 50, left: 20, right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _isRecording ? AppColors.doubleBogey : Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_isRecording ? 'RECORDING 00:${_recordSeconds.toString().padLeft(2, '0')}' : 'READY', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 40), // spacer
        ],
      ),
    );
  }

  Widget _buildRecordUI() {
    return Positioned(
      bottom: 80, left: 0, right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _toggleRecording,
          child: Column(
            children: [
              Container(
                width: 80, height: 80,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: const BoxDecoration(
                    color: AppColors.doubleBogey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(_isRecording ? 'STOP' : 'PRESS TO RECORD', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubSelector() {
    return Positioned(
      bottom: 200, left: 0, right: 0,
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _clubs.length,
          itemBuilder: (context, index) {
            final club = _clubs[index];
            final isSelected = _selectedClubId == club.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedClubId = club.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.golfLime : Colors.black45,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isSelected ? AppColors.golfLime : Colors.white24, width: 1.5),
                ),
                child: Center(
                  child: Text(club.type, 
                    style: TextStyle(
                      color: isSelected ? AppColors.grey900 : Colors.white70, 
                      fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.grey900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Invalid Recording', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.golfLime, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
