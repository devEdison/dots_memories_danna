import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/memory_folder.dart';
import 'models/memory_item.dart';
import 'services/appwrite_auth_service.dart';
import 'services/download_helper.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/access_key_dialog.dart';
import 'widgets/event_header.dart';
import 'widgets/festive_effects.dart';
import 'widgets/folder_card.dart';
import 'widgets/folder_detail_dialog.dart';
import 'widgets/gatekeeper_screen.dart';
import 'widgets/guest_portal_screen.dart';
import 'widgets/live_slideshow_dialog.dart';
import 'widgets/media_delete_controls.dart';
import 'widgets/photo_lightbox.dart';
import 'widgets/qr_code_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/upload_modal.dart';
import 'widgets/video_player_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  final storageService = StorageService();
  await storageService.init();

  final authService = AppwriteAuthService();
  await authService.init();

  runApp(DotsMemoriesApp(
    storageService: storageService,
    authService: authService,
  ));
}

class DotsMemoriesApp extends StatelessWidget {
  final StorageService storageService;
  final AppwriteAuthService authService;

  const DotsMemoriesApp({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis 15 Años - Danna Alejandra | Dots Memories',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: ValueListenableBuilder<bool>(
        valueListenable: authService.isLoggedInNotifier,
        builder: (context, isLoggedIn, _) {
          // 1. Si ha iniciado sesión con Appwrite -> PAGINA PRINCIPAL COMPLETA
          if (isLoggedIn) {
            return HomeScreen(
              storageService: storageService,
              authService: authService,
            );
          }

          // 2. Si no es admin pero tiene QR / clave de invitado -> ESPACIO AISLADO DE INVITADO
          return ValueListenableBuilder<bool>(
            valueListenable: storageService.isAccessUnlockedNotifier,
            builder: (context, isUnlocked, _) {
              if (isUnlocked) {
                return GuestPortalScreen(
                  storageService: storageService,
                  authService: authService,
                );
              }

              // 3. Bloqueado: nadie puede ver la página principal sin QR o sin login de Appwrite
              return GatekeeperScreen(
                storageService: storageService,
                authService: authService,
              );
            },
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final AppwriteAuthService authService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

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
    _openUploadModal();
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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF0A110C),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) => LiveSlideshowDialog(
        folders: folders,
        storageService: widget.storageService,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        );
      },
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
          final latestFolder = widget.storageService.foldersNotifier.value.firstWhere(
            (f) =>
                f.id == folder.id ||
                (folder.googleFolderId != null &&
                    f.googleFolderId == folder.googleFolderId),
            orElse: () => folder,
          );
          if (latestFolder.photos.isEmpty) return;
          final safeIndex = photoIndex.clamp(0, latestFolder.photos.length - 1);
          _openLightbox(latestFolder.photos, safeIndex, latestFolder);
        },
        onDeleteFolder: () => _confirmAndDeleteFolder(folder, closeDetailAfter: true),
        onDeletePhoto: (photo) => _confirmAndDeletePhoto(photo, folderHint: folder),
      ),
    );
  }

  Future<bool> _confirmAndDeletePhoto(
    MemoryItem photo, {
    MemoryFolder? folderHint,
  }) {
    return confirmAndDeleteMedia(
      context: context,
      storageService: widget.storageService,
      item: photo,
      folderHint: folderHint,
    );
  }

  Future<void> _confirmAndDeleteFolder(
    MemoryFolder folder, {
    bool closeDetailAfter = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.goldBorder, width: 1.4),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.softPinkBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.pinkBorder),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.deepRose, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Eliminar carpeta',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sageDeep,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Seguro que deseas eliminar la carpeta de "${folder.guestName}" (${folder.photos.length} archivo(s))?\n\nSe quitará del álbum y se moverá a la papelera de Google Drive.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.charcoal, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: AppTheme.mutedText, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18, color: Colors.white),
            label: Text(
              'Eliminar',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepRose,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    BuildContext? progressDialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (progressCtx) {
        progressDialogContext = progressCtx;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Row(
              children: [
                const CircularProgressIndicator(color: AppTheme.sageDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Eliminando carpeta en Google Drive...',
                    style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.sageDeep),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final result = await widget.storageService.deleteFolder(folder);

    if (progressDialogContext != null && progressDialogContext!.mounted) {
      Navigator.of(progressDialogContext!).pop();
    }
    if (!mounted) return;

    if (result.success && closeDetailAfter && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.success ? AppTheme.sageDark : AppTheme.deepRose,
        content: Text(
          result.message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openLightbox(List<MemoryItem> photos, int initialIndex, [MemoryFolder? folder]) {
    final photo = photos[initialIndex];
    if (photo.isVideo) {
      showDialog(
        context: context,
        builder: (context) => VideoPlayerDialog(
          item: photo,
          guestName: folder?.guestName,
          onDelete: (deletedItem) => _confirmAndDeletePhoto(
            deletedItem,
            folderHint: folder,
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => PhotoLightbox(
        photos: photos,
        initialIndex: initialIndex,
        folder: folder,
        onDeletePhoto: (deletedPhoto) => _confirmAndDeletePhoto(
          deletedPhoto,
          folderHint: folder,
        ),
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
                scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                slivers: [
                  // BARRA SUPERIOR DE ANFITRIÓN AUTENTICADO CON APPWRITE
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.sageDeep, AppTheme.sageDark, AppTheme.sageDeep],
                        ),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.goldBorder, width: 1.2),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.goldBorder.withAlpha(150)),
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.goldLight, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sesión Anfitrión: ${widget.authService.currentUser?.name ?? "Familia Danna"}${widget.authService.currentUser?.email != null ? " (${widget.authService.currentUser!.email})" : ""}',
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => DownloadHelper.openUrl(widget.storageService.config.googleDriveFolderUrl),
                                icon: const Icon(Icons.folder_shared_rounded, size: 14, color: AppTheme.goldLight),
                                label: Text(isMobile ? 'Drive' : 'Google Drive 📁'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: AppTheme.goldBorder),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => GuestPortalScreen(
                                        storageService: widget.storageService,
                                        authService: widget.authService,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.qr_code_rounded, size: 14),
                                label: Text(isMobile ? 'QR' : 'Ver como Invitado (QR)'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => widget.authService.logout(config: widget.storageService.config),
                                icon: const Icon(Icons.logout_rounded, size: 14),
                                label: Text(isMobile ? '' : 'Cerrar Sesión'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFD1DC),
                                  side: const BorderSide(color: Color(0xFFFFD1DC)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // CABECERA HERO EN VERDE SALVIA, ROSADO Y DORADO
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
                          onGoogleDrivePressed: () => DownloadHelper.openUrl(widget.storageService.config.googleDriveFolderUrl),
                          isSyncing: isSyncing,
                          onRefreshPressed: _handleManualSync,
                        );
                      },
                    ),
                  ),

                  // TARJETA DE RUTA GOOGLE DRIVE PARA ANFITRIÓN
                  SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        margin: EdgeInsets.only(
                          top: 18,
                          left: isMobile ? 16 : 36,
                          right: isMobile ? 16 : 36,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFDF6F8)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.goldBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.sageGreen.withAlpha(24),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: AppTheme.warmGold.withAlpha(25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppTheme.sageLight, AppTheme.goldLight],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppTheme.goldBorder),
                                        ),
                                        child: const Icon(Icons.folder_shared_rounded, color: AppTheme.sageDark, size: 20),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ruta en Google Drive:',
                                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.mutedText),
                                            ),
                                            Text(
                                              'Mi Unidad > 15 Años Danna - Fotos de Invitados',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.sageDeep,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: QuincePrimaryButton(
                                      onPressed: () => DownloadHelper.openUrl(widget.storageService.config.googleDriveFolderUrl),
                                      icon: Icons.open_in_new_rounded,
                                      label: 'Abrir Carpeta en Google Drive ↗',
                                      minHeight: 42,
                                      borderRadius: 14,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.sageLight, AppTheme.goldLight],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.goldBorder),
                                    ),
                                    child: const Icon(Icons.folder_shared_rounded, color: AppTheme.sageDark, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Ruta de Respaldos en Google Drive:',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.mutedText,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppTheme.sageLight, AppTheme.goldLight],
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppTheme.goldBorder),
                                              ),
                                              child: Text(
                                                'Nube Conectada ✨',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.sageDeep,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        SelectableText(
                                          'Mi Unidad > 15 Años Danna - Fotos de Invitados',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.sageDeep,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cada invitado tiene su propia subcarpeta con fotos originales en alta resolución.',
                                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.mutedText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  QuincePrimaryButton(
                                    onPressed: () => DownloadHelper.openUrl(widget.storageService.config.googleDriveFolderUrl),
                                    icon: Icons.open_in_new_rounded,
                                    label: 'Abrir Carpeta en Google Drive ↗',
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    borderRadius: 16,
                                    fontSize: 13,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // BARRA DE BÚSQUEDA Y CONTROLES
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
                            // Campo de búsqueda en vivo
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.borderLight, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.sageGreen.withAlpha(20),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) => setState(() => _searchQuery = value),
                                  decoration: InputDecoration(
                                    hintText: _activeTab == 'folders'
                                        ? 'Buscar invitado o dedicatoria...'
                                        : 'Buscar fotos por invitado o mensaje...',
                                    hintStyle: GoogleFonts.poppins(color: AppTheme.mutedText, fontSize: 13),
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
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // VISTA 1: CARPETAS DE INVITADOS (MODO DEFAULT)
                  if (_activeTab == 'folders') ...[
                    if (filteredFolders.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.softPinkBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('🌸', style: TextStyle(fontSize: 40)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'Aún no hay recuerdos subidos'
                                      : 'No se encontraron recuerdos para "$_searchQuery"',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.sageDeep,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchQuery.isEmpty
                                      ? '¡Comparte el QR con los invitados para que comiencen a subir fotos!'
                                      : 'Intenta con otro término de búsqueda',
                                  style: GoogleFonts.poppins(color: AppTheme.mutedText, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.crossAxisExtent;
                          final minSidePadding = isMobile ? 16.0 : 36.0;
                          final contentWidth = (totalWidth - minSidePadding * 2).clamp(0.0, 1200.0);
                          final horizontalPadding = (totalWidth - contentWidth) / 2;

                          int crossAxisCount = 3;
                          if (contentWidth < 600) {
                            crossAxisCount = 1;
                          } else if (contentWidth < 960) {
                            crossAxisCount = 2;
                          }

                          return SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 12,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.82,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final folder = filteredFolders[index];
                                  return FolderCard(
                                    key: ValueKey<String>(folder.id),
                                    folder: folder,
                                    onOpen: () => _openFolderDetail(folder),
                                    onLike: () => widget.storageService.toggleLike(folder.id),
                                    onDelete: () => _confirmAndDeleteFolder(folder),
                                  )
                                      .animate(delay: ((index % 6) * 55).ms)
                                      .fadeIn(duration: 380.ms)
                                      .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.0, 1.0));
                                },
                                childCount: filteredFolders.length,
                                addAutomaticKeepAlives: false,
                              ),
                            ),
                          );
                        },
                      ),
                  ],

                  // VISTA 2: MURO DE FOTOS GENERAL (WALL)
                  if (_activeTab == 'wall') ...[
                    if (filteredWall.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 50, color: AppTheme.dustyPink),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay fotos en el muro',
                                  style: GoogleFonts.playfairDisplay(fontSize: 20, color: AppTheme.sageDeep),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final totalWidth = constraints.crossAxisExtent;
                          final minSidePadding = isMobile ? 16.0 : 36.0;
                          final contentWidth = (totalWidth - minSidePadding * 2).clamp(0.0, 1200.0);
                          final horizontalPadding = (totalWidth - contentWidth) / 2;

                          int crossAxisCount = 4;
                          if (contentWidth < 480) {
                            crossAxisCount = 2;
                          } else if (contentWidth < 768) {
                            crossAxisCount = 3;
                          } else if (contentWidth < 1100) {
                            crossAxisCount = 4;
                          } else {
                            crossAxisCount = 5;
                          }

                          final allPhotos = [for (final e in filteredWall) e.photo];

                          return SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 12,
                            ),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.95,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = filteredWall[index];
                                  return RepaintBoundary(
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => _openLightbox(allPhotos, index, item.folder),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: AppTheme.goldBorder, width: 1.3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.sageGreen.withAlpha(24),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              item.photo.isVideo
                                                  ? Container(
                                                      color: const Color(0xFF1E2621),
                                                      child: const Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.play_circle_fill, color: Colors.white, size: 38),
                                                            SizedBox(height: 4),
                                                            Text(
                                                              'VIDEO',
                                                              style: TextStyle(
                                                                color: Colors.white70,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  : Image(
                                                      image: item.photo.thumbnailProvider,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true,
                                                      filterQuality: FilterQuality.medium,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: AppTheme.softPinkBg,
                                                          child: const Center(
                                                            child: Icon(Icons.photo_outlined, color: AppTheme.dustyPink, size: 36),
                                                          ),
                                                        );
                                                        },
                                                      ),
                                              MediaTileDeleteButton(
                                                onTap: () => _confirmAndDeletePhoto(
                                                  item.photo,
                                                  folderHint: item.folder,
                                                ),
                                                tooltip: item.photo.isVideo
                                                    ? 'Eliminar video no permitido'
                                                    : 'Eliminar foto no permitida',
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
                                        )
                                            .animate(delay: ((index % 10) * 35).ms)
                                            .fadeIn(duration: 340.ms)
                                            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),
                                      ),
                                    ),
                                  );
                                },
                                childCount: filteredWall.length,
                                addAutomaticKeepAlives: false,
                              ),
                            ),
                          );
                        },
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
                              'Mis 15 Años • Danna Alejandra',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.sageDeep,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dots Memories • Mis 15 Años Danna Alejandra • Álbum Digital de Recuerdos 👑✨',
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
                                const SizedBox(width: 12),
                                TextButton.icon(
                                  onPressed: () => DownloadHelper.printPage(),
                                  icon: const Icon(Icons.print_rounded, size: 14),
                                  label: const Text('Imprimir Álbum'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.sageDark,
                                    textStyle: GoogleFonts.poppins(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const QuinceCopyrightNotice(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _onUploadAttempt,
                backgroundColor: AppTheme.sageDark,
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: AppTheme.goldBorder, width: 1.5),
                ),
                icon: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.goldLight),
                label: Text(
                  'Subir Fotos y Videos ✨',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(delay: 2800.ms, duration: 1400.ms, color: AppTheme.goldLight.withAlpha(110)),
            );
          },
        );
      },
    );
  }
}

class _PhotoWallItem {
  final MemoryItem photo;
  final MemoryFolder folder;

  _PhotoWallItem({required this.photo, required this.folder});
}
