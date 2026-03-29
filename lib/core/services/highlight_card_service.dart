import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final highlightCardServiceProvider = Provider((ref) => HighlightCardService());

class HighlightCardService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get controller => _screenshotController;

  Future<void> shareHighlight({
    required Widget cardWidget,
    required BuildContext context,
    String? text,
    String? subject,
  }) async {
    try {
      // 1. Capture the widget as an image
      // Optimized for Instagram Stories (1080x1920)
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: cardWidget,
        ),
        delay: const Duration(milliseconds: 500),
        context: context,
        pixelRatio: 3.0, // Force high resolution density
        targetSize: const Size(1080, 1920),
      );

      if (imageBytes == null) throw Exception('Failed to capture screenshot');

      // 2. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/scorecaddie_highlight_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // 3. Share using share_plus
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: text ?? 'Check out my latest golf round on ScoreCaddie! 🏌️‍♂️⛳',
        subject: subject ?? 'ScoreCaddie Highlight',
      );
    } catch (e) {
      debugPrint('Error sharing highlight: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing highlight: $e')),
        );
      }
    }
  }
}
