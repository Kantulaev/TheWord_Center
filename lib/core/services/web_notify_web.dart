import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get isBrowserNotificationSupported {
  try {
    return web.Notification.permission.isNotEmpty;
  } catch (_) {
    return false;
  }
}

bool get isBrowserNotificationGranted {
  try {
    return web.Notification.permission == 'granted';
  } catch (_) {
    return false;
  }
}

Future<bool> requestBrowserNotificationPermission() async {
  try {
    if (web.Notification.permission == 'granted') return true;
    if (web.Notification.permission == 'denied') return false;
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void showBrowserNotificationPopup({
  required String title,
  required String body,
  String? tag,
}) {
  try {
    if (web.Notification.permission != 'granted') return;
    web.Notification(
      title,
      web.NotificationOptions(
        body: body,
        tag: tag ?? 'the_word_notification',
        icon: '/icons/Icon-192.png',
      ),
    );
  } catch (_) {}
}
