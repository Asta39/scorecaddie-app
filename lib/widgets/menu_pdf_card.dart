import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/theme/app_theme.dart';
import '../core/services/pdf_cache_service.dart';
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
  File? _thumbnail;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final file = await PdfCacheService.getCachedThumbnail(widget.document.pdfUrl);
      if (mounted) setState(() => _thumbnail = file);
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
                  ? Image.file(_thumbnail!, fit: BoxFit.cover)
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
