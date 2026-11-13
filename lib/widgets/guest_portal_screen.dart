import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../services/appwrite_auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'festive_effects.dart';
import 'media_delete_controls.dart';
import 'photo_lightbox.dart';
import 'qr_code_dialog.dart';
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
  static final DateFormat _guestDateFormat = DateFormat('dd/MM/yyyy • hh:mm a', 'es');
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

  void _openQrDialog() {
    showDialog(
      context: context,
      builder: (context) => QrCodeDialog(storageService: widget.storageService),
    );
  }

  Future<bool> _confirmAndDeleteOwnPhoto(MemoryItem item, MemoryFolder folder) {
    return confirmAndDeleteMedia(
      context: context,
      storageService: widget.storageService,
      item: item,
      folderHint: folder,
      requireGuestOwnership: true,
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
          onDelete: (deletedItem) => _confirmAndDeleteOwnPhoto(deletedItem, folder),
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
          onDeletePhoto: (deletedPhoto) => _confirmAndDeleteOwnPhoto(deletedPhoto, folder),
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
              final rawName = _linkNameController.text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
              if (rawName.isNotEmpty) {
                final safeName = rawName.length > 50 ? rawName.substring(0, 50) : rawName;
                await widget.storageService.setMyGuestName(safeName);
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
    final emailCtrl = TextEditingController();
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
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo de Anfitrión',
                      hintText: 'correo@ejemplo.com',
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
                      hintText: '••••••••',
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
            scrollCacheExtent: const ScrollCacheExtent.pixels(600),
            slivers: [
              // HERO HEADER AISLADO EN VERDE SALVIA, ROSADO Y DORADO
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.goldBorder, width: 1.5),
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: QuinceTopRibbon(height: 3.5),
                      ),
                      const Positioned.fill(
                        child: QuinceAmbientBackdrop(particleCount: 22, opacityMultiplier: 0.85),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 18 : 36,
                          vertical: isMobile ? 24 : 32,
                        ),
                        child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        children: [
                          // Barra superior: botón para compartir QR y acciones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openQrDialog,
                                icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: AppTheme.deepRose),
                                label: Text(
                                  isMobile ? 'Compartir QR' : 'Compartir QR 📲',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.deepRose,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: AppTheme.pinkBorder, width: 1.5),
                                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 1,
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

                          // Corona animada de 15 Años con brillos dorados y rosados (aislado en RepaintBoundary)
                          RepaintBoundary(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 18))
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .fade(begin: 0.3, end: 1.0, duration: 1500.ms)
                                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFFDF2F4),
                                        Color(0xFFFCF7E3),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.warmGold, width: 2.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.warmGold.withAlpha(75),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: AppTheme.blushPink.withAlpha(50),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                  child: const Text('👑', style: TextStyle(fontSize: 36)),
                                )
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.10, 1.10), duration: 2000.ms)
                                    .shimmer(duration: 2400.ms, color: AppTheme.goldLight),
                                const SizedBox(width: 12),
                                const Text('✨', style: TextStyle(fontSize: 18))
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .fade(begin: 1.0, end: 0.3, duration: 1500.ms)
                                    .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Título con efecto de Brillo Dorado y Rosado (aislado en RepaintBoundary)
                          RepaintBoundary(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Mis 15 Años • ',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: isMobile ? 24 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.sageDeep,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Danna Alejandra 🌸',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: isMobile ? 24 : 32,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.deepRose,
                                      shadows: [
                                        Shadow(
                                          color: AppTheme.warmGold.withAlpha(80),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(duration: 2600.ms, color: AppTheme.goldLight),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 1.2, width: 32, color: AppTheme.goldBorder),
                              const SizedBox(width: 8),
                              const Text('🌿✨🌸✨🌿', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 8),
                              Container(height: 1.2, width: 32, color: AppTheme.goldBorder),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Insignia oficial de Fecha del Evento
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.goldBorder, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.warmGold.withAlpha(30),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 14,
                                  color: AppTheme.sageDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '28 de Noviembre de 2026',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                    color: AppTheme.sageDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            guestName.isNotEmpty
                                ? '¡Bienvenido(a), $guestName! Tu Espacio Privado de Recuerdos ✨'
                                : 'Tu Espacio Privado de Recuerdos ✨',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 13 : 15,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoal,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Aquí solo tú puedes ver tus fotos y videos subidos, y agregar todos los recuerdos que desees para Danna Alejandra.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tarjeta de Acción Rápida (visible cuando el invitado ya tiene recuerdos subidos)
                          if (myFolders.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppTheme.goldBorder, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.sageGreen.withAlpha(32),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: AppTheme.warmGold.withAlpha(28),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: isMobile
                                  ? Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppTheme.softPinkBg, AppTheme.goldLight],
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppTheme.goldBorder),
                                              ),
                                              child: const Text('📸', style: TextStyle(fontSize: 20)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tus recuerdos subidos:',
                                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.mutedText),
                                                  ),
                                                  Text(
                                                    '$totalPhotos fotos • $totalVideos videos (${myFolders.length} dedicatorias)',
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
                                            onPressed: _openUploadModal,
                                            icon: Icons.add_photo_alternate_rounded,
                                            label: 'Subir Más Fotos o Videos 📸',
                                            minHeight: 46,
                                            borderRadius: 16,
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
                                              colors: [AppTheme.softPinkBg, AppTheme.goldLight],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.goldBorder),
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
                                        QuincePrimaryButton(
                                          onPressed: _openUploadModal,
                                          icon: Icons.add_photo_alternate_rounded,
                                          label: 'Subir Más Fotos o Videos 📸',
                                          borderRadius: 16,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          fontSize: 14,
                                        ),
                                      ],
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                      ),
                    ],
                  ),
                ),
              ),

              // CONTENIDO DE RECUERDOS DEL INVITADO
              if (myFolders.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 20))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .fade(begin: 0.3, end: 1.0, duration: 1500.ms),
                              const SizedBox(width: 14),
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.softPinkBg, AppTheme.goldLight],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.warmGold, width: 1.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.warmGold.withAlpha(65),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: const Text('🌸', style: TextStyle(fontSize: 48)),
                              )
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 2200.ms),
                              const SizedBox(width: 14),
                              const Text('✨', style: TextStyle(fontSize: 20))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .fade(begin: 1.0, end: 0.3, duration: 1500.ms),
                            ],
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
                              '¡Sé el primero en dejarle un hermoso recuerdo a Danna Alejandra en sus 15 años! Comparte todas las fotos y videos que tomaste durante la celebración.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: AppTheme.mutedText, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 24),
                          QuincePrimaryButton(
                            onPressed: _openUploadModal,
                            icon: Icons.cloud_upload_rounded,
                            label: 'Subir Mis Fotos y Videos Ahora ✨',
                            borderRadius: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            fontSize: 15,
                          ),
                          const SizedBox(height: 16),
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
                        final dateStr = _guestDateFormat.format(folder.timestamp);

                        return RepaintBoundary(
                          child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 900),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.goldBorder, width: 1.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.sageGreen.withAlpha(24),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado de la carpeta Verde Salvia + Rosado + Dorado
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.sageLight, Color(0xFFFAF3F5)],
                                      ),
                                      border: Border(
                                        bottom: BorderSide(color: AppTheme.goldBorder, width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.goldBorder, width: 1.3),
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
                                    child: folder.photos.isEmpty
                                        ? Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 22,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.scaffoldBg,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppTheme.borderLight),
                                            ),
                                            child: Text(
                                              'No quedan fotos en esta publicación. Toca "Subir Fotos / Videos" para agregar nuevas.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: AppTheme.mutedText,
                                              ),
                                            ),
                                          )
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: isMobile
                                                  ? (size.width < 420 ? 2 : 3)
                                                  : (size.width < 900 ? 4 : 5),
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
                                                          image: photo.thumbnailProvider,
                                                          fit: BoxFit.cover,
                                                          gaplessPlayback: true,
                                                          filterQuality: FilterQuality.medium,
                                                          errorBuilder: (ctx, err, stack) => Container(
                                                            color: AppTheme.sageLight,
                                                            child: const Center(
                                                              child: Icon(Icons.broken_image_rounded, color: AppTheme.sageGreen),
                                                            ),
                                                          ),
                                                        ),
                                                      MediaTileDeleteButton(
                                                        onTap: () => _confirmAndDeleteOwnPhoto(photo, folder),
                                                        tooltip: photo.isVideo
                                                            ? 'Eliminar mi video'
                                                            : 'Eliminar mi foto',
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
                            )
                                .animate(delay: ((index % 5) * 80).ms)
                                .fadeIn(duration: 420.ms)
                                .slideY(begin: 0.04, end: 0, curve: Curves.easeOut),
                          ),
                        ),
                        );
                      },
                      childCount: myFolders.length,
                    ),
                  ),
                ),

              // Pie de página con opción para Anfitrión y copyright
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 84, left: 20, right: 20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _showHostLoginDialog,
                          icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                          label: const Text('¿Eres el Anfitrión o Familia de Danna Alejandra? Iniciar sesión aquí'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.mutedText,
                            textStyle: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const QuinceCopyrightNotice(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
