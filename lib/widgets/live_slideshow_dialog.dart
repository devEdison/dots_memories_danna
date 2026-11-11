import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/memory_folder.dart';
import '../models/memory_item.dart';
import '../services/download_helper.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'festive_effects.dart';

enum ProjectionFrameStyle { cinema, galaMatte }

enum ProjectionOrder { shuffled, latestFirst }

class SlideshowItem {
  final MemoryItem photo;
  final MemoryFolder folder;

  const SlideshowItem({required this.photo, required this.folder});
}

class LiveSlideshowDialog extends StatefulWidget {
  final List<MemoryFolder> folders;
  final StorageService? storageService;

  const LiveSlideshowDialog({
    super.key,
    required this.folders,
    this.storageService,
  });

  @override
  State<LiveSlideshowDialog> createState() => _LiveSlideshowDialogState();
}

class _LiveSlideshowDialogState extends State<LiveSlideshowDialog>
    with SingleTickerProviderStateMixin {
  static const List<int> _intervalOptions = [5, 8, 12];

  late List<SlideshowItem> _items;
  final Set<String> _knownPhotoIds = <String>{};
  int _videoCount = 0;
  int _currentIndex = 0;
  int _intervalSeconds = 8;

  bool _isPlaying = true;
  bool _controlsVisible = true;
  bool _showQrCard = true;
  bool _isFullscreen = false;
  bool _isSyncingManual = false;
  String? _liveArrivalGuest;

  ProjectionFrameStyle _frameStyle = ProjectionFrameStyle.cinema;
  ProjectionOrder _order = ProjectionOrder.shuffled;

  late final AnimationController _slideController;
  Timer? _hideControlsTimer;
  Timer? _liveSyncTimer;
  Timer? _arrivalBannerTimer;

  @override
  void initState() {
    super.initState();
    _isFullscreen = DownloadHelper.isFullscreen;

    _slideController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _intervalSeconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && _isPlaying) {
          _next(fromAutoAdvance: true);
        }
      });

    final sourceFolders = widget.storageService?.folders.isNotEmpty == true
        ? widget.storageService!.folders
        : widget.folders;
    _rebuildItemsList(sourceFolders, preserveCurrent: false);

    widget.storageService?.foldersNotifier.addListener(_onFoldersUpdated);
    if (widget.storageService != null) {
      _liveSyncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (mounted) {
          widget.storageService!.syncMemoriesFromGoogle(showLoading: false);
        }
      });
    }

    if (_items.isNotEmpty && _isPlaying) {
      _slideController.forward(from: 0.0);
    }
    _scheduleHideControls();
  }

  void _rebuildItemsList(
    List<MemoryFolder> folders, {
    required bool preserveCurrent,
  }) {
    final collected = <SlideshowItem>[];
    int videos = 0;

    for (final folder in folders) {
      for (final photo in folder.photos) {
        if (photo.isVideo) {
          videos++;
          continue;
        }
        collected.add(SlideshowItem(photo: photo, folder: folder));
        _knownPhotoIds.add(photo.id);
      }
    }

    if (_order == ProjectionOrder.latestFirst) {
      collected.sort((a, b) => b.photo.timestamp.compareTo(a.photo.timestamp));
    } else {
      collected.shuffle();
    }

    final currentId =
        (preserveCurrent && _items.isNotEmpty && _currentIndex < _items.length)
            ? _items[_currentIndex].photo.id
            : null;

    _items = collected;
    _videoCount = videos;

    if (currentId != null) {
      final idx = _items.indexWhere((i) => i.photo.id == currentId);
      _currentIndex = idx >= 0 ? idx : 0;
    } else {
      _currentIndex = 0;
    }
  }

  void _onFoldersUpdated() {
    if (!mounted || widget.storageService == null) return;
    final updatedFolders = widget.storageService!.folders;

    final newlyArrived = <SlideshowItem>[];
    int updatedVideos = 0;

    for (final folder in updatedFolders) {
      for (final photo in folder.photos) {
        if (photo.isVideo) {
          updatedVideos++;
          continue;
        }
        if (!_knownPhotoIds.contains(photo.id)) {
          _knownPhotoIds.add(photo.id);
          newlyArrived.add(SlideshowItem(photo: photo, folder: folder));
        }
      }
    }

    if (newlyArrived.isEmpty && updatedVideos == _videoCount) return;

    setState(() {
      _videoCount = updatedVideos;
      if (newlyArrived.isNotEmpty) {
        if (_items.isEmpty) {
          _items = newlyArrived;
          _currentIndex = 0;
          if (_isPlaying) _slideController.forward(from: 0.0);
        } else {
          final insertPos = (_currentIndex + 1).clamp(0, _items.length);
          _items.insertAll(insertPos, newlyArrived);
        }
        _showLiveArrival(newlyArrived.first.folder.guestName);
      }
    });
  }

  void _showLiveArrival(String guestName) {
    _arrivalBannerTimer?.cancel();
    _liveArrivalGuest = guestName;
    _arrivalBannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _liveArrivalGuest = null);
      }
    });
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_isPlaying) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _revealControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _scheduleHideControls();
  }

  void _togglePlay() {
    _revealControls();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        if (_items.isNotEmpty) {
          _slideController.forward();
        }
        _scheduleHideControls();
      } else {
        _slideController.stop();
        _hideControlsTimer?.cancel();
      }
    });
  }

  void _next({bool fromAutoAdvance = false}) {
    if (!fromAutoAdvance) _revealControls();
    if (_items.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex + 1) % _items.length;
    });

    if (_isPlaying) {
      _slideController.forward(from: 0.0);
    } else {
      _slideController.value = 0.0;
    }
  }

  void _prev() {
    _revealControls();
    if (_items.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex - 1 + _items.length) % _items.length;
    });

    if (_isPlaying) {
      _slideController.forward(from: 0.0);
    } else {
      _slideController.value = 0.0;
    }
  }

  void _cycleInterval() {
    _revealControls();
    final idx = _intervalOptions.indexOf(_intervalSeconds);
    final nextSec = _intervalOptions[(idx + 1) % _intervalOptions.length];
    setState(() {
      _intervalSeconds = nextSec;
      _slideController.duration = Duration(seconds: nextSec);
      if (_isPlaying && _items.isNotEmpty) {
        _slideController.forward(from: 0.0);
      }
    });
  }

  void _toggleOrder() {
    _revealControls();
    final sourceFolders = widget.storageService?.folders.isNotEmpty == true
        ? widget.storageService!.folders
        : widget.folders;
    setState(() {
      _order = _order == ProjectionOrder.shuffled
          ? ProjectionOrder.latestFirst
          : ProjectionOrder.shuffled;
      _rebuildItemsList(sourceFolders, preserveCurrent: false);
      if (_isPlaying && _items.isNotEmpty) {
        _slideController.forward(from: 0.0);
      }
    });
  }

  void _toggleFrameStyle() {
    _revealControls();
    setState(() {
      _frameStyle = _frameStyle == ProjectionFrameStyle.cinema
          ? ProjectionFrameStyle.galaMatte
          : ProjectionFrameStyle.cinema;
    });
  }

  void _toggleQr() {
    _revealControls();
    setState(() => _showQrCard = !_showQrCard);
  }

  Future<void> _toggleFullscreen() async {
    _revealControls();
    await DownloadHelper.toggleFullscreen();
    if (mounted) {
      setState(() {
        _isFullscreen = DownloadHelper.isFullscreen;
      });
    }
  }

  Future<void> _manualSync() async {
    if (widget.storageService == null || _isSyncingManual) return;
    _revealControls();
    setState(() => _isSyncingManual = true);
    await widget.storageService!.syncMemoriesFromGoogle(showLoading: false);
    if (mounted) {
      setState(() => _isSyncingManual = false);
    }
  }

  Future<void> _closeProjection() async {
    if (DownloadHelper.isFullscreen) {
      await DownloadHelper.toggleFullscreen();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.storageService?.foldersNotifier.removeListener(_onFoldersUpdated);
    _slideController.dispose();
    _hideControlsTimer?.cancel();
    _liveSyncTimer?.cancel();
    _arrivalBannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessKey = widget.storageService?.config.accessKey ?? 'DANNA15';
    final qrUrl = DownloadHelper.buildAccessUrl(accessKey);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _next,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _prev,
        const SingleActivator(LogicalKeyboardKey.keyF): _toggleFullscreen,
        const SingleActivator(LogicalKeyboardKey.keyQ): _toggleQr,
        const SingleActivator(LogicalKeyboardKey.escape): _closeProjection,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF0A110C),
          body: _items.isEmpty
              ? _buildEmptyStage(qrUrl: qrUrl, isMobile: isMobile)
              : _buildProjectionStage(
                  currentItem: _items[_currentIndex],
                  qrUrl: qrUrl,
                  isMobile: isMobile,
                  size: size,
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyStage({required String qrUrl, required bool isMobile}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildStageBackdropGradient(),
        const QuinceAmbientBackdrop(particleCount: 22, opacityMultiplier: 0.45),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GalaCornerFiligreePainter(),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: QuinceTopRibbon(height: 3.5),
        ),
        SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 20,
                child: _GlassPillButton(
                  icon: Icons.close_rounded,
                  label: 'Salir',
                  onTap: _closeProjection,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: EdgeInsets.all(isMobile ? 22 : 34),
                    decoration: BoxDecoration(
                      color: const Color(0xCC111C14),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.goldBorder.withAlpha(140),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(110),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: AppTheme.warmGold.withAlpha(24),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.sageDark, AppTheme.sageDeep],
                            ),
                            border: Border.all(color: AppTheme.warmGold, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.goldLight,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Proyección de Gala',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.goldLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mis 15 Años • Danna Alejandra',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            letterSpacing: 1.4,
                            color: AppTheme.blushPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _videoCount > 0
                              ? 'Actualmente hay $_videoCount video(s) en la galería.\nLas fotografías que suban los invitados aparecerán aquí en vivo.'
                              : 'Aún no hay fotografías para proyectar en pantalla grande.\n¡Invita a tus asistentes a escanear el código QR!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.white.withAlpha(210),
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.goldBorder, width: 2),
                          ),
                          child: QrImageView(
                            data: qrUrl,
                            version: QrVersions.auto,
                            size: 132,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.circle,
                              color: AppTheme.sageDeep,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.circle,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _GlassPillButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Volver a la Galería',
                          highlightGold: true,
                          onTap: _closeProjection,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectionStage({
    required SlideshowItem currentItem,
    required String qrUrl,
    required bool isMobile,
    required Size size,
  }) {
    final topInset = isMobile ? 76.0 : 88.0;
    final bottomInset = isMobile ? 116.0 : 128.0;
    final sideInset = isMobile ? 18.0 : 60.0;

    return MouseRegion(
      cursor: _controlsVisible ? SystemMouseCursors.basic : SystemMouseCursors.none,
      onHover: (_) => _revealControls(),
      onEnter: (_) => _revealControls(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _revealControls,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -250) {
            _next();
          } else if (velocity > 250) {
            _prev();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. FONDO ATMOSFÉRICO EN VERDE SALVIA OSCURO, ROSADO Y DORADO
            _buildStageBackdropGradient(),

            // 2. RESPLANDOR AMBIENTAL DIFUMINADO DE LA FOTO ACTUAL
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1200),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: SizedBox.expand(
                key: ValueKey<String>('bg_${currentItem.photo.id}'),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Opacity(
                    opacity: 0.36,
                    child: Image(
                      image: currentItem.photo.imageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

            // 3. VIÑETA EDITORIAL PARA MÁXIMO CONTRASTE Y PROFUNDIDAD
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [
                      const Color(0x550A120D),
                      const Color(0xBB09110B),
                      const Color(0xEE060B07),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // 4. DESTELLOS SUTILES DE SALVIA, ROSADO Y ORO EN LOS BORDES
            const QuinceAmbientBackdrop(
              particleCount: 18,
              opacityMultiplier: 0.34,
            ),

            // 5. MARCO ARQUITECTÓNICO DE ESQUINAS DORADAS
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 10 : 20),
                  child: CustomPaint(
                    painter: _GalaCornerFiligreePainter(),
                  ),
                ),
              ),
            ),

            // 6. ESCENARIO PRINCIPAL DE LA FOTOGRAFÍA CON MOVIMIENTO KEN BURNS
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  sideInset,
                  topInset,
                  sideInset,
                  bottomInset,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1050),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.985, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _AnimatedKenBurnsStage(
                      key: ValueKey<String>(
                        'fg_${currentItem.photo.id}_${_frameStyle.name}',
                      ),
                      item: currentItem,
                      slideIndex: _currentIndex,
                      progressAnimation: _slideController,
                      frameStyle: _frameStyle,
                      maxWidth: size.width - (sideInset * 2),
                      maxHeight: size.height - topInset - bottomInset - 20,
                      isMobile: isMobile,
                    ),
                  ),
                ),
              ),
            ),

            // CINTA SUPERIOR DELGADA DE GALA
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: QuinceTopRibbon(height: 3),
            ),

            // 7. CABECERA SUPERIOR: CRESTA DE GALA + DOCK DE CONTROLES AUTO-OCULTABLE
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 28,
                    vertical: isMobile ? 12 : 18,
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: _buildHeaderCrest(isMobile: true)),
                                const SizedBox(width: 8),
                                _buildMobileCounterBadge(),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(child: _buildAutoHideControlDock(isMobile: true)),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCrest(isMobile: false),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: _buildAutoHideControlDock(isMobile: false),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // 8. NOTIFICACIÓN EN VIVO CUANDO LLEGA UNA FOTO NUEVA DE UN INVITADO
            if (_liveArrivalGuest != null)
              Positioned(
                top: isMobile ? 74 : 84,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: _LiveArrivalBanner(guestName: _liveArrivalGuest!),
                  ),
                ),
              ),

            // 9. ZÓCALO INFERIOR EDITORIAL (INVITADO + DEDICATORIA) Y QR DE SALÓN
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 14 : 28,
                    0,
                    isMobile ? 14 : 28,
                    isMobile ? 12 : 18,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 650),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) {
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.14),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              );
                            },
                            child: _LowerThirdCard(
                              key: ValueKey<String>(
                                'caption_${currentItem.photo.id}',
                              ),
                              item: currentItem,
                              isMobile: isMobile,
                            ),
                          ),
                        ),
                      ),
                      if (_showQrCard && !isMobile) ...[
                        const SizedBox(width: 20),
                        _LiveQrOverlay(qrUrl: qrUrl),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // 10. BARRA FINA DE PROGRESO EN EL BORDE INFERIOR (SALVIA • ROSADO • DORADO)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _slideController,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _slideController.value.clamp(0.0, 1.0),
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.sageGreen,
                              AppTheme.blushPink,
                              AppTheme.warmGold,
                              AppTheme.goldLight,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCrest({required bool isMobile}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _controlsVisible ? 1.0 : 0.72,
      child: _GalaHeaderCrest(
        isMobile: isMobile,
        isLiveSync: widget.storageService != null,
        currentIndex: _currentIndex + 1,
        totalCount: _items.length,
      ),
    );
  }

  Widget _buildMobileCounterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB3101A13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.goldBorder.withAlpha(110),
          width: 1,
        ),
      ),
      child: Text(
        '${_currentIndex + 1} / ${_items.length}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.goldLight,
        ),
      ),
    );
  }

  Widget _buildAutoHideControlDock({required bool isMobile}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: _controlsVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !_controlsVisible,
        child: _GlassControlBar(
          isMobile: isMobile,
          isPlaying: _isPlaying,
          intervalSeconds: _intervalSeconds,
          frameStyle: _frameStyle,
          order: _order,
          showQrCard: _showQrCard,
          isFullscreen: _isFullscreen,
          canSync: widget.storageService != null,
          isSyncing: _isSyncingManual,
          onPrev: _prev,
          onTogglePlay: _togglePlay,
          onNext: _next,
          onCycleInterval: _cycleInterval,
          onToggleOrder: _toggleOrder,
          onToggleFrameStyle: _toggleFrameStyle,
          onToggleQr: _toggleQr,
          onSync: _manualSync,
          onToggleFullscreen: _toggleFullscreen,
          onClose: _closeProjection,
        ),
      ),
    );
  }

  Widget _buildStageBackdropGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B130D),
            Color(0xFF132016),
            Color(0xFF1A1418),
            Color(0xFF0A110C),
          ],
        ),
      ),
    );
  }
}

