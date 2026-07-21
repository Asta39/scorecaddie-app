import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/pdf_cache_service.dart';
import '../../widgets/pill.dart';

/// Full in-app viewer for an uploaded menu PDF — scrollable, pinch-to-zoom,
/// all pages. Opened by tapping the first-page preview card.
class MenuPdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const MenuPdfViewerScreen({super.key, required this.title, required this.pdfUrl});

  @override
  State<MenuPdfViewerScreen> createState() => _MenuPdfViewerScreenState();
}

class _MenuPdfViewerScreenState extends State<MenuPdfViewerScreen> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(document: _openCachedDocument());
  }

  Future<PdfDocument> _openCachedDocument() async {
    final file = await PdfCacheService.getCachedFile(widget.pdfUrl);
    return PdfDocument.openFile(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey900,
      appBar: AppBar(
        backgroundColor: AppColors.grey900,
        foregroundColor: AppColors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: AppTypeScale.body, fontWeight: FontWeight.w700)),
      ),
      body: PdfViewPinch(
        controller: _controller,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          pageLoaderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorBuilder: (_, error) => Center(
            child: Text('Could not open PDF.\n$error', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
