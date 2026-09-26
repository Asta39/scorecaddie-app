import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final String supabaseUrl = dotenv.get('SUPABASE_URL', fallback: 'https://placeholder.supabase.co');
  static final String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: 'placeholder_key');
  // Gemini (supabase/functions/ai-generate) and Daniel's Groq/ElevenLabs
  // calls (supabase/functions/voice-coach) run server-side. Never add
  // third-party API keys here: everything in .env ships inside the APK.

  static const bool isDebug = true;
}
