import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audio_source_utils.dart';
import '../../core/cloud/groq_service.dart';
import '../../core/services/ai_caddie_service.dart';
import '../../widgets/voice_orb_visualizer.dart';
import '../../providers/app_providers.dart';
import '../../widgets/top_notification.dart';

class CaddieOrbScreen extends ConsumerStatefulWidget {
  final String? preselectedClub;
  final Function(Map<String, dynamic> shot) onShotSaved;

  const CaddieOrbScreen({
    super.key,
    this.preselectedClub,
    required this.onShotSaved,
  });

  @override
  ConsumerState<CaddieOrbScreen> createState() => _CaddieOrbScreenState();
}

class _CaddieOrbScreenState extends ConsumerState<CaddieOrbScreen> {
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

      setState(() {
        _orbState = OrbState.listening;
        _caddieFeedback = null;
        _extractedShot = null;
      });
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
      final transcript = await GroqShotService.transcribe(File(path));
      final shotData = await GroqShotService.extractShot(transcript);
      
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
        TopNotification.showError(context, 'Daniel: Connection issue. Try again.');
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
      case OrbState.idle: return _caddieFeedback != null ? 'Ready for next shot' : 'Tap to speak';
      case OrbState.listening: return 'Listening...';
      case OrbState.speaking: return 'Daniel Speaking';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background iOS-style Dark Blur
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.5,
                  colors: [Color(0xFF0F1A0F), Color(0xFF050505), Colors.black],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildIOSHeader(),
                  const Spacer(),
                  
                  // THE ORB (Siri Style)
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
                      size: 260,
                      audioLevel: _audioLevel,
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // IOS Style Status Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText.toUpperCase(),
                      key: ValueKey(_statusText),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  if (_caddieFeedback != null && !_isProcessing) _buildDanielFeedbackCard(),

                  const Spacer(),
                  
                  if (_orbState == OrbState.idle && _extractedShot != null) 
                    _buildIOSActionArea(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronDown, color: Colors.white54, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'DANIEL AI CADDIE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          _buildVoiceToggle(),
        ],
      ),
    );
  }

  Widget _buildVoiceToggle() {
    return GestureDetector(
      onTap: () {
        setState(() => _voiceEnabled = !_voiceEnabled);
        AICaddieService.setVoiceEnabled(_voiceEnabled);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _voiceEnabled ? AppColors.golfLime.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _voiceEnabled ? AppColors.golfLime.withValues(alpha: 0.3) : Colors.white12),
        ),
        child: Row(
          children: [
            Icon(_voiceEnabled ? LucideIcons.volume2 : LucideIcons.volumeX, size: 16, color: _voiceEnabled ? AppColors.golfLime : Colors.white38),
            const SizedBox(width: 8),
            Text(
              _voiceEnabled ? 'VOICE ON' : 'TEXT ONLY',
              style: TextStyle(
                color: _voiceEnabled ? AppColors.golfLime : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDanielFeedbackCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              '"$_caddieFeedback"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMiniPill('CLUB', _extractedShot?['club']?.toString().toUpperCase() ?? '—'),
                const SizedBox(width: 12),
                _buildMiniPill('DIST', '${_extractedShot?['distance'] ?? '—'}Y'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 8, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildIOSActionArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              color: AppColors.golfLime,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(vertical: 20),
              onPressed: () {
                widget.onShotSaved(_extractedShot!);
                setState(() {
                  _extractedShot = null;
                  _caddieFeedback = null;
                });
                HapticFeedback.mediumImpact();
              },
              child: const Text('Save Shot', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(20),
            onPressed: () => setState(() {
              _extractedShot = null;
              _caddieFeedback = null;
              _orbState = OrbState.idle;
            }),
            child: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ignore_for_file: experimental_member_use
