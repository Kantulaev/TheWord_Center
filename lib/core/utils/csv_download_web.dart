import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> downloadCsvImpl(String filename, String csvContent) async {
  final bytes = utf8.encode('\uFEFF$csvContent');
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8;'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
