import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Placeholder Firebase configuration allowing "The Word" to boot immediately
/// in Demo Mode (`flutter run -d chrome`) without any Firebase credentials.
///
/// To connect your free Firebase Spark Cloud Firestore database:
/// 1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
/// 2. Run `flutterfire configure` in the project root.
/// 3. Overwrite this file when prompted — the app will automatically switch
///    from Demo Mode to real-time Cloud Firestore synchronization.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this project yet. '
      'Booting in Demo Realtime Mode.',
    );
  }
}
