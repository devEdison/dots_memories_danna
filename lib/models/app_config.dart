class AppConfig {
  String googleScriptUrl;
  bool useGoogleBackend;
  String eventTitle;
  String eventDate;
  String quinceaneraName;
  String accessKey;
  bool requireAccessKey;

  AppConfig({
    this.googleScriptUrl = '',
    this.useGoogleBackend = false,
    this.eventTitle = 'Mis 15 Años • Danna 👑✨',
    this.eventDate = '2026-11-04',
    this.quinceaneraName = 'Danna',
    this.accessKey = 'DANNA15',
    this.requireAccessKey = true,
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
    };
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      googleScriptUrl: json['googleScriptUrl'] as String? ?? '',
      useGoogleBackend: json['useGoogleBackend'] as bool? ?? false,
      eventTitle: json['eventTitle'] as String? ?? 'Mis 15 Años • Danna 👑✨',
      eventDate: json['eventDate'] as String? ?? '2026-11-04',
      quinceaneraName: json['quinceaneraName'] as String? ?? 'Danna',
      accessKey: json['accessKey'] as String? ?? 'DANNA15',
      requireAccessKey: json['requireAccessKey'] as bool? ?? true,
    );
  }
}
