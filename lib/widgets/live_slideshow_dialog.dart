import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../theme/app_theme.dart';

class SlideshowItem {
  final MemoryItem photo;
  final MemoryFolder folder;

  SlideshowItem({required this.photo, required this.folder});
}

class LiveSlideshowDialog extends StatefulWidget {
  final List<MemoryFolder> folders;

  const LiveSlideshowDialog({
    super.key,
    required this.folders,
  });

  @override
  State<LiveSlideshowDialog> createState() => _LiveSlideshowDialogState();
}

class _LiveSlideshowDialogState extends State<LiveSlideshowDialog> {
  late List<SlideshowItem> _items;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _buildItemsList();
    _startTimer();
  }

  void _buildItemsList() {
    _items = [];
    for (final folder in widget.folders) {
      for (final photo in folder.photos) {
        _items.add(SlideshowItem(photo: photo, folder: folder));
      }
    }
    // Si no hay items, fallback
    _items.shuffle(); // Mezclar recuerdos para que sea variado y dinámico
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_isPlaying || _items.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _items.length;
        });
      }
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _next() {
    if (_items.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _items.length;
    });
    if (_isPlaying) _startTimer();
  }

  void _prev() {
    if (_items.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + _items.length) % _items.length;
    });
    if (_isPlaying) _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('👑', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Aún no hay fotos para el proyector',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = _items[_currentIndex];
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // IMAGEN DEL SLIDESHOW CON ANIMATED SWITCHER
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1200),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: SizedBox.expand(
              key: ValueKey<String>(currentItem.photo.id),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo difuminado
                  Image(
                    image: currentItem.photo.imageProvider,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                  ),
                  Container(
                    color: Colors.black.withAlpha(160),
                  ),
                  // Imagen principal nítida
                  Center(
                    child: Image(
                      image: currentItem.photo.imageProvider,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_outlined, color: AppTheme.dustyPink, size: 72),
                              const SizedBox(height: 12),
                              Text(
                                currentItem.folder.guestName,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BARRA SUPERIOR PROYECTOR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Text(
                          'MIS 15 AÑOS • DANNA',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isMobile ? 16 : 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: const Color(0xFFFFD1DC),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _prev,
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: _togglePlay,
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: _next,
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(40),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LOWER THIRD: DETALLES DEL INVITADO Y DEDICATORIA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: isMobile ? 20 : 30,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF0000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.sageGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('💌', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentItem.folder.guestName,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFDF79),
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 15 : 18,
                            ),
                          ),
                          if (currentItem.folder.comment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '“${currentItem.folder.comment}”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withAlpha(220),
                                fontSize: isMobile ? 13 : 15,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${_items.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
