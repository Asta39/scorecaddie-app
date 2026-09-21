import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database.dart' hide Provider;

/// AI practice and performance insights.
///
/// Generation runs server-side in the `ai-generate` edge function. The
/// Gemini key used to be bundled into the app, where anyone could extract it
/// from the APK; it now lives only in the function's secrets, and the prompts
/// live there with it.
class PracticeAnalysisService {
  const PracticeAnalysisService();

  Future<String?> _generate(Map<String, dynamic> body) async {
    final res = await Supabase.instance.client.functions.invoke('ai-generate', body: body);
    final data = res.data;
    return data is Map ? data['text'] as String? : null;
  }

  Future<String> analyzeSession({
    required PracticeSession session,
    required List<PracticeShot> shots,
    required List<Map<String, dynamic>> clubStats,
    Drill? drill,
  }) async {
    final statsSummary = clubStats.map((s) =>
      "${s['name']}: ${s['count']} shots, ${s['successPct']}% quality. Avg Distance: ${s['avgDist']}y. Common Shape: ${s['commonShape']}"
    ).join('\n');

    try {
      final text = await _generate({
        'task': 'practice_session',
        'session_type': drill?.name ?? session.sessionType,
        'total_balls': session.totalBalls,
        'stats_summary': statsSummary,
      });
      return text ?? 'Solid grind today. Your data shows consistency, keep focus on the target.';
    } catch (e) {
      debugPrint('AI_SESSION_ERROR: $e');
      return 'Session analysis unavailable, but the numbers don\'t lie: keep grinding on that tempo.';
    }
  }

  Future<String> analyzePerformance({
    required String playerName,
    required dynamic stats,
  }) async {
    try {
      final text = await _generate({
        'task': 'performance',
        'player_name': playerName,
        'rounds_played': stats.roundsPlayed,
        'fairway_pct': stats.fairwayHitPercentage,
        'gir_pct': stats.greensInRegulationPercentage,
        'putts_per_round': stats.puttsPerRound,
        'score_trend': stats.scoreTrend?.toStringAsFixed(1),
      });
      return text ?? 'Insights unavailable. Keep up the grind.';
    } catch (e) {
      debugPrint('AI_PERFORMANCE_ERROR: $e');
      return 'Performance analysis offline. The data shows potential—keep focusing on your tempo.';
    }
  }
}

final practiceAnalysisServiceProvider = Provider((ref) => const PracticeAnalysisService());
