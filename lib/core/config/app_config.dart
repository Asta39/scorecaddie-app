import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static final String supabaseUrl = dotenv.get('SUPABASE_URL');
  static final String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY');
  static final String groqApiKey = dotenv.get('GROQ_API_KEY');
  static final String elevenLabsApiKey = dotenv.get('ELEVENLABS_API_KEY');
  static final String geminiApiKey = dotenv.get('GEMINI_API_KEY');

  static const bool isDebug = true;
}
