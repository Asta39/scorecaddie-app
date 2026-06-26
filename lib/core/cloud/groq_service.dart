import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GroqShotService {
  static String get _groqApiKey => AppConfig.groqApiKey;
  static const String _whisperUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _chatUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''
You are a golf shot data extractor for a mobile app called Score Caddie, used by golfers on the driving range in Kenya.
Your job is to extract structured shot data from a golfer's voice transcript.
ALWAYS return valid JSON only. No explanation, no preamble, no markdown.

Extract these fields:
- club: normalize to standard names ("driver", "3 wood", "5 wood", "7 wood", "hybrid", "2 iron", "3 iron", "4 iron", "5 iron", "6 iron", "7 iron", "8 iron", "9 iron", "pitching wedge", "gap wedge", "sand wedge", "lob wedge", "putter"). 
- distance: yards as integer. If player says meters, convert (meters * 1.094).
- distance_confidence: "exact" | "approximate" | "unknown"
- shape: "straight", "draw", "fade", "hook", "slice", "push", "pull".
- trajectory: "low", "normal", "high"
- quality: "great" (pure/flushed), "good" (solid), "okay" (not bad), "miss" (fat/thin/shank)
- notes: extra detail, max 10 words.

Example Input: "hit my 7 iron about 150 yards, slight fade"
Example Output: {"club": "7 iron", "distance": 150, "distance_confidence": "approximate", "shape": "fade", "trajectory": null, "quality": null, "notes": null}
''';

  /// Step 1: Voice -> Text
  static Future<String> transcribe(File audioFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl))
      ..headers['Authorization'] = 'Bearer $_groqApiKey'
      ..fields['model'] = 'whisper-large-v3-turbo'
      ..fields['language'] = 'en'
      ..fields['response_format'] = 'text'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path, filename: 'shot.m4a'));

    final streamed = await request.send().timeout(const Duration(seconds: 15));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Whisper error ${streamed.statusCode}: $body');
    }
    return body.trim();
  }

  /// Step 2: Text -> JSON
  static Future<Map<String, dynamic>> extractShot(String transcript) async {
    final response = await http.post(
      Uri.parse(_chatUrl),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'temperature': 0.1,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': transcript},
        ],
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Llama error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final content = decoded['choices'][0]['message']['content'];
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
