import 'package:flutter/foundation.dart';
import 'web_helper_interface.dart';

class WebHelperImpl extends WebHelper {
  @override
  void downloadBytes(Uint8List bytes, String fileName) {
    debugPrint('[Stub] Descargando $fileName (${bytes.length} bytes)');
  }

  @override
  void openUrl(String url) {
    debugPrint('[Stub] Abriendo $url');
  }

  @override
  void printPage() {
    debugPrint('[Stub] Imprimiendo página');
  }

  @override
  String getCurrentUrl() {
    return 'https://dotsmemories.danna15.com';
  }
}

WebHelper getWebHelper() => WebHelperImpl();
