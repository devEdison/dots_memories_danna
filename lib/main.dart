import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/memory_folder.dart';
import 'models/memory_item.dart';
import 'services/download_helper.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/access_key_dialog.dart';
import 'widgets/event_header.dart';
import 'widgets/folder_card.dart';
import 'widgets/folder_detail_dialog.dart';
import 'widgets/live_slideshow_dialog.dart';
import 'widgets/photo_lightbox.dart';
import 'widgets/qr_code_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/upload_modal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  final storageService = StorageService();
  await storageService.init();

  runApp(DotsMemoriesApp(storageService: storageService));
}

class DotsMemoriesApp extends StatelessWidget {
  final StorageService storageService;

  const DotsMemoriesApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis 15 Años - Danna | Dots Memories',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: HomeScreen(storageService: storageService),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeTab = 'folders'; // 'folders' o 'wall'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleManualSync() async {
    final count = await widget.storageService.syncMemoriesFromGoogle(showLoading: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.sageDark,
        content: Text('Sincronizados $count recuerdos desde Google Nube ☁️✨'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onUploadAttempt() {
    if (widget.storageService.isAccessUnlocked) {
      _openUploadModal();
    } else {
      showDialog(
        context: context,
        builder: (context) => AccessKeyDialog(
          storageService: widget.storageService,
          onUnlocked: _openUploadModal,
        ),
      );
    }
  }

  void _openUnlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AccessKeyDialog(
        storageService: widget.storageService,
        onUnlocked: () {},
      ),
    );
  }

