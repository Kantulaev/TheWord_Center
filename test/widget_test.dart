import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:the_word/core/models/language_type.dart';
import 'package:the_word/core/models/study_group.dart';
import 'package:the_word/core/providers/app_providers.dart';
import 'package:the_word/core/repositories/auth_repository.dart';
import 'package:the_word/core/repositories/demo_realtime_repository.dart';
import 'package:the_word/main.dart';

class _SignedOutCloudAuthRepo implements AuthRepository {
  @override
  bool get isSignInRequired => true;

  @override
  Stream<AuthUser?> watchAuthState() => Stream.value(null);

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle({bool requireStaff = false}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<List<AllowedStaffEmail>> watchAllowedEmails() =>
      Stream.value(const []);

  @override
  Future<void> addAllowedEmail(String email) async {}

  @override
  Future<void> removeAllowedEmail(String email) async {}
}

class _StudentSignedInAuthRepo extends _SignedOutCloudAuthRepo {
  @override
  Stream<AuthUser?> watchAuthState() => Stream.value(
        const AuthUser(
          uid: 'student-1',
          email: 'student@gmail.com',
          displayName: 'Alex Student',
          role: UserRole.student,
        ),
      );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildTestApp(DemoRealtimeRepository repo) {
    return ProviderScope(
      overrides: [
        dataRepositoryProvider.overrideWithValue(repo),
        enableAmbientAnimationsProvider.overrideWithValue(false),
        enableLiveClockTickerProvider.overrideWithValue(false),
      ],
      child: const TheWordApp(),
    );
  }

