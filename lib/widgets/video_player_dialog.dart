import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory_item.dart';
import '../services/download_helper.dart';
import '../theme/app_theme.dart';

class VideoPlayerDialog extends StatelessWidget {
  final MemoryItem item;
  final String? guestName;

  const VideoPlayerDialog({
    super.key,
    required this.item,
    this.guestName,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final videoUrl = item.remoteUrl ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 40,
        vertical: isMobile ? 20 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.sageLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.movie_rounded, color: AppTheme.sageDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video de Recuerdo 🎬',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                        if (guestName != null && guestName!.isNotEmpty)
                          Text(
                            'Subido por: $guestName',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.sageDeep),
                  ),
                ],
              ),
            ),

            // Video Preview & Action Card
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2621),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.sageBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.deepRose.withAlpha(200),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            item.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'VIDEO HD • CLOUD CDN',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón Reproducir / Abrir
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (videoUrl.isNotEmpty) {
                          DownloadHelper.openUrl(videoUrl);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                      label: Text(
                        'Reproducir Video en Pantalla Completa',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sageDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  if (item.bytes != null && item.bytes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        DownloadHelper.downloadBytes(item.bytes!, item.fileName);
                      },
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Descargar archivo de video'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.sageDark,
                        side: const BorderSide(color: AppTheme.sageBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