  void _openUploadModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadModal(storageService: widget.storageService),
    );
  }

  void _openSlideshow(List<MemoryFolder> folders) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => LiveSlideshowDialog(folders: folders),
    );
  }

  void _openQrDialog() {
    showDialog(
      context: context,
      builder: (context) => QrCodeDialog(storageService: widget.storageService),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(storageService: widget.storageService),
    );
  }

  void _openFolderDetail(MemoryFolder folder) {
    showDialog(
      context: context,
      builder: (context) => FolderDetailDialog(
        folder: folder,
        onPhotoTap: (photoIndex) {
          Navigator.of(context).pop();
          _openLightbox(folder.photos, photoIndex, folder);
        },
      ),
    );
  }

  void _openLightbox(List<MemoryItem> photos, int initialIndex, [MemoryFolder? folder]) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => PhotoLightbox(
        photos: photos,
        initialIndex: initialIndex,
        folder: folder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.storageService.isAccessUnlockedNotifier,
      builder: (context, isUnlocked, _) {
        return ValueListenableBuilder<List<MemoryFolder>>(
          valueListenable: widget.storageService.foldersNotifier,
          builder: (context, folders, child) {
            // Calcular estadísticas
            int totalPhotos = 0;
            int totalLikes = 0;
            final allPhotosWithFolder = <_PhotoWallItem>[];

            for (final f in folders) {
              totalPhotos += f.photos.length;
              totalLikes += f.likes;
              for (final p in f.photos) {
                allPhotosWithFolder.add(_PhotoWallItem(photo: p, folder: f));
              }
            }

            // Filtrar carpetas según búsqueda
            final filteredFolders = folders.where((f) {
              if (_searchQuery.isEmpty) return true;
              final query = _searchQuery.toLowerCase();
              return f.guestName.toLowerCase().contains(query) ||
                  f.comment.toLowerCase().contains(query);
            }).toList();

            // Filtrar muro de fotos
            final filteredWall = allPhotosWithFolder.where((item) {
              if (_searchQuery.isEmpty) return true;
              final query = _searchQuery.toLowerCase();
              return item.folder.guestName.toLowerCase().contains(query) ||
                  item.folder.comment.toLowerCase().contains(query) ||
                  (item.photo.caption?.toLowerCase().contains(query) ?? false);
            }).toList();

            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  // CABECERA HERO EN VERDE SALVIA Y ROSADO
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: widget.storageService.isSyncingNotifier,
                      builder: (context, isSyncing, _) {
                        return EventHeader(
                          totalPhotos: totalPhotos,
                          totalFolders: folders.length,
                          totalLikes: totalLikes,
                          isAccessUnlocked: isUnlocked,
                          activeTab: _activeTab,
                          onTabChanged: (tab) => setState(() => _activeTab = tab),
                          onUploadPressed: _onUploadAttempt,
                          onSlideshowPressed: () => _openSlideshow(folders),
                          onQrPressed: _openQrDialog,
                          onSettingsPressed: _openSettingsDialog,
                          onUnlockPressed: _openUnlockDialog,
                          onGooglePhotosPressed: () => DownloadHelper.openUrl(widget.storageService.config.googlePhotosAlbumUrl),
                          isSyncing: isSyncing,
                          onRefreshPressed: _handleManualSync,
                        );
                      },
                    ),
                  ),

                  // AVISO VISUAL SI EL ACCESO ESTÁ BLOQUEADO (SIN LLAVE QR)
                  if (!isUnlocked)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          margin: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 36,
                            vertical: 12,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.softPinkBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.pinkBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.dustyPink),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Subida exclusiva para invitados',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.sageDeep,
                                      ),
                                    ),
                                    Text(
                                      'Escanea el código QR que se encuentra en las mesas de la fiesta para activar el botón de subida.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _openUnlockDialog,
                                style: TextButton.styleFrom(foregroundColor: AppTheme.deepRose),
                                child: const Text('Ingresar Clave'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // BARRA DE BÚSQUEDA Y FILTROS
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 36,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por invitado o dedicatoria...',
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.sageGreen),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.sageBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sort_rounded, size: 18, color: AppTheme.sageGreen),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Más recientes primero',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.sageDeep,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // CONTENIDO DE LA PESTAÑA SELECCIONADA
                  if (_activeTab == 'folders') ...[
                    if (filteredFolders.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          icon: Icons.folder_open_rounded,
                          title: 'No se encontraron carpetas',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'Prueba con otra palabra en la búsqueda'
                              : '¡Sé el primero en subir fotos para los 15 de Danna!',
                          onAction: _onUploadAttempt,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 36,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount = 1;
                                  if (constraints.maxWidth > 950) {
                                    crossAxisCount = 3;
                                  } else if (constraints.maxWidth > 600) {
                                    crossAxisCount = 2;
                                  }

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredFolders.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 20,
                                      mainAxisSpacing: 20,
                                      childAspectRatio: isMobile ? 0.90 : 0.85,
                                    ),
                                    itemBuilder: (context, index) {
                                      final folder = filteredFolders[index];
                                      return FolderCard(
                                        folder: folder,
                                        onOpen: () => _openFolderDetail(folder),
                                        onLike: () => widget.storageService.toggleLike(folder.id),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ] else ...[
                    // PESTAÑA: MURO DE FOTOS GENERAL
                    if (filteredWall.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(
                          icon: Icons.photo_library_outlined,
                          title: 'No hay fotos en el muro',
                          subtitle: 'Sube las primeras fotos de la fiesta',
                          onAction: _onUploadAttempt,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 36,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount = 2;
                                  if (constraints.maxWidth > 1000) {
                                    crossAxisCount = 4;
                                  } else if (constraints.maxWidth > 650) {
                                    crossAxisCount = 3;
                                  }

                                  final allPhotos = filteredWall.map((e) => e.photo).toList();

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredWall.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 0.95,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = filteredWall[index];
                                      return MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () => _openLightbox(allPhotos, index, item.folder),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image(
                                                  image: item.photo.imageProvider,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: AppTheme.softPinkBg,
                                                      child: const Center(
                                                        child: Icon(Icons.photo_outlined, color: AppTheme.dustyPink, size: 36),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: const BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                        colors: [Colors.black87, Colors.transparent],
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          item.folder.guestName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        if (item.folder.comment.isNotEmpty)
                                                          Text(
                                                            item.folder.comment,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: GoogleFonts.poppins(
                                                              color: Colors.white70,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // PIE DE PÁGINA ELEGANTE EN VERDE SALVIA Y ROSADO
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('👑 🌸 🌿', style: TextStyle(fontSize: 26)),
                            const SizedBox(height: 8),
                            Text(
                              'Mis 15 Años • Danna',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.sageDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dots Memories Web • Verde Salvia & Rosado • Solo Fotos 📸',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: () => DownloadHelper.openUrl(
                                    widget.storageService.config.googlePhotosAlbumUrl,
                                  ),
                                  icon: const Icon(Icons.photo_library_rounded, size: 14),
                                  label: const Text('Álbum Google Fotos'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.sageDark,
                                    textStyle: GoogleFonts.poppins(fontSize: 11),
                                  ),
                                ),
                                const Text('•', style: TextStyle(color: AppTheme.mutedText)),
                                TextButton.icon(
                                  onPressed: _openSettingsDialog,
                                  icon: const Icon(Icons.tune_rounded, size: 14),
                                  label: const Text('Ajustes y Llave QR'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.sageDark,
                                    textStyle: GoogleFonts.poppins(fontSize: 11),
                                  ),
                                ),
                                const Text('•', style: TextStyle(color: AppTheme.mutedText)),
                                TextButton.icon(
                                  onPressed: _openQrDialog,
                                  icon: const Icon(Icons.qr_code_2_rounded, size: 14),
                                  label: const Text('Llave QR Mesa'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.dustyPink,
                                    textStyle: GoogleFonts.poppins(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // FAB EN DISPOSITIVOS MÓVILES
              floatingActionButton: isMobile
                  ? FloatingActionButton.extended(
                      onPressed: _onUploadAttempt,
                      backgroundColor: isUnlocked ? AppTheme.sageGreen : AppTheme.dustyPink,
                      icon: Icon(
                        isUnlocked ? Icons.add_photo_alternate_rounded : Icons.lock_open_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        isUnlocked ? 'Subir Fotos' : 'Desbloquear 🔒',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.sageLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.sageBorder),
              ),
              child: Icon(icon, size: 48, color: AppTheme.sageGreen),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.sageDeep,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Subir Fotos Ahora'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sageGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoWallItem {
  final MemoryItem photo;
  final MemoryFolder folder;

  _PhotoWallItem({required this.photo, required this.folder});
}