  testWidgets('Desktop layout renders Live Master Schedule and navigates all modules',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = DemoRealtimeRepository(
      referenceNow: DateTime(2026, 11, 25, 12, 30),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('The Word'), findsOneWidget);
    expect(find.text('Live Master Schedule'), findsOneWidget);
    expect(find.text('Active Now'), findsOneWidget);
    expect(find.text("Today's Lessons"), findsOneWidget);
    expect(find.text('Free Classrooms'), findsOneWidget);
    expect(find.text('Active Students'), findsOneWidget);

    // Switch Schedule views: Week -> Agenda -> Day
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    // Navigate to Groups
    await tester.tap(find.text('Groups'));
    await tester.pumpAndSettle();
    expect(find.text('Study Groups (HSK & CEFR)'), findsOneWidget);
    expect(find.text('HSK 1 — Foundations'), findsOneWidget);

    // Navigate to Teachers
    await tester.tap(find.text('Teachers'));
    await tester.pumpAndSettle();
    expect(find.text('Teachers Directory'), findsOneWidget);
    expect(find.text('Sharllote'), findsOneWidget);
    expect(find.text('Olga'), findsOneWidget);

    // Navigate to Classrooms
    await tester.tap(find.text('Classrooms'));
    await tester.pumpAndSettle();
    expect(find.text('Classrooms & Live Status'), findsOneWidget);
    expect(find.text('Hall'), findsOneWidget);
    expect(find.text('OldCenter'), findsOneWidget);

    // Navigate to Students & test quick +1 credit button
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    expect(find.text('Students Roster'), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsOneWidget);

    final plusButtons = find.byTooltip('Increase credits (+1)');
    expect(plusButtons, findsWidgets);
    await tester.tap(plusButtons.first);
    await tester.pumpAndSettle();

    // Navigate to Finance
    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();
    expect(find.text('Finance, Payroll & Exports'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);

    // Navigate to Leads
    await tester.tap(find.text('Leads'));
    await tester.pumpAndSettle();
    expect(find.text('Trial Leads & Student Requests'), findsOneWidget);

    // Navigate to Updates
    await tester.tap(find.text('Updates'));
    await tester.pumpAndSettle();
    expect(find.text('App Updates & Center Activity Log'), findsOneWidget);
    expect(find.text("What's New in The Word"), findsOneWidget);

    // Toggle Dark Mode
    await tester.tap(find.text('Pearl Light'));
    await tester.pumpAndSettle();
    expect(find.text('Obsidian Dark'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile viewport renders floating bottom nav bar without overflow',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = DemoRealtimeRepository(
      referenceNow: DateTime(2026, 11, 25, 12, 30),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('The Word'), findsOneWidget);
    expect(find.text('Live Master Schedule'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Open More sheet on mobile and navigate to Teachers
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('More Sections'), findsOneWidget);
    await tester.tap(find.text('Teachers'));
    await tester.pumpAndSettle();
    expect(find.text('Teachers Directory'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Tablet viewport renders NavigationRail without overflow',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(820, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = DemoRealtimeRepository(
      referenceNow: DateTime(2026, 11, 25, 12, 30),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Live Master Schedule'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Lesson and Student modals validate conflicts and language scales',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final refTime = DateTime(now.year, now.month, now.day, 12, 30);
    final repo = DemoRealtimeRepository(referenceNow: refTime);
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildTestApp(repo));
    await tester.pumpAndSettle();

    // Open New Lesson modal
    await tester.tap(find.text('New Lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Schedule New Lesson'), findsOneWidget);

    // Close New Lesson modal
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Navigate to Students and open Add Student modal
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Student'));
    await tester.pumpAndSettle();

    expect(find.text('Proficiency Level (HSK 1–6)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('HSK 1'),
      ),
      findsOneWidget,
    );

    // Switch target language to English inside the dialog and verify CEFR levels appear
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('English'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Proficiency Level (CEFR A1–C2)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('A1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Closed Sign-In screen gates access when Cloud auth is required',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = DemoRealtimeRepository(
      referenceNow: DateTime(2026, 11, 25, 12, 30),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(_SignedOutCloudAuthRepo()),
          enableAmbientAnimationsProvider.overrideWithValue(false),
          enableLiveClockTickerProvider.overrideWithValue(false),
        ],
        child: const TheWordApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Authorized Staff Only'), findsOneWidget);
    expect(find.text('Welcome to The Word'), findsOneWidget);
    expect(find.text('Ogonbaeva 222, Bishkek, Kyrgyzstan, 720000'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Staff Sign In Only'), findsOneWidget);
    expect(find.text('Live Master Schedule'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Student Portal lets student join HSK group and view homework',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = DemoRealtimeRepository(
      referenceNow: DateTime(2026, 11, 25, 12, 30),
    );
    addTearDown(repo.dispose);

    // Seed a Sharing group to prove Student Portal never renders Sharing groups
    await repo.upsertGroup(
      StudyGroup(
        id: 'grp_hidden_sharing',
        name: 'Private Staff Sharing',
        language: CourseLanguage.sharing,
        level: 'All Levels',
        teacherId: 't_sharllote',
        classroomId: 'room_hall',
        scheduleWeekdays: const [DateTime.friday],
        startHour: 17,
        startMinute: 0,
        createdAt: DateTime(2026, 11, 25),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(_StudentSignedInAuthRepo()),
          enableAmbientAnimationsProvider.overrideWithValue(false),
          enableLiveClockTickerProvider.overrideWithValue(false),
        ],
        child: const TheWordApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The Word • Student Portal'), findsOneWidget);
    expect(find.text('Ogonbaeva 222, Bishkek, Kyrgyzstan, 720000 (Near Victory Business Center (280 m) & Detsky Mir (3 min))'), findsOneWidget);
    expect(find.text('HSK 1 — Foundations'), findsOneWidget);
    expect(find.text('Private Staff Sharing'), findsNothing);

    await tester.tap(find.text('HSK 1 — Foundations'));
    await tester.pumpAndSettle();

    expect(find.text('Joined ✓'), findsOneWidget);
    expect(find.text('HSK 1 Unit 3 Tone Drills & Audio'), findsOneWidget);
    expect(find.text('Submit Answer / Link'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Request Change'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Request Change'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
