import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'festive_effects.dart';

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
  final VoidCallback? onGoogleDrivePressed;
  final VoidCallback? onRefreshPressed;
  final bool isSyncing;
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final String? eventDate;

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
    this.onGoogleDrivePressed,
    this.onRefreshPressed,
    this.isSyncing = false,
    required this.activeTab,
    required this.onTabChanged,
    this.eventDate,
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
          bottom: BorderSide(color: AppTheme.goldBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.sageGreen.withAlpha(24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
            child: QuinceAmbientBackdrop(particleCount: 24, opacityMultiplier: 0.85),
          ),
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
              opacity: 0.18,
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
                                border: Border.all(color: AppTheme.goldBorder, width: 1.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warmGold.withAlpha(35),
                                    blurRadius: 10,
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
                                  const SizedBox(width: 4),
                                  const Text('✨', style: TextStyle(fontSize: 11)),
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
                            if (onGoogleDrivePressed != null) ...[
                              _buildIconButton(
                                icon: Icons.folder_shared_rounded,
                                label: isCompact ? null : 'Google Drive',
                                tooltip: 'Abrir carpeta del evento en Google Drive (Mi Unidad > 15 Años Danna - Fotos de Invitados)',
                                onTap: onGoogleDrivePressed,
                              ),
                              const SizedBox(width: 8),
                            ],
                            _buildIconButton(
                              icon: Icons.qr_code_rounded,
                              label: isCompact ? null : 'Llave QR',
                              tooltip: 'Código QR con llave de acceso para invitados',
                              onTap: onQrPressed,
                            ),
                            const SizedBox(width: 8),
                            _buildIconButton(
                              icon: Icons.auto_awesome_rounded,
                              label: isCompact ? null : 'Proyección',
                              tooltip: 'Abrir Proyección de Gala en Pantalla Grande (TV / Proyector)',
                              onTap: onSlideshowPressed,
                              highlightGold: true,
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

                  // Corona Real con halo Dorado, Rosado y Salvia animado (aislado en RepaintBoundary para evitar repintados innecesarios)
                  RepaintBoundary(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 22))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.3, end: 1.0, duration: 1500.ms)
                            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
                        const SizedBox(width: 14),
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
                            border: Border.all(color: AppTheme.warmGold, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.warmGold.withAlpha(75),
                                blurRadius: 22,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: AppTheme.blushPink.withAlpha(60),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Text('👑', style: TextStyle(fontSize: 40)),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.10, 1.10), duration: 2000.ms)
                            .shimmer(duration: 2400.ms, color: AppTheme.goldLight),
                        const SizedBox(width: 14),
                        const Text('✨', style: TextStyle(fontSize: 22))
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 1.0, end: 0.3, duration: 1500.ms)
                            .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Título principal con efecto Shimmer Dorado y Rosado (aislado en RepaintBoundary)
                  RepaintBoundary(
                    child: RichText(
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
                            text: 'Danna Alejandra 🌸',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: isMobile ? 30 : 44,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.deepRose,
                              letterSpacing: -0.5,
                              shadows: [
                                Shadow(
                                  color: AppTheme.warmGold.withAlpha(90),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(duration: 2800.ms, color: AppTheme.goldLight),
                  ),
                  const SizedBox(height: 6),

                  // Decoración botánica y dorada
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 1.5, width: 42, color: AppTheme.goldBorder),
                      const SizedBox(width: 8),
                      const Text('🌿✨🌸✨🌿', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Container(height: 1.5, width: 42, color: AppTheme.goldBorder),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Insignia oficial de Fecha del Evento
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.goldBorder, width: 1.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warmGold.withAlpha(35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 15,
                          color: AppTheme.sageDark,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          eventDate?.trim().isNotEmpty == true
                              ? (eventDate!.contains('-') ? '28 de Noviembre de 2026' : eventDate!)
                              : '28 de Noviembre de 2026',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: AppTheme.sageDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

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

                  // Métricas del evento (Verde Salvia, Rosado & Dorado)
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
                        borderColor: AppTheme.sageBorder,
                      ),
                      _buildMetricPill(
                        icon: Icons.folder_shared_rounded,
                        value: '$totalFolders',
                        label: 'Carpetas de invitados',
                        color: AppTheme.deepRose,
                        borderColor: AppTheme.pinkBorder,
                      ),
                      _buildMetricPill(
                        icon: Icons.favorite_rounded,
                        value: '$totalLikes',
                        label: 'Amores',
                        color: AppTheme.goldDeep,
                        borderColor: AppTheme.goldBorder,
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // BOTÓN PRINCIPAL DE SUBIDA (Verde Salvia con borde Dorado y destello)
                  QuincePrimaryButton(
                    onPressed: onUploadPressed,
                    icon: isAccessUnlocked ? Icons.add_photo_alternate_rounded : Icons.lock_open_rounded,
                    label: isAccessUnlocked
                        ? (isMobile ? 'Subir Mis Fotos' : 'Subir Fotos y Dedicatoria 🌸')
                        : 'Desbloquear y Subir Fotos 🔒',
                    usePinkGradient: !isAccessUnlocked,
                    borderRadius: 30,
                    fontSize: isMobile ? 15 : 17,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 26 : 38,
                      vertical: isMobile ? 14 : 18,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // PESTAÑAS: Carpetas de Invitados vs Muro General
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.goldBorder, width: 1.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.warmGold.withAlpha(30),
                          blurRadius: 12,
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
          gradient: isActive ? AppTheme.sageGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: isActive ? Border.all(color: AppTheme.goldBorder, width: 1.2) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.sageGreen.withAlpha(85),
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
    bool highlightGold = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlightGold ? const Color(0xFFFFFCF3) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: highlightGold
              ? const BorderSide(color: AppTheme.goldBorder, width: 1.4)
              : BorderSide.none,
        ),
        elevation: highlightGold ? 3 : 2,
        shadowColor: highlightGold
            ? AppTheme.warmGold.withAlpha(65)
            : Colors.black.withAlpha(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: highlightGold ? AppTheme.goldDeep : AppTheme.sageGreen,
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: highlightGold ? AppTheme.sageDeep : AppTheme.charcoal,
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
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? color.withAlpha(70), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? color).withAlpha(35),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
