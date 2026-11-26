import 'package:flutter/services.dart';

Future<bool> downloadCsvImpl(String filename, String csvContent) async {
  await Clipboard.setData(ClipboardData(text: csvContent));
  return false; // Copied to clipboard on non-web platforms.
}
