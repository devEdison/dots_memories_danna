import 'dart:convert';
import 'dart:math';
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

  bool get isVideo =>
      mimeType.toLowerCase().startsWith('video/') ||
      name.toLowerCase().endsWith('.mp4') ||
      name.toLowerCase().endsWith('.mov') ||
      name.toLowerCase().endsWith('.webm') ||
      name.toLowerCase().endsWith('.avi') ||
      name.toLowerCase().endsWith('.mkv') ||
      name.toLowerCase().endsWith('.m4v') ||
      name.toLowerCase().endsWith('.3gp');
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _prefKeyFolders = 'dots_memories_folders_v1';
  static const String _prefKeyConfig = 'dots_memories_config_v1';
  static const String _prefKeyUnlocked = 'dots_memories_unlocked_v1';
  static const String _prefKeyMyFolders = 'dots_my_folder_ids_v1';
  static const String _prefKeyMyGuestName = 'dots_my_guest_name_v1';
  static const String _prefKeyDeviceId = 'dots_device_id_v1';

  final http.Client _httpClient = http.Client();
  Future<int>? _inFlightSync;

  String deviceId = '';

  final ValueNotifier<List<MemoryFolder>> foldersNotifier = ValueNotifier<List<MemoryFolder>>([]);
  final ValueNotifier<AppConfig> configNotifier = ValueNotifier<AppConfig>(AppConfig());
  final ValueNotifier<bool> isUploadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadProgressNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<String> uploadStatusNotifier = ValueNotifier<String>('');
  final ValueNotifier<bool> isAccessUnlockedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier<bool>(false);

  // Registro de recuerdos del invitado en este dispositivo
  final ValueNotifier<List<String>> myFolderIdsNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<String> myGuestNameNotifier = ValueNotifier<String>('');

  List<MemoryFolder> get folders => foldersNotifier.value;
  AppConfig get config => configNotifier.value;
  bool get isAccessUnlocked => isAccessUnlockedNotifier.value;
  bool get isSyncing => isSyncingNotifier.value;

  /// Retorna la carpeta principal de este dispositivo si ya existe
  MemoryFolder? get myDeviceFolder {
    final myF = myFolders;
    return myF.isNotEmpty ? myF.first : null;
  }

  /// Retorna ÚNICAMENTE las carpetas que pertenecen al invitado de este dispositivo
  List<MemoryFolder> get myFolders {
    final myIds = myFolderIdsNotifier.value;
    final guestName = myGuestNameNotifier.value.trim().toLowerCase();

    return foldersNotifier.value.where((f) {
      // 1. Vinculación estricta por ID de dispositivo
      if (deviceId.isNotEmpty && f.deviceId != null && f.deviceId == deviceId) {
        return true;
      }
      // 2. Vinculación por IDs de carpetas registradas localmente
      if (myIds.contains(f.id) || (f.googleFolderId != null && myIds.contains(f.googleFolderId))) {
        return true;
      }
      // 3. Vinculación por nombre del invitado de este dispositivo
      if (guestName.isNotEmpty && f.guestName.trim().toLowerCase() == guestName) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Inicializar o cargar identificador único persistente del dispositivo
    deviceId = prefs.getString(_prefKeyDeviceId) ?? '';
    if (deviceId.isEmpty) {
      final rand = Random().nextInt(900000) + 100000;
      deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
      await prefs.setString(_prefKeyDeviceId, deviceId);
    }

    // Cargar Configuración
    final configStr = prefs.getString(_prefKeyConfig);
    if (configStr != null && configStr.isNotEmpty) {
      try {
        final configJson = jsonDecode(configStr) as Map<String, dynamic>;
        final loadedConfig = AppConfig.fromJson(configJson);
        if (loadedConfig.googleScriptUrl.isEmpty) {
          loadedConfig.googleScriptUrl =
              'https://script.google.com/macros/s/AKfycbzeQ_sLwh-FkZh4YvmTh1YGRPa9GlpcwwOJEf9UiiWXTf3A-rpfJaXiXw1DBM88pDnN/exec';
          loadedConfig.useGoogleBackend = true;
        }
        configNotifier.value = loadedConfig;
      } catch (e) {
        debugPrint('Error decodificando configuración: $e');
      }
    }

    // Cargar carpetas y nombre de invitado de este dispositivo
    final savedMyIds = prefs.getStringList(_prefKeyMyFolders) ?? [];
    myFolderIdsNotifier.value = savedMyIds;
    final savedGuestName = prefs.getString(_prefKeyMyGuestName) ?? '';
    myGuestNameNotifier.value = savedGuestName;

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

    // Cargar Recuerdos / Carpetas desde caché local
    final foldersStr = prefs.getString(_prefKeyFolders);
    if (foldersStr != null && foldersStr.isNotEmpty) {
      try {
        final listJson = jsonDecode(foldersStr) as List<dynamic>;
        final loaded = listJson
            .map((item) => MemoryFolder.fromJson(item as Map<String, dynamic>))
            .toList();
        if (loaded.isNotEmpty) {
          foldersNotifier.value = loaded;
        }
      } catch (e) {
        debugPrint('Error cargando carpetas guardadas: $e');
      }
    }

    // Si aún no hay recuerdos, mostrar muestra inicial mientras sincroniza
    if (foldersNotifier.value.isEmpty) {
      foldersNotifier.value = SampleData.getInitialMemories();
    }

    // Sincronizar de inmediato con Google Fotos / Drive en segundo plano
    syncMemoriesFromGoogle();
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

  Future<void> setMyGuestName(String name) async {
    myGuestNameNotifier.value = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMyGuestName, name.trim());
  }

  Future<void> _saveFoldersToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = foldersNotifier.value.map((f) => f.toJson()).toList();
      await prefs.setString(_prefKeyFolders, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Aviso guardando en almacenamiento local: $e');
    }
  }

  Future<void> _saveMyFoldersToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKeyMyFolders, myFolderIdsNotifier.value);
      if (myGuestNameNotifier.value.isNotEmpty) {
        await prefs.setString(_prefKeyMyGuestName, myGuestNameNotifier.value);
      }
    } catch (e) {
      debugPrint('Aviso guardando identificador de invitado: $e');
    }
  }

  /// Sube fotos y videos seleccionados por el invitado a Appwrite Storage y Google Drive
  Future<bool> uploadMemories({
    required String guestName,
    required String comment,
    required List<SelectedFile> files,
  }) async {
    if (files.isEmpty) return false;

    isUploadingNotifier.value = true;
    uploadProgressNotifier.value = 0.1;
    final totalFiles = files.length;
    final videoCount = files.where((f) => f.isVideo).length;
    final photoCount = totalFiles - videoCount;

    String typeSummary = '$photoCount fotos';
    if (videoCount > 0) {
      typeSummary = photoCount > 0 ? '$photoCount fotos y $videoCount videos' : '$videoCount videos';
    }

    uploadStatusNotifier.value = 'Procesando $typeSummary...';

    final now = DateTime.now();

    // Detectar si este dispositivo ya tiene una carpeta para sumarle las fotos directamente
    final existingFolder = myDeviceFolder;
    final folderId = existingFolder?.id ?? 'folder_${now.millisecondsSinceEpoch}';
    final targetGuestName = guestName.trim().isNotEmpty
        ? guestName.trim()
        : (existingFolder?.guestName ?? 'Invitado Especial');
    final targetComment = comment.trim().isNotEmpty
        ? comment.trim()
        : (existingFolder?.comment ?? '');

    // Codificar Base64 una sola vez por archivo para reducir uso de memoria y CPU
    final encodedBase64 = <String?>[];
    for (final f in files) {
      encodedBase64.add(f.isVideo && f.size > 24 * 1024 * 1024 ? null : base64Encode(f.bytes));
    }

    // 1. Subir a Appwrite Storage en lotes concurrentes (máx. 3 en paralelo)
    final currentConfig = configNotifier.value;
    uploadStatusNotifier.value = 'Subiendo a Appwrite Storage CDN...';
    uploadProgressNotifier.value = 0.15;

    final appwritePhotoUrls = List<String?>.filled(files.length, null);
    int completedAppwrite = 0;
    const maxConcurrency = 3;

    Future<void> uploadSingleToAppwrite(int index) async {
      final f = files[index];
      try {
        final uploadUri = Uri.parse(
          '${currentConfig.appwriteEndpoint}/storage/buckets/${currentConfig.appwriteBucketId}/files',
        );
        final request = http.MultipartRequest('POST', uploadUri)
          ..headers['X-Appwrite-Project'] = currentConfig.appwriteProjectId
          ..fields['fileId'] = 'unique()'
          ..files.add(http.MultipartFile.fromBytes('file', f.bytes, filename: f.name));
        final streamed = await _httpClient.send(request).timeout(const Duration(seconds: 45));
        final body = await streamed.stream.bytesToString();
        if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
          final resJson = jsonDecode(body) as Map<String, dynamic>;
          final fId = resJson[r'$id'] as String;
          appwritePhotoUrls[index] =
              '${currentConfig.appwriteEndpoint}/storage/buckets/${currentConfig.appwriteBucketId}/files/$fId/view?project=${currentConfig.appwriteProjectId}';
        }
      } catch (e) {
        debugPrint('Aviso subida Appwrite Storage: $e');
      } finally {
        completedAppwrite++;
        uploadProgressNotifier.value = 0.15 + (completedAppwrite / files.length) * 0.35;
      }
    }

    for (int start = 0; start < files.length; start += maxConcurrency) {
      final end = (start + maxConcurrency) < files.length ? (start + maxConcurrency) : files.length;
      await Future.wait([
        for (int idx = start; idx < end; idx++) uploadSingleToAppwrite(idx),
      ]);
    }

    // Crear elementos de memoria para visualización inmediata (con URL de CDN lista)
    final localPhotoItems = <MemoryItem>[];
    final startIndex = existingFolder?.photos.length ?? 0;
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final aUrl = appwritePhotoUrls[i];
      localPhotoItems.add(
        MemoryItem(
          id: '${folderId}_media_${startIndex + i}',
          fileName: f.name,
          bytes: f.bytes,
          remoteUrl: aUrl,
          base64Data: (aUrl != null || f.isVideo) ? null : encodedBase64[i],
          timestamp: now,
          fileSize: f.size,
          mimeType: f.mimeType,
        ),
      );
    }

    var activeFolder = existingFolder != null
        ? existingFolder.copyWith(
            guestName: targetGuestName,
            comment: targetComment,
            photos: [...existingFolder.photos, ...localPhotoItems],
            timestamp: now,
            deviceId: deviceId,
          )
        : MemoryFolder(
            id: folderId,
            guestName: targetGuestName,
            comment: targetComment,
            timestamp: now,
            photos: localPhotoItems,
            deviceId: deviceId,
            isSyncedToGoogle: false,
          );

    // 2. Intentar subida y respaldo a Google Apps Script / Google Drive si está configurado
    if (currentConfig.useGoogleBackend &&
        currentConfig.googleScriptUrl.trim().isNotEmpty) {
      uploadStatusNotifier.value = 'Respaldando en Google Fotos / Drive...';
      uploadProgressNotifier.value = 0.55;

      try {
        String? targetGoogleFolderId = existingFolder?.googleFolderId;
        if (targetGoogleFolderId == null || targetGoogleFolderId.isEmpty) {
          if (existingFolder != null && !existingFolder.id.startsWith('folder_')) {
            targetGoogleFolderId = existingFolder.id;
          }
        }

        // Dividir en lotes seguros si el payload base64 supera ~14 MB para evitar timeouts de Apps Script
        final chunks = <List<int>>[];
        var currentChunk = <int>[];
        var currentChunkBytes = 0;
        const maxChunkBase64Chars = 14 * 1024 * 1024;

        for (int i = 0; i < files.length; i++) {
          final b64Len = encodedBase64[i]?.length ?? 0;
          if (currentChunk.isNotEmpty &&
              (currentChunkBytes + b64Len > maxChunkBase64Chars || currentChunk.length >= 4)) {
            chunks.add(currentChunk);
            currentChunk = <int>[];
            currentChunkBytes = 0;
          }
          currentChunk.add(i);
          currentChunkBytes += b64Len;
        }
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
        }

        String? googleFolderUrl = existingFolder?.folderUrl;
        final remoteUrlByFileIndex = <int, String?>{};
        bool googleSuccess = false;

        for (int cIdx = 0; cIdx < chunks.length; cIdx++) {
          final chunkIndices = chunks[cIdx];
          final photosPayload = <Map<String, dynamic>>[];
          for (final i in chunkIndices) {
            final f = files[i];
            photosPayload.add({
              'name': f.name,
              'type': f.mimeType,
              'base64': encodedBase64[i] ?? base64Encode(f.bytes),
              'appwriteUrl': appwritePhotoUrls[i],
            });
          }

          final payload = jsonEncode({
            'guestName': targetGuestName,
            'comment': targetComment,
            'deviceId': deviceId,
            'folderId': targetGoogleFolderId,
            'photos': photosPayload,
          });

          uploadProgressNotifier.value = 0.58 + ((cIdx + 0.5) / chunks.length) * 0.34;
          uploadStatusNotifier.value = chunks.length > 1
              ? 'Respaldando lote ${cIdx + 1} de ${chunks.length} en Drive...'
              : 'Guardando dedicatoria y archivos en tu carpeta...';

          final response = await _httpClient
              .post(
                Uri.parse(currentConfig.googleScriptUrl.trim()),
                body: payload,
                headers: {'Content-Type': 'text/plain'},
              )
              .timeout(const Duration(seconds: 55));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            try {
              final resJson = jsonDecode(response.body) as Map<String, dynamic>;
              if (resJson['status'] == 'success') {
                googleSuccess = true;
                googleFolderUrl = (resJson['folderUrl'] as String?) ?? googleFolderUrl;
                targetGoogleFolderId = (resJson['folderId'] as String?) ?? targetGoogleFolderId;
                final remotePhotos = resJson['photos'] as List<dynamic>?;
                    if (remotePhotos != null) {
                  for (final i in chunkIndices) {
                    final f = files[i];
                    Map<String, dynamic>? match;
                    for (final rp in remotePhotos) {
                      if (rp is Map<String, dynamic> && rp['name'] == f.name) {
                        match = rp;
                        break;
                      }
                    }
                    if (match != null && match['url'] is String) {
                      remoteUrlByFileIndex[i] = match['url'] as String;
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('Aviso al interpretar respuesta de Google: $e');
            }
          }
        }

        if (googleSuccess) {
          final updatedNewPhotos = <MemoryItem>[];
          for (int i = 0; i < localPhotoItems.length; i++) {
            final resolvedUrl = appwritePhotoUrls[i] ?? remoteUrlByFileIndex[i];
            updatedNewPhotos.add(
              MemoryItem(
                id: localPhotoItems[i].id,
                fileName: localPhotoItems[i].fileName,
                bytes: localPhotoItems[i].bytes,
                remoteUrl: resolvedUrl,
                base64Data: resolvedUrl != null ? null : localPhotoItems[i].base64Data,
                timestamp: localPhotoItems[i].timestamp,
                fileSize: localPhotoItems[i].fileSize,
                mimeType: localPhotoItems[i].mimeType,
              ),
            );
          }

          final finalPhotos = existingFolder != null
              ? [...existingFolder.photos, ...updatedNewPhotos]
              : updatedNewPhotos;

          activeFolder = activeFolder.copyWith(
            folderUrl: googleFolderUrl ?? existingFolder?.folderUrl,
            googleFolderId: targetGoogleFolderId ?? existingFolder?.googleFolderId,
            photos: finalPhotos,
            deviceId: deviceId,
            isSyncedToGoogle: true,
          );
          uploadStatusNotifier.value = '¡Guardado con éxito en tu carpeta!';
        }
      } catch (e) {
        debugPrint('Error enviando a Google Apps Script: $e');
        uploadStatusNotifier.value = 'Guardado en Appwrite Nube';
      }
    } else {
      uploadProgressNotifier.value = 0.85;
      uploadStatusNotifier.value = 'Guardando en galería...';
    }

    uploadProgressNotifier.value = 1.0;

    // Actualizar la carpeta en la lista (reemplazar si existía o insertar al inicio)
    final currentList = List<MemoryFolder>.from(foldersNotifier.value);
    final existingIndex = currentList.indexWhere((f) =>
        f.id == activeFolder.id ||
        (activeFolder.googleFolderId != null && f.googleFolderId == activeFolder.googleFolderId) ||
        (activeFolder.googleFolderId != null && f.id == activeFolder.googleFolderId) ||
        (f.deviceId != null && f.deviceId == deviceId));

    if (existingIndex != -1) {
      currentList[existingIndex] = activeFolder;
    } else {
      currentList.insert(0, activeFolder);
    }

    // Limpiar duplicados accidentales para este dispositivo
    final seenIds = <String>{};
    currentList.retainWhere((f) {
      if (f.id == activeFolder.id) return true;
      if (f.deviceId != null && f.deviceId == deviceId && f.id != activeFolder.id) {
        return false;
      }
      return seenIds.add(f.id);
    });
    foldersNotifier.value = currentList;
    await _saveFoldersToDisk();

    // Registrar como carpeta de este invitado en su espacio privado
    final currentMyIds = List<String>.from(myFolderIdsNotifier.value);
    if (!currentMyIds.contains(activeFolder.id)) {
      currentMyIds.insert(0, activeFolder.id);
    }
    if (activeFolder.googleFolderId != null && !currentMyIds.contains(activeFolder.googleFolderId!)) {
      currentMyIds.insert(0, activeFolder.googleFolderId!);
    }
    myFolderIdsNotifier.value = currentMyIds;
    if (activeFolder.guestName.isNotEmpty) {
      myGuestNameNotifier.value = activeFolder.guestName;
    }
    await _saveMyFoldersToDisk();

    // Sincronizar en segundo plano con la nube de Google
    syncMemoriesFromGoogle();

    await Future.delayed(const Duration(milliseconds: 600));
    isUploadingNotifier.value = false;
    uploadStatusNotifier.value = '';
    return true;
  }

  String _foldersFingerprint(List<MemoryFolder> list) {
    final buf = StringBuffer();
    for (final f in list) {
      buf
        ..write(f.id)
        ..write('|')
        ..write(f.guestName)
        ..write('|')
        ..write(f.comment)
        ..write('|')
        ..write(f.likes)
        ..write('|')
        ..write(f.photos.length)
        ..write('|');
      for (final p in f.photos) {
        buf
          ..write(p.id)
          ..write(':')
          ..write(p.remoteUrl ?? p.fileName)
          ..write(',');
      }
      buf.write(';');
    }
    return buf.toString();
  }

  /// Sincroniza en tiempo real las carpetas y fotos subidas a Google Drive / Fotos
  Future<int> syncMemoriesFromGoogle({bool showLoading = false}) {
    final currentConfig = configNotifier.value;
    if (!currentConfig.useGoogleBackend || currentConfig.googleScriptUrl.trim().isEmpty) {
      return Future.value(0);
    }

    if (showLoading) {
      isSyncingNotifier.value = true;
    }

    if (_inFlightSync != null) {
      return _inFlightSync!;
    }

    final future = _performSyncMemoriesFromGoogle(currentConfig);
    _inFlightSync = future;
    future.whenComplete(() {
      if (identical(_inFlightSync, future)) {
        _inFlightSync = null;
      }
    });
    return future;
  }

  Future<int> _performSyncMemoriesFromGoogle(AppConfig currentConfig) async {
    try {
      final listUri = Uri.parse('${currentConfig.googleScriptUrl.trim()}?action=list');
      final response = await _httpClient.get(listUri).timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Preservar conteo de likes locales entre sincronizaciones
        final existingLikes = <String, int>{};
        for (final existing in foldersNotifier.value) {
          existingLikes[existing.id] = existing.likes;
          if (existing.googleFolderId != null) {
            existingLikes[existing.googleFolderId!] = existing.likes;
          }
        }

        // Actualizar URL directa de la carpeta principal de Google Drive si viene en la respuesta
        final driveUrl = data['mainDriveFolderUrl'] as String?;
        if (driveUrl != null && driveUrl.isNotEmpty && driveUrl != currentConfig.googleDriveFolderUrl) {
          currentConfig.googleDriveFolderUrl = driveUrl;
          configNotifier.value = currentConfig;
          saveConfig(currentConfig);
        }

        final memoriesList = data['memories'] as List<dynamic>?;

        if (memoriesList != null && memoriesList.isNotEmpty) {
          final loadedFolders = <MemoryFolder>[];

          for (final item in memoriesList) {
            final folderMap = item as Map<String, dynamic>;
            final metaGuestName = folderMap['guestName'] as String?;
            final cleanGuestName = (metaGuestName != null && metaGuestName.trim().isNotEmpty)
                ? metaGuestName.trim()
                : (folderMap['folderName'] as String? ?? 'Invitado')
                    .replaceAll(RegExp(r'\s*\(\d{4}-\d{2}-\d{2}.*\)'), '')
                    .trim();

            // Limpiar dedicatoria si viene formateada con cabeceras
            var rawComment = folderMap['comment'] as String? ?? '';
            String cleanComment = rawComment;
            if (rawComment.contains('DEDICATORIA / MENSAJE:')) {
              final parts = rawComment.split('DEDICATORIA / MENSAJE:');
              if (parts.length > 1) {
                cleanComment = parts[1]
                    .replaceAll(RegExp(r'═+'), '')
                    .replaceAll('(Sin mensaje de texto)', '')
                    .trim();
              }
            }

            final rawPhotos = folderMap['photos'] as List<dynamic>? ?? [];
            final photosItems = <MemoryItem>[];

            for (int i = 0; i < rawPhotos.length; i++) {
              final p = rawPhotos[i] as Map<String, dynamic>;
              final pId = p['id'] as String? ?? '${folderMap['folderId']}_photo_$i';
              final pName = p['name'] as String? ?? 'archivo_${i + 1}.jpg';

              // Priorizar URL de Appwrite Storage CDN para evitar error 429 de Google Drive
              String pUrl = p['appwriteUrl'] as String? ?? '';
              if (pUrl.isEmpty) {
                if (pId == '1suOg92VkiELFrKpO5LTu2W4O-dxeu8Q8') {
                  pUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/photos/files/6af23d8f369a3dc77748/view?project=danna15-memories';
                } else if (pId == '1B8duLCsx0DqsHM5y9m58Ze0eT2C7T5Ad') {
                  pUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/photos/files/6af23def35cad9eacb10/view?project=danna15-memories';
                } else if (pId == '1raLOylF7hTxeFctlTiUatPvFnSzIObFP' || pName.contains('Captura de pantalla 2026-10-28')) {
                  pUrl = 'https://fra.cloud.appwrite.io/v1/storage/buckets/photos/files/6af2439cb4ad0a6a4dc6/view?project=danna15-memories';
                } else {
                  pUrl = p['url'] as String? ?? 'https://lh3.googleusercontent.com/d/$pId';
                }
              }

              final lowerName = pName.toLowerCase();
              final isVid = lowerName.endsWith('.mp4') ||
                  lowerName.endsWith('.mov') ||
                  lowerName.endsWith('.webm') ||
                  lowerName.endsWith('.avi') ||
                  lowerName.endsWith('.mkv');

              photosItems.add(
                MemoryItem(
                  id: pId,
                  fileName: pName,
                  remoteUrl: pUrl,
                  mimeType: isVid ? 'video/mp4' : 'image/jpeg',
                  timestamp: folderMap['created'] != null
                      ? (DateTime.tryParse(folderMap['created'] as String) ?? DateTime.now())
                      : DateTime.now(),
                ),
              );
            }

            // Omitir carpetas de prueba del sistema vacías
            if (photosItems.isEmpty && (cleanGuestName.toLowerCase().contains('test') || cleanGuestName.toLowerCase().contains('prueba'))) {
              continue;
            }

            final remoteDevId = folderMap['deviceId'] as String?;
            final folderId = folderMap['folderId'] as String?;
            final isMyDevice = (remoteDevId != null && remoteDevId.isNotEmpty && remoteDevId == deviceId) ||
                (folderId != null && myFolderIdsNotifier.value.contains(folderId)) ||
                (myGuestNameNotifier.value.isNotEmpty && cleanGuestName.toLowerCase() == myGuestNameNotifier.value.toLowerCase());

            if (isMyDevice && folderId != null) {
              final myIds = List<String>.from(myFolderIdsNotifier.value);
              if (!myIds.contains(folderId)) {
                myIds.add(folderId);
                myFolderIdsNotifier.value = myIds;
                _saveMyFoldersToDisk();
              }
              if (myGuestNameNotifier.value.isEmpty && cleanGuestName.isNotEmpty) {
                myGuestNameNotifier.value = cleanGuestName;
              }
            }

            final resolvedId = folderId ?? UniqueKey().toString();
            loadedFolders.add(
              MemoryFolder(
                id: resolvedId,
                guestName: cleanGuestName.isEmpty ? 'Invitado Especial' : cleanGuestName,
                comment: cleanComment,
                timestamp: folderMap['created'] != null
                    ? (DateTime.tryParse(folderMap['created'] as String) ?? DateTime.now())
                    : DateTime.now(),
                photos: photosItems,
                folderUrl: folderMap['folderUrl'] as String?,
                googleFolderId: folderId,
                deviceId: isMyDevice ? deviceId : remoteDevId,
                likes: existingLikes[resolvedId] ?? (folderId != null ? existingLikes[folderId] : null) ?? 0,
                isSyncedToGoogle: true,
              ),
            );
          }

          if (loadedFolders.isNotEmpty) {
            // Consolidar carpetas del mismo dispositivo para que el invitado siempre vea sus fotos unificadas
            final consolidated = <String, MemoryFolder>{};
            for (final f in loadedFolders) {
              final isThisDevice = (f.deviceId != null && f.deviceId!.isNotEmpty && f.deviceId == deviceId) ||
                  (myFolderIdsNotifier.value.contains(f.id)) ||
                  (f.googleFolderId != null && myFolderIdsNotifier.value.contains(f.googleFolderId!));

              final key = isThisDevice ? 'my_device_$deviceId' : (f.googleFolderId ?? f.id);

              if (consolidated.containsKey(key)) {
                final existing = consolidated[key]!;
                final existingNames = existing.photos.map((p) => p.fileName).toSet();
                final mergedPhotos = List<MemoryItem>.from(existing.photos);
                for (final p in f.photos) {
                  if (!existingNames.contains(p.fileName)) {
                    mergedPhotos.add(p);
                    existingNames.add(p.fileName);
                  }
                }
                consolidated[key] = existing.copyWith(
                  photos: mergedPhotos,
                  timestamp: f.timestamp.isAfter(existing.timestamp) ? f.timestamp : existing.timestamp,
                  comment: existing.comment.isNotEmpty ? existing.comment : f.comment,
                  googleFolderId: existing.googleFolderId ?? f.googleFolderId,
                  folderUrl: existing.folderUrl ?? f.folderUrl,
                  deviceId: deviceId,
                  likes: existing.likes > f.likes ? existing.likes : f.likes,
                );
              } else {
                consolidated[key] = f;
              }
            }

            final finalFolders = consolidated.values.toList();
            // Ordenar con las más recientes primero
            finalFolders.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            // Evitar reconstrucciones UI y escrituras en disco si no hubo cambios reales
            if (_foldersFingerprint(finalFolders) != _foldersFingerprint(foldersNotifier.value)) {
              foldersNotifier.value = finalFolders;
              await _saveFoldersToDisk();
            }
            return finalFolders.length;
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso sincronizando recuerdos desde Google: $e');
    } finally {
      isSyncingNotifier.value = false;
    }
    return 0;
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
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json['status'] == 'ok') {
          final driveUrl = json['mainDriveFolderUrl'] as String?;
          if (driveUrl != null && driveUrl.isNotEmpty) {
            final c = configNotifier.value;
            c.googleDriveFolderUrl = driveUrl;
            configNotifier.value = c;
            saveConfig(c);
          }
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
