import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../database/database.dart' hide Provider;

class PracticeAnalysisService {
  final String _apiKey;

  PracticeAnalysisService(this._apiKey);

  Future<String> analyzeSession({
    required PracticeSession session,
    required List<PracticeShot> shots,
    required List<Map<String, dynamic>> clubStats,
    Drill? drill,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    final statsSummary = clubStats.map((s) => 
      "${s['name']}: ${s['count']} shots, ${s['successPct']}% quality. Avg Distance: ${s['avgDist']}y. Common Shape: ${s['commonShape']}"
    ).join('\n');

    final prompt = '''
      You are Daniel, an elite AI Golf Caddie and Data Analyst. Analyze this player's practice session data and provide sharp, professional insights.

      SESSION TYPE: ${drill?.name ?? session.sessionType}
      TOTAL BALLS: ${session.totalBalls}
      
      CLUB PERFORMANCE DATA:
      $statsSummary

      INSTRUCTIONS:
      1. Provide a "Session Verdict" (1 concise sentence).
      2. Identify the "Struggling Club" if any, and why based on data.
      3. Identify the "Pure Club" of the session.
      4. Give one specific biomechanical tip or drill adjustment for the next session.
      5. Use the "Golf Brain" knowledge: Irons need descending blows, Woods need sweeping.
      6. Keep it encouraging but data-driven and elite.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Solid grind today. Your data shows consistency, keep focus on the target.';
    } catch (e) {
      return 'Session analysis unavailable, but the numbers don\'t lie: keep grinding on that tempo.';
    }
  }

  Future<String> analyzePerformance({
    required String playerName,
    required dynamic stats,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    final prompt = '''
      You are Daniel, an elite AI Golf Caddie and Data Analyst. 
      Analyze this player's recent performance trends and provide sharp, professional insights.

      PLAYER: $playerName
      ROUNDS PLAYED: ${stats.roundsPlayed}
      FAIRWAY HIT %: ${stats.fairwayHitPercentage.toInt()}%
      GIR %: ${stats.greensInRegulationPercentage.toInt()}%
      PUTTS PER ROUND: ${stats.puttsPerRound.toStringAsFixed(1)}
      SCORE TREND: ${stats.scoreTrend?.toStringAsFixed(1) ?? 'Stable'}

      INSTRUCTIONS:
      1. Start with a direct address: "$playerName, ..."
      2. Provide a 2-3 sentence high-level analysis of their game.
      3. Identify their biggest strength from the data.
      4. Give one specific "Pro Tip" to lower their scores next week.
      5. Tone: Elite, data-driven, encouraging, and sharp.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Insights unavailable. Keep up the grind.';
    } catch (e) {
      debugPrint('AI_PERFORMANCE_ERROR: $e');
      return 'Performance analysis offline. The data shows potential—keep focusing on your tempo.';
    }
  }
}

final practiceAnalysisServiceProvider = Provider((ref) {
  return PracticeAnalysisService(AppConfig.geminiApiKey);
});
