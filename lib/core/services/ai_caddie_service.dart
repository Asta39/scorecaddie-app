import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../database/database.dart' as db;

class AICaddieService {
  static String get _groqApiKey => AppConfig.groqApiKey;
  static String get _elevenLabsKey => AppConfig.elevenLabsApiKey;
  
  static const _caddieVoiceId = 'onwK4e9ZLuTAKqWW03F9'; // Daniel - British, Cool under pressure
  static const _elevenModel = 'eleven_flash_v2_5';
  static const _groqModel = 'llama-3.3-70b-versatile';
  
  static const _groqChatUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _elevenTtsUrl = 'https://api.elevenlabs.io/v1/text-to-speech/$_caddieVoiceId';
  static const _prefVoiceKey = 'caddie_voice_enabled';

  static String _buildSystemPrompt(db.UserProfile player) {
    return '''
You are Daniel — an experienced, sharp-witted golf caddie and coach inside the Score Caddie app.
You are standing on the driving range in Kenya with the player RIGHT NOW, between shots.
You speak with quiet authority. Direct. Knowledgeable. Max 2-3 sentences. 

PLAYER PROFILE:
- Name: ${player.name}
- Handicap: ${player.handicap ?? "unknown"}

YOUR PERSONALITY:
- Name ROOT causes for misses (one fix only).
- Conversational, not textbook. 
- Detect patterns over 3+ shots.
- Use "you", be specific. No generic "well done".

RULES:
- NO markdown, NO bullet points.
- Spoken caddie language.
''';
  }

  static Future<String> getCoachingFeedback({
    required Map<String, dynamic> shot,
    required db.UserProfile player,
    required List<Map<String, dynamic>> recentShots,
  }) async {
    final response = await http.post(
      Uri.parse(_groqChatUrl),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _groqModel,
        'temperature': 0.7,
        'max_tokens': 150,
        'messages': [
          {'role': 'system', 'content': _buildSystemPrompt(player)},
          {'role': 'user', 'content': 'CURRENT SHOT: $shot. RECENT SESSION: $recentShots. Give feedback.'},
        ],
      }),
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) throw Exception('Daniel is quiet right now.');

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  static Future<Uint8List> textToSpeech(String text) async {
    final response = await http.post(
      Uri.parse(_elevenTtsUrl),
      headers: {
        'xi-api-key': _elevenLabsKey,
        'Content-Type': 'application/json',
        'accept': 'audio/mpeg',
      },
      body: jsonEncode({
        'text': text.replaceAll('*', '').replaceAll('_', ''),
        'model_id': _elevenModel,
        'voice_settings': {'stability': 0.5, 'similarity_boost': 0.8},
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) throw Exception('ElevenLabs error');
    return response.bodyBytes;
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
