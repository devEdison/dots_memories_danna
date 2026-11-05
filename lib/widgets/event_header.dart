import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class EventHeader extends StatelessWidget {
  final int totalPhotos;
  final int totalFolders;
  final int totalLikes;
  final VoidCallback onUploadPressed;
  final VoidCallback onSlideshowPressed;
  final VoidCallback onQrPressed;
  final VoidCallback onSettingsPressed;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const EventHeader({
    super.key,
    required this.totalPhotos,
    required this.totalFolders,
    required this.totalLikes,
    required this.onUploadPressed,
    required this.onSlideshowPressed,
    required this.onQrPressed,
    required this.onSettingsPressed,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Elementos decorativos de fondo (destellos sutiles)
          Positioned(
            top: -20,
            right: 40,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                '15',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 220,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRose,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 20,
            child: Opacity(
              opacity: 0.12,
              child: Text(
                '✨ 🌸 👑 💖',
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
                  // Barra superior con botones secundarios
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge "Dots Memories"
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.borderLight),
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
                            const Text('📸', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'DOTS MEMORIES',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppTheme.primaryRose,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botones rápidos: Slideshow, QR, Configuración
                      Row(
                        children: [
                          _buildIconButton(
                            icon: Icons.qr_code_rounded,
                            label: isMobile ? null : 'QR Mesa',
                            tooltip: 'Código QR para las mesas',
                            onTap: onQrPressed,
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.slideshow_rounded,
                            label: isMobile ? null : 'Proyector',
                            tooltip: 'Pase de diapositivas en vivo',
                            onTap: onSlideshowPressed,
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            icon: Icons.cloud_outlined,
                            label: isMobile ? null : 'Google Nube',
                            tooltip: 'Configuración de Google Fotos / Drive',
                            onTap: onSettingsPressed,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Corona y Título Principal
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRose.withAlpha(40),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Text('👑', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 12),

                  ShaderMask(
                    shaderCallback: (bounds) => AppTheme.roseGoldGradient.createShader(bounds),
                    child: Text(
                      'Mis 15 Años • Danna',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isMobile ? 32 : 46,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '¡Bienvenido a mi álbum de recuerdos! Sube todas tus fotos y déjame tu dedicatoria.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 16,
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Métricas del evento
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      _buildMetricPill(
                        icon: Icons.photo_library_rounded,
                        value: '$totalPhotos',
                        label: 'Fotos subidas',
                        color: AppTheme.primaryRose,
                      ),
                      _buildMetricPill(
                        icon: Icons.folder_shared_rounded,
                        value: '$totalFolders',
                        label: 'Carpetas de invitados',
                        color: AppTheme.champagneGold,
                      ),
                      _buildMetricPill(
                        icon: Icons.favorite_rounded,
                        value: '$totalLikes',
                        label: 'Amores',
                        color: const Color(0xFFE55375),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // BOTÓN PRINCIPAL DE SUBIDA
                  ElevatedButton.icon(
                    onPressed: onUploadPressed,
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 22),
                    label: Text(
                      isMobile ? 'Subir Mis Fotos' : 'Subir Fotos y Dedicatoria ✨',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRose,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 26 : 38,
                        vertical: isMobile ? 14 : 18,
                      ),
                      elevation: 6,
                      shadowColor: AppTheme.primaryRose.withAlpha(120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // PESTAÑAS: Carpetas de Invitados vs Muro General
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.borderLight),
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
                          label: '📁 Carpetas por Invitado',
                          isActive: activeTab == 'folders',
                        ),
                        _buildTabButton(
                          id: 'wall',
                          label: '🖼️ Muro de Todas las Fotos',
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
          color: isActive ? AppTheme.primaryRose : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRose.withAlpha(80),
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
    required VoidCallback onTap,
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
                Icon(icon, size: 18, color: AppTheme.primaryRose),
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
        color: Colors.white.withAlpha(220),
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
              color: AppTheme.deepPlum,
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
