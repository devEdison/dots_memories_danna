import 'memory_item.dart';

class MemoryFolder {
  final String id;
  final String guestName;
  final String comment;
  final DateTime timestamp;
  final List<MemoryItem> photos;
  final String? folderUrl;
  final String? googleFolderId;
  final String? deviceId;
  int likes;
  bool isSyncedToGoogle;

  MemoryFolder({
    required this.id,
    required this.guestName,
    required this.comment,
    required this.timestamp,
    required this.photos,
    this.folderUrl,
    this.googleFolderId,
    this.deviceId,
    this.likes = 0,
    this.isSyncedToGoogle = false,
  });

  /// Retorna la primera foto como portada o null si no hay fotos
  MemoryItem? get coverPhoto => photos.isNotEmpty ? photos.first : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guestName': guestName,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'photos': photos.map((p) => p.toJson()).toList(),
      'folderUrl': folderUrl,
      'googleFolderId': googleFolderId,
      'deviceId': deviceId,
      'likes': likes,
      'isSyncedToGoogle': isSyncedToGoogle,
    };
  }

  factory MemoryFolder.fromJson(Map<String, dynamic> json) {
    return MemoryFolder(
      id: json['id'] as String? ?? '',
      guestName: json['guestName'] as String? ?? 'Invitado',
      comment: json['comment'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((item) => MemoryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      folderUrl: json['folderUrl'] as String?,
      googleFolderId: json['googleFolderId'] as String?,
      deviceId: json['deviceId'] as String?,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      isSyncedToGoogle: json['isSyncedToGoogle'] as bool? ?? false,
    );
  }

  MemoryFolder copyWith({
    String? id,
    String? guestName,
    String? comment,
    DateTime? timestamp,
    List<MemoryItem>? photos,
    String? folderUrl,
    String? googleFolderId,
    String? deviceId,
    int? likes,
    bool? isSyncedToGoogle,
  }) {
    return MemoryFolder(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
      photos: photos ?? this.photos,
      folderUrl: folderUrl ?? this.folderUrl,
      googleFolderId: googleFolderId ?? this.googleFolderId,
      deviceId: deviceId ?? this.deviceId,
      likes: likes ?? this.likes,
      isSyncedToGoogle: isSyncedToGoogle ?? this.isSyncedToGoogle,
    );
  }
}