/// Fotografía con movimiento cinematográfico Ken Burns y selector de marco
class _AnimatedKenBurnsStage extends StatelessWidget {
  final SlideshowItem item;
  final int slideIndex;
  final Animation<double> progressAnimation;
  final ProjectionFrameStyle frameStyle;
  final double maxWidth;
  final double maxHeight;
  final bool isMobile;

  const _AnimatedKenBurnsStage({
    super.key,
    required this.item,
    required this.slideIndex,
    required this.progressAnimation,
    required this.frameStyle,
    required this.maxWidth,
    required this.maxHeight,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final zoomIn = slideIndex.isEven;
    final panDirection = slideIndex % 3 == 0 ? 1.0 : (slideIndex % 3 == 1 ? -1.0 : 0.0);

    final imageWidget = AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(progressAnimation.value);
        final scale = zoomIn ? (1.0 + 0.055 * t) : (1.055 - 0.05 * t);
        final dx = panDirection * (t - 0.5) * 14.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Image(
        image: item.photo.imageProvider,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 350),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: isMobile ? 260 : 380,
            height: isMobile ? 220 : 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF152218),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.goldBorder.withAlpha(110)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_camera_back_rounded,
                  color: AppTheme.blushPink,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  item.folder.guestName,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.goldLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (frameStyle == ProjectionFrameStyle.galaMatte) {
      final mattePadding = isMobile ? 10.0 : 18.0;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth.clamp(120.0, 1400.0),
          maxHeight: maxHeight.clamp(120.0, 1000.0),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            mattePadding,
            mattePadding,
            mattePadding,
            mattePadding + (isMobile ? 22 : 30),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFCFBF7),
                Color(0xFFF3F6F2),
                Color(0xFFFDF5F6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldBorder, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(150),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: AppTheme.warmGold.withAlpha(38),
                blurRadius: 28,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.sageBorder,
                      width: 1.0,
                    ),
                  ),
                  child: ClipRect(child: imageWidget),
                ),
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 1,
                    color: AppTheme.warmGold,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'XV Danna Alejandra  •  ${item.folder.guestName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isMobile ? 12 : 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sageDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 24,
                    height: 1,
                    color: AppTheme.warmGold,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Modo Cinematográfico por defecto
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(120.0, 1520.0),
        maxHeight: maxHeight.clamp(120.0, 1060.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(165),
              blurRadius: 48,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: AppTheme.sageGreen.withAlpha(40),
              blurRadius: 34,
            ),
            BoxShadow(
              color: AppTheme.warmGold.withAlpha(24),
              blurRadius: 24,
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.goldBorder.withAlpha(135),
            width: 1.3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imageWidget,
        ),
      ),
    );
  }
}

/// Cresta elegante del evento en la esquina superior izquierda
class _GalaHeaderCrest extends StatelessWidget {
  final bool isMobile;
  final bool isLiveSync;
  final int currentIndex;
  final int totalCount;

  const _GalaHeaderCrest({
    required this.isMobile,
    required this.isLiveSync,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xB3101A13),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.goldBorder.withAlpha(120),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.sageDark, AppTheme.sageDeep],
                  ),
                  border: Border.all(color: AppTheme.warmGold, width: 1.1),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.goldLight,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MIS 15 AÑOS',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: AppTheme.blushPink,
                          ),
                        ),
                        if (isLiveSync) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8CE09A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'EN VIVO',
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: const Color(0xFFBEEFC6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isMobile ? 'Danna Alejandra' : 'Danna Alejandra • $currentIndex / $totalCount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de control flotante con efecto vidrio esmerilado y atajos profesionales
class _GlassControlBar extends StatelessWidget {
  final bool isMobile;
  final bool isPlaying;
  final int intervalSeconds;
  final ProjectionFrameStyle frameStyle;
  final ProjectionOrder order;
  final bool showQrCard;
  final bool isFullscreen;
  final bool canSync;
  final bool isSyncing;
  final VoidCallback onPrev;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onCycleInterval;
  final VoidCallback onToggleOrder;
  final VoidCallback onToggleFrameStyle;
  final VoidCallback onToggleQr;
  final VoidCallback onSync;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onClose;

  const _GlassControlBar({
    required this.isMobile,
    required this.isPlaying,
    required this.intervalSeconds,
    required this.frameStyle,
    required this.order,
    required this.showQrCard,
    required this.isFullscreen,
    required this.canSync,
    required this.isSyncing,
    required this.onPrev,
    required this.onTogglePlay,
    required this.onNext,
    required this.onCycleInterval,
    required this.onToggleOrder,
    required this.onToggleFrameStyle,
    required this.onToggleQr,
    required this.onSync,
    required this.onToggleFullscreen,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xBF0F1912),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppTheme.goldBorder.withAlpha(115),
              width: 1.1,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HudIconAction(
                  icon: Icons.skip_previous_rounded,
                  tooltip: 'Anterior (←)',
                  onTap: onPrev,
                ),
                _HudIconAction(
                  icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  tooltip: isPlaying ? 'Pausar (Espacio)' : 'Reanudar (Espacio)',
                  isHighlighted: true,
                  onTap: onTogglePlay,
                ),
                _HudIconAction(
                  icon: Icons.skip_next_rounded,
                  tooltip: 'Siguiente (→)',
                  onTap: onNext,
                ),
                _HudDivider(),
                _GlassChipAction(
                  icon: Icons.timer_outlined,
                  label: '${intervalSeconds}s',
                  tooltip: 'Cambiar duración de cada fotografía',
                  onTap: onCycleInterval,
                ),
                const SizedBox(width: 4),
                _GlassChipAction(
                  icon: frameStyle == ProjectionFrameStyle.cinema
                      ? Icons.crop_landscape_rounded
                      : Icons.filter_frames_rounded,
                  label: frameStyle == ProjectionFrameStyle.cinema ? 'Cine' : 'Marco Gala',
                  tooltip: 'Alternar entre modo Cinematográfico y Marco de Gala',
                  onTap: onToggleFrameStyle,
                ),
                const SizedBox(width: 4),
                _GlassChipAction(
                  icon: order == ProjectionOrder.shuffled
                      ? Icons.shuffle_rounded
                      : Icons.schedule_rounded,
                  label: order == ProjectionOrder.shuffled ? 'Aleatorio' : 'Recientes',
                  tooltip: 'Cambiar orden de reproducción',
                  onTap: onToggleOrder,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 4),
                  _GlassChipAction(
                    icon: Icons.qr_code_2_rounded,
                    label: 'QR',
                    isActive: showQrCard,
                    tooltip: 'Mostrar u ocultar código QR para invitados (Q)',
                    onTap: onToggleQr,
                  ),
                ],
                if (canSync) ...[
                  const SizedBox(width: 4),
                  _HudIconAction(
                    icon: isSyncing ? Icons.sync_rounded : Icons.cloud_sync_rounded,
                    tooltip: 'Sincronizar fotos nuevas ahora',
                    onTap: onSync,
                  ),
                ],
                _HudDivider(),
                _HudIconAction(
                  icon: isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  tooltip: isFullscreen ? 'Salir de pantalla completa (F)' : 'Pantalla completa (F)',
                  onTap: onToggleFullscreen,
                ),
                _HudIconAction(
                  icon: Icons.close_rounded,
                  tooltip: 'Cerrar proyección (Esc)',
                  isClose: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HudDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: AppTheme.goldBorder.withAlpha(65),
    );
  }
}

