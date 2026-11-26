bool get isBrowserNotificationSupported => false;

bool get isBrowserNotificationGranted => false;

Future<bool> requestBrowserNotificationPermission() async => false;

void showBrowserNotificationPopup({
  required String title,
  required String body,
  String? tag,
}) {}
