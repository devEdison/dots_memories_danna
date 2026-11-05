import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/memory_folder.dart';
import '../theme/app_theme.dart';

class FolderCard extends StatelessWidget {
  final MemoryFolder folder;
  final VoidCallback onOpen;
  final VoidCallback onLike;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onOpen,
    required this.onLike,
  });

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Justo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return DateFormat('d MMM, h:mm a', 'es').format(dt);
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppTheme.sageGreen,
      AppTheme.dustyPink,
      AppTheme.sageDark,
      AppTheme.blushPink,
      const Color(0xFF5B7F67),
      const Color(0xFFC07688),
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'I';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(folder.guestName);
    final photoCount = folder.photos.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: AppTheme.sageGreen.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.sageBorder, width: 1.2),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la carpeta estilo pestaña Verde Salvia
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.sageLight,
                border: Border(
                  bottom: BorderSide(color: AppTheme.sageBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Avatar de iniciales
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor,
                    child: Text(
                      _getInitials(folder.guestName),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nombre del invitado y fecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _formatTime(folder.timestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            if (folder.isSyncedToGoogle) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.sageBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.cloud_done_rounded, size: 11, color: AppTheme.sageDark),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Google Nube',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.sageDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge de cantidad de fotos en Rosado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.softPinkBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.pinkBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 14, color: AppTheme.dustyPink),
                        const SizedBox(width: 4),
                        Text(
                          '$photoCount',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepRose,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Previsualización de fotos de la carpeta
            Expanded(
              child: _buildPhotoCollage(),
            ),

            // Comentario / Dedicatoria del invitado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (folder.comment.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '“',
                          style: TextStyle(
                            fontSize: 22,
                            color: AppTheme.dustyPink,
                            fontWeight: FontWeight.bold,
                            height: 0.8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            folder.comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.charcoal,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '(Sin mensaje de texto)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.mutedText.withAlpha(140),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Barra inferior con botón de corazón y abrir
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Like
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onLike,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                size: 18,
                                color: AppTheme.dustyPink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${folder.likes}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Botón Abrir Carpeta
                      Row(
                        children: [
                          Text(
                            'Ver fotos',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sageDark,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppTheme.sageDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCollage() {
    final photos = folder.photos;
    if (photos.isEmpty) {
      return Container(
        color: AppTheme.sageLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_outlined, size: 36, color: AppTheme.sageBorder),
              const SizedBox(height: 6),
              Text(
                'Sin fotos',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
      );
    }

    if (photos.length == 1) {
      return _buildImageTile(photos[0].imageProvider);
    }

    if (photos.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageTile(photos[0].imageProvider)),
          const SizedBox(width: 2),
          Expanded(child: _buildImageTile(photos[1].imageProvider)),
        ],
      );
    }

    if (photos.length == 3) {
      return Row(
        children: [
          Expanded(flex: 2, child: _buildImageTile(photos[0].imageProvider)),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildImageTile(photos[1].imageProvider)),
                const SizedBox(height: 2),
                Expanded(child: _buildImageTile(photos[2].imageProvider)),
              ],
            ),
          ),
        ],
      );
    }

    // 4 o más fotos
    final extra = photos.length - 4;
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(child: _buildImageTile(photos[0].imageProvider)),
              const SizedBox(height: 2),
              Expanded(child: _buildImageTile(photos[1].imageProvider)),
            ],
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Expanded(child: _buildImageTile(photos[2].imageProvider)),
              const SizedBox(height: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImageTile(photos[3].imageProvider),
                    if (extra > 0)
                      Container(
                        color: Colors.black.withAlpha(150),
                        child: Center(
                          child: Text(
                            '+$extra',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(ImageProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sageLight,
        image: DecorationImage(
          image: provider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
