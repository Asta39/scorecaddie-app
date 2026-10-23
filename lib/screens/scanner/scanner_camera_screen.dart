import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../onboarding/ob_app.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';
import '../../providers/scorecard_scanner_provider.dart';

class ScannerCameraScreen extends ConsumerStatefulWidget {
  const ScannerCameraScreen({super.key});

  @override
  ConsumerState<ScannerCameraScreen> createState() => _ScannerCameraScreenState();
}

class _ScannerCameraScreenState extends ConsumerState<ScannerCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _previewFile;
  @override
  void initState() {
    super.initState();
    final scanState = ref.read(scorecardScannerProvider);
    if (scanState.imagePath != null && scanState.imagePath!.isNotEmpty) {
      _previewFile = File(scanState.imagePath!);
    }
  }

  Future<void> _captureImage() async {
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
    final hasPhoto = _previewFile != null;

    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ObTopBar('Scan a card', onBack: () => context.pop()),
              if (state.course != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(state.course!.name, style: Ob.body(15, color: Ob.creamA(.6))),
                ),
              const SizedBox(height: 16),
              Expanded(child: hasPhoto ? _buildImagePreview() : _buildInstructionTips()),
              const SizedBox(height: 16),
              if (hasPhoto) ...[
                ObButton(
                  height: 54,
                  radius: 14,
                  onPressed: () => context.pushReplacement('/scanner/processing'),
                  child: Text('Read scores', style: Ob.label(17)),
                ),
                CupertinoButton(
                  onPressed: () {
                    ref.read(scorecardScannerProvider.notifier).clearImage();
                    setState(() => _previewFile = null);
                  },
                  child: Text('Retake', style: Ob.body(17, color: Ob.lime)),
                ),
              ] else ...[
                ObButton(height: 54, radius: 14, onPressed: _captureImage, child: Text('Take photo', style: Ob.label(17))),
                CupertinoButton(onPressed: _pickFromGallery, child: Text('Choose from library', style: Ob.body(17, color: Ob.lime))),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(_previewFile!, fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 10),
      Text('Check every score and name is sharp before reading.', textAlign: TextAlign.center, style: Ob.body(13, color: Ob.creamA(.6))),
    ]);
  }

  Widget _buildInstructionTips() {
    return ListView(children: [
      const SizedBox(height: 24),
      Icon(LucideIcons.camera, size: 44, color: Ob.lime),
      const SizedBox(height: 14),
      Text('Photograph the card', textAlign: TextAlign.center, style: Ob.display(24)),
      const SizedBox(height: 6),
      Text('Daniel reads each hole and fills in the round for you to check.', textAlign: TextAlign.center, style: Ob.body(15, height: 1.4, color: Ob.creamA(.6))),
      const SizedBox(height: 24),
      ObGroup(header: 'For a clean read', children: [
        ObRow('Lay it flat', subtitle: 'On a dark, even surface', leading: ObRowIcon(LucideIcons.sheet, Ob.lime)),
        ObRow('Avoid glare', subtitle: 'No shadows or shiny reflections', leading: ObRowIcon(LucideIcons.sun, const Color(0xFFB7791F))),
        ObRow('Fit every column', subtitle: 'All holes and the totals', leading: ObRowIcon(LucideIcons.maximize2, const Color(0xFF2563EB))),
      ]),
    ]);
  }
}
