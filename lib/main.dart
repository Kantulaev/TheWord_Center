import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/providers/app_providers.dart';
import 'core/repositories/data_repository.dart';
import 'core/repositories/demo_realtime_repository.dart';
import 'core/repositories/firestore_repository.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'shared/widgets/adaptive_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = await _createDataRepository();

  runApp(
    ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWithValue(repository),
      ],
      child: const TheWordApp(),
    ),
  );
}

Future<DataRepository> _createDataRepository() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    final unconfigured = options.apiKey.isEmpty ||
        options.apiKey.startsWith('YOUR_') ||
        options.projectId.isEmpty ||
        options.projectId.startsWith('YOUR_');
    if (unconfigured) {
      return DemoRealtimeRepository();
    }
    await Firebase.initializeApp(options: options);
    return FirestoreRepository();
  } catch (_) {
    // Automatically falls back to Demo Mode when firebase_options.dart is
    // unconfigured or Firebase initialization is unavailable.
    return DemoRealtimeRepository();
  }
}

class TheWordApp extends ConsumerWidget {
  const TheWordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'The Word',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AdaptiveShell(),
    );
  }
}
