import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dots_memories_danna/main.dart';
import 'package:dots_memories_danna/models/memory_folder.dart';
import 'package:dots_memories_danna/models/memory_item.dart';
import 'package:dots_memories_danna/services/appwrite_auth_service.dart';
import 'package:dots_memories_danna/services/storage_service.dart';
import 'package:dots_memories_danna/widgets/folder_card.dart';
import 'package:dots_memories_danna/widgets/folder_detail_dialog.dart';
import 'package:dots_memories_danna/widgets/guest_portal_screen.dart';
import 'package:dots_memories_danna/widgets/live_slideshow_dialog.dart';
import 'package:dots_memories_danna/widgets/photo_lightbox.dart';
import 'package:dots_memories_danna/widgets/video_player_dialog.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  final samplePngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );

  testWidgets('Dots Memories smoke test', (WidgetTester tester) async {
    final storageService = StorageService();
    final authService = AppwriteAuthService();
    await tester.pumpWidget(DotsMemoriesApp(
      storageService: storageService,
      authService: authService,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Danna'), findsWidgets);
    expect(find.text('28 de Noviembre de 2026'), findsWidgets);
    expect(storageService.config.eventDate, '2026-11-28');
    expect(find.text('Desarrollado por Edison Gonzalez'), findsOneWidget);
    expect(find.textContaining('Todos los derechos reservados'), findsOneWidget);
  });

  testWidgets('LiveSlideshowDialog renders empty gala stage when no photos', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiveSlideshowDialog(folders: []),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Proyección de Gala'), findsOneWidget);
    expect(find.text('Volver a la Galería'), findsOneWidget);
  });

  testWidgets('LiveSlideshowDialog renders luxury projection stage and toggles frame styles', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final folders = [
      MemoryFolder(
        id: 'f1',
        guestName: 'Sofía Martínez',
        comment: '¡Felices 15 años Danna Alejandra!',
        timestamp: DateTime(2026, 11, 10, 20, 30),
        photos: [
          MemoryItem(
            id: 'p1',
            fileName: 'gala_1.png',
            bytes: samplePngBytes,
            timestamp: DateTime(2026, 11, 10, 20, 30),
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: LiveSlideshowDialog(folders: folders),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sofía Martínez'), findsOneWidget);
    expect(find.textContaining('Felices 15 años Danna Alejandra'), findsOneWidget);
    expect(find.text('Cine'), findsOneWidget);

    await tester.tap(find.text('Cine'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Marco Gala'), findsOneWidget);
    expect(find.textContaining('XV Danna Alejandra'), findsOneWidget);
  });

  testWidgets('LiveSlideshowDialog renders cleanly on narrow mobile screen without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final folders = [
      MemoryFolder(
        id: 'f_mob',
        guestName: 'Carlos Rivera',
        comment: 'Recuerdo increíble de la fiesta',
        timestamp: DateTime(2026, 11, 10, 21, 15),
        photos: [
          MemoryItem(
            id: 'p_mob',
            fileName: 'mobile_1.png',
            bytes: samplePngBytes,
            timestamp: DateTime(2026, 11, 10, 21, 15),
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: LiveSlideshowDialog(folders: folders),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Carlos Rivera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('MemoryItem caches providers and protects localStorage quota in toJson', () {
    final item = MemoryItem(
      id: 'cache_test_1',
      fileName: 'recuerdo.png',
      base64Data: base64Encode(samplePngBytes),
      timestamp: DateTime(2026, 11, 10),
    );

    final firstFull = item.imageProvider;
    final secondFull = item.imageProvider;
    final firstThumb = item.thumbnailProvider;
    final secondThumb = item.thumbnailProvider;

    expect(identical(firstFull, secondFull), isTrue);
    expect(identical(firstThumb, secondThumb), isTrue);

    final oversizedItem = MemoryItem(
      id: 'oversized_1',
      fileName: 'camara_4k.jpg',
      bytes: Uint8List(400 * 1024),
      timestamp: DateTime(2026, 11, 10),
    );
    expect(oversizedItem.toJson()['base64Data'], isNull);

    final smallItem = MemoryItem(
      id: 'small_1',
      fileName: 'mini.png',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    expect(smallItem.toJson()['base64Data'], isNotNull);

    final drivePhoto = MemoryItem(
      id: 'drive_abc123',
      fileName: 'valenzuela.jpg',
      remoteUrl: 'https://lh3.googleusercontent.com/d/drive_abc123',
      timestamp: DateTime(2026, 11, 10),
    );
    expect(
      (drivePhoto.thumbnailProvider as NetworkImage).url,
      'https://lh3.googleusercontent.com/d/drive_abc123=w600',
    );
    expect(
      (drivePhoto.imageProvider as NetworkImage).url,
      'https://lh3.googleusercontent.com/d/drive_abc123=w1920',
    );
  });

  testWidgets('FolderCard shows admin delete button only when onDelete is provided', (WidgetTester tester) async {
    bool deleted = false;
    final folder = MemoryFolder(
      id: 'folder_admin_test',
      guestName: 'Invitado Test',
      comment: '¡Felices 15!',
      timestamp: DateTime(2026, 11, 10),
      photos: [
        MemoryItem(
          id: 'p_1',
          fileName: 'foto.png',
          bytes: samplePngBytes,
          timestamp: DateTime(2026, 11, 10),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            height: 400,
            child: FolderCard(
              folder: folder,
              onOpen: () {},
              onLike: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            height: 400,
            child: FolderCard(
              folder: folder,
              onOpen: () {},
              onLike: () {},
              onDelete: () => deleted = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    expect(deleted, isTrue);
  });

  test('StorageService.deleteFolder removes local folder cleanly', () async {
    SharedPreferences.setMockInitialValues({});
    final folder = MemoryFolder(
      id: 'folder_admin_local_test',
      guestName: 'Invitado Test',
      comment: '¡Felices 15!',
      timestamp: DateTime(2026, 11, 10),
      photos: const [],
    );
    final storage = StorageService();
    storage.foldersNotifier.value = [folder];
    final res = await storage.deleteFolder(folder);
    expect(res.success, isTrue);
    expect(storage.foldersNotifier.value, isEmpty);
  });

  test('StorageService.deletePhoto removes single photo while preserving folder', () async {
    SharedPreferences.setMockInitialValues({});
    final keepPhoto = MemoryItem(
      id: 'photo_keep_1',
      fileName: 'keep.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final badPhoto = MemoryItem(
      id: 'photo_bad_2',
      fileName: 'bad.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final folder = MemoryFolder(
      id: 'folder_photo_delete_test',
      guestName: 'Camila',
      comment: 'Con mucho cariño',
      timestamp: DateTime(2026, 11, 10),
      photos: [keepPhoto, badPhoto],
    );

    final storage = StorageService();
    storage.foldersNotifier.value = [folder];
    final res = await storage.deletePhoto(badPhoto, folderHint: folder);

    expect(res.success, isTrue);
    expect(storage.foldersNotifier.value, hasLength(1));
    expect(storage.foldersNotifier.value.first.photos, hasLength(1));
    expect(storage.foldersNotifier.value.first.photos.first.id, 'photo_keep_1');
  });

  testWidgets('PhotoLightbox shows delete control only when onDeletePhoto is provided', (WidgetTester tester) async {
    final photos = [
      MemoryItem(
        id: 'photo_lb_1',
        fileName: 'uno.jpg',
        bytes: samplePngBytes,
        timestamp: DateTime(2026, 11, 10),
      ),
      MemoryItem(
        id: 'photo_lb_2',
        fileName: 'dos.jpg',
        bytes: samplePngBytes,
        timestamp: DateTime(2026, 11, 10),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoLightbox(
          photos: photos,
          initialIndex: 0,
        ),
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);

    var deletedIds = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PhotoLightbox(
          photos: photos,
          initialIndex: 0,
          onDeletePhoto: (photo) async {
            deletedIds.add(photo.id);
            return true;
          },
        ),
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(deletedIds, ['photo_lb_1']);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('FolderDetailDialog and VideoPlayerDialog wire individual delete callbacks', (WidgetTester tester) async {
    final p1 = MemoryItem(
      id: 'photo_fd_1',
      fileName: 'fd1.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final p2 = MemoryItem(
      id: 'photo_fd_2',
      fileName: 'fd2.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final folder = MemoryFolder(
      id: 'folder_fd_test',
      guestName: 'Lucía',
      comment: 'Hermosa fiesta',
      timestamp: DateTime(2026, 11, 10),
      photos: [p1, p2],
    );

    final deletedInFolder = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderDetailDialog(
            folder: folder,
            onPhotoTap: (_) {},
            onDeletePhoto: (photo) async {
              deletedInFolder.add(photo.id);
              return true;
            },
          ),
        ),
      ),
    );
    expect(find.text('Fotos del Álbum (2)'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(deletedInFolder, ['photo_fd_1']);
    expect(find.text('Fotos del Álbum (1)'), findsOneWidget);

    final videoItem = MemoryItem(
      id: 'video_1',
      fileName: 'baile.mp4',
      remoteUrl: 'https://lh3.googleusercontent.com/d/abc123',
      mimeType: 'video/mp4',
      timestamp: DateTime(2026, 11, 10),
    );
    var videoDeleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoPlayerDialog(
            item: videoItem,
            guestName: 'Lucía',
            onDelete: (_) async {
              videoDeleted = true;
              return false;
            },
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(videoDeleted, isTrue);
  });

  test('StorageService.deletePhoto enforces guest ownership when requested', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    storage.deviceId = 'dev_guest_a';
    storage.myFolderIdsNotifier.value = ['folder_own_a'];
    storage.myGuestNameNotifier.value = 'Ana';

    final ownPhoto = MemoryItem(
      id: 'photo_own_1',
      fileName: 'own.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final ownFolder = MemoryFolder(
      id: 'folder_own_a',
      guestName: 'Ana',
      comment: 'Mi recuerdo',
      deviceId: 'dev_guest_a',
      timestamp: DateTime(2026, 11, 10),
      photos: [ownPhoto],
    );

    final otherPhoto = MemoryItem(
      id: 'photo_other_1',
      fileName: 'other.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final otherFolder = MemoryFolder(
      id: 'folder_other_b',
      guestName: 'Carlos',
      comment: 'Otro invitado',
      deviceId: 'dev_guest_b',
      timestamp: DateTime(2026, 11, 10),
      photos: [otherPhoto],
    );

    storage.foldersNotifier.value = [ownFolder, otherFolder];

    final deniedRes = await storage.deletePhoto(
      otherPhoto,
      folderHint: otherFolder,
      requireGuestOwnership: true,
    );
    expect(deniedRes.success, isFalse);
    expect(storage.foldersNotifier.value[1].photos, hasLength(1));

    final allowedRes = await storage.deletePhoto(
      ownPhoto,
      folderHint: ownFolder,
      requireGuestOwnership: true,
    );
    expect(allowedRes.success, isTrue);
    expect(storage.foldersNotifier.value[0].photos, isEmpty);
    expect(storage.foldersNotifier.value[1].photos, hasLength(1));
  });

  testWidgets('GuestPortalScreen lets guests delete their own photos after confirmation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferences.getInstance();
    });
    final storage = StorageService();
    final authService = AppwriteAuthService();

    storage.deviceId = 'dev_guest_portal';
    storage.myFolderIdsNotifier.value = ['folder_guest_portal'];
    storage.myGuestNameNotifier.value = 'Valeria';

    final p1 = MemoryItem(
      id: 'photo_gp_1',
      fileName: 'valeria1.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final p2 = MemoryItem(
      id: 'photo_gp_2',
      fileName: 'valeria2.jpg',
      bytes: samplePngBytes,
      timestamp: DateTime(2026, 11, 10),
    );
    final guestFolder = MemoryFolder(
      id: 'folder_guest_portal',
      guestName: 'Valeria',
      comment: '¡Feliz cumpleaños Danna!',
      deviceId: 'dev_guest_portal',
      timestamp: DateTime(2026, 11, 10),
      photos: [p1, p2],
    );
    final strangerFolder = MemoryFolder(
      id: 'folder_stranger',
      guestName: 'Desconocido',
      comment: 'No debe mostrarse',
      deviceId: 'dev_stranger',
      timestamp: DateTime(2026, 11, 10),
      photos: [
        MemoryItem(
          id: 'photo_stranger_1',
          fileName: 'stranger.jpg',
          bytes: samplePngBytes,
          timestamp: DateTime(2026, 11, 10),
        ),
      ],
    );

    storage.foldersNotifier.value = [guestFolder, strangerFolder];

    await tester.pumpWidget(
      MaterialApp(
        home: GuestPortalScreen(
          storageService: storage,
          authService: authService,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Valeria'), findsOneWidget);
    expect(find.text('Desconocido'), findsNothing);
    expect(find.text('2 recuerdos'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('¿Eliminar tu foto?'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('1 recuerdos'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(storage.myFolders.first.photos.map((p) => p.id), ['photo_gp_2']);
  });
}
