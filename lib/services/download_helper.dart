import 'package:flutter/foundation.dart';
import 'web_helpers/web_helper.dart';

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
}