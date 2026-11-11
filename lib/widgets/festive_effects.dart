import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Cinta superior de gala en Verde Salvia (principal), Rosado y Dorado
class QuinceTopRibbon extends StatelessWidget {
  final double height;

  const QuinceTopRibbon({super.key, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.sageDeep,
            AppTheme.sageGreen,
            AppTheme.warmGold,
            AppTheme.blushPink,
            AppTheme.warmGold,
            AppTheme.sageGreen,
            AppTheme.sageDeep,
          ],
        ),
      ),
    );
  }
}

/// Fondo animado con destellos dorados, pétalos rosados y orbes verde salvia
class QuinceAmbientBackdrop extends StatefulWidget {
  final int particleCount;
  final double opacityMultiplier;

  const QuinceAmbientBackdrop({
    super.key,
    this.particleCount = 26,
    this.opacityMultiplier = 1.0,
  });

  @override
  State<QuinceAmbientBackdrop> createState() => _QuinceAmbientBackdropState();
}

class _QuinceAmbientBackdropState extends State<QuinceAmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_AmbientParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    final rng = math.Random(15022026);
    _particles = List.generate(widget.particleCount, (i) {
      final kind = _ParticleKind.values[i % _ParticleKind.values.length];
      return _AmbientParticle(
        xFraction: rng.nextDouble(),
        yFraction: rng.nextDouble(),
        size: switch (kind) {
          _ParticleKind.goldStar => 5.0 + rng.nextDouble() * 7.0,
          _ParticleKind.pinkPetal => 4.5 + rng.nextDouble() * 5.5,
          _ParticleKind.sageOrb => 7.0 + rng.nextDouble() * 11.0,
        },
        speed: 0.15 + rng.nextDouble() * 0.35,
        swayAmp: 0.015 + rng.nextDouble() * 0.025,
        phase: rng.nextDouble() * math.pi * 2,
        kind: kind,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _AmbientPainter(
                progress: _controller.value,
                particles: _particles,
                opacityMultiplier: widget.opacityMultiplier,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

enum _ParticleKind { goldStar, pinkPetal, sageOrb }

class _AmbientParticle {
  final double xFraction;
  final double yFraction;
  final double size;
  final double speed;
  final double swayAmp;
  final double phase;
  final _ParticleKind kind;

  const _AmbientParticle({
    required this.xFraction,
    required this.yFraction,
    required this.size,
    required this.speed,
    required this.swayAmp,
    required this.phase,
    required this.kind,
  });
}

class _AmbientPainter extends CustomPainter {
  final double progress;
  final List<_AmbientParticle> particles;
  final double opacityMultiplier;

  _AmbientPainter({
    required this.progress,
    required this.particles,
    required this.opacityMultiplier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = progress * math.pi * 2;

    for (final p in particles) {
      final yRaw = (p.yFraction - progress * p.speed) % 1.0;
      final y = (yRaw < 0 ? yRaw + 1.0 : yRaw) * size.height;
      final sway = math.sin(t + p.phase) * p.swayAmp * size.width;
      final x = (p.xFraction * size.width + sway) % size.width;
      final twinkle = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(t * 2 + p.phase));
      final alpha = (twinkle * opacityMultiplier).clamp(0.0, 1.0);

      switch (p.kind) {
        case _ParticleKind.goldStar:
          _drawFourPointStar(
            canvas,
            Offset(x, y),
            p.size,
            AppTheme.warmGold.withValues(alpha: 0.55 * alpha),
          );
          break;
        case _ParticleKind.pinkPetal:
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(math.sin(t + p.phase) * 0.6);
          final petalPaint = Paint()
            ..color = AppTheme.blushPink.withValues(alpha: 0.35 * alpha)
            ..style = PaintingStyle.fill;
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: p.size * 1.4, height: p.size * 0.85),
            petalPaint,
          );
          canvas.restore();
          break;
        case _ParticleKind.sageOrb:
          final orbPaint = Paint()
            ..color = AppTheme.sageGreen.withValues(alpha: 0.16 * alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(x, y), p.size, orbPaint);
          break;
      }
    }
  }

  void _drawFourPointStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final inner = radius * 0.28;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + inner, center.dy - inner)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + inner, center.dy + inner)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - inner, center.dy + inner)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - inner, center.dy - inner)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Botón principal en Verde Salvia con borde Dorado metálico y efecto Shimmer
class QuincePrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? leading;
  final String label;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool usePinkGradient;
  final double? minHeight;

  const QuincePrimaryButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.leading,
    required this.label,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.fontSize = 15,
    this.usePinkGradient = false,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = usePinkGradient ? AppTheme.pinkGradient : AppTheme.sageGradient;
    final glowColor = usePinkGradient ? AppTheme.blushPink : AppTheme.sageGreen;

    final buttonContent = Container(
      constraints: minHeight != null ? BoxConstraints(minHeight: minHeight!) : null,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? AppTheme.sageBorder : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.goldBorder,
          width: 1.6,
        ),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: glowColor.withAlpha(85),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: AppTheme.warmGold.withAlpha(55),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onPressed == null) return buttonContent;

    return buttonContent
        .animate(onPlay: (c) => c.repeat())
        .shimmer(delay: 2400.ms, duration: 1400.ms, color: AppTheme.goldLight.withAlpha(110));
  }
}

/// Botón de corazón interactivo con animación festiva
class AnimatedLikeButton extends StatefulWidget {
  final int likes;
  final VoidCallback onLike;

  const AnimatedLikeButton({
    super.key,
    required this.likes,
    required this.onLike,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton> {
  int _pulseCount = 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _pulseCount++);
        widget.onLike();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.softPinkBg.withAlpha(140),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.pinkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 17,
              color: AppTheme.deepRose,
            )
                .animate(key: ValueKey(_pulseCount))
                .scale(
                  begin: const Offset(1.35, 1.35),
                  end: const Offset(1.0, 1.0),
                  duration: 380.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(width: 5),
            Text(
              '${widget.likes}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepRose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

