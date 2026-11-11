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
import 'package:dots_memories_danna/widgets/live_slideshow_dialog.dart';

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
}
