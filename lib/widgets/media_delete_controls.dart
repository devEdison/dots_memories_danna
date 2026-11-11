import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Muestra un diálogo de confirmación y elimina una foto o video individual.
Future<bool> confirmAndDeleteMedia({
  required BuildContext context,
  required StorageService storageService,
  required MemoryItem item,
  MemoryFolder? folderHint,
  bool requireGuestOwnership = false,
}) async {
  final allFolders = storageService.foldersNotifier.value;
  MemoryFolder? resolvedFolder;
  for (final f in allFolders) {
    if (f.photos.any((p) => p.id == item.id)) {
      resolvedFolder = f;
      break;
    }
  }
  resolvedFolder ??= folderHint;

  final itemLabel = item.isVideo ? 'video' : 'foto';
  final guestLabel = resolvedFolder?.guestName ?? 'este invitado';
  final title = item.isVideo
      ? (requireGuestOwnership ? '¿Eliminar tu video?' : '¿Eliminar este video?')
      : (requireGuestOwnership ? '¿Eliminar tu foto?' : '¿Eliminar esta foto?');
  final description = requireGuestOwnership
      ? 'Se eliminará ${item.isVideo ? 'este video' : 'esta foto'} de tus recuerdos y se moverá a la papelera de Google Drive para que no vuelva a aparecer.'
      : 'Se eliminará ${item.isVideo ? 'este $itemLabel' : 'esta $itemLabel'} de "$guestLabel" en el álbum y se moverá a la papelera de Google Drive para que no vuelva a aparecer.';

  var isDeleting = false;
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFB91C1C),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.sageDeep,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.mutedText,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: isDeleting
                ? null
                : () async {
                    setDialogState(() => isDeleting = true);
                    final result = await storageService.deletePhoto(
                      item,
                      folderHint: resolvedFolder,
                      requireGuestOwnership: requireGuestOwnership,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(result.success);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: result.success
                              ? AppTheme.sageDeep
                              : const Color(0xFFB91C1C),
                          content: Text(
                            result.message,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
            icon: isDeleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              isDeleting ? 'Eliminando...' : 'Eliminar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
  return deleted ?? false;
}

/// Botón discreto en la esquina superior derecha para eliminar una miniatura de foto o video.
class MediaTileDeleteButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isDeleting;
  final String tooltip;

  const MediaTileDeleteButton({
    super.key,
    required this.onTap,
    required this.tooltip,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.black.withAlpha(155),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: isDeleting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

