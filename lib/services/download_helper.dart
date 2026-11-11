import 'package:flutter/foundation.dart';
import 'web_helpers/web_helper.dart';
import 'web_helpers/web_helper_interface.dart' show OptimizedImageResult;

class DownloadHelper {
  static void downloadBytes(Uint8List bytes, String fileName) {
    webHelper.downloadBytes(bytes, fileName);
  }

  static void downloadText(String text, String fileName) {
    webHelper.downloadText(text, fileName);
  }

  static const Set<String> _allowedRelativeAssets = {
    'tarjeta_mesa_qr.html',
    'tarjeta_mesa_qr.pdf',
  };

  /// Valida que una URL externa o asset local sea seguro antes de abrirlo
  static bool isSafeExternalUrl(String url) {
    final cleaned = url.trim();
    if (cleaned.isEmpty) return false;
    if (cleaned.contains(RegExp(r'[\x00-\x1F\x7F]'))) return false;
    if (_allowedRelativeAssets.contains(cleaned)) return true;

    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'https') return uri.host.isNotEmpty;
    if (scheme == 'http') {
      final host = uri.host.toLowerCase();
      return host == 'localhost' || host == '127.0.0.1';
    }
    return false;
  }

  static void openUrl(String url) {
    if (!isSafeExternalUrl(url)) {
      debugPrint('Bloqueado intento de abrir URL no segura: $url');
      return;
    }
    webHelper.openUrl(url.trim());
  }

  static void printPage() {
    webHelper.printPage();
  }

  static String getCurrentUrl() {
    return webHelper.getCurrentUrl();
  }

  static String? getQueryParam(String paramName) {
    return webHelper.getQueryParam(paramName);
  }

  static String buildAccessUrl(String accessKey) {
    return webHelper.buildAccessUrl(accessKey);
  }

  static bool get isFullscreen => webHelper.isFullscreen;

  static Future<void> toggleFullscreen() {
    return webHelper.toggleFullscreen();
  }

  static Future<OptimizedImageResult> optimizeImageForUpload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    int maxDimension = 1920,
    double quality = 0.84,
  }) {
    return webHelper.optimizeImageForUpload(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      maxDimension: maxDimension,
      quality: quality,
    );
  }
}