import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/top_notification.dart';

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
      // 1. Capture the widget as an image.
      // The card widget already lays itself out at the exact Stories canvas
      // size (1080x1920 logical px — see HighlightCardKit). Previously this
      // rendered at pixelRatio 3.0 (3240x5760) and then force-resized down
      // to targetSize 1080x1920, and that extra resize pass is what was
      // visibly softening/artifacting the shared image. Capturing at
      // pixelRatio 1.0 with no targetSize renders the true 1080x1920 output
      // directly, with no intermediate downscale.
      final Uint8List imageBytes = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: cardWidget,
        ),
        delay: const Duration(milliseconds: 500),
        context: context,
        pixelRatio: 1.0,
      );

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
        TopNotification.showError(context, 'Error sharing highlight: $e');
      }
    }
  }
}
