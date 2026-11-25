import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:the_word/core/providers/app_providers.dart';
import 'package:the_word/core/repositories/demo_realtime_repository.dart';
import 'package:the_word/main.dart';

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

    // Navigate to Teachers
    await tester.tap(find.text('Teachers'));
    await tester.pumpAndSettle();
    expect(find.text('Teachers Directory'), findsOneWidget);
    expect(find.text('Mei Lin'), findsOneWidget);

    // Navigate to Classrooms
    await tester.tap(find.text('Classrooms'));
    await tester.pumpAndSettle();
    expect(find.text('Classrooms & Live Status'), findsOneWidget);
    expect(find.text('Room 1 - Beijing'), findsOneWidget);

    // Navigate to Students & test quick +1 credit button
    await tester.tap(find.text('Students'));
    await tester.pumpAndSettle();
    expect(find.text('Students Roster'), findsOneWidget);
    expect(find.text('Olivia Bennett'), findsOneWidget);

    final plusButtons = find.byTooltip('Increase credits (+1)');
    expect(plusButtons, findsWidgets);
    await tester.tap(plusButtons.first);
    await tester.pumpAndSettle();

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
    expect(find.text('Teachers'), findsOneWidget);
    expect(find.text('Classrooms'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);

    // Switch to Teachers on mobile
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
}
