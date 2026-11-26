import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Signature Apple "Liquid Glass" surface optimized for 120 FPS:
/// - Multi-layered translucent pearl-white (light) or obsidian (dark) frosted gradient
/// - 1px specular top-left light-catching rim
/// - Optional real-time [BackdropFilter] blur reserved ONLY for top-level floating
///   chrome/modals ([enableBlur] = true) so scrollable cards never trigger expensive
///   offscreen GPU render passes during scrolling.
class LiquidGlassContainer extends StatefulWidget {
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blurSigma = 22.0,
    this.enableBlur = false,
    this.tintColor,
    this.tintStrength = 0.08,
    this.elevation = 1.0,
    this.isSelected = false,
    this.enableHover = true,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.constraints,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final bool enableBlur;
  final Color? tintColor;
  final double tintStrength;
  final double elevation;
  final bool isSelected;
  final bool enableHover;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _allowDesktopHover =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interactive = widget.onTap != null || widget.onLongPress != null;
    final radius = BorderRadius.circular(widget.borderRadius);

    // Slightly richer translucent frost when real-time blur is skipped gives
    // identical visual depth at a tiny fraction of GPU cost.
    final effectiveTint = widget.tintColor;
    final baseStart = isDark
        ? Color(0xFF131B2E).withValues(
            alpha: widget.enableBlur ? (_hovered ? 0.42 : 0.34) : (_hovered ? 0.90 : 0.82),
          )
        : Colors.white.withValues(
            alpha: widget.enableBlur ? (_hovered ? 0.84 : 0.74) : (_hovered ? 0.94 : 0.88),
          );
    final baseEnd = isDark
        ? const Color(0xFF0B1120).withValues(
            alpha: widget.enableBlur ? (_hovered ? 0.68 : 0.60) : (_hovered ? 0.86 : 0.78),
          )
        : Colors.white.withValues(
            alpha: widget.enableBlur ? (_hovered ? 0.62 : 0.50) : (_hovered ? 0.82 : 0.74),
          );

    final startColor = effectiveTint != null
        ? Color.alphaBlend(
            effectiveTint.withValues(
              alpha: widget.isSelected
                  ? widget.tintStrength * 2.1
                  : widget.tintStrength,
            ),
            baseStart,
          )
        : baseStart;
    final endColor = effectiveTint != null
        ? Color.alphaBlend(
            effectiveTint.withValues(
              alpha: widget.isSelected
                  ? widget.tintStrength * 1.3
                  : widget.tintStrength * 0.55,
            ),
            baseEnd,
          )
        : baseEnd;

    final shadowAlpha = isDark ? 0.28 : 0.07;

    Widget surface = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
      ),
      child: widget.child,
    );

    surface = CustomPaint(
      painter: _SpecularBorderPainter(
        borderRadius: widget.borderRadius,
        isDark: isDark,
        accentColor: widget.isSelected ? effectiveTint : null,
        isHighlighted: _hovered || widget.isSelected,
      ),
      child: surface,
    );

    if (widget.enableBlur && widget.blurSigma > 0.5) {
      final cappedSigma = widget.blurSigma.clamp(0.0, 12.0);
      surface = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: cappedSigma,
            sigmaY: cappedSigma,
          ),
          child: surface,
        ),
      );
    }

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.elevation <= 0
            ? null
            : [
                BoxShadow(
                  color: (effectiveTint ?? Colors.black).withValues(
                    alpha: widget.isSelected
                        ? shadowAlpha * 1.35
                        : shadowAlpha * widget.elevation,
                  ),
                  blurRadius: 18 * widget.elevation,
                  offset: Offset(0, 8 * widget.elevation),
                  spreadRadius: -4,
                ),
                if (!isDark)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.55),
                    blurRadius: 1,
                    offset: const Offset(0, -0.5),
                  ),
              ],
      ),
      child: surface,
    );

    if (interactive) {
      final scale = _pressed
          ? 0.985
          : (_hovered && _allowDesktopHover && widget.enableHover ? 1.004 : 1.0);
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: _pressed
            ? Transform.scale(scale: scale, child: content)
            : (scale != 1.0 ? Transform.scale(scale: scale, child: content) : content),
      );
      if (_allowDesktopHover && widget.enableHover) {
        content = MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() {
            _hovered = false;
            _pressed = false;
          }),
          child: content,
        );
      }
    }

    if (widget.margin != null) {
      return Padding(padding: widget.margin!, child: content);
    }
    return content;
  }
}

/// Paints a 1px specular light-catching rim brightest at top-left.
class _SpecularBorderPainter extends CustomPainter {
  const _SpecularBorderPainter({
    required this.borderRadius,
    required this.isDark,
    this.accentColor,
    this.isHighlighted = false,
  });

  final double borderRadius;
  final bool isDark;
  final Color? accentColor;
  final bool isHighlighted;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(borderRadius),
    );

    final topLeft = accentColor != null
        ? accentColor!.withValues(alpha: isDark ? 0.72 : 0.58)
        : Colors.white.withValues(
            alpha: isDark ? (isHighlighted ? 0.36 : 0.24) : 0.92,
          );
    final mid = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.42);
    final bottomRight = accentColor != null
        ? accentColor!.withValues(alpha: 0.22)
        : isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.06);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted && accentColor != null ? 1.4 : 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [topLeft, mid, bottomRight],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isDark != isDark ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isHighlighted != isHighlighted;
  }
}

/// Compact pill button styled in Liquid Glass for filters, view switchers, and CTAs.
class LiquidGlassPillButton extends StatelessWidget {
  const LiquidGlassPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? Theme.of(context).colorScheme.primary;
    final foreground = selected
        ? effectiveAccent
        : AppColors.textPrimary(context);

    return LiquidGlassContainer(
      borderRadius: 999,
      blurSigma: 0,
      enableBlur: false,
      elevation: selected ? 0.65 : 0.2,
      tintColor: selected ? effectiveAccent : null,
      tintStrength: selected ? 0.14 : 0.0,
      isSelected: selected,
      padding: padding,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Primary vibrant CTA button with subtle specular highlight and glow.
class LiquidPrimaryButton extends StatelessWidget {
  const LiquidPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.englishSapphire;
    final style = FilledButton.styleFrom(
      backgroundColor: base,
      foregroundColor: Colors.white,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    );
    final labelWidget = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 18),
        label: labelWidget,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: labelWidget,
    );
  }
}
