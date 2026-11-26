import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Soft animated aurora mesh backdrop that gives Liquid Glass surfaces depth
/// and luminous color refraction in both Light and Dark mode.
class LiquidAuroraBackground extends StatefulWidget {
  const LiquidAuroraBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;
  final bool animate;

  @override
  State<LiquidAuroraBackground> createState() => _LiquidAuroraBackgroundState();
}

class _LiquidAuroraBackgroundState extends State<LiquidAuroraBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 24),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LiquidAuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 24),
      )..repeat();
    } else if (!widget.animate && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final shouldAnimate =
        widget.animate && !disableAnimations && _controller != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: shouldAnimate
                ? AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, _) {
                      final t = _controller!.value * 2 * math.pi;
                      return CustomPaint(
                        painter: _AuroraMeshPainter(
                          phase: t,
                          isDark: isDark,
                        ),
                        isComplex: true,
                        willChange: true,
                        size: Size.infinite,
                      );
                    },
                  )
                : CustomPaint(
                    painter: _AuroraMeshPainter(
                      phase: 0.6,
                      isDark: isDark,
                    ),
                    isComplex: true,
                    willChange: false,
                    size: Size.infinite,
                  ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraMeshPainter extends CustomPainter {
  const _AuroraMeshPainter({
    required this.phase,
    required this.isDark,
  });

  final double phase;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final orbs = isDark
        ? [
            _AuroraOrb(
              center: Offset(
                size.width * (0.18 + 0.08 * math.sin(phase)),
                size.height * (0.20 + 0.06 * math.cos(phase)),
              ),
              radius: size.longestSide * 0.44,
              color: AppColors.englishSapphire.withValues(alpha: 0.24),
            ),
            _AuroraOrb(
              center: Offset(
                size.width * (0.82 + 0.06 * math.cos(phase * 0.8)),
                size.height * (0.24 + 0.08 * math.sin(phase * 0.9)),
              ),
              radius: size.longestSide * 0.38,
              color: AppColors.chineseCrimson.withValues(alpha: 0.20),
            ),
            _AuroraOrb(
              center: Offset(
                size.width * (0.55 + 0.10 * math.sin(phase + 2.1)),
                size.height * (0.78 + 0.07 * math.cos(phase + 1.4)),
              ),
              radius: size.longestSide * 0.42,
              color: AppColors.englishCyan.withValues(alpha: 0.14),
            ),
            _AuroraOrb(
              center: Offset(
                size.width * (0.22 + 0.05 * math.cos(phase + 3.1)),
                size.height * (0.84 + 0.05 * math.sin(phase + 2.5)),
              ),
              radius: size.longestSide * 0.32,
              color: AppColors.chineseCoralGold.withValues(alpha: 0.12),
            ),
          ]
        : [
            _AuroraOrb(
              center: Offset(
                size.width * (0.16 + 0.07 * math.sin(phase)),
                size.height * (0.16 + 0.06 * math.cos(phase)),
              ),
              radius: size.longestSide * 0.46,
              color: const Color(0xFF93C5FD).withValues(alpha: 0.34),
            ),
            _AuroraOrb(
              center: Offset(
                size.width * (0.84 + 0.06 * math.cos(phase * 0.8)),
                size.height * (0.22 + 0.07 * math.sin(phase * 0.9)),
              ),
              radius: size.longestSide * 0.40,
              color: const Color(0xFFFDA4AF).withValues(alpha: 0.28),
            ),
            _AuroraOrb(
              center: Offset(
                size.width * (0.56 + 0.09 * math.sin(phase + 2.1)),
                size.height * (0.80 + 0.06 * math.cos(phase + 1.4)),
              ),
              radius: size.longestSide * 0.44,
              color: const Color(0xFFA5F3FC).withValues(alpha: 0.32),
            ),
            _AuroraOrb(
              center: Offset(
                size.width * (0.20 + 0.05 * math.cos(phase + 3.1)),
                size.height * (0.82 + 0.05 * math.sin(phase + 2.5)),
              ),
              radius: size.longestSide * 0.34,
              color: const Color(0xFFFDE68A).withValues(alpha: 0.26),
            ),
          ];

    for (final orb in orbs) {
      final rect = Rect.fromCircle(center: orb.center, radius: orb.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            orb.color,
            orb.color.withValues(alpha: orb.color.a * 0.35),
            orb.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(rect);
      canvas.drawCircle(orb.center, orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraMeshPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.isDark != isDark;
  }
}

class _AuroraOrb {
  const _AuroraOrb({
    required this.center,
    required this.radius,
    required this.color,
  });

  final Offset center;
  final double radius;
  final Color color;
}
