import 'package:flutter/foundation.dart';

@immutable
class ScannedRoundResult {
  final String playerSlot;
  final String matchedName;
  final double confidence;
  final String roundType; // 'full_18', 'front_9', 'back_9'
  final List<ScannedHole> holes;
  final int? front9Total;
  final int? back9Total;
  final int? grossTotal;
  final List<String> warnings;

  const ScannedRoundResult({
    required this.playerSlot,
    required this.matchedName,
    required this.confidence,
    required this.roundType,
    required this.holes,
    this.front9Total,
    this.back9Total,
    this.grossTotal,
    this.warnings = const [],
  });

  factory ScannedRoundResult.fromJson(Map<String, dynamic> json) {
    final holesList = (json['holes'] as List? ?? [])
        .map((h) => ScannedHole.fromJson(h as Map<String, dynamic>))
        .toList();

    return ScannedRoundResult(
      playerSlot: json['player_slot'] as String? ?? '',
      matchedName: json['matched_name'] as String? ?? '',
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      roundType: json['round_type'] as String? ?? 'full_18',
      holes: holesList,
      front9Total: json['front_9_total'] as int?,
      back9Total: json['back_9_total'] as int?,
      grossTotal: json['gross_total'] as int?,
      warnings: (json['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player_slot': playerSlot,
      'matched_name': matchedName,
      'confidence': confidence,
      'round_type': roundType,
      'holes': holes.map((h) => h.toJson()).toList(),
      'front_9_total': front9Total,
      'back_9_total': back9Total,
      'gross_total': grossTotal,
      'warnings': warnings,
    };
  }
}

class ScannedHole {
  final int hole;
  final int par;
  final int? score; // null if unreadable
  final bool isFlagged; // computed/managed client-side or from AI

  const ScannedHole({
    required this.hole,
    required this.par,
    this.score,
    this.isFlagged = false,
  });

  ScannedHole copyWith({
    int? hole,
    int? par,
    int? score,
    bool? isFlagged,
    bool clearScore = false,
  }) {
    return ScannedHole(
      hole: hole ?? this.hole,
      par: par ?? this.par,
      score: clearScore ? null : (score ?? this.score),
      isFlagged: isFlagged ?? this.isFlagged,
    );
  }

  factory ScannedHole.fromJson(Map<String, dynamic> json) {
    return ScannedHole(
      hole: json['hole'] as int? ?? 0,
      par: json['par'] as int? ?? 0,
      score: json['score'] as int?,
      isFlagged: json['is_flagged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hole': hole,
      'par': par,
      'score': score,
      'is_flagged': isFlagged,
    };
  }
}
