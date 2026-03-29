import 'dart:io';
import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';

class VideoValidationException implements Exception {
  final String message;
  VideoValidationException(this.message);
  @override
  String toString() => message;
}

class AIShotAnalysis {
  final double carry;
  final double totalDistance;
  final double ballSpeed;
  final double launchAngle;
  final List<Offset> trajectory;
  final String swingQuality;
  final Map<String, dynamic>? poseMetrics;

  AIShotAnalysis({
    required this.carry,
    required this.totalDistance,
    required this.ballSpeed,
    required this.launchAngle,
    required this.trajectory,
    required this.swingQuality,
    this.poseMetrics,
  });
}

class AIAnalyzerService {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());

  Future<AIShotAnalysis> analyzeShot(File videoFile, String clubType) async {
    debugPrint('AI_ANALYZER: Starting analysis for $clubType...');
    // 1. Basic File Validation
    final length = await videoFile.length();
    debugPrint('AI_ANALYZER: Video size: $length bytes');
    if (length < 100000) { // Lowered threshold for testing
      throw VideoValidationException('Recording was too short. Please capture the full swing.');
    }

    // 2. Extract frame for primary pose detection
    debugPrint('AI_ANALYZER: Extracting thumbnail...');
    final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 320, // Smaller for faster processing
      quality: 30,
      timeMs: 0, // Start of video is safer than 1500ms
    );
    debugPrint('AI_ANALYZER: Thumbnail path: $thumbnailPath');

    if (thumbnailPath == null) {
      throw VideoValidationException('Could not process video. Try recording in better light.');
    }

    // 3. Real Pose Detection
    debugPrint('AI_ANALYZER: Processing pose detection...');
    List<Pose> poses;
    try {
      final inputImage = InputImage.fromFilePath(thumbnailPath);
      poses = await _poseDetector.processImage(inputImage);
      debugPrint('AI_ANALYZER: Detected ${poses.length} poses');
    } catch (e) {
      debugPrint('AI_ANALYZER: Pose detection error: $e');
      rethrow;
    } finally {
      try { File(thumbnailPath).delete(); } catch (_) {}
    }

    if (poses.isEmpty) {
      throw VideoValidationException('No golfer detected. Ensure your full body is visible in the frame.');
    }

    final pose = poses.first;
    
    // 4. Calculate Personalized Metrics from Landmarks
    final metrics = _calculateRealMetrics(pose);
    
    // 5. Physics Simulation adjusted by pose-derived swing quality
    final double loft = _getLoftForClub(clubType);
    final double initialVelocity = 45.0 + (metrics['shoulderTurn']! / 90.0 * 20.0);
    final double launchAngleDeg = loft * 0.85;
    
    final List<Offset> trajectory = _calculateTrajectory(initialVelocity, launchAngleDeg);
    final double carryMeters = trajectory.last.dx;
    final double totalMeters = carryMeters * 1.1;

    return AIShotAnalysis(
      carry: carryMeters * 1.09361,
      totalDistance: totalMeters * 1.09361,
      ballSpeed: initialVelocity * 2.23694,
      launchAngle: launchAngleDeg,
      trajectory: trajectory,
      swingQuality: _analyzeSwingQuality(metrics),
      poseMetrics: metrics,
    );
  }

  Map<String, double> _calculateRealMetrics(Pose pose) {
    // Note: Landmark coordinates are normalized 0.0 to 1.0 or pixel values depending on image
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (nose == null || leftShoulder == null || rightShoulder == null || leftHip == null) {
       return {'headStability': 0.5, 'spineAngle': 35, 'shoulderTurn': 60};
    }

    // 1. Head Stability (Check if nose is roughly centered / high)
    double headStability = (1.0 - (nose.x - 240).abs() / 240).clamp(0.0, 1.0);

    // 2. Spine Angle
    // Angle between shoulder line and vertical? No, usually spine is tilt from vertical.
    final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
    final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final midHipX = (leftHip.x + (rightHip?.x ?? leftHip.x)) / 2;
    final midHipY = (leftHip.y + (rightHip?.y ?? leftHip.y)) / 2;
    
    final spineAngle = (math.atan2(midShoulderX - midHipX, midHipY - midShoulderY) * 180 / math.pi).abs();

    // 3. Shoulder Turn (Width of shoulders in 2D indicates rotation)
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final shoulderTurn = (shoulderWidth / 100 * 90).clamp(45.0, 110.0);

    return {
      'headStability': headStability,
      'spineAngle': spineAngle > 20 ? spineAngle : 35.0,
      'shoulderTurn': shoulderTurn,
    };
  }

  String _analyzeSwingQuality(Map<String, dynamic> metrics) {
    if (metrics['headStability']! > 0.9 && metrics['shoulderTurn']! > 90) return 'GREAT';
    if (metrics['headStability']! > 0.7) return 'GOOD';
    return 'OKAY';
  }

  double _getLoftForClub(String club) {
    if (club.contains('Driver')) return 10.5;
    if (club.contains('3')) return 15.0;
    if (club.contains('5')) return 18.0;
    if (club.contains('7')) return 34.0;
    if (club.contains('9')) return 42.0;
    if (club.contains('Putter')) return 3.0;
    return 24.0;
  }



  List<Offset> _calculateTrajectory(double v0, double angleDeg) {
    List<Offset> points = [];
    double angleRad = angleDeg * math.pi / 180;
    double dt = 0.1;
    double x = 0;
    double y = 0;
    double vx = v0 * math.cos(angleRad);
    double vy = v0 * math.sin(angleRad);
    
    points.add(Offset(x, y));
    
    while (y >= 0 && points.length < 100) {
      x += vx * dt;
      y += vy * dt;
      vy -= 9.81 * dt; // Simple gravity
      points.add(Offset(x, y));
      if (y < 0) break;
    }
    return points;
  }


  void dispose() {
    _poseDetector.close();
  }
}