class _HudIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool isClose;

  const _HudIconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isHighlighted = false,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isHighlighted
            ? AppTheme.sageGreen.withAlpha(200)
            : (isClose ? AppTheme.deepRose.withAlpha(110) : Colors.transparent),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 19,
              color: isHighlighted ? AppTheme.goldLight : Colors.white.withAlpha(235),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassChipAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _GlassChipAction({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.sageGreen.withAlpha(140)
                : Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppTheme.goldBorder.withAlpha(170)
                  : Colors.white.withAlpha(28),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppTheme.goldLight),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(235),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlightGold;

  const _GlassPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlightGold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlightGold ? AppTheme.sageDark : const Color(0xB3101A13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: highlightGold
              ? AppTheme.goldBorder
              : Colors.white.withAlpha(60),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppTheme.goldLight),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zócalo editorial inferior con nombre del invitado y dedicatoria
class _LowerThirdCard extends StatelessWidget {
  final SlideshowItem item;
  final bool isMobile;

  const _LowerThirdCard({
    super.key,
    required this.item,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final guestName = item.folder.guestName.trim().isNotEmpty
        ? item.folder.guestName.trim()
        : 'Invitado Especial';
    final initial = guestName.characters.first.toUpperCase();
    final timeStr = DateFormat('HH:mm').format(item.photo.timestamp);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 580),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 18,
              vertical: isMobile ? 11 : 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xB80E1811),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.goldBorder.withAlpha(115),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cinta vertical tricolor de acento
                Container(
                  width: 3.5,
                  height: item.folder.comment.isNotEmpty ? 46 : 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.goldLight,
                        AppTheme.blushPink,
                        AppTheme.sageGreen,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Monograma dorado & salvia
                Container(
                  width: isMobile ? 38 : 44,
                  height: isMobile ? 38 : 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.sageGradient,
                    border: Border.all(color: AppTheme.warmGold, width: 1.4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.goldLight,
                      fontSize: isMobile ? 17 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            isMobile ? 'RECUERDO EN VIVO' : 'RECUERDO COMPARTIDO POR',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.blushPink,
                            ),
                          ),
                          Text(
                            '• $timeStr hrs',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guestName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          color: AppTheme.goldLight,
                          fontSize: isMobile ? 17 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.folder.comment.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '“${item.folder.comment.trim()}”',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withAlpha(225),
                            fontSize: isMobile ? 12 : 13.5,
                            fontStyle: FontStyle.italic,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta compacta de código QR para proyectar en el salón
class _LiveQrOverlay extends StatelessWidget {
  final String qrUrl;

  const _LiveQrOverlay({required this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xBD0F1912),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.goldBorder.withAlpha(135),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldBorder, width: 1.2),
                ),
                child: QrImageView(
                  data: qrUrl,
                  version: QrVersions.auto,
                  size: 72,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: AppTheme.sageDeep,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: AppTheme.charcoal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¡SUMA TUS FOTOS!',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppTheme.goldLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Escanea el QR y\naparece aquí en vivo',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.white.withAlpha(220),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'XV • Danna Alejandra',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.blushPink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveArrivalBanner extends StatelessWidget {
  final String guestName;

  const _LiveArrivalBanner({required this.guestName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.sageDark, AppTheme.sageDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.warmGold, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmGold.withAlpha(65),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppTheme.goldLight, size: 16),
          const SizedBox(width: 8),
          Text(
            'Nuevo recuerdo en vivo de $guestName ✨',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filigrana arquitectónica minimalista dorada para las cuatro esquinas de proyección
class _GalaCornerFiligreePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    const cornerLen = 34.0;
    const innerOffset = 7.0;

    final outerPaint = Paint()
      ..color = AppTheme.warmGold.withAlpha(78)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final innerPaint = Paint()
      ..color = AppTheme.blushPink.withAlpha(55)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.goldLight.withAlpha(110)
      ..style = PaintingStyle.fill;

    void drawCorner(Offset origin, double dx, double dy) {
      final path = Path()
        ..moveTo(origin.dx + dx * cornerLen, origin.dy)
        ..lineTo(origin.dx, origin.dy)
        ..lineTo(origin.dx, origin.dy + dy * cornerLen);
      canvas.drawPath(path, outerPaint);

      final innerOrigin = Offset(
        origin.dx + dx * innerOffset,
        origin.dy + dy * innerOffset,
      );
      final innerPath = Path()
        ..moveTo(innerOrigin.dx + dx * (cornerLen * 0.55), innerOrigin.dy)
        ..lineTo(innerOrigin.dx, innerOrigin.dy)
        ..lineTo(innerOrigin.dx, innerOrigin.dy + dy * (cornerLen * 0.55));
      canvas.drawPath(innerPath, innerPaint);

      canvas.drawCircle(innerOrigin, 1.8, dotPaint);
    }

    drawCorner(Offset.zero, 1, 1);
    drawCorner(Offset(size.width, 0), -1, 1);
    drawCorner(Offset(0, size.height), 1, -1);
    drawCorner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
