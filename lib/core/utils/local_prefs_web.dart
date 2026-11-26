import 'package:web/web.dart' as web;

String? readLocalPref(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void writeLocalPref(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}
