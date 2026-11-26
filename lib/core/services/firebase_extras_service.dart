import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/data_repository.dart';
import 'web_notify.dart';

/// Status returned when syncing FCM / Browser push notification permissions.
@immutable
class PushSyncResult {
  const PushSyncResult({
    required this.supported,
    required this.permissionGranted,
    this.tokenRegistered = false,
    this.statusText = '',
  });

  final bool supported;
  final bool permissionGranted;
  final bool tokenRegistered;
  final String statusText;
}

/// Safe wrapper around free Firebase APIs:
/// - Firebase Analytics (Google Analytics for Web & Android)
/// - Firebase Cloud Messaging (FCM token registration & foreground messages)
/// - Browser Web Notifications API popup helper for real-time Spark alerts
abstract final class FirebaseExtrasService {
  static bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static bool get _supportsMessagingPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static FirebaseAnalytics? get _analytics {
    if (!_isFirebaseReady) return null;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<void> logLogin({required String role}) async {
    try {
      final analytics = _analytics;
      if (analytics == null) return;
      await analytics.logLogin(loginMethod: 'google');
      await analytics.setUserProperty(name: 'center_role', value: role);
    } catch (_) {}
  }

  static Future<void> logAutoRegistered({required String role}) async {
    await logEvent(
      'auto_registered_user',
      parameters: {'role': role},
    );
  }

  static Future<void> logScreenView(String screenName) async {
    try {
      final analytics = _analytics;
      if (analytics == null) return;
      await analytics.logScreenView(screenName: screenName);
    } catch (_) {}
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      final analytics = _analytics;
      if (analytics == null) return;
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  static Stream<RemoteMessage> get foregroundMessages {
    if (!_isFirebaseReady || !_supportsMessagingPlatform) {
      return const Stream.empty();
    }
    try {
      return FirebaseMessaging.onMessage;
    } catch (_) {
      return const Stream.empty();
    }
  }

  static String get _platformKey {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  /// Requests permission (when [requestPermission] is true) and registers the
  /// device's FCM token in Firestore `/fcm_tokens/{uid}_{platform}`.
  static Future<PushSyncResult> syncMessagingPermissionAndToken({
    required AuthUser user,
    required DataRepository repository,
    bool requestPermission = false,
  }) async {
    if (!_supportsMessagingPlatform) {
      return const PushSyncResult(
        supported: false,
        permissionGranted: false,
        statusText: 'Realtime Firestore inbox active',
      );
    }

    bool browserGranted = isBrowserNotificationGranted;
    if (kIsWeb && requestPermission && !browserGranted) {
      browserGranted = await requestBrowserNotificationPermission();
    }

    if (!_isFirebaseReady || !repository.isCloudSync) {
      return PushSyncResult(
        supported: true,
        permissionGranted: browserGranted,
        statusText: browserGranted
            ? 'In-app + browser alerts active (Demo)'
            : 'In-app notifications active (Demo)',
      );
    }

    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings;
      if (requestPermission) {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } else {
        settings = await messaging.getNotificationSettings();
      }

      final granted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional ||
          browserGranted;

      if (!granted) {
        return PushSyncResult(
          supported: true,
          permissionGranted: false,
          statusText: requestPermission
              ? 'Permission blocked in browser/device settings (in-app alerts active)'
              : 'Tap "Enable Push" for system alerts',
        );
      }

      String? token;
      try {
        final completer = Completer<String?>();
        final sub = messaging.onRegistered.listen((registeredId) {
          final clean = registeredId.trim();
          if (clean.isNotEmpty) {
            if (!completer.isCompleted) completer.complete(clean);
            unawaited(
              repository.saveFcmToken(
                uid: user.uid,
                email: user.email,
                role: user.role.name,
                token: clean,
                platform: _platformKey,
              ),
            );
          }
        });
        await messaging.register(
          serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
        );
        token = await completer.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => null,
        );
        await sub.cancel();
      } catch (_) {
        // Web push without a Web Push certificate falls back seamlessly to
        // Firestore realtime listeners + Browser Notification API popups.
      }

      if (token != null && token.trim().isNotEmpty) {
        return const PushSyncResult(
          supported: true,
          permissionGranted: true,
          tokenRegistered: true,
          statusText: 'FCM Push + Realtime Alerts Connected',
        );
      }

      return const PushSyncResult(
        supported: true,
        permissionGranted: true,
        tokenRegistered: false,
        statusText: 'Browser/System Alerts + Realtime Inbox Active',
      );
    } catch (_) {
      return PushSyncResult(
        supported: true,
        permissionGranted: browserGranted,
        statusText: 'Realtime Firestore Inbox Active',
      );
    }
  }

  static void notifyWebPopupIfGranted({
    required String title,
    required String body,
    String? tag,
  }) {
    if (kIsWeb) {
      showBrowserNotificationPopup(title: title, body: body, tag: tag);
    }
  }
}
