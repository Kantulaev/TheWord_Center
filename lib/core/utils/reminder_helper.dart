import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds and launches WhatsApp, Telegram, or clipboard reminders for students.
abstract final class ReminderHelper {
  static String _cleanPhone(String rawPhone) =>
      rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');

  static Future<void> copyToClipboard(
    BuildContext context,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: message));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder message copied to clipboard')),
    );
  }

  static Future<void> openWhatsApp(
    BuildContext context, {
    required String phone,
    required String message,
  }) async {
    final cleaned = _cleanPhone(phone).replaceAll('+', '');
    final encoded = Uri.encodeComponent(message);
    final uri = cleaned.isNotEmpty
        ? Uri.parse('https://wa.me/$cleaned?text=$encoded')
        : Uri.parse('https://wa.me/?text=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        await copyToClipboard(context, message);
      }
    }
  }

  static Future<void> openTelegram(
    BuildContext context, {
    required String message,
  }) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://t.me/share/url?url=%20&text=$encoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        await copyToClipboard(context, message);
      }
    }
  }
}
