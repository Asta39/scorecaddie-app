import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../onboarding/ob_style.dart';
import '../onboarding/ob_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/utils/audio_source_utils.dart';
import '../../core/services/ai_caddie_service.dart';
import '../../widgets/voice_orb_visualizer.dart';
import '../../widgets/voice_beam.dart';
import '../../widgets/voice_mic_button.dart';
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
          // Speech sits roughly between -50 and -10 dBFS; below that is room noise.
          _audioLevel = ((amp.current + 50) / 40).clamp(0.0, 1.0);
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
      // Transcribe, extract and coach in one server call.
      final result = await AICaddieService.logShot(File(path));
      final shotData = result.shot;
      final feedback = result.feedback;

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
      value: Ob.overlay,
      child: Scaffold(
        backgroundColor: Ob.bg,
        body: DefaultTextStyle(
          style: Ob.textBase,
          child: Stack(
            children: [
              // Voice glow along the bottom edge, for both the player and Daniel.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 300,
                child: IgnorePointer(child: VoiceBeam(state: _orbState, level: _audioLevel)),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(children: [
                        ObIconButton(icon: LucideIcons.chevronDown, label: 'Close', onPressed: () => Navigator.pop(context)),
                        Expanded(child: Text('Daniel', textAlign: TextAlign.center, style: Ob.body(17, weight: FontWeight.w600))),
                        _buildVoiceToggle(),
                      ]),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: _orbState == OrbState.listening ? 'Stop and send' : 'Speak to Daniel',
                      child: GestureDetector(
                        onTap: () {
                          if (_orbState == OrbState.idle) {
                            _startListening();
                          } else if (_orbState == OrbState.listening) {
                            _stopAndProcess();
                          }
                        },
                        child: VoiceMicButton(state: _orbState),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(_statusText, style: Ob.body(15, color: Ob.creamA(.6))),
                    const SizedBox(height: 28),
                    if (_caddieFeedback != null && !_isProcessing) _buildDanielFeedbackCard(),
                    const Spacer(),
                    if (_orbState == OrbState.idle && _extractedShot != null) _buildIOSActionArea(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceToggle() {
    return Semantics(
      button: true,
      label: _voiceEnabled ? 'Daniel speaks out loud. Turn off' : 'Daniel replies in text. Turn voice on',
      child: GestureDetector(
        onTap: () {
          setState(() => _voiceEnabled = !_voiceEnabled);
          AICaddieService.setVoiceEnabled(_voiceEnabled);
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Ob.field, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_voiceEnabled ? LucideIcons.volume2 : LucideIcons.volumeX, size: 16, color: _voiceEnabled ? Ob.lime : Ob.creamA(.6)),
            const SizedBox(width: 6),
            Text(_voiceEnabled ? 'Voice' : 'Text', style: Ob.body(14, weight: FontWeight.w600, color: _voiceEnabled ? Ob.lime : Ob.creamA(.6))),
          ]),
        ),
      ),
    );
  }

  Widget _buildDanielFeedbackCard() {
    final club = _extractedShot?['club']?.toString();
    final dist = _extractedShot?['distance'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(16)),
          child: Text(_caddieFeedback!, style: Ob.body(17, height: 1.4)),
        ),
        if (club != null || dist != null) ...[
          const SizedBox(height: 12),
          ObGroup(children: [
            if (club != null) ObRow('Club', value: club),
            if (dist != null) ObRow('Distance', value: '$dist yd'),
          ]),
        ],
      ]),
    );
  }

  Widget _buildIOSActionArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: ObButton(
            height: 54,
            radius: 14,
            onPressed: () {
              widget.onShotSaved(_extractedShot!);
              setState(() {
                _extractedShot = null;
                _caddieFeedback = null;
              });
              HapticFeedback.mediumImpact();
            },
            child: Text('Save shot', style: Ob.label(17)),
          ),
        ),
        const SizedBox(width: 10),
        ObIconButton(
          icon: LucideIcons.refreshCw,
          label: 'Discard and try again',
          size: 54,
          onPressed: () => setState(() {
            _extractedShot = null;
            _caddieFeedback = null;
            _orbState = OrbState.idle;
          }),
        ),
      ]),
    );
  }
}

// ignore_for_file: experimental_member_use
