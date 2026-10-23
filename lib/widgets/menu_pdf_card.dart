import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/providers/restaurant_provider.dart';
import '../core/services/pdf_cache_service.dart';
import '../screens/onboarding/ob_style.dart';
import '../screens/restaurant/menu_pdf_viewer_screen.dart';

/// A menu PDF shown by its cover: the first page, then its name, like a
/// book on a shelf. Tapping opens the whole menu.
class MenuPdfCard extends StatefulWidget {
  final MenuDocument document;
  final double width;

  const MenuPdfCard({super.key, required this.document, this.width = 150});

  @override
  State<MenuPdfCard> createState() => _MenuPdfCardState();
}

class _MenuPdfCardState extends State<MenuPdfCard> {
  File? _thumbnail;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await PdfCacheService.getCachedThumbnail(widget.document.pdfUrl);
      if (mounted) setState(() => _thumbnail = file);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    return Semantics(
      button: true,
      label: 'Open menu ${doc.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MenuPdfViewerScreen(title: doc.name, pdfUrl: doc.pdfUrl)),
        ),
        child: SizedBox(
          width: widget.width,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(
              aspectRatio: 1 / 1.414, // A4
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Ob.cardFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Ob.hairline),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: _thumbnail != null
                    ? Image.file(_thumbnail!, fit: BoxFit.cover, alignment: Alignment.topCenter)
                    : Center(
                        child: _failed
                            ? Icon(LucideIcons.fileText, size: 32, color: Ob.creamA(.3))
                            : const CupertinoActivityIndicator(color: Ob.lime),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(doc.name.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: Ob.body(15, weight: FontWeight.w500, height: 1.25)),
          ]),
        ),
      ),
    );
  }
}
