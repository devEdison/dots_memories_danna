import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EventHeader extends StatelessWidget {
  final int totalPhotos;
  final int totalFolders;
  final int totalLikes;
  final bool isAccessUnlocked;
  final VoidCallback onUploadPressed;
  final VoidCallback onSlideshowPressed;
  final VoidCallback onQrPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onUnlockPressed;
  final VoidCallback onGooglePhotosPressed;
  final VoidCallback? onRefreshPressed;
  final bool isSyncing;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const EventHeader({
    super.key,
    required this.totalPhotos,
    required this.totalFolders,
    required this.totalLikes,
    required this.isAccessUnlocked,
    required this.onUploadPressed,
    required this.onSlideshowPressed,
    required this.onQrPressed,
    required this.onSettingsPressed,
    required this.onUnlockPressed,
    required this.onGooglePhotosPressed,
    this.onRefreshPressed,
    this.isSyncing = false,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isCompact = screenWidth < 900;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sageGreen.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Elementos decorativos de fondo en verde salvia y rosa
          Positioned(
            top: -20,
            right: 40,
            child: Opacity(
              opacity: 0.06,
              child: Text(
                '15',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 220,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sageGreen,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 20,
            child: Opacity(
              opacity: 0.15,
              child: Text(
                '🌿 🌸 👑 ✨',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16.0 : 36.0,
                vertical: isMobile ? 20.0 : 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Barra superior responsive con Wrap (evita cualquier desbordamiento)
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Badge "Dots Memories" & Estado de llave QR
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppTheme.sageBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🌿', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'DOTS MEMORIES',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      color: AppTheme.sageDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 10),
                              _buildAccessBadge(),
                            ],
                          ],
                        ),

                        // Botones rápidos: Actualizar, Google Fotos, Slideshow, QR, Configuración
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onRefreshPressed != null) ...[
                              _buildIconButton(
                                icon: isSyncing ? Icons.sync_rounded : Icons.refresh_rounded,
                                label: isCompact ? null : (isSyncing ? 'Sincronizando...' : 'Actualizar'),
                                tooltip: 'Sincronizar recuerdos en tiempo real desde Google Nube',
                                onTap: isSyncing ? null : onRefreshPressed,
                              ),
                              const SizedBox(width: 8),
                            ],
                            _buildIconButton(
                              icon: Icons.photo_library_rounded,
                              label: isCompact ? null : 'Google Fotos',
                              tooltip: 'Ver álbum oficial en Google Fotos',
                              onTap: onGooglePhotosPressed,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.qr_code_rounded,
                              label: isCompact ? null : 'Llave QR',
                              tooltip: 'Código QR con llave de acceso para invitados',
                              onTap: onQrPressed,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.slideshow_rounded,
                              label: isCompact ? null : 'Proyector',
                              tooltip: 'Pase de diapositivas en vivo',
                              onTap: onSlideshowPressed,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.cloud_outlined,
                              label: isCompact ? null : 'Nube',
                              tooltip: 'Configuración de Google Fotos / Drive',
                              onTap: onSettingsPressed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (isCompact) ...[
                    const SizedBox(height: 12),
                    _buildAccessBadge(),
                  ],

                  const SizedBox(height: 22),

                  // Corona e icono floral con animación
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(220),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.pinkBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.blushPink.withAlpha(50),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Text('👑', style: TextStyle(fontSize: 38)),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.08, 1.08), duration: 2200.ms),
                  const SizedBox(height: 12),

                  // Título principal con efecto Shimmer para Danna
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Mis 15 Años • ',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isMobile ? 30 : 46,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageDeep,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Danna 🌸',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isMobile ? 32 : 48,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepRose,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 2800.ms, color: const Color(0xFFFFDCE5)),
                  const SizedBox(height: 6),

                  Text(
                    '¡Bienvenido a mi álbum de recuerdos! Sube tus fotos de esta noche y déjame tu dedicatoria.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 16,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Métricas del evento
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      _buildMetricPill(
                        icon: Icons.photo_library_rounded,
                        value: '$totalPhotos',
                        label: 'Fotos de la fiesta',
                        color: AppTheme.sageDark,
                      ),
                      _buildMetricPill(
                        icon: Icons.folder_shared_rounded,
                        value: '$totalFolders',
                        label: 'Carpetas de invitados',
                        color: AppTheme.dustyPink,
                      ),
                      _buildMetricPill(
                        icon: Icons.favorite_rounded,
                        value: '$totalLikes',
                        label: 'Amores',
                        color: AppTheme.deepRose,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // BOTÓN PRINCIPAL DE SUBIDA (Verde Salvia y Rosado)
                  ElevatedButton.icon(
                    onPressed: onUploadPressed,
                    icon: Icon(
                      isAccessUnlocked ? Icons.add_photo_alternate_rounded : Icons.lock_open_rounded,
                      size: 22,
                    ),
                    label: Text(
                      isAccessUnlocked
                          ? (isMobile ? 'Subir Mis Fotos' : 'Subir Fotos y Dedicatoria 🌸')
                          : 'Desbloquear y Subir Fotos 🔒',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAccessUnlocked ? AppTheme.sageGreen : AppTheme.dustyPink,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 26 : 38,
                        vertical: isMobile ? 14 : 18,
                      ),
                      elevation: 5,
                      shadowColor: (isAccessUnlocked ? AppTheme.sageGreen : AppTheme.dustyPink).withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // PESTAÑAS: Carpetas de Invitados vs Muro General
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.sageBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(
                          id: 'folders',
                          label: '📁 Carpetas de Invitados',
                          isActive: activeTab == 'folders',
                        ),
                        _buildTabButton(
                          id: 'wall',
                          label: '🌸 Muro de Fotos',
                          isActive: activeTab == 'wall',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessBadge() {
    return GestureDetector(
      onTap: onUnlockPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isAccessUnlocked ? AppTheme.sageLight : AppTheme.softPinkBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAccessUnlocked ? AppTheme.sageBorder : AppTheme.pinkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAccessUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
              size: 13,
              color: isAccessUnlocked ? AppTheme.sageDark : AppTheme.deepRose,
            ),
            const SizedBox(width: 5),
            Text(
              isAccessUnlocked ? 'Llave QR Activa (Subidas habilitadas)' : 'Escanea QR o ingresa clave',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAccessUnlocked ? AppTheme.sageDark : AppTheme.deepRose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTabChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.sageGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.sageGreen.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.charcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    String? label,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppTheme.sageGreen),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.sageDeep,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
