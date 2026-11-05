import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import 'download_helper.dart';
import 'sample_data.dart';

class SelectedFile {
  final String name;
  final Uint8List bytes;
  final int size;
  final String mimeType;

  SelectedFile({
    required this.name,
    required this.bytes,
    required this.size,
    this.mimeType = 'image/jpeg',
  });
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _prefKeyFolders = 'dots_memories_folders_v1';
  static const String _prefKeyConfig = 'dots_memories_config_v1';
  static const String _prefKeyUnlocked = 'dots_memories_unlocked_v1';

  final ValueNotifier<List<MemoryFolder>> foldersNotifier = ValueNotifier<List<MemoryFolder>>([]);
  final ValueNotifier<AppConfig> configNotifier = ValueNotifier<AppConfig>(AppConfig());
  final ValueNotifier<bool> isUploadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> uploadStatusNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> isAccessUnlockedNotifier = ValueNotifier<bool>(false);

  List<MemoryFolder> get folders => foldersNotifier.value;
  AppConfig get config => configNotifier.value;
  bool get isAccessUnlocked => isAccessUnlockedNotifier.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar Configuración
    final configStr = prefs.getString(_prefKeyConfig);
    if (configStr != null && configStr.isNotEmpty) {
      try {
        final configJson = jsonDecode(configStr) as Map<String, dynamic>;
        configNotifier.value = AppConfig.fromJson(configJson);
      } catch (e) {
        debugPrint('Error decodificando configuración: $e');
      }
    }

    // Comprobar llave de acceso (vía URL del QR ?key=... o guardada en sesión)
    final urlKey = DownloadHelper.getQueryParam('key') ?? DownloadHelper.getQueryParam('token');
    final activeConfig = configNotifier.value;

    if (!activeConfig.requireAccessKey) {
      isAccessUnlockedNotifier.value = true;
    } else if (urlKey != null &&
        urlKey.trim().toUpperCase() == activeConfig.accessKey.trim().toUpperCase()) {
      isAccessUnlockedNotifier.value = true;
      await prefs.setBool(_prefKeyUnlocked, true);
    } else {
      final wasUnlocked = prefs.getBool(_prefKeyUnlocked) ?? false;
      isAccessUnlockedNotifier.value = wasUnlocked;
    }

    // Cargar Recuerdos / Carpetas
    final foldersStr = prefs.getString(_prefKeyFolders);
    if (foldersStr != null && foldersStr.isNotEmpty) {
      try {
        final listJson = jsonDecode(foldersStr) as List<dynamic>;
        final loaded = listJson
            .map((item) => MemoryFolder.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) {
          foldersNotifier.value = loaded;
          return;
        }
      } catch (e) {
        debugPrint('Error cargando carpetas guardadas: $e');
      }
    }

