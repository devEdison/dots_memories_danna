import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/memory_folder.dart';
import '../services/download_helper.dart';
import '../theme/app_theme.dart';

class FolderDetailDialog extends StatelessWidget {
  final MemoryFolder folder;
  final Function(int photoIndex) onPhotoTap;

  const FolderDetailDialog({
    super.key,
    required this.folder,
    required this.onPhotoTap,
  });

  void _openGoogleDriveUrl(String url) {
    DownloadHelper.openUrl(url);
  }

  void _downloadDedication() {
    final text = '═══════════════════════════════════════════════\r\n'
        '  MIS 15 AÑOS - DANNA | DEDICATORIA DE INVITADO\r\n'
        '═══════════════════════════════════════════════\r\n\r\n'
        'De: ${folder.guestName}\r\n'
        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(folder.timestamp)}\r\n'
        'Total de fotos: ${folder.photos.length}\r\n\r\n'
        'MENSAJE:\r\n'
        '${folder.comment.isNotEmpty ? folder.comment : "(Sin mensaje de texto)"}\r\n\r\n'
        '═══════════════════════════════════════════════';

    final safeName = folder.guestName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    DownloadHelper.downloadText(text, 'Dedicatoria_$safeName.txt');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 16 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 950,
        height: size.height * (isMobile ? 0.92 : 0.88),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withAlpha(40),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // BARRA SUPERIOR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRose.withAlpha(30),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: AppTheme.primaryRose,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isMobile ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepPlum,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              DateFormat('d \'de\' MMMM, yyyy - h:mm a', 'es').format(folder.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${folder.photos.length} fotos',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryRose,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botón cerrar
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.charcoal,
                    ),
                  ),
                ],
              ),
            ),

            // CONTENIDO SCROLLABLE
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TARJETA DE DEDICATORIA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.softBlush,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('💌', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Dedicatoria para Danna',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.primaryDarkRose,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _downloadDedication,
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Descargar Nota'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryRose,
                                  textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            folder.comment.isNotEmpty
                                ? folder.comment
                                : '¡Muchas felicidades a Danna en sus 15 años! 🎉💖',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              color: AppTheme.charcoal,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (folder.folderUrl != null && folder.folderUrl!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => _openGoogleDriveUrl(folder.folderUrl!),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add_to_drive_rounded, color: Colors.blue.shade800, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Carpeta respaldada en Google Drive / Fotos',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    Text(
                                      'Toca aquí para abrir la carpeta original y descargar todas en alta resolución',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.open_in_new_rounded, color: Colors.blue.shade800, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // TÍTULO DE LA GALERÍA
                    Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, size: 20, color: AppTheme.primaryRose),
                        const SizedBox(width: 8),
                        Text(
                          'Fotos del Álbum (${folder.photos.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepPlum,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Toca cualquier foto para ampliar',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // GRID DE FOTOS
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: folder.photos.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        final photo = folder.photos[index];
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => onPhotoTap(index),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image(
                                    image: photo.imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                  // Gradiente inferior con hover
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Colors.black87, Colors.transparent],
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(
                                            Icons.zoom_in_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              if (photo.bytes != null) {
                                                DownloadHelper.downloadBytes(photo.bytes!, photo.fileName);
                                              }
                                            },
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
