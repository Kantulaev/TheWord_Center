import 'package:material_ui/material_ui.dart';

/// Semantic and Apple Liquid Glass color tokens for "The Word".
abstract final class AppColors {
  // Brand & Course Language Accents
  static const Color chineseCrimson = Color(0xFFD93848);
  static const Color chineseCrimsonBright = Color(0xFFFF5C6C);
  static const Color chineseCoralGold = Color(0xFFF59E42);

  static const Color englishSapphire = Color(0xFF1E66F5);
  static const Color englishSapphireBright = Color(0xFF4FA3FF);
  static const Color englishCyan = Color(0xFF06B6D4);

  static const Color sharingViolet = Color(0xFF8B5CF6);
  static const Color sharingVioletBright = Color(0xFFA78BFA);
  static const Color sharingTeal = Color(0xFF14B8A6);

  static const Color bilingualIndigo = Color(0xFF6366F1);

  // Semantic Statuses
  static const Color liveEmerald = Color(0xFF10B981);
  static const Color liveEmeraldBright = Color(0xFF34D399);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRose = Color(0xFFE11D48);
  static const Color completedSlate = Color(0xFF64748B);

  // Light Mode Surfaces & Ink
  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Dark Mode Surfaces & Ink
  static const Color darkBackground = Color(0xFF070A12);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Curated avatar color palette (hex strings without #)
  static const List<String> avatarColorHexes = [
    'D93848', // Crimson
    'F59E42', // Coral Gold
    '1E66F5', // Sapphire
    '06B6D4', // Cyan
    '10B981', // Emerald
    '6366F1', // Indigo
    '8B5CF6', // Violet
    'EC4899', // Rose
    '0F766E', // Deep Teal
    'B45309', // Warm Bronze
  ];

  static Color fromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return englishSapphire;
  }

  static String toHex(Color color) {
    final argb = color.toARGB32();
    return (argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextMuted
          : lightTextMuted;

  static Color chineseAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? chineseCrimsonBright
          : chineseCrimson;

  static Color englishAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? englishSapphireBright
          : englishSapphire;

  static Color sharingAccent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? sharingVioletBright
          : sharingViolet;
}
