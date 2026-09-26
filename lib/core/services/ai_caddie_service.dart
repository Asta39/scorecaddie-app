import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// What Daniel made of one spoken shot.
class DanielShotResult {
  final String transcript;
  final Map<String, dynamic> shot;
  final String feedback;

  const DanielShotResult({required this.transcript, required this.shot, required this.feedback});
}

/// Daniel, the voice caddie.
///
/// Speech-to-text, shot extraction, coaching and Daniel's voice all run in
/// the `voice-coach` edge function, which holds the Groq and ElevenLabs keys.
/// They used to be called straight from the app with keys bundled in the
/// APK, where anyone could extract them.
class AICaddieService {
  static const _function = 'voice-coach';
  static const _prefVoiceKey = 'caddie_voice_enabled';

  static SupabaseClient get _client => Supabase.instance.client;

  /// Recording in, shot data and Daniel's reply out.
  static Future<DanielShotResult> logShot(
    File recording, {
    List<Map<String, dynamic>> recentShots = const [],
  }) async {
    final bytes = await recording.readAsBytes();
    final res = await _invoke({
      'task': 'log_shot',
      'audio_base64': base64Encode(bytes),
      'recent_shots': recentShots,
    });
    return DanielShotResult(
      transcript: res['transcript'] as String? ?? '',
      shot: Map<String, dynamic>.from(res['shot'] as Map? ?? const {}),
      feedback: res['feedback'] as String? ?? '',
    );
  }

  /// Daniel's reply as mp3 audio.
  static Future<Uint8List> textToSpeech(String text) async {
    final res = await _invoke({'task': 'speak', 'text': text});
    return base64Decode(res['audio_base64'] as String);
  }

  static Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final res = await _client.functions.invoke(_function, body: body);
      return Map<String, dynamic>.from(res.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error'] : null;
      throw Exception(message ?? 'Daniel is quiet right now');
    }
  }

  static Future<bool> isVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefVoiceKey) ?? true;
  }

  static Future<void> setVoiceEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVoiceKey, enabled);
  }
}
