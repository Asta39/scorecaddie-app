import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scanned_round_result.dart';

class ScorecardScannerService {
  const ScorecardScannerService();

  Future<ScannedRoundResult> scanScorecard({
    required Uint8List imageBytes,
    required String playerName,
    required String clubName,
  }) async {
    try {
      // Runs server-side (supabase/functions/ai-generate). The Gemini key no
      // longer ships inside the app, and the prompt lives with it.
      final res = await Supabase.instance.client.functions.invoke(
        'ai-generate',
        body: {
          'task': 'scan_scorecard',
          'image_base64': base64Encode(imageBytes),
          'player_name': playerName,
          'club_name': clubName,
        },
      );
      final data = res.data;
      final jsonText = data is Map ? data['text'] as String? : null;
      
      if (jsonText == null || jsonText.isEmpty) {
        throw 'The scanner received an empty response. Please try again.';
      }

      Map<String, dynamic> parsedJson;
      try {
        // Find the first '{' and last '}' to handle potential markdown formatting
        String cleanedJson = jsonText.trim();
        if (cleanedJson.contains('```json')) {
          cleanedJson = cleanedJson.split('```json')[1].split('```')[0].trim();
        } else if (cleanedJson.contains('```')) {
          cleanedJson = cleanedJson.split('```')[1].split('```')[0].trim();
        }
        final startIndex = cleanedJson.indexOf('{');
        final endIndex = cleanedJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          cleanedJson = cleanedJson.substring(startIndex, endIndex + 1);
        }
        parsedJson = jsonDecode(cleanedJson);
      } catch (e) {
        throw 'The image does not appear to contain a recognizable golf scorecard.';
      }

      ScannedRoundResult result;
      try {
        result = ScannedRoundResult.fromJson(parsedJson);
      } catch (e) {
        throw 'Could not extract scores from this scorecard. Ensure scores are written clearly.';
      }

      // Auto-detect round type based on populated scores to correct any Gemini discrepancy
      final frontScoresCount = result.holes.where((h) => h.hole >= 1 && h.hole <= 9 && h.score != null).length;
      final backScoresCount = result.holes.where((h) => h.hole >= 10 && h.hole <= 18 && h.score != null).length;
      
      String finalRoundType = result.roundType;
      if (frontScoresCount > 0 && backScoresCount == 0) {
        finalRoundType = 'front_9';
      } else if (backScoresCount > 0 && frontScoresCount == 0) {
        finalRoundType = 'back_9';
      } else if (frontScoresCount >= 4 && backScoresCount <= 2) {
        finalRoundType = 'front_9';
      } else if (backScoresCount >= 4 && frontScoresCount <= 2) {
        finalRoundType = 'back_9';
      } else if (frontScoresCount == 0 && backScoresCount == 0) {
        finalRoundType = result.roundType;
      } else {
        finalRoundType = 'full_18';
      }

      // Filter holes based on round type
      List<ScannedHole> filteredHoles = result.holes;
      if (finalRoundType == 'front_9') {
        filteredHoles = result.holes.where((h) => h.hole >= 1 && h.hole <= 9).toList();
      } else if (finalRoundType == 'back_9') {
        filteredHoles = result.holes.where((h) => h.hole >= 10 && h.hole <= 18).toList();
      }

      // Perform local client-side validation check to flag suspicious scores
      final validatedHoles = filteredHoles.map((hole) {
        bool isFlagged = false;
        if (hole.score != null) {
          // If score is less than 1 or greater than par + 6, flag it
          if (hole.score! < 1 || hole.score! > (hole.par + 6)) {
            isFlagged = true;
          }
        } else {
          // Null score (unreadable) is also flagged for user review
          isFlagged = true;
        }
        return hole.copyWith(isFlagged: isFlagged);
      }).toList();

      // Recalculate totals client-side if they're null, to make editing experience seamless
      int? front9Sum;
      int? back9Sum;
      int? grossSum;

      final front9Holes = validatedHoles.where((h) => h.hole >= 1 && h.hole <= 9);
      final back9Holes = validatedHoles.where((h) => h.hole >= 10 && h.hole <= 18);

      if (front9Holes.any((h) => h.score != null)) {
        front9Sum = front9Holes.fold<int>(0, (sum, h) => sum + (h.score ?? 0));
      }
      if (back9Holes.any((h) => h.score != null)) {
        back9Sum = back9Holes.fold<int>(0, (sum, h) => sum + (h.score ?? 0));
      }
      if (validatedHoles.any((h) => h.score != null)) {
        grossSum = (front9Sum ?? 0) + (back9Sum ?? 0);
      }

      return ScannedRoundResult(
        playerSlot: result.playerSlot,
        matchedName: result.matchedName,
        confidence: result.confidence,
        roundType: finalRoundType,
        holes: validatedHoles,
        front9Total: finalRoundType == 'back_9' ? null : (result.front9Total ?? front9Sum),
        back9Total: finalRoundType == 'front_9' ? null : (result.back9Total ?? back9Sum),
        grossTotal: finalRoundType == 'front_9' ? front9Sum : (finalRoundType == 'back_9' ? back9Sum : (result.grossTotal ?? grossSum)),
        warnings: result.warnings,
      );
    } catch (e) {
      debugPrint('ScorecardScannerService error: $e');
      if (e is String) {
        rethrow;
      }
      throw 'An unexpected error occurred while scanning. Please try again.';
    }
  }
}
