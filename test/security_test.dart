import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dots_memories_danna/main.dart';
import 'package:dots_memories_danna/models/app_config.dart';
import 'package:dots_memories_danna/models/memory_folder.dart';
import 'package:dots_memories_danna/models/memory_item.dart';
import 'package:dots_memories_danna/services/appwrite_auth_service.dart';
import 'package:dots_memories_danna/services/download_helper.dart';
import 'package:dots_memories_danna/services/storage_service.dart';
import 'package:dots_memories_danna/widgets/gatekeeper_screen.dart';
import 'package:dots_memories_danna/widgets/guest_portal_screen.dart';
import 'package:dots_memories_danna/widgets/photo_lightbox.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  final samplePngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  late StorageService storage;
  late AppwriteAuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    authService = AppwriteAuthService();

    storage.deviceId = '';
    storage.configNotifier.value = AppConfig();
    storage.foldersNotifier.value = [];
    storage.myFolderIdsNotifier.value = [];
    storage.myGuestNameNotifier.value = '';
    storage.isAccessUnlockedNotifier.value = false;
    storage.bindAdminSessionChecker(null);
    storage.setHttpClientForTest(null);
    authService.currentUserNotifier.value = null;
    authService.isLoggedInNotifier.value = false;
  });

  tearDown(() {
    storage.bindAdminSessionChecker(null);
    storage.setHttpClientForTest(null);
    authService.currentUserNotifier.value = null;
    authService.isLoggedInNotifier.value = false;
  });

  group('Pruebas de Seguridad: Gatekeeper y Autenticación', () {
    testWidgets('Sin sesión Admin ni clave QR muestra exclusivamente GatekeeperScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        DotsMemoriesApp(
          storageService: storage,
          authService: authService,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GatekeeperScreen), findsOneWidget);
      expect(find.byType(GuestPortalScreen), findsNothing);
      expect(find.byType(HomeScreen), findsNothing);
    });

    test('unlockWithKey rechaza claves inválidas, vacías o configuración con clave en blanco',
        () async {
      storage.configNotifier.value = AppConfig(
        requireAccessKey: true,
        accessKey: 'DANNA15',
      );

      expect(await storage.unlockWithKey(''), isFalse);
      expect(await storage.unlockWithKey('   '), isFalse);
      expect(await storage.unlockWithKey('INCORRECTA'), isFalse);
      expect(await storage.unlockWithKey('DANNA14'), isFalse);
      expect(storage.isAccessUnlockedNotifier.value, isFalse);

      // Even if a tampered config has blank accessKey, blank input must not bypass lock
      storage.configNotifier.value = AppConfig(
        requireAccessKey: true,
        accessKey: '   ',
      );
      expect(await storage.unlockWithKey(''), isFalse);
      expect(storage.isAccessUnlockedNotifier.value, isFalse);
    });
  });

  group('Pruebas de Seguridad: Aislamiento de Roles (Invitado vs Admin)', () {
    testWidgets('Invitado desbloqueado entra a GuestPortalScreen y nunca ve controles Admin',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      storage.deviceId = 'dev_guest_ui';
      storage.isAccessUnlockedNotifier.value = true;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);

      await tester.pumpWidget(
        DotsMemoriesApp(
          storageService: storage,
          authService: authService,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GuestPortalScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byIcon(Icons.settings_rounded), findsNothing);
      expect(find.byIcon(Icons.slideshow_rounded), findsNothing);
      expect(find.text('Muro de Fotos'), findsNothing);
    });

    test('Invitado no autenticado como Admin tiene bloqueado deleteFolder, deletePhoto admin, saveConfig y resetToDemo',
        () async {
      storage.deviceId = 'dev_guest_1';
      storage.isAccessUnlockedNotifier.value = true;
      authService.isLoggedInNotifier.value = false;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);

      final victimPhoto = MemoryItem(
        id: 'photo_victim_1',
        fileName: 'victim.jpg',
        bytes: samplePngBytes,
        timestamp: DateTime(2026, 11, 10),
      );
      final victimFolder = MemoryFolder(
        id: 'folder_victim_1',
        guestName: 'Mariana',
        comment: 'Felicidades',
        deviceId: 'dev_victim_99',
        timestamp: DateTime(2026, 11, 10),
        photos: [victimPhoto],
      );
      storage.foldersNotifier.value = [victimFolder];

      // 1. Invitado intenta borrar una carpeta completa
      final folderRes = await storage.deleteFolder(victimFolder);
      expect(folderRes.success, isFalse);
      expect(storage.foldersNotifier.value, hasLength(1));

      // 2. Invitado intenta llamar deletePhoto saltando requireGuestOwnership
      final photoRes = await storage.deletePhoto(
        victimPhoto,
        folderHint: victimFolder,
        requireGuestOwnership: false,
      );
      expect(photoRes.success, isFalse);
      expect(storage.foldersNotifier.value.first.photos, hasLength(1));

      // 3. Invitado intenta alterar configuración crítica (accessKey / backend URL)
      final configSaved = await storage.saveConfig(
        AppConfig(
          accessKey: 'HACKEADA',
          googleScriptUrl: 'https://evil.example.com/steal',
          requireAccessKey: false,
        ),
        requireAdmin: true,
      );
      expect(configSaved, isFalse);
      expect(storage.configNotifier.value.accessKey, 'DANNA15');
      expect(storage.configNotifier.value.requireAccessKey, isTrue);

      // 4. Invitado intenta restaurar demo / sobrescribir galería
      final resetOk = await storage.resetToDemo();
      expect(resetOk, isFalse);
      expect(storage.foldersNotifier.value.first.id, 'folder_victim_1');
    });

    testWidgets('PhotoLightbox en modo solo lectura no muestra control de borrado',
        (WidgetTester tester) async {
      final photo = MemoryItem(
        id: 'photo_readonly_1',
        fileName: 'recuerdo.jpg',
        bytes: samplePngBytes,
        timestamp: DateTime(2026, 11, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PhotoLightbox(
            photos: [photo],
            initialIndex: 0,
          ),
        ),
      );
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });

  group('Pruebas de Seguridad: Anti-IDOR en Propiedad de Fotos (Invitados)', () {
    test('Un invitado NO puede apropiarse ni borrar fotos de otro escribiendo su nombre en Vincular por Nombre',
        () async {
      storage.deviceId = 'dev_attacker';
      storage.isAccessUnlockedNotifier.value = true;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);

      final carlosPhoto = MemoryItem(
        id: 'drive_file_carlos_1',
        fileName: 'carlos.jpg',
        remoteUrl: 'https://lh3.googleusercontent.com/d/drive_file_carlos_1',
        timestamp: DateTime(2026, 11, 10),
      );
      final carlosFolder = MemoryFolder(
        id: 'drive_folder_carlos',
        googleFolderId: 'drive_folder_carlos',
        guestName: 'Tío Carlos',
        comment: 'Con mucho cariño',
        deviceId: 'dev_carlos_original',
        isSyncedToGoogle: true,
        timestamp: DateTime(2026, 11, 10),
        photos: [carlosPhoto],
      );
      storage.foldersNotifier.value = [carlosFolder];

      // Atacante escribe "Tío Carlos" intentando suplantar al dueño original
      await storage.setMyGuestName('Tío Carlos');

      expect(storage.isFolderOwnedByGuest(carlosFolder), isFalse);
      expect(storage.myFolders, isEmpty);

      // Incluso limpiando su deviceId local, sigue bloqueado por pertenecer a otro deviceId remoto
      storage.deviceId = '';
      expect(storage.isFolderOwnedByGuest(carlosFolder), isFalse);

      // Restaurar deviceId del atacante e intentar borrar foto ajena
      storage.deviceId = 'dev_attacker';
      final deleteRes = await storage.deletePhoto(
        carlosPhoto,
        folderHint: carlosFolder,
        requireGuestOwnership: true,
      );
      expect(deleteRes.success, isFalse);
      expect(storage.foldersNotifier.value.first.photos, hasLength(1));
    });

    test('syncMemoriesFromGoogle tampoco permite secuestrar por nombre carpetas de otro dispositivo',
        () async {
      storage.deviceId = 'dev_attacker';
      storage.isAccessUnlockedNotifier.value = true;
      await storage.setMyGuestName('Sofía');

      storage.setHttpClientForTest(
        MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'memories': [
                {
                  'folderId': 'drive_folder_sofia',
                  'folderName': 'Sofía (2026-11-10)',
                  'guestName': 'Sofía',
                  'comment': 'Recuerdo privado',
                  'deviceId': 'dev_sofia_legitima',
                  'created': '2026-11-10T20:00:00.000Z',
                  'photos': [
                    {
                      'id': 'drive_photo_sofia_1',
                      'name': 'sofia.jpg',
                      'url': 'https://lh3.googleusercontent.com/d/drive_photo_sofia_1',
                    }
                  ],
                }
              ],
            }),
            200,
          );
        }),
      );

      await storage.syncMemoriesFromGoogle();

      expect(storage.foldersNotifier.value, hasLength(1));
      expect(storage.foldersNotifier.value.first.deviceId, 'dev_sofia_legitima');
      expect(storage.myFolderIdsNotifier.value, isNot(contains('drive_folder_sofia')));
      expect(storage.myFolders, isEmpty);
    });
  });

  group('Pruebas de Seguridad: Contrato Backend Apps Script (MockClient)', () {
    test('Si Google Apps Script rechaza por no autorizado (403/error), no elimina la foto localmente',
        () async {
      storage.deviceId = 'dev_own';
      storage.myFolderIdsNotifier.value = ['drive_folder_own'];
      storage.isAccessUnlockedNotifier.value = true;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);

      String? sentRole;
      String? sentDeviceId;
      storage.setHttpClientForTest(
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sentRole = body['role'] as String?;
          sentDeviceId = body['deviceId'] as String?;
          return http.Response(
            jsonEncode({
              'status': 'error',
              'action': 'deleteFile',
              'code': 403,
              'message': 'No autorizado: solo puedes eliminar fotos subidas desde tu dispositivo.',
            }),
            200,
          );
        }),
      );

      final photo = MemoryItem(
        id: 'drive_photo_own',
        fileName: 'mia.jpg',
        remoteUrl: 'https://lh3.googleusercontent.com/d/drive_photo_own',
        timestamp: DateTime(2026, 11, 10),
      );
      final folder = MemoryFolder(
        id: 'drive_folder_own',
        googleFolderId: 'drive_folder_own',
        guestName: 'Invitada',
        comment: 'Hola',
        deviceId: 'dev_own',
        isSyncedToGoogle: true,
        timestamp: DateTime(2026, 11, 10),
        photos: [photo],
      );
      storage.foldersNotifier.value = [folder];

      final res = await storage.deletePhoto(
        photo,
        folderHint: folder,
        requireGuestOwnership: true,
      );

      expect(sentRole, 'guest');
      expect(sentDeviceId, 'dev_own');
      expect(res.success, isFalse);
      expect(storage.foldersNotifier.value.first.photos, hasLength(1));
    });

    test('Admin envia role=admin al eliminar carpeta y respeta error del backend',
        () async {
      authService.isLoggedInNotifier.value = true;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);

      String? sentRole;
      storage.setHttpClientForTest(
        MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sentRole = body['role'] as String?;
          return http.Response(
            jsonEncode({
              'status': 'error',
              'action': 'deleteFolder',
              'code': 403,
              'message': 'Rechazado por script',
            }),
            200,
          );
        }),
      );

      final folder = MemoryFolder(
        id: 'drive_folder_x',
        googleFolderId: 'drive_folder_x',
        guestName: 'Pedro',
        comment: '',
        deviceId: 'dev_pedro',
        isSyncedToGoogle: true,
        timestamp: DateTime(2026, 11, 10),
        photos: const [],
      );
      storage.foldersNotifier.value = [folder];

      final res = await storage.deleteFolder(folder);
      expect(sentRole, 'admin');
      expect(res.success, isFalse);
      expect(storage.foldersNotifier.value, hasLength(1));
    });
  });

  group('Pruebas de Seguridad: Subida de Archivos y Sanitización XSS / URL', () {
    test('uploadMemories bloquea subidas sin llave desbloqueada y rechaza archivos peligrosos (.html, .js, .svg)',
        () async {
      storage.deviceId = 'dev_upload_test';
      storage.configNotifier.value = AppConfig(requireAccessKey: true);
      storage.isAccessUnlockedNotifier.value = false;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);

      final validPhoto = SelectedFile(
        name: 'recuerdo.jpg',
        bytes: samplePngBytes,
        size: samplePngBytes.length,
        mimeType: 'image/jpeg',
      );

      // Bloqueado mientras Gatekeeper está cerrado
      final blockedRes = await storage.uploadMemories(
        guestName: 'Atacante',
        comment: 'Sin permiso',
        files: [validPhoto],
      );
      expect(blockedRes, isFalse);
      expect(storage.foldersNotifier.value, isEmpty);

      // Desbloqueado, pero intenta subir scripts/HTML
      storage.isAccessUnlockedNotifier.value = true;
      final htmlFile = SelectedFile(
        name: 'payload.html',
        bytes: utf8.encode('<script>alert(1)</script>'),
        size: 25,
        mimeType: 'text/html',
      );
      final jsFile = SelectedFile(
        name: 'malware.js',
        bytes: utf8.encode('alert(1)'),
        size: 8,
        mimeType: 'application/javascript',
      );
      final svgFile = SelectedFile(
        name: 'xss.svg',
        bytes: utf8.encode('<svg onload="alert(1)"/>'),
        size: 24,
        mimeType: 'image/svg+xml',
      );

      expect(StorageService.isAllowedMediaUpload(htmlFile), isFalse);
      expect(StorageService.isAllowedMediaUpload(jsFile), isFalse);
      expect(StorageService.isAllowedMediaUpload(svgFile), isFalse);
      expect(StorageService.isAllowedMediaUpload(validPhoto), isTrue);

      final scriptUploadRes = await storage.uploadMemories(
        guestName: 'Invitado',
        comment: 'Prueba XSS',
        files: [htmlFile, jsFile, svgFile],
      );
      expect(scriptUploadRes, isFalse);
      expect(storage.foldersNotifier.value, isEmpty);
    });

    test('DownloadHelper rechaza esquemas peligrosos (XSS/LFI) y codifica query params',
        () async {
      expect(DownloadHelper.isSafeExternalUrl('javascript:alert(1)'), isFalse);
      expect(DownloadHelper.isSafeExternalUrl('  \tjavascript:alert(1)'), isFalse);
      expect(DownloadHelper.isSafeExternalUrl('data:text/html,<script>alert(1)</script>'), isFalse);
      expect(DownloadHelper.isSafeExternalUrl('vbscript:msgbox(1)'), isFalse);
      expect(DownloadHelper.isSafeExternalUrl('file:///etc/passwd'), isFalse);
      expect(DownloadHelper.isSafeExternalUrl('http://evil.com/steal'), isFalse);

      expect(
        DownloadHelper.isSafeExternalUrl('https://drive.google.com/drive/folders/123'),
        isTrue,
      );
      expect(DownloadHelper.isSafeExternalUrl('tarjeta_mesa_qr.pdf'), isTrue);
      expect(DownloadHelper.isSafeExternalUrl('tarjeta_mesa_qr.html'), isTrue);

      // URL encoding prevents parameter injection via accessKey
      final builtUrl = DownloadHelper.buildAccessUrl('DANNA15&admin=true');
      expect(builtUrl, contains('key=DANNA15%26admin%3Dtrue'));

      // saveConfig strips unsafe googleScriptUrl schemes
      authService.isLoggedInNotifier.value = true;
      storage.bindAdminSessionChecker(() => authService.isLoggedIn);
      final originalUrl = storage.config.googleScriptUrl;
      await storage.saveConfig(
        AppConfig(googleScriptUrl: 'javascript:alert(1)'),
        requireAdmin: true,
      );
      expect(storage.config.googleScriptUrl, originalUrl);
    });
  });
}

