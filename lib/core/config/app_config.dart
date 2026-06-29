import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final String supabaseUrl = dotenv.get('SUPABASE_URL', fallback: 'https://placeholder.supabase.co');
  static final String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: 'placeholder_key');
  static final String groqApiKey = dotenv.get('GROQ_API_KEY', fallback: '');
  static final String elevenLabsApiKey = dotenv.get('ELEVENLABS_API_KEY', fallback: '');
  static final String geminiApiKey = dotenv.get('GEMINI_API_KEY', fallback: '');

  static const bool isDebug = true;
}
