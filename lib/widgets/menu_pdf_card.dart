import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import 'pill.dart';
import '../core/providers/restaurant_provider.dart';
import '../screens/restaurant/menu_pdf_viewer_screen.dart';

/// Card showing a rendered first-page preview of an uploaded menu PDF.
/// Tapping opens the full document in-app via [MenuPdfViewerScreen].
class MenuPdfCard extends StatefulWidget {
  final MenuDocument document;

  const MenuPdfCard({super.key, required this.document});

  @override
  State<MenuPdfCard> createState() => _MenuPdfCardState();
}

class _MenuPdfCardState extends State<MenuPdfCard> {
  Uint8List? _thumbnail;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _renderFirstPage();
  }

  Future<void> _renderFirstPage() async {
    try {
      final response = await http.get(Uri.parse(widget.document.pdfUrl));
      final document = await PdfDocument.openData(response.bodyBytes);
      final page = await document.getPage(1);
      final image = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();
      await document.close();
      if (mounted && image != null) {
        setState(() => _thumbnail = image.bytes);
      } else if (mounted) {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MenuPdfViewerScreen(title: widget.document.name, pdfUrl: widget.document.pdfUrl),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: _thumbnail != null
                  ? Image.memory(_thumbnail!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.grey50,
                      alignment: Alignment.center,
                      child: _failed
                          ? const Icon(LucideIcons.fileText, size: 36, color: AppColors.grey400)
                          : const CircularProgressIndicator(strokeWidth: 2.5),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w800, color: AppColors.grey900),
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.grey400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
