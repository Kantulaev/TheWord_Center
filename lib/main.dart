import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/providers/app_providers.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/data_repository.dart';
import 'core/repositories/demo_realtime_repository.dart';
import 'core/repositories/firestore_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = await _initializeServices();

  runApp(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWithValue(env.dataRepository),
        authRepositoryProvider.overrideWithValue(env.authRepository),
      ],
      child: const TheWordApp(),
    ),
  );
}

Future<({DataRepository dataRepository, AuthRepository authRepository})>
    _initializeServices() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final unconfigured = options.apiKey.isEmpty ||
        options.apiKey.startsWith('YOUR_') ||
        options.projectId.isEmpty ||
        options.projectId.startsWith('YOUR_');
    if (unconfigured) {
      return (
        dataRepository: DemoRealtimeRepository(),
        authRepository: DemoAuthRepository(),
      );
    }
    await Firebase.initializeApp(options: options);
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Multi-tab IndexedDB lock safely falls back to in-memory cache.
    }
    return (
      dataRepository: FirestoreRepository(),
      authRepository: FirebaseAuthRepository(),
    );
  } catch (_) {
    // Automatically falls back to Demo Mode when firebase_options.dart is
    // unconfigured or Firebase initialization is unavailable.
    return (
      dataRepository: DemoRealtimeRepository(),
      authRepository: DemoAuthRepository(),
    );
  }
}

class TheWordApp extends ConsumerWidget {
  const TheWordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp(
      title: 'The Word',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}
