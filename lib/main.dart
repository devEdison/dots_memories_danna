import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/memory_folder.dart';
import 'models/memory_item.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
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
      builder: (context) => const QrCodeDialog(),
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
          Navigator.of(context).pop(); // Cerrar detalle para abrir lightbox
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
              // CABECERA HERO ELEGANTE
              SliverToBoxAdapter(
                child: EventHeader(
                  totalPhotos: totalPhotos,
                  totalFolders: folders.length,
                  totalLikes: totalLikes,
                  activeTab: _activeTab,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                  onUploadPressed: _openUploadModal,
                  onSlideshowPressed: () => _openSlideshow(folders),
                  onQrPressed: _openQrDialog,
                  onSettingsPressed: _openSettingsDialog,
                ),
              ),

              // BARRA DE BÚSQUEDA Y FILTROS
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 36,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: 'Buscar por invitado o dedicatoria...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryRose),
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
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sort_rounded, size: 18, color: AppTheme.primaryRose),
                                const SizedBox(width: 6),
                                Text(
                                  'Más recientes primero',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.deepPlum,
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
                      onAction: _openUploadModal,
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
                      onAction: _openUploadModal,
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
                                            ),
                                            // Gradiente inferior con autor
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

              // PIE DE PÁGINA ELEGANTE
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(
                          'Mis 15 Años • Danna',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dots Memories Web • Todos los recuerdos guardados con amor 💕',
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
                              onPressed: _openSettingsDialog,
                              icon: const Icon(Icons.settings_outlined, size: 14),
                              label: const Text('Configurar Google Nube'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryRose,
                                textStyle: GoogleFonts.poppins(fontSize: 11),
                              ),
                            ),
                            const Text('•', style: TextStyle(color: AppTheme.mutedText)),
                            TextButton.icon(
                              onPressed: _openQrDialog,
                              icon: const Icon(Icons.qr_code_2_rounded, size: 14),
                              label: const Text('QR de Mesa'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryRose,
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
                  onPressed: _openUploadModal,
                  backgroundColor: AppTheme.primaryRose,
                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
                  label: Text(
                    'Subir Fotos',
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
                color: AppTheme.softBlush,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryRose),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepPlum,
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
