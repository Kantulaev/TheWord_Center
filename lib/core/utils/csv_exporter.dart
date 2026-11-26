import 'package:material_ui/material_ui.dart';

import 'csv_download_stub.dart' if (dart.library.js_interop) 'csv_download_web.dart';

abstract final class CsvExporter {
  static String encode(List<List<String>> rows) {
    return rows.map((row) => row.map(_escapeCell).join(',')).join('\r\n');
  }

  static String _escapeCell(String value) {
    final needsQuotes = value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static Future<void> exportAndNotify(
    BuildContext context, {
    required String filename,
    required List<List<String>> rows,
  }) async {
    final csv = encode(rows);
    final downloaded = await downloadCsvImpl(filename, csv);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? 'Downloaded $filename'
              : 'CSV copied to clipboard ($filename)',
        ),
      ),
    );
  }
}
