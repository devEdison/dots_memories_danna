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

  static void openUrl(String url) {
    webHelper.openUrl(url);
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