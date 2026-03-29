import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());

class CameraService {
  CameraController? _controller;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;

  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use the back camera by default
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high, // High (720p) for better AI/ML detail
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.bgra8888 : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
  }

  Future<void> startRecording() async {
    if (!isInitialized || _isRecording) return;
    await _controller!.startVideoRecording();
    _isRecording = true;
  }

  Future<XFile?> stopRecording() async {
    if (!isInitialized || !_isRecording) return null;
    final file = await _controller!.stopVideoRecording();
    _isRecording = false;
    return file;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isRecording = false;
  }
}
