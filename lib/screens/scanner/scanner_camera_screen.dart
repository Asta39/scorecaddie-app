import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/scorecard_scanner_provider.dart';

class ScannerCameraScreen extends ConsumerStatefulWidget {
  const ScannerCameraScreen({super.key});

  @override
  ConsumerState<ScannerCameraScreen> createState() => _ScannerCameraScreenState();
}

class _ScannerCameraScreenState extends ConsumerState<ScannerCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _previewFile;
  Timer? _timer;
  int _countdown = 10;
  bool _timerPaused = false;

  @override
  void initState() {
    super.initState();
    final scanState = ref.read(scorecardScannerProvider);
    if (scanState.imagePath != null && scanState.imagePath!.isNotEmpty) {
      _previewFile = File(scanState.imagePath!);
    }
    if (_previewFile == null) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _countdown = 10;
      _timerPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_previewFile != null) {
        timer.cancel();
        return;
      }
      if (_timerPaused) return;

      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _captureImage();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _captureImage() async {
    _timer?.cancel();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        
        // Update the provider state
        ref.read(scorecardScannerProvider.notifier).setImage(bytes, image.path);
        
        setState(() {
          _previewFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    _timer?.cancel();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        
        // Update the provider state
        ref.read(scorecardScannerProvider.notifier).setImage(bytes, image.path);
        
        setState(() {
          _previewFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scorecardScannerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.grey900, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scorecard Scanner',
          style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Subtitle
              Text(
                state.course != null
                    ? 'Scanning for ${state.course!.name}'
                    : 'Scan Golf Scorecard',
                style: const TextStyle(
                  color: AppColors.grey500,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Main content area
              Expanded(
                child: _previewFile != null
                    ? _buildImagePreview()
                    : _buildInstructionTips(),
              ),
              const SizedBox(height: 32),

              // Button actions
              _buildBottomControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _previewFile!,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.sparkles, color: AppColors.golfLime, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ensure scores & names are clear and legible before scanning.',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionTips() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.grey100, width: 2),
          ),
          child: const Icon(
            LucideIcons.camera,
            color: AppColors.emerald700,
            size: 48,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Capture Scorecard',
          style: TextStyle(color: AppColors.grey900, fontSize: 24, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'For best results, align the physical scorecard flat inside your viewfinder.',
          style: TextStyle(color: AppColors.grey500, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),

        // Custom list item tips
        _buildTipRow(LucideIcons.sheet, 'Lay scorecard flat on a dark/contrasting background.'),
        const SizedBox(height: 16),
        _buildTipRow(LucideIcons.sun, 'Avoid dark shadows or bright light reflections/glare.'),
        const SizedBox(height: 16),
        _buildTipRow(LucideIcons.maximize2, 'Include all holes and totals columns in the frame.'),
      ],
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.emerald700, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.grey700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    if (_previewFile != null) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(scorecardScannerProvider.notifier).clearImage();
                  setState(() {
                    _previewFile = null;
                  });
                  _startTimer();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.grey300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'CHANGE PHOTO',
                  style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 60,
              child: FilledButton(
                onPressed: () {
                  // Navigate to processing screen and trigger scan!
                  context.pushReplacement('/scanner/processing');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.golfLime,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'CONFIRM PHOTO',
                  style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _timerPaused ? LucideIcons.pauseCircle : LucideIcons.playCircle,
              color: AppColors.grey500,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _timerPaused
                  ? 'Auto-open paused.'
                  : 'Opening camera in $_countdown seconds...',
              style: const TextStyle(
                color: AppColors.grey600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _timerPaused = !_timerPaused;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _timerPaused ? 'RESUME' : 'PAUSE',
                style: const TextStyle(
                  color: AppColors.emerald700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: FilledButton.icon(
            onPressed: _captureImage,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.golfLime,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(LucideIcons.camera, color: AppColors.grey900, size: 20),
            label: const Text(
              'OPEN CAMERA NOW',
              style: TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grey300, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            icon: const Icon(LucideIcons.image, color: AppColors.grey700, size: 20),
            label: const Text(
              'UPLOAD FROM GALLERY',
              style: TextStyle(color: AppColors.grey700, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
