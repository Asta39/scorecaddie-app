import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/database/database.dart' as db;
import '../core/models/scanned_round_result.dart';
import '../core/services/scorecard_scanner_service.dart';

@immutable
class ScorecardScannerState {
  final db.Course? course;
  final db.Tee? tee;
  final String playerName;
  final DateTime date;
  final Uint8List? imageBytes;
  final String? imagePath;
  final bool isLoading;
  final String? errorMessage;
  final ScannedRoundResult? scanResult;

  const ScorecardScannerState({
    this.course,
    this.tee,
    this.playerName = '',
    required this.date,
    this.imageBytes,
    this.imagePath,
    this.isLoading = false,
    this.errorMessage,
    this.scanResult,
  });

  ScorecardScannerState copyWith({
    db.Course? course,
    db.Tee? tee,
    String? playerName,
    DateTime? date,
    Uint8List? imageBytes,
    String? imagePath,
    bool? isLoading,
    String? errorMessage,
    ScannedRoundResult? scanResult,
  }) {
    return ScorecardScannerState(
      course: course ?? this.course,
      tee: tee ?? this.tee,
      playerName: playerName ?? this.playerName,
      date: date ?? this.date,
      imageBytes: imageBytes ?? this.imageBytes,
      imagePath: imagePath ?? this.imagePath,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      scanResult: scanResult ?? this.scanResult,
    );
  }
}

final scorecardScannerServiceProvider = Provider<ScorecardScannerService>((ref) {
  return ScorecardScannerService(AppConfig.geminiApiKey);
});

class ScorecardScannerNotifier extends StateNotifier<ScorecardScannerState> {
  final Ref ref;

  ScorecardScannerNotifier(this.ref)
      : super(ScorecardScannerState(date: DateTime.now()));

  void reset() {
    state = ScorecardScannerState(date: DateTime.now());
  }

  void setCourse(db.Course course) {
    state = state.copyWith(course: course, tee: null);
  }

  void setTee(db.Tee tee) {
    state = state.copyWith(tee: tee);
  }

  void setPlayerName(String name) {
    state = state.copyWith(playerName: name);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setImage(Uint8List bytes, String path) {
    state = state.copyWith(imageBytes: bytes, imagePath: path);
  }

  void clearImage() {
    state = ScorecardScannerState(
      course: state.course,
      tee: state.tee,
      playerName: state.playerName,
      date: state.date,
      imageBytes: null,
      imagePath: null,
      isLoading: false,
      errorMessage: null,
      scanResult: null,
    );
  }

  Future<void> runScan() async {
    if (state.imageBytes == null) {
      state = state.copyWith(errorMessage: 'No image captured yet.');
      return;
    }
    if (state.course == null) {
      state = state.copyWith(errorMessage: 'Please select a course first.');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, scanResult: null);

    int attempts = 0;
    const maxAttempts = 3;
    ScannedRoundResult? result;
    dynamic lastError;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final scannerService = ref.read(scorecardScannerServiceProvider);
        result = await scannerService.scanScorecard(
          imageBytes: state.imageBytes!,
          playerName: state.playerName.isNotEmpty ? state.playerName : 'Golfer',
          clubName: state.course!.name,
        );
        break; // Success!
      } catch (e) {
        lastError = e;
        debugPrint('Scorecard scan attempt $attempts failed with error: $e');
        if (attempts < maxAttempts) {
          // Wait 1 second before retrying
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }

    if (result != null) {
      state = state.copyWith(scanResult: result, isLoading: false);
    } else {
      String friendlyMessage = 'Failed to scan scorecard. Please ensure the photo is clear and try again.';
      final errStr = lastError.toString().toLowerCase();

      if (errStr.contains('format') || errStr.contains('json') || errStr.contains('recognizable') || errStr.contains('extract')) {
        friendlyMessage = "We couldn't recognize a golf scorecard in this image. Please make sure the scorecard is flat, well-lit, and clearly shows the holes and scores.";
      } else if (errStr.contains('quota') || errStr.contains('limit') || errStr.contains('api key')) {
        friendlyMessage = "The AI scanning service is currently busy or unavailable. Please try again shortly or enter scores manually.";
      } else if (errStr.contains('blocked') || errStr.contains('safety')) {
        friendlyMessage = "The image could not be processed due to safety filters. Please try another photo.";
      } else if (errStr.contains('network') || errStr.contains('socket') || errStr.contains('host')) {
        friendlyMessage = "Network error. Please check your internet connection and try again.";
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyMessage,
      );
    }
  }

  void updateHoleScore(int holeNumber, int? score) {
    if (state.scanResult == null) return;

    final updatedHoles = state.scanResult!.holes.map((h) {
      if (h.hole == holeNumber) {
        bool isFlagged = score == null;
        if (score != null) {
          if (score < 1 || score > (h.par + 6)) {
            isFlagged = true;
          }
        }
        return h.copyWith(score: score, isFlagged: isFlagged, clearScore: score == null);
      }
      return h;
    }).toList();

    int? front9Sum;
    int? back9Sum;
    int? grossSum;

    final front9Holes = updatedHoles.where((h) => h.hole >= 1 && h.hole <= 9);
    final back9Holes = updatedHoles.where((h) => h.hole >= 10 && h.hole <= 18);

    if (front9Holes.any((h) => h.score != null)) {
      front9Sum = front9Holes.fold<int>(0, (sum, h) => sum + (h.score ?? 0));
    }
    if (back9Holes.any((h) => h.score != null)) {
      back9Sum = back9Holes.fold<int>(0, (sum, h) => sum + (h.score ?? 0));
    }
    if (updatedHoles.any((h) => h.score != null)) {
      grossSum = (front9Sum ?? 0) + (back9Sum ?? 0);
    }

    state = state.copyWith(
      scanResult: ScannedRoundResult(
        playerSlot: state.scanResult!.playerSlot,
        matchedName: state.scanResult!.matchedName,
        confidence: state.scanResult!.confidence,
        roundType: state.scanResult!.roundType,
        holes: updatedHoles,
        front9Total: front9Sum,
        back9Total: back9Sum,
        grossTotal: grossSum,
        warnings: state.scanResult!.warnings,
      ),
    );
  }
}

final scorecardScannerProvider =
    StateNotifierProvider<ScorecardScannerNotifier, ScorecardScannerState>((ref) {
  return ScorecardScannerNotifier(ref);
});
