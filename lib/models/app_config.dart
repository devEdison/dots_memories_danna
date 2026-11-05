class AppConfig {
  String googleScriptUrl;
  bool useGoogleBackend;
  String eventTitle;
  String eventDate;
  String quinceaneraName;
  String accessKey;
  bool requireAccessKey;
  String googlePhotosAlbumUrl;
  String googlePhotosAlbumId;

  AppConfig({
    this.googleScriptUrl =
        'https://script.google.com/macros/s/AKfycbzeQ_sLwh-FkZh4YvmTh1YGRPa9GlpcwwOJEf9UiiWXTf3A-rpfJaXiXw1DBM88pDnN/exec',
    this.useGoogleBackend = true,
    this.eventTitle = 'Mis 15 Años • Danna 👑✨',
    this.eventDate = '2026-11-04',
    this.quinceaneraName = 'Danna',
    this.accessKey = 'DANNA15',
    this.requireAccessKey = true,
    this.googlePhotosAlbumUrl =
        'https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm',
    this.googlePhotosAlbumId = 'AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm',
  });

  Map<String, dynamic> toJson() {
    return {
      'googleScriptUrl': googleScriptUrl,
      'useGoogleBackend': useGoogleBackend,
      'eventTitle': eventTitle,
      'eventDate': eventDate,
      'quinceaneraName': quinceaneraName,
      'accessKey': accessKey,
      'requireAccessKey': requireAccessKey,
      'googlePhotosAlbumUrl': googlePhotosAlbumUrl,
      'googlePhotosAlbumId': googlePhotosAlbumId,
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['googleScriptUrl'] as String?;
    final scriptUrl = (rawUrl != null && rawUrl.isNotEmpty)
        ? rawUrl
        : 'https://script.google.com/macros/s/AKfycbzeQ_sLwh-FkZh4YvmTh1YGRPa9GlpcwwOJEf9UiiWXTf3A-rpfJaXiXw1DBM88pDnN/exec';

    return AppConfig(
      googleScriptUrl: scriptUrl,
      useGoogleBackend: json['useGoogleBackend'] as bool? ?? true,
      eventTitle: json['eventTitle'] as String? ?? 'Mis 15 Años • Danna 👑✨',
      eventDate: json['eventDate'] as String? ?? '2026-11-04',
      quinceaneraName: json['quinceaneraName'] as String? ?? 'Danna',
      accessKey: json['accessKey'] as String? ?? 'DANNA15',
      requireAccessKey: json['requireAccessKey'] as bool? ?? true,
      googlePhotosAlbumUrl: json['googlePhotosAlbumUrl'] as String? ??
          'https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm',
      googlePhotosAlbumId: json['googlePhotosAlbumId'] as String? ??
          'AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm',
    );
  }
}
