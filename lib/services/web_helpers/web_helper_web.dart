import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'web_helper_interface.dart';

class WebHelperImpl extends WebHelper {
  @override
  void downloadBytes(Uint8List bytes, String fileName) {
    try {
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      web.URL.revokeObjectURL(url);
    } catch (e) {
      debugPrint('Error en web downloadBytes: $e');
    }
  }

  @override
  void openUrl(String url) {
    try {
      web.window.open(url, '_blank');
    } catch (e) {
      debugPrint('Error en web openUrl: $e');
    }
  }

  @override
  void printPage() {
    try {
      web.window.print();
    } catch (e) {
      debugPrint('Error en web printPage: $e');
    }
  }

  @override
  String getCurrentUrl() {
    try {
      return web.window.location.href;
    } catch (_) {
      return 'https://dotsmemories.danna15.com';
    }
  }

  @override
  String? getQueryParam(String paramName) {
    try {
      final current = web.window.location.href;
      final uri = Uri.parse(current);
      return uri.queryParameters[paramName];
    } catch (e) {
      debugPrint('Error obteniendo query param: $e');
      return null;
    }
  }

  @override
  String buildAccessUrl(String accessKey) {
    try {
      final origin = web.window.location.origin;
      final pathname = web.window.location.pathname;
      return '$origin$pathname?key=$accessKey';
    } catch (_) {
      return 'https://dotsmemories.danna15.com/?key=$accessKey';
    }
  }

  @override
  bool get isFullscreen {
    try {
      return web.document.fullscreenElement != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> toggleFullscreen() async {
    try {
      if (web.document.fullscreenElement != null) {
        await web.document.exitFullscreen().toDart;
      } else {
        final root = web.document.documentElement;
        if (root != null) {
          await root.requestFullscreen().toDart;
        }
      }
    } catch (e) {
      debugPrint('Fullscreen no disponible: $e');
    }
  }

  /// Redimensiona y comprime imágenes en navegador usando Canvas antes de enviarlas a Google
  @override
  Future<OptimizedImageResult> optimizeImageForUpload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    int maxDimension = 1920,
    double quality = 0.84,
  }) async {
    if (!mimeType.toLowerCase().startsWith('image/') || bytes.isEmpty) {
      return (bytes: bytes, mimeType: mimeType, fileName: fileName);
    }

    web.ImageBitmap? bitmap;
    web.HTMLCanvasElement? canvas;
    try {
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: mimeType),
      );
      bitmap = await web.window
          .createImageBitmap(blob)
          .toDart
          .timeout(const Duration(seconds: 10));

      final origW = bitmap.width;
      final origH = bitmap.height;
      if (origW <= 0 || origH <= 0) {
        return (bytes: bytes, mimeType: mimeType, fileName: fileName);
      }

      final lowerName = fileName.toLowerCase();
      final isHeic = mimeType.toLowerCase().contains('heic') ||
          mimeType.toLowerCase().contains('heif') ||
          lowerName.endsWith('.heic') ||
          lowerName.endsWith('.heif');

      // Conservar intactas imágenes ya ligeras y en resolución adecuada (salvo HEIC)
      if (bytes.length <= 320 * 1024 &&
          origW <= maxDimension &&
          origH <= maxDimension &&
          !isHeic) {
        return (bytes: bytes, mimeType: mimeType, fileName: fileName);
      }

      int targetW = origW;
      int targetH = origH;
      final maxSide = math.max(origW, origH);
      if (maxSide > maxDimension) {
        final scale = maxDimension / maxSide;
        targetW = math.max(1, (origW * scale).round());
        targetH = math.max(1, (origH * scale).round());
      }

      canvas = web.HTMLCanvasElement()
        ..width = targetW
        ..height = targetH;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
      if (ctx == null) {
        return (bytes: bytes, mimeType: mimeType, fileName: fileName);
      }

      // Evitar fondos negros al convertir PNG/WebP transparentes a JPEG
      ctx.fillStyle = '#FFFFFF'.toJS;
      ctx.fillRect(0, 0, targetW, targetH);
      ctx.drawImage(bitmap, 0, 0, targetW, targetH);

      final completer = Completer<web.Blob?>();
      canvas.toBlob(
        ((web.Blob? outBlob) {
          if (!completer.isCompleted) {
            completer.complete(outBlob);
          }
        }).toJS,
        'image/jpeg',
        quality.toJS,
      );

      final outBlob = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
      if (outBlob == null) {
        return (bytes: bytes, mimeType: mimeType, fileName: fileName);
      }

      final arrayBuf = await outBlob.arrayBuffer().toDart;
      final compressed = arrayBuf.toDart.asUint8List();

      if (compressed.isNotEmpty && (compressed.length < bytes.length || isHeic)) {
        final dotIdx = fileName.lastIndexOf('.');
        final base = dotIdx > 0 ? fileName.substring(0, dotIdx) : fileName;
        return (
          bytes: compressed,
          mimeType: 'image/jpeg',
          fileName: '$base.jpg',
        );
      }
      return (bytes: bytes, mimeType: mimeType, fileName: fileName);
    } catch (e) {
      debugPrint('Aviso optimizando imagen ($fileName): $e');
      return (bytes: bytes, mimeType: mimeType, fileName: fileName);
    } finally {
      try {
        bitmap?.close();
      } catch (_) {}
      if (canvas != null) {
        canvas.width = 0;
        canvas.height = 0;
      }
    }
  }
}

WebHelper getWebHelper() => WebHelperImpl();
