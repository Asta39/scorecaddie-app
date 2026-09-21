import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final String supabaseUrl = dotenv.get('SUPABASE_URL', fallback: 'https://placeholder.supabase.co');
  static final String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: 'placeholder_key');
  static final String groqApiKey = dotenv.get('GROQ_API_KEY', fallback: '');
  static final String elevenLabsApiKey = dotenv.get('ELEVENLABS_API_KEY', fallback: '');
  // Gemini now runs server-side (supabase/functions/ai-generate). Never add
  // third-party API keys here: everything in .env ships inside the APK.

  static const bool isDebug = true;
}
