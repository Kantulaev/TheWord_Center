import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Squircle Liquid Glass avatar displaying initials over a softly tinted gradient.
class EntityAvatar extends StatelessWidget {
  const EntityAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 44,
    this.badgeText,
    this.badgeColor,
    this.isActiveDot,
  });

  final String initials;
  final Color color;
  final double size;
  final String? badgeText;
  final Color? badgeColor;
  final bool? isActiveDot;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.34);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.92),
                color.withValues(alpha: 0.68),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (badgeText != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
        else if (isActiveDot != null)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActiveDot!
                    ? AppColors.liveEmerald
                    : AppColors.warningAmber,
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F172A)
                      : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
