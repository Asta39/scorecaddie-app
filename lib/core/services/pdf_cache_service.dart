import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Downloads a menu PDF once and keeps it on disk, keyed by its URL. Both the
/// first-page thumbnail and the full-document viewer read from this same
/// cached file — the PDF is fetched over the network at most once per
/// device, not every time a player opens the menu screen.
class PdfCacheService {
  static final Map<String, Future<File>> _inFlight = {};
  static final Map<String, Future<File>> _thumbInFlight = {};

  static Future<File> getCachedFile(String url) {
    return _inFlight.putIfAbsent(url, () => _fetchAndCache(url));
  }

  /// First-page preview, rendered once and kept on disk — the menu screen
  /// never has to re-render (or re-download) a thumbnail it has already
  /// shown on this device.
  static Future<File> getCachedThumbnail(String url) {
    return _thumbInFlight.putIfAbsent(url, () => _renderAndCacheThumbnail(url));
  }

  static Future<File> _renderAndCacheThumbnail(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/menu_pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final key = url.hashCode.toUnsigned(32).toRadixString(16);
    final thumbFile = File('${cacheDir.path}/$key.jpg');

    if (await thumbFile.exists() && await thumbFile.length() > 0) {
      return thumbFile;
    }

    final pdfFile = await getCachedFile(url);
    final document = await PdfDocument.openFile(pdfFile.path);
    final page = await document.getPage(1);
    final image = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();
    await document.close();

    if (image == null) {
      throw Exception('Could not render PDF thumbnail');
    }
    await thumbFile.writeAsBytes(image.bytes, flush: true);
    return thumbFile;
  }

  static Future<File> _fetchAndCache(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/menu_pdf_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final key = url.hashCode.toUnsigned(32).toRadixString(16);
    final file = File('${cacheDir.path}/$key.pdf');

    if (await file.exists() && await file.length() > 0) {
      return file;
    }

    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }
}
