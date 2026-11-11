import 'dart:convert';
import 'package:flutter/foundation.dart';

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
}
