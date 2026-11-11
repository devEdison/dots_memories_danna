import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../services/download_helper.dart';
import '../theme/app_theme.dart';
import 'media_delete_controls.dart';

class FolderDetailDialog extends StatefulWidget {
  final MemoryFolder folder;
  final Function(int photoIndex) onPhotoTap;
  final VoidCallback? onDeleteFolder;
  final Future<bool> Function(MemoryItem photo)? onDeletePhoto;

  const FolderDetailDialog({
    super.key,
    required this.folder,
    required this.onPhotoTap,
    this.onDeleteFolder,
    this.onDeletePhoto,
  });

  @override
  State<FolderDetailDialog> createState() => _FolderDetailDialogState();
}

class _FolderDetailDialogState extends State<FolderDetailDialog> {
  late List<MemoryItem> _photos;
  String? _deletingPhotoId;

  MemoryFolder get folder => widget.folder;
  Function(int photoIndex) get onPhotoTap => widget.onPhotoTap;
  VoidCallback? get onDeleteFolder => widget.onDeleteFolder;
  Future<bool> Function(MemoryItem photo)? get onDeletePhoto => widget.onDeletePhoto;

  @override
  void initState() {
    super.initState();
    _photos = List<MemoryItem>.from(widget.folder.photos);
  }

  Future<void> _handleDeletePhoto(MemoryItem photo) async {
    if (onDeletePhoto == null || _deletingPhotoId != null) return;
    setState(() => _deletingPhotoId = photo.id);
    try {
      final deleted = await onDeletePhoto!(photo);
      if (deleted && mounted) {
        setState(() {
          _photos.removeWhere((p) => p.id == photo.id);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _deletingPhotoId = null);
      }
    }
  }

  void _openGoogleDriveUrl(String url) {
    DownloadHelper.openUrl(url);
  }

  void _downloadDedication() {
    final text = '═══════════════════════════════════════════════\r\n'
        '  MIS 15 AÑOS - DANNA | DEDICATORIA DE INVITADO\r\n'
        '═══════════════════════════════════════════════\r\n\r\n'
        'De: ${folder.guestName}\r\n'
        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(folder.timestamp)}\r\n'
        'Total de fotos: ${_photos.length}\r\n\r\n'
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
              color: AppTheme.sageGreen.withAlpha(40),
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
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.softPinkBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.pinkBorder),
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: AppTheme.sageDark,
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
                            color: AppTheme.sageDeep,
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
                              '• ${_photos.length} fotos',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.dustyPink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onDeleteFolder != null) ...[
                    Tooltip(
                      message: 'Eliminar carpeta del álbum y Drive',
                      child: IconButton(
                        onPressed: onDeleteFolder,
                        icon: const Icon(Icons.delete_outline_rounded, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFDECEF),
                          foregroundColor: AppTheme.deepRose,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
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
                    // TARJETA DE DEDICATORIA EN ROSADO SUAVE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.softPinkBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.pinkBorder, width: 1.2),
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
                                      color: AppTheme.deepRose,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _downloadDedication,
                                icon: const Icon(Icons.download_rounded, size: 16),
                                label: const Text('Descargar Nota'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.sageDark,
                                  textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            folder.comment.isNotEmpty
                                ? folder.comment
                                : '¡Muchas felicidades a Danna en sus 15 años! 🌸💖',
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
                            color: AppTheme.sageLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.sageBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_done_rounded, color: AppTheme.sageDark, size: 22),
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
                                        color: AppTheme.sageDeep,
                                      ),
                                    ),
                                    Text(
                                      'Ruta: Mi Unidad > 15 Años Danna - Fotos de Invitados > ${folder.guestName}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.sageDark,
                                      ),
                                    ),
                                    Text(
                                      'Toca aquí para abrir la subcarpeta original en Google Drive',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded, color: AppTheme.sageDark, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Botón directo al Álbum oficial de Google Fotos de Danna
                    InkWell(
                      onTap: () => DownloadHelper.openUrl(
                        'https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm',
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.softPinkBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.pinkBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_library_rounded, color: AppTheme.dustyPink, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Álbum Oficial en Google Fotos de Danna',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.sageDeep,
                                    ),
                                  ),
                                  Text(
                                    'Abrir álbum en Google Fotos para ver la colección completa',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded, color: AppTheme.dustyPink, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TÍTULO DE LA GALERÍA
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_rounded, size: 20, color: AppTheme.sageGreen),
                              const SizedBox(width: 8),
                              Text(
                                'Fotos del Álbum (${_photos.length})',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.sageDeep,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Toca cualquier foto para ampliar',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GRID DE FOTOS
                    if (_photos.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              color: AppTheme.mutedText,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No hay fotos en esta carpeta.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _photos.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 2 : 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          final photo = _photos[index];
                          final isDeletingThis = _deletingPhotoId == photo.id;
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => onPhotoTap(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    photo.isVideo
                                        ? Container(
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
                                        : Image(
                                            image: photo.thumbnailProvider,
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
                                    if (onDeletePhoto != null)
                                      MediaTileDeleteButton(
                                        isDeleting: isDeletingThis,
                                        onTap: _deletingPhotoId != null
                                            ? null
                                            : () => _handleDeletePhoto(photo),
                                        tooltip: photo.isVideo
                                            ? 'Eliminar video no permitido'
                                            : 'Eliminar foto no permitida',
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
