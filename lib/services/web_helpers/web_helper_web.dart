import 'dart:js_interop';
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
}

WebHelper getWebHelper() => WebHelperImpl();
