import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../services/download_helper.dart';
import '../theme/app_theme.dart';

class PhotoLightbox extends StatefulWidget {
  final List<MemoryItem> photos;
  final int initialIndex;
  final MemoryFolder? folder;
  final Future<bool> Function(MemoryItem photo)? onDeletePhoto;

  const PhotoLightbox({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.folder,
    this.onDeletePhoto,
  });

  @override
  State<PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<PhotoLightbox> {
  late PageController _pageController;
  late List<MemoryItem> _photos;
  late int _currentIndex;
  bool _isDeleting = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _photos = List<MemoryItem>.from(widget.photos);
    final safeInitial = _photos.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _photos.length - 1);
    _currentIndex = safeInitial;
    _pageController = PageController(initialPage: safeInitial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _nextPhoto() {
    if (_currentIndex < _photos.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPhoto() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _deleteCurrentPhoto() async {
    if (_isDeleting || widget.onDeletePhoto == null || _photos.isEmpty) return;
    setState(() => _isDeleting = true);
    try {
      final targetPhoto = _photos[_currentIndex];
      final deleted = await widget.onDeletePhoto!(targetPhoto);
      if (!mounted || !deleted) return;

      final remaining = List<MemoryItem>.from(_photos)
        ..removeAt(_currentIndex);
      if (remaining.isEmpty) {
        Navigator.of(context).pop();
        return;
      }

      final nextIndex = _currentIndex.clamp(0, remaining.length - 1);
      setState(() {
        _photos = remaining;
        _currentIndex = nextIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(nextIndex);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextPhoto();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _prevPhoto();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  void _downloadCurrentPhoto() {
    if (_photos.isEmpty) return;
    final currentPhoto = _photos[_currentIndex];
    if (currentPhoto.bytes != null) {
      DownloadHelper.downloadBytes(currentPhoto.bytes!, currentPhoto.fileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Descargando ${currentPhoto.fileName}...'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (currentPhoto.remoteUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto respaldada en la nube de Google.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return const SizedBox.shrink();
    }
    final isMobile = MediaQuery.of(context).size.width < 768;
    final currentPhoto = _photos[_currentIndex];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black.withAlpha(245),
        body: Stack(
          children: [
            // PAGE VIEW DE FOTOS
            PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: photo.id,
                      child: Image(
                        image: photo.imageProvider,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.sageGreen,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_outlined, color: AppTheme.dustyPink, size: 64),
                                const SizedBox(height: 12),
                                Text(
                                  'Cargando imagen desde la nube...',
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),

            // FLECHAS DE NAVEGACIÓN (Desktop / Tablet)
            if (!isMobile && _photos.length > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _prevPhoto,
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 30),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              if (_currentIndex < _photos.length - 1)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _nextPhoto,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 30),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
            ],

            // BARRA SUPERIOR
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_photos.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentPhoto.caption ?? currentPhoto.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (widget.onDeletePhoto != null) ...[
                        IconButton(
                          onPressed: _isDeleting ? null : _deleteCurrentPhoto,
                          tooltip: 'Eliminar foto no permitida',
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xCC991B1B),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: _downloadCurrentPhoto,
                        tooltip: 'Descargar foto',
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(30),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Cerrar',
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // BARRA INFERIOR CON DETALLES DEL INVITADO
            if (widget.folder != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xF0000000), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              widget.folder!.guestName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        if (widget.folder!.comment.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '“${widget.folder!.comment}”',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withAlpha(200),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
