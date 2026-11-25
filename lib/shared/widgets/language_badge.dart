import 'package:material_ui/material_ui.dart';

import '../../core/models/language_type.dart';
import '../../core/theme/app_colors.dart';

/// Semantic badge for Chinese (Crimson / Coral-Gold) or English (Sapphire / Cyan).
class LanguageBadge extends StatelessWidget {
  const LanguageBadge({
    super.key,
    required this.language,
    this.compact = false,
  });

  final CourseLanguage language;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = language.accentColor(context);
    final secondary = language.secondaryAccent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.16),
            secondary.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.34),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            language.label,
            style: TextStyle(
              color: accent,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing status pill used for lesson status, live occupancy, and active states.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.glow = false,
    this.compact = false,
    this.icon,
  });

  final String label;
  final Color color;
  final bool glow;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: glow ? 0.18 : 0.12),
        border: Border.all(
          color: color.withValues(alpha: glow ? 0.55 : 0.30),
          width: 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glow) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.75),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic soft glass tag pill for specializations, equipment, or levels.
class GlassInfoTag extends StatelessWidget {
  const GlassInfoTag({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = color ?? AppColors.textSecondary(context);
    final bg = color != null
        ? color!.withValues(alpha: 0.11)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.lightTextPrimary.withValues(alpha: 0.05));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bg,
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.24)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : AppColors.lightTextPrimary.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
