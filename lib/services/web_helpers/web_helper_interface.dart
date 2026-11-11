import 'dart:convert';
import 'package:flutter/foundation.dart';

typedef OptimizedImageResult = ({
  Uint8List bytes,
  String mimeType,
  String fileName,
});

abstract class WebHelper {
  void downloadBytes(Uint8List bytes, String fileName);
  void downloadText(String text, String fileName) {
    downloadBytes(Uint8List.fromList(utf8.encode(text)), fileName);
  }
  void openUrl(String url);
  void printPage();
  String getCurrentUrl();
  String? getQueryParam(String paramName);
  String buildAccessUrl(String accessKey);
  bool get isFullscreen;
  Future<void> toggleFullscreen();

  Future<OptimizedImageResult> optimizeImageForUpload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    int maxDimension = 1920,
    double quality = 0.84,
  }) async {
    return (bytes: bytes, mimeType: mimeType, fileName: fileName);
  }
}
