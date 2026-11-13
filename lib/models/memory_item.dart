import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class MemoryItem {
  final String id;
  final String fileName;
  final Uint8List? bytes;
  final String? remoteUrl;
  final String? base64Data;
  final DateTime timestamp;
  final String? caption;
  final int fileSize;
  final String? mimeType;

  ImageProvider? _cachedImageProvider;
  ImageProvider? _cachedThumbnailProvider;
  Uint8List? _decodedBytes;

  MemoryItem({
    required this.id,
    required this.fileName,
    this.bytes,
    this.remoteUrl,
    this.base64Data,
    required this.timestamp,
    this.caption,
    this.fileSize = 0,
    this.mimeType,
  });

  /// Determina si el elemento es un video
  bool get isVideo {
    if (mimeType != null && mimeType!.toLowerCase().startsWith('video/')) {
      return true;
    }
    final lower = fileName.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.3gp');
  }

  Uint8List? _resolveLocalBytes() {
    if (bytes != null && bytes!.isNotEmpty) return bytes;
    if (_decodedBytes != null) return _decodedBytes;
    if (base64Data != null && base64Data!.isNotEmpty) {
      try {
        _decodedBytes = base64Decode(base64Data!);
        return _decodedBytes;
      } catch (_) {}
    }
    return null;
  }

  static final RegExp _driveLh3BasePattern = RegExp(
    r'^https://lh3\.googleusercontent\.com/d/[^=/?#]+$',
  );

  static String _sizedRemoteUrl(String url, String sizeSuffix) {
    if (_driveLh3BasePattern.hasMatch(url)) {
      return '$url=$sizeSuffix';
    }
    return url;
  }

  /// Retorna y cachea un ImageProvider en resolución optimizada para lightbox y proyector
  ImageProvider get imageProvider {
    if (_cachedImageProvider != null) return _cachedImageProvider!;
    final localBytes = _resolveLocalBytes();
    if (localBytes != null) {
      _cachedImageProvider = ResizeImage.resizeIfNeeded(
        1920,
        null,
        MemoryImage(localBytes),
      );
    } else if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      _cachedImageProvider = NetworkImage(
        _sizedRemoteUrl(remoteUrl!, 'w1920'),
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      );
    } else {
      _cachedImageProvider = MemoryImage(_transparentPixel);
    }
    return _cachedImageProvider!;
  }

  /// Retorna y cachea una versión ligera para miniaturas (evita saturar GPU y decodificar 4K)
  ImageProvider get thumbnailProvider {
    if (_cachedThumbnailProvider != null) return _cachedThumbnailProvider!;
    final localBytes = _resolveLocalBytes();
    if (localBytes != null) {
      _cachedThumbnailProvider = ResizeImage.resizeIfNeeded(
        360,
        null,
        MemoryImage(localBytes),
      );
    } else if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      final thumbUrl = _sizedRemoteUrl(remoteUrl!, 'w600');
      _cachedThumbnailProvider = NetworkImage(
        thumbUrl,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      );
    } else {
      _cachedThumbnailProvider = imageProvider;
    }
    return _cachedThumbnailProvider!;
  }

  static final Uint8List _transparentPixel = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  Map<String, dynamic> toJson() {
    String? safeInlineBase64;
    if (remoteUrl == null) {
      if (base64Data != null && base64Data!.length <= 350000) {
        safeInlineBase64 = base64Data;
      } else if (bytes != null && bytes!.length <= 262144) {
        safeInlineBase64 = base64Encode(bytes!);
      }
    }
    return {
      'id': id,
      'fileName': fileName,
      'remoteUrl': remoteUrl,
      // Evitar exceder la cuota de 5MB de localStorage si no hay URL remota
      'base64Data': safeInlineBase64,
      'timestamp': timestamp.toIso8601String(),
      'caption': caption,
      'fileSize': fileSize,
      'mimeType': mimeType,
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    Uint8List? rawBytes;
    final b64 = json['base64Data'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        rawBytes = base64Decode(b64);
      } catch (_) {}
    }

    return MemoryItem(
      id: json['id'] as String? ?? UniqueKey().toString(),
      fileName: json['fileName'] as String? ?? 'recuerdo.jpg',
      remoteUrl: json['remoteUrl'] as String?,
      base64Data: b64,
      bytes: rawBytes,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      caption: json['caption'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType'] as String?,
    );
  }
}
