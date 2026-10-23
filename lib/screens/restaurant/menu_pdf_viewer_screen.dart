import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/services/pdf_cache_service.dart';
import '../onboarding/ob_forms.dart';
import '../onboarding/ob_style.dart';

/// A menu PDF as a plain scroll of page pictures.
///
/// Each page is drawn once, at screen resolution, when the menu opens;
/// after that scrolling and pinch-zoom only move images. The previous
/// viewer re-rendered tiles of the PDF on every zoom and scroll, which is
/// what made menus feel laggy.
class MenuPdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const MenuPdfViewerScreen({super.key, required this.title, required this.pdfUrl});

  @override
  State<MenuPdfViewerScreen> createState() => _MenuPdfViewerScreenState();
}

class _MenuPdfViewerScreenState extends State<MenuPdfViewerScreen> {
  final _pages = <Uint8List>[];
  final _sizes = <Size>[];
  int? _count;
  Object? _error;
  bool _disposed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_count == null && _error == null) _render();
  }

  Future<void> _render() async {
    final mq = MediaQuery.of(context);
    // Sharp on this screen, and a bit beyond for zoom, without huge images.
    final width = (mq.size.width * mq.devicePixelRatio * 1.5).clamp(800, 2000).toDouble();
    PdfDocument? doc;
    try {
      final file = await PdfCacheService.getCachedFile(widget.pdfUrl);
      doc = await PdfDocument.openFile(file.path);
      if (_disposed) return;
      setState(() => _count = doc!.pagesCount);
      for (var i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        final scale = width / page.width;
        final img = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.jpeg,
          quality: 90,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        if (_disposed) return;
        if (img != null) {
          setState(() {
            _pages.add(img.bytes);
            _sizes.add(Size(page.width, page.height));
          });
        }
      }
    } catch (e) {
      if (!_disposed) setState(() => _error = e);
    } finally {
      await doc?.close();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    return Scaffold(
      backgroundColor: Ob.bg,
      body: DefaultTextStyle(
        style: Ob.textBase,
        child: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ObTopBar(widget.title, onBack: () => Navigator.of(context).maybePop()),
            ),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Couldn’t open this menu. Check your connection and try again.',
                            textAlign: TextAlign.center, style: Ob.body(17, color: Ob.creamA(.6))),
                      ),
                    )
                  : count == null
                      ? const Center(child: CupertinoActivityIndicator(color: Ob.lime))
                      : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
                            itemCount: count,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              if (i >= _pages.length) {
                                // Not drawn yet: hold the space so the list doesn't jump.
                                return AspectRatio(
                                  aspectRatio: _sizes.isEmpty ? 1 / 1.414 : _sizes.first.aspectRatio,
                                  child: Container(
                                    decoration: BoxDecoration(color: Ob.cardFill, borderRadius: BorderRadius.circular(8)),
                                    child: const Center(child: CupertinoActivityIndicator(color: Ob.lime)),
                                  ),
                                );
                              }
                              // The list only scrolls; tap a page to zoom it full screen.
                              return Semantics(
                                label: 'Menu page ${i + 1} of $count. Opens to zoom.',
                                button: true,
                                image: true,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => _PageZoom(bytes: _pages[i], label: 'Page ${i + 1} of $count'),
                                  )),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(_pages[i], fit: BoxFit.fitWidth, gaplessPlayback: true),
                                  ),
                                ),
                              );
                            },
                          ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// One menu page, full screen: pinch to zoom, drag to move, double-tap to
/// toggle 2x.
class _PageZoom extends StatefulWidget {
  const _PageZoom({required this.bytes, required this.label});
  final Uint8List bytes;
  final String label;

  @override
  State<_PageZoom> createState() => _PageZoomState();
}

class _PageZoomState extends State<_PageZoom> {
  final _ctrl = TransformationController();
  TapDownDetails? _tap;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_ctrl.value.getMaxScaleOnAxis() > 1.01) {
      _ctrl.value = Matrix4.identity();
    } else {
      final p = _tap?.localPosition ?? Offset.zero;
      _ctrl.value = Matrix4.identity()
        ..translate(-p.dx, -p.dy)
        ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _tap = d,
              onDoubleTap: _toggle,
              child: InteractiveViewer(
                transformationController: _ctrl,
                minScale: 1,
                maxScale: 5,
                child: Center(child: Image.memory(widget.bytes, fit: BoxFit.contain, semanticLabel: widget.label)),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 8,
            child: ObIconButton(icon: Icons.close_rounded, label: 'Close', onPressed: () => Navigator.of(context).pop()),
          ),
        ]),
      ),
    );
  }
}
