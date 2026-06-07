import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_source_utils.dart';
import '../../core/cloud/groq_service.dart';
import '../../core/services/ai_caddie_service.dart';
import '../../widgets/voice_orb_visualizer.dart';
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';

class VoiceLoggerScreen extends ConsumerStatefulWidget {
  final String? preselectedClub;
  final Function(Map<String, dynamic> shot) onShotSaved;

  const VoiceLoggerScreen({
    super.key,
    this.preselectedClub,
    required this.onShotSaved,
  });

  @override
  ConsumerState<VoiceLoggerScreen> createState() => _VoiceLoggerScreenState();
}

class _VoiceLoggerScreenState extends ConsumerState<VoiceLoggerScreen> {
  final _recorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  
  OrbState _orbState = OrbState.idle;
  double _audioLevel = 0.0;
  StreamSubscription? _amplitudeSub;
  
  Map<String, dynamic>? _extractedShot;
  String? _caddieFeedback;
  bool _voiceEnabled = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadVoicePref();
  }

  Future<void> _loadVoicePref() async {
    _voiceEnabled = await AICaddieService.isVoiceEnabled();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (await _recorder.hasPermission()) {
      HapticFeedback.heavyImpact();
      final dir = Directory.systemTemp;
      final path = '${dir.path}/shot_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      
      _amplitudeSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 40)).listen((amp) {
        setState(() {
          _audioLevel = (amp.current + 60).clamp(0, 60) / 60;
        });
      });

      setState(() => _orbState = OrbState.listening);
    }
  }

  Future<void> _stopAndProcess() async {
    _amplitudeSub?.cancel();
    final path = await _recorder.stop();
    if (path == null) {
      setState(() => _orbState = OrbState.idle);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _orbState = OrbState.thinking;
      _isProcessing = true;
      _audioLevel = 0;
    });

    try {
      // 1. Transcribe & Extract
      final transcript = await GroqShotService.transcribe(File(path));
      final shotData = await GroqShotService.extractShot(transcript);
      
      // 2. Get Caddie Feedback (Daniel)
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile != null) {
        final feedback = await AICaddieService.getCoachingFeedback(
          shot: shotData,
          player: profile,
          recentShots: [], 
        );
        
        setState(() {
          _extractedShot = shotData;
          _caddieFeedback = feedback;
          _isProcessing = false;
        });

        // 3. Speak if enabled
        if (_voiceEnabled) {
          await _speakFeedback(feedback);
        } else {
          setState(() => _orbState = OrbState.idle);
        }
      }
    } catch (e) {
      debugPrint('Caddie Error: $e');
      setState(() {
        _orbState = OrbState.idle;
        _isProcessing = false;
      });
      if (mounted) {
        TopNotification.showError(context, 'Daniel is quiet: $e');
      }
    }
  }

  Future<void> _speakFeedback(String text) async {
    try {
      setState(() => _orbState = OrbState.speaking);
      final bytes = await AICaddieService.textToSpeech(text);
      await _audioPlayer.setAudioSource(BytesAudioSource(bytes));
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);
      setState(() => _orbState = OrbState.idle);
    } catch (e) {
      debugPrint('TTS Error: $e');
      setState(() => _orbState = OrbState.idle);
    }
  }

  String get _statusText {
    if (_isProcessing) return 'Daniel is thinking...';
    switch (_orbState) {
      case OrbState.idle: return _caddieFeedback != null ? 'Tap to log next' : 'Tap to log a shot';
      case OrbState.listening: return 'Listening...';
      case OrbState.speaking: return 'Daniel';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.4,
                colors: [Color(0xFF0A1A0A), Color(0xFF050A05), Color(0xFF020502)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                
                // THE ORB
                GestureDetector(
                  onTap: () {
                    if (_orbState == OrbState.idle) {
                      _startListening();
                    } else if (_orbState == OrbState.listening) {
                      _stopAndProcess();
                    }
                  },
                  child: CaddieOrbWidget(
                    state: _orbState,
                    size: 280,
                    audioLevel: _audioLevel,
                  ),
                ),

                const SizedBox(height: 40),
                
                // Status Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusText,
                    key: ValueKey(_statusText),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_caddieFeedback != null && !_isProcessing) _buildFeedbackCard(),

                const Spacer(),
                
                if (_orbState == OrbState.idle && _extractedShot != null) 
                  _buildBottomActions(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronDown, color: Colors.white54),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          const Text('DANIEL', style: TextStyle(fontFamily: 'monospace', color: Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _voiceEnabled = !_voiceEnabled);
              AICaddieService.setVoiceEnabled(_voiceEnabled);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(_voiceEnabled ? LucideIcons.volume2 : LucideIcons.volumeX, size: 14, color: AppColors.golfLime),
                  const SizedBox(width: 6),
                  Text(_voiceEnabled ? 'VOICE ON' : 'TEXT ONLY', style: TextStyle(color: AppColors.golfLime.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          '"$_caddieFeedback"',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontStyle: FontStyle.italic, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              color: AppColors.golfLime,
              borderRadius: BorderRadius.circular(16),
              onPressed: () {
                widget.onShotSaved(_extractedShot!);
                setState(() {
                  _extractedShot = null;
                  _caddieFeedback = null;
                });
              },
              child: const Text('Save Shot', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: experimental_member_use
