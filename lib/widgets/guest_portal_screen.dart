import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../services/appwrite_auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'photo_lightbox.dart';
import 'upload_modal.dart';
import 'video_player_dialog.dart';

class GuestPortalScreen extends StatefulWidget {
  final StorageService storageService;
  final AppwriteAuthService authService;

  const GuestPortalScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends State<GuestPortalScreen> {
  final TextEditingController _linkNameController = TextEditingController();

  @override
  void dispose() {
    _linkNameController.dispose();
    super.dispose();
  }

  void _openUploadModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadModal(storageService: widget.storageService),
    );
  }

  void _openPhoto(List<MemoryItem> photos, int index, MemoryFolder folder) {
    final item = photos[index];
    if (item.isVideo) {
      showDialog(
        context: context,
        builder: (context) => VideoPlayerDialog(
          item: item,
          guestName: folder.guestName,
        ),
      );
    } else {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (context) => PhotoLightbox(
          photos: photos,
          initialIndex: index,
          folder: folder,
        ),
      );
    }
  }

  void _showLinkNameDialog() {
    _linkNameController.text = widget.storageService.myGuestNameNotifier.value;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_search_rounded, color: AppTheme.sageGreen),
            const SizedBox(width: 10),
            Text('Vincular por Nombre', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Si subiste fotos desde otro dispositivo o cerraste la ventana, escribe aquí el mismo nombre que usaste para recuperar tus fotos y videos.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.mutedText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkNameController,
              decoration: InputDecoration(
                labelText: 'Tu Nombre de Invitado',
                hintText: 'Ej: Tío Carlos, Sofia...',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.sageGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _linkNameController.text.trim();
              if (name.isNotEmpty) {
                await widget.storageService.setMyGuestName(name);
                await widget.storageService.syncMemoriesFromGoogle();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sageGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buscar mis Recuerdos'),
          ),
        ],
      ),
    );
  }

  void _showHostLoginDialog() {
    final emailCtrl = TextEditingController(text: 'admin@danna15.com');
    final passCtrl = TextEditingController();
    bool isSubmitting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.softPinkBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.deepRose, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Acceso Anfitrión',
                    style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inicia sesión con tu cuenta de Appwrite para acceder al Muro General y todas las carpetas del evento.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.mutedText),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Correo de Anfitrión',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.sageGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña de Appwrite',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.sageGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMsg!,
                      style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() {
                          isSubmitting = true;
                          errorMsg = null;
                        });
                        final res = await widget.authService.login(
                          config: widget.storageService.config,
                          email: emailCtrl.text,
                          password: passCtrl.text,
                        );
                        if (res['success'] == true) {
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMsg = res['message'] as String? ?? 'Credenciales incorrectas';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.sageDark,
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Iniciar Sesión'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return ValueListenableBuilder<List<MemoryFolder>>(
      valueListenable: widget.storageService.foldersNotifier,
      builder: (context, folders, _) {
        final myFolders = widget.storageService.myFolders;
        final guestName = widget.storageService.myGuestNameNotifier.value;

        // Calcular conteo de fotos y videos del invitado
        int totalPhotos = 0;
        int totalVideos = 0;
        for (final f in myFolders) {
          for (final p in f.photos) {
            if (p.isVideo) {
              totalVideos++;
            } else {
              totalPhotos++;
            }
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          body: CustomScrollView(
            slivers: [
              // HERO HEADER AISLADO EN VERDE SALVIA Y ROSADO
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 18 : 36,
                    vertical: isMobile ? 24 : 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        children: [
                          // Barra superior: badge de QR y botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.pinkBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.dustyPink.withAlpha(30),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.qr_code_2_rounded, size: 16, color: AppTheme.deepRose),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Acceso QR Invitado',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.deepRose,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  // Botón Actualizar
                                  ValueListenableBuilder<bool>(
                                    valueListenable: widget.storageService.isSyncingNotifier,
                                    builder: (context, isSyncing, _) {
                                      return OutlinedButton.icon(
                                        onPressed: isSyncing
                                            ? null
                                            : () => widget.storageService.syncMemoriesFromGoogle(showLoading: true),
                                        icon: isSyncing
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sageDark),
                                              )
                                            : const Icon(Icons.sync_rounded, size: 16),
                                        label: Text(isMobile ? '' : 'Actualizar'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.sageDark,
                                          backgroundColor: Colors.white,
                                          side: const BorderSide(color: AppTheme.sageBorder),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  // Botón Salir / Bloquear
                                  OutlinedButton.icon(
                                    onPressed: () => widget.storageService.lockAccess(),
                                    icon: const Icon(Icons.lock_outline_rounded, size: 16),
                                    label: Text(isMobile ? '' : 'Salir'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.deepRose,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: AppTheme.pinkBorder),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Corona y Título
                          Text(
                            '👑 Mis 15 Años • Danna 🌸',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: isMobile ? 22 : 30,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.sageDeep,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            guestName.isNotEmpty
                                ? '¡Bienvenido(a), $guestName! Tu Espacio Privado de Recuerdos ✨'
                                : 'Tu Espacio Privado de Recuerdos ✨',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Aquí solo tú puedes ver tus fotos y videos subidos, y agregar todos los recuerdos que desees para Danna.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tarjeta de Acción Rápida: Subir Más Fotos y Videos
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppTheme.sageBorder, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.sageGreen.withAlpha(30),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.softPinkBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('📸', style: TextStyle(fontSize: 22)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tus recuerdos subidos:',
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.mutedText),
                                      ),
                                      Text(
                                        '$totalPhotos fotos • $totalVideos videos (${myFolders.length} dedicatorias)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.sageDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _openUploadModal,
                                  icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),
                                  label: Text(
                                    isMobile ? 'Subir' : 'Subir Fotos y Videos',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.sageDark,
                                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // CONTENIDO DE RECUERDOS DEL INVITADO
              if (myFolders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: AppTheme.softPinkBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🌸', style: TextStyle(fontSize: 48)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Aún no has subido fotos o videos',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.sageDeep,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Text(
                              '¡Sé el primero en dejarle un hermoso recuerdo a Danna en sus 15 años! Comparte todas las fotos y videos que tomaste durante la celebración.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: AppTheme.mutedText, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _openUploadModal,
                            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                            label: Text(
                              'Subir Mis Fotos y Videos Ahora ✨',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sageDark,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _showLinkNameDialog,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: const Text('¿Ya habías subido antes? Vincular por tu nombre'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.sageGreen),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 36,
                    vertical: 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final folder = myFolders[index];
                        final dateFormat = DateFormat('dd/MM/yyyy • hh:mm a', 'es');
                        final dateStr = dateFormat.format(folder.timestamp);

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.sageBorder, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.sageGreen.withAlpha(20),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado de la carpeta
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    color: AppTheme.sageLight.withAlpha(120),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.sageBorder),
                                          ),
                                          child: const Icon(Icons.folder_shared_rounded, color: AppTheme.sageDark, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                folder.guestName,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppTheme.sageDeep,
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.mutedText),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.softPinkBg,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppTheme.pinkBorder),
                                          ),
                                          child: Text(
                                            '${folder.photos.length} recuerdos',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.deepRose,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Dedicatoria / Mensaje
                                  if (folder.comment.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppTheme.softPinkBg.withAlpha(100),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppTheme.pinkBorder),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('💌 ', style: TextStyle(fontSize: 18)),
                                            Expanded(
                                              child: Text(
                                                folder.comment,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontStyle: FontStyle.italic,
                                                  color: AppTheme.charcoal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Cuadrícula de fotos y videos
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isMobile ? 3 : 4,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: folder.photos.length,
                                      itemBuilder: (context, photoIndex) {
                                        final photo = folder.photos[photoIndex];
                                        return InkWell(
                                          onTap: () => _openPhoto(folder.photos, photoIndex, folder),
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppTheme.sageBorder),
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                if (photo.isVideo)
                                                  Container(
                                                    color: const Color(0xFF1E2621),
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
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
                                                else
                                                  Image(
                                                    image: photo.imageProvider,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx, err, stack) => Container(
                                                      color: AppTheme.sageLight,
                                                      child: const Center(
                                                        child: Icon(Icons.broken_image_rounded, color: AppTheme.sageGreen),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: myFolders.length,
                    ),
                  ),
                ),

              // Pie de página con opción para Anfitrión
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _showHostLoginDialog,
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                      label: const Text('¿Eres el Anfitrión o Familia de Danna? Iniciar sesión aquí'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.mutedText,
                        textStyle: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openUploadModal,
            backgroundColor: AppTheme.sageDark,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_photo_alternate_rounded),
            label: Text(
              'Subir Más Fotos y Videos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