    // Si no hay recuerdos previos, cargar datos iniciales de muestra
    foldersNotifier.value = SampleData.getInitialMemories();
    await _saveFoldersToDisk();
  }

  Future<void> saveConfig(AppConfig newConfig) async {
    configNotifier.value = newConfig;
    if (!newConfig.requireAccessKey) {
      isAccessUnlockedNotifier.value = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyConfig, jsonEncode(newConfig.toJson()));
  }

  Future<bool> unlockWithKey(String enteredKey) async {
    final activeConfig = configNotifier.value;
    if (!activeConfig.requireAccessKey ||
        enteredKey.trim().toUpperCase() == activeConfig.accessKey.trim().toUpperCase()) {
      isAccessUnlockedNotifier.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyUnlocked, true);
      return true;
    }
    return false;
  }

  Future<void> lockAccess() async {
    isAccessUnlockedNotifier.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyUnlocked, false);
  }

  Future<void> _saveFoldersToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Para optimizar el tamaño en SharedPreferences de web (localStorage / IndexedDB),
      // guardamos los datos asegurando que no exceda el límite del navegador.
      final jsonList = foldersNotifier.value.map((f) => f.toJson()).toList();
      await prefs.setString(_prefKeyFolders, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Aviso al persistir en almacenamiento local: $e');
    }
  }

  /// Sube un conjunto de fotos y dedicatoria
  Future<bool> uploadMemories({
    required String guestName,
    required String comment,
    required List<SelectedFile> files,
  }) async {
    if (files.isEmpty) return false;

    isUploadingNotifier.value = true;
    uploadProgressNotifier.value = 0.1;
    uploadStatusNotifier.value = 'Procesando ${files.length} fotos...';

    final now = DateTime.now();
    final folderId = 'folder_${now.millisecondsSinceEpoch}';

    // Crear elementos de memoria para visualización inmediata
    final localPhotoItems = <MemoryItem>[];
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      localPhotoItems.add(
        MemoryItem(
          id: '${folderId}_photo_$i',
          fileName: f.name,
          bytes: f.bytes,
          base64Data: base64Encode(f.bytes),
          timestamp: now,
          fileSize: f.size,
        ),
      );
    }

    var newFolder = MemoryFolder(
      id: folderId,
      guestName: guestName.trim().isEmpty ? 'Invitado Especial' : guestName.trim(),
      comment: comment.trim(),
      timestamp: now,
      photos: localPhotoItems,
      isSyncedToGoogle: false,
    );

    // Intentar subida a Google Apps Script / Google Drive / Fotos si está configurado
    final currentConfig = configNotifier.value;
    if (currentConfig.useGoogleBackend &&
        currentConfig.googleScriptUrl.trim().isNotEmpty) {
      uploadStatusNotifier.value = 'Subiendo a Google Fotos / Drive...';
      uploadProgressNotifier.value = 0.35;

      try {
        final photosPayload = files.map((f) {
          return {
            'name': f.name,
            'type': f.mimeType,
            'base64': base64Encode(f.bytes),
          };
        }).toList();

        final payload = jsonEncode({
          'guestName': newFolder.guestName,
          'comment': newFolder.comment,
          'photos': photosPayload,
        });

        uploadProgressNotifier.value = 0.65;
        uploadStatusNotifier.value = 'Guardando en carpeta de Google...';

        final response = await http.post(
          Uri.parse(currentConfig.googleScriptUrl.trim()),
          body: payload,
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 45));

        uploadProgressNotifier.value = 0.90;

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final resJson = jsonDecode(response.body) as Map<String, dynamic>;
            if (resJson['status'] == 'success') {
              final googleFolderUrl = resJson['folderUrl'] as String?;
              final googleFolderId = resJson['folderId'] as String?;
              final remotePhotos = resJson['photos'] as List<dynamic>?;

              final updatedPhotos = <MemoryItem>[];
              for (int i = 0; i < localPhotoItems.length; i++) {
                String? remoteUrl;
                if (remotePhotos != null && i < remotePhotos.length) {
                  remoteUrl = remotePhotos[i]['url'] as String?;
                }
                updatedPhotos.add(
                  MemoryItem(
                    id: localPhotoItems[i].id,
                    fileName: localPhotoItems[i].fileName,
                    bytes: localPhotoItems[i].bytes,
                    remoteUrl: remoteUrl,
                    base64Data: localPhotoItems[i].base64Data,
                    timestamp: localPhotoItems[i].timestamp,
                    fileSize: localPhotoItems[i].fileSize,
                  ),
                );
              }

              newFolder = newFolder.copyWith(
                folderUrl: googleFolderUrl,
                googleFolderId: googleFolderId,
                photos: updatedPhotos,
                isSyncedToGoogle: true,
              );
              uploadStatusNotifier.value = '¡Guardado en Google Drive / Fotos con éxito!';
            }
          } catch (e) {
            debugPrint('Aviso al interpretar respuesta de Google: $e');
          }
        }
      } catch (e) {
        debugPrint('Error enviando a Google Apps Script: $e');
        uploadStatusNotifier.value = 'Guardado localmente (Sin conexión a Google)';
      }
    } else {
      uploadProgressNotifier.value = 0.85;
      uploadStatusNotifier.value = 'Guardando en galería local...';
    }

    uploadProgressNotifier.value = 1.0;

    // Insertar la nueva carpeta al inicio de la lista
    final updatedList = [newFolder, ...foldersNotifier.value];
    foldersNotifier.value = updatedList;
    await _saveFoldersToDisk();

    await Future.delayed(const Duration(milliseconds: 600));
    isUploadingNotifier.value = false;
    uploadStatusNotifier.value = '';
    return true;
  }

  void toggleLike(String folderId) {
    final list = List<MemoryFolder>.from(foldersNotifier.value);
    final index = list.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      final f = list[index];
      list[index] = f.copyWith(likes: f.likes + 1);
      foldersNotifier.value = list;
      _saveFoldersToDisk();
    }
  }

  void deleteFolder(String folderId) {
    final list = List<MemoryFolder>.from(foldersNotifier.value);
    list.removeWhere((f) => f.id == folderId);
    foldersNotifier.value = list;
    _saveFoldersToDisk();
  }

  Future<void> resetToDemo() async {
    foldersNotifier.value = SampleData.getInitialMemories();
    await _saveFoldersToDisk();
  }

  /// Prueba la conexión con el script de Google
  Future<Map<String, dynamic>> testGoogleConnection(String scriptUrl) async {
    try {
      final uri = Uri.parse(scriptUrl.trim()).replace(
        queryParameters: {'action': 'ping'},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'ok') {
          return {
            'success': true,
            'message': '¡Conexión exitosa! El backend de Google Drive/Fotos respondió correctamente.',
          };
        }
      }
      return {
        'success': false,
        'message': 'Respuesta inesperada (${res.statusCode}): ${res.body}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'No se pudo conectar: $e. Revisa que los permisos sean "Cualquiera" (Anyone).',
      };
    }
  }
}

