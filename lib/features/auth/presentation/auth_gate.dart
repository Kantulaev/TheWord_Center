import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/community_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/services/firebase_extras_service.dart';
import '../../../core/theme/glass_background.dart';
import '../../../shared/widgets/adaptive_shell.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../../community/presentation/notifications_sheet.dart';
import '../../student_portal/presentation/student_portal_screen.dart';
import 'sign_in_screen.dart';

/// Routes signed-in staff to [AdaptiveShell], signed-in students to [StudentPortalScreen],
/// and handles automatic DB registration, Analytics login tracking, FCM token sync,
/// and live in-app/browser notification alerts.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _syncedSessionKey;
  bool _notificationsInitialized = false;
  final Set<String> _knownNotificationIds = {};
  StreamSubscription<dynamic>? _fcmForegroundSub;

  @override
  void initState() {
    super.initState();
    _fcmForegroundSub = FirebaseExtrasService.foregroundMessages.listen((msg) {
      if (!mounted) return;
      final title = msg.notification?.title ?? 'The Word Update';
      final body = msg.notification?.body ?? '';
      _showLiveAlertBanner(title: title, subtitle: body);
    });
  }

  @override
  void dispose() {
    _fcmForegroundSub?.cancel();
    super.dispose();
  }

  void _showLiveAlertBanner({
    required String title,
    required String subtitle,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              if (mounted) {
                showNotificationsCenterDialog(context);
              }
            },
          ),
        ),
      );
  }

  Future<void> _onUserSessionReady(AuthUser user) async {
    final repo = ref.read(dataRepositoryProvider);
    await FirebaseExtrasService.logLogin(role: user.role.name);

    try {
      final created = await repo.ensureUserRegisteredOnSignIn(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName ?? '',
        isStaff: user.isStaff,
      );
      if (created) {
        await FirebaseExtrasService.logAutoRegistered(role: user.role.name);
      }
    } catch (_) {
      // Never block sign-in flow if offline/transient error occurs.
    }

    await FirebaseExtrasService.syncMessagingPermissionAndToken(
      user: user,
      repository: repo,
      requestPermission: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    if (!authRepo.isSignInRequired) {
      return const AdaptiveShell();
    }

    final authAsync = ref.watch(authStateProvider);
    final animateBg = ref.watch(enableAmbientAnimationsProvider);

    ref.listen<AsyncValue<AuthUser?>>(authStateProvider, (_, next) {
      final user = next.value;
      if (user == null) {
        _syncedSessionKey = null;
        _notificationsInitialized = false;
        _knownNotificationIds.clear();
        return;
      }
      final key = '${user.uid}:${user.role.name}';
      if (_syncedSessionKey != key) {
        _syncedSessionKey = key;
        unawaited(_onUserSessionReady(user));
      }
    });

    ref.listen<AsyncValue<List<AppNotification>>>(
      notificationsStreamProvider,
      (_, next) {
        final list = next.value;
        final user = ref.read(authStateProvider).value;
        if (list == null || user == null) return;
        if (!_notificationsInitialized) {
          _notificationsInitialized = true;
          _knownNotificationIds
            ..clear()
            ..addAll(list.map((n) => n.id));
          return;
        }
        for (final item in list) {
          if (_knownNotificationIds.add(item.id) &&
              !item.isReadBy(user.uid) &&
              item.createdByUid != user.uid) {
            final subtitle = item.clubTopic.isNotEmpty
                ? '${item.clubTopic} — ${item.message}'
                : item.message;
            _showLiveAlertBanner(title: item.title, subtitle: subtitle);
            FirebaseExtrasService.notifyWebPopupIfGranted(
              title: item.title,
              body: subtitle,
              tag: item.id,
            );
          }
        }
      },
    );

    final initialUser = authAsync.value;
    if (initialUser != null) {
      final key = '${initialUser.uid}:${initialUser.role.name}';
      if (_syncedSessionKey != key) {
        _syncedSessionKey = key;
        Future.microtask(() => _onUserSessionReady(initialUser));
      }
    }

    return authAsync.when(
      loading: () => LiquidAuroraBackground(
        animate: animateBg,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: LiquidGlassContainer(
              borderRadius: 24,
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
      error: (_, _) => const SignInScreen(),
      data: (user) {
        if (user == null) {
          return const SignInScreen();
        }
        if (user.isStudent) {
          return const StudentPortalScreen();
        }
        return const AdaptiveShell();
      },
    );
  }
}
