# The Word — Language Center Management App

A cross-platform Flutter application for **The Word** language center (Mandarin Chinese & English courses), crafted with an Apple Liquid Glass aesthetic, responsive desktop/tablet/mobile layouts, smart scheduling conflict prevention, and real-time Firebase Cloud Firestore synchronization (with automatic zero-config Demo Mode for instant browser preview).

---

## Project Structure

```text
lib/
├── main.dart
├── firebase_options.dart                  # Drop-in FlutterFire target (Demo fallback if unconfigured)
├── core/
│   ├── models/                            # Teacher, Classroom, Student, Lesson, ConflictDetector
│   ├── providers/                         # Riverpod StreamProviders & UI Notifiers
│   ├── repositories/                      # DataRepository, DemoRealtimeRepository, FirestoreRepository
│   └── theme/                             # Apple Liquid Glass palette, typography, aurora backdrop
├── features/
│   ├── schedule/presentation/             # Master Schedule (Day / Week / Agenda), forms, inspector
│   ├── teachers/presentation/             # Teachers directory, weekly hours & profile inspector
│   ├── classrooms/presentation/           # Classrooms & live Free/Occupied status tracking
│   └── students/presentation/             # Students roster, HSK/CEFR levels & quick credit buttons
└── shared/widgets/                        # LiquidGlassContainer, AdaptiveShell, Today's Pulse strip
```

---

## Quick Start (Instant Browser Demo Mode)

The project automatically starts in **Demo Realtime Mode** with pre-populated teachers, classrooms, students, and live lessons happening right now whenever `lib/firebase_options.dart` has not been configured yet.

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Launch immediately in Chrome
flutter run -d chrome

# Optional: Launch on Windows, macOS, Android, or iOS
flutter run -d windows
flutter run -d macos
```

---

## Connecting Firebase Cloud Firestore (Free Spark Plan)

Any creation, edit, rescheduling, or deletion will sync across every connected browser and device in real time once Firebase is connected.

### 1. Create a Free Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com/) and click **Add project** (choose the free **Spark plan**).
2. In the left sidebar, go to **Build → Firestore Database → Create database**.
3. Start in **Test mode** (or configure security rules below) and pick the closest region.

### 2. Configure FlutterFire
Install and run the official FlutterFire CLI inside this project directory:

```bash
# Install Firebase & FlutterFire CLI tools
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Log in to your Google / Firebase account
firebase login

# Generate lib/firebase_options.dart for Web, Android, iOS, macOS, and Windows
flutterfire configure
```

When prompted to overwrite `lib/firebase_options.dart`, confirm **Yes**. Restart the app (`flutter run -d chrome`) and the bottom-left status indicator will switch automatically from **Demo Mode (Live Sync)** to **Cloud Sync (Firestore)**.

### 3. Recommended Firestore Security Rules
For internal staff usage (or while prototyping):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{collection}/{docId} {
      allow read, write: if collection in ['lessons', 'teachers', 'classrooms', 'students'];
    }
  }
}
```

> **Production tip:** Before opening the web URL publicly, add Firebase Authentication (`firebase_auth`) and restrict `allow read, write: if request.auth != null;`.

---

## Running Static Analysis & Tests

```bash
dart analyze
flutter test
flutter build web --release
```
