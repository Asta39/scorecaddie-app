import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/scanned_round_result.dart';

class ScorecardScannerService {
  final String _apiKey;

  ScorecardScannerService(this._apiKey);

  Future<ScannedRoundResult> scanScorecard({
    required Uint8List imageBytes,
    required String playerName,
    required String clubName,
  }) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    final prompt = '''
You are an expert golf scorecard reader. Your task is to analyze the scorecard image, find the scores for the specified player, and extract them.

PLAYER NAME TO FIND: $playerName
CLUB/COURSE: $clubName

INSTRUCTIONS:
1. Identify which row or column belongs to "$playerName" using fuzzy string matching. If there are multiple player columns (e.g., Column A, B, C, D) or rows, look for the name written in the header/label.
2. If the name is not explicitly written but there's a player slot (e.g. "Player 1", "A"), match the most likely golfer row/column.
3. Determine the type of round based on the holes filled: 'full_18', 'front_9', or 'back_9'.
   - If scores are only written/filled for holes 1-9, round_type must be 'front_9', and you should only return holes 1-9 in the 'holes' list.
   - If scores are only written/filled for holes 10-18, round_type must be 'back_9', and you should only return holes 10-18 in the 'holes' list.
   - If scores are filled for both, round_type must be 'full_18', and you should return all 18 holes.
4. Extract the hole number (1-18), the par for each hole, and the score.
5. If a score is unreadable, blurred, or blank, return null for that hole's score. Do not guess.
6. Check for totals on the scorecard (Front 9 Total, Back 9 Total, Gross Total) and return them if present.
7. Assess your confidence (0.0 to 1.0) in the extraction accuracy. If the scorecard is very blurry, low contrast, or does not contain scores for the specified player, confidence should be below 0.4.
8. Add warnings if you find suspicious numbers, double strokes, or markings that might be hard to read.

Return a JSON object conforming exactly to this schema:
{
  "player_slot": "String representing player slot identified on card (e.g. 'Player A', 'Row 2')",
  "matched_name": "String representing the name matched on the card",
  "confidence": double (0.0 to 1.0),
  "round_type": "full_18" | "front_9" | "back_9",
  "holes": [
    {
      "hole": integer (1-18),
      "par": integer,
      "score": integer or null
    }
  ],
  "front_9_total": integer or null,
  "back_9_total": integer or null,
  "gross_total": integer or null,
  "warnings": ["String of warnings if any"]
}

Output must be raw JSON conforming to this schema.
''';

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final jsonText = response.text;
      
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
