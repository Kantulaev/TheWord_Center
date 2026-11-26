import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/student_portal/l10n/student_portal_strings.dart';
import '../models/classroom.dart';
import '../models/homework.dart';
import '../models/language_type.dart';
import '../models/lesson.dart';
import '../models/operations_models.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/teacher.dart';
import '../repositories/auth_repository.dart';
import '../repositories/data_repository.dart';
import '../repositories/demo_realtime_repository.dart';
import '../utils/local_prefs.dart';

enum AppTab {
  schedule('Schedule'),
  groups('Groups'),
  teachers('Teachers'),
  classrooms('Classrooms'),
  students('Students'),
  finance('Finance'),
  leads('Leads'),
  updates('Updates');

  const AppTab(this.label);
  final String label;
}

enum ScheduleViewMode {
  day('Day'),
  week('Week'),
  agenda('Agenda');

  const ScheduleViewMode(this.label);
  final String label;
}

@immutable
class ScheduleFilterState {
  const ScheduleFilterState({
    this.language,
    this.teacherId,
    this.classroomId,
    this.searchQuery = '',
    required this.selectedDate,
    this.viewMode = ScheduleViewMode.day,
  });

  final CourseLanguage? language;
  final String? teacherId;
  final String? classroomId;
  final String searchQuery;
  final DateTime selectedDate;
  final ScheduleViewMode viewMode;

  bool get hasActiveFilters =>
      language != null ||
      teacherId != null ||
      classroomId != null ||
      searchQuery.trim().isNotEmpty;

  ScheduleFilterState copyWith({
    CourseLanguage? language,
    bool clearLanguage = false,
    String? teacherId,
    bool clearTeacher = false,
    String? classroomId,
    bool clearClassroom = false,
    String? searchQuery,
    DateTime? selectedDate,
    ScheduleViewMode? viewMode,
  }) {
    return ScheduleFilterState(
      language: clearLanguage ? null : (language ?? this.language),
      teacherId: clearTeacher ? null : (teacherId ?? this.teacherId),
      classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

/// Active inspector panel selection shown on tablet split / desktop slide-over.
@immutable
class InspectorTarget {
  const InspectorTarget.lesson(this.id)
      : kind = InspectorKind.lesson;
  const InspectorTarget.group(this.id)
      : kind = InspectorKind.group;
  const InspectorTarget.teacher(this.id)
      : kind = InspectorKind.teacher;
  const InspectorTarget.classroom(this.id)
      : kind = InspectorKind.classroom;
  const InspectorTarget.student(this.id)
      : kind = InspectorKind.student;

  final InspectorKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectorTarget &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          id == other.id;

  @override
  int get hashCode => Object.hash(kind, id);
}

enum InspectorKind { lesson, group, teacher, classroom, student }

@immutable
class TodayPulseStats {
  const TodayPulseStats({
    required this.activeNowCount,
    required this.todayTotalCount,
    required this.freeClassroomsCount,
    required this.totalClassroomsCount,
    required this.activeStudentsCount,
  });

  final int activeNowCount;
  final int todayTotalCount;
  final int freeClassroomsCount;
  final int totalClassroomsCount;
  final int activeStudentsCount;
}

@immutable
class ClassroomOccupancy {
  const ClassroomOccupancy({
    required this.classroom,
    required this.activeLesson,
    required this.activeTeacher,
    required this.nextLessonToday,
  });

  final Classroom classroom;
  final Lesson? activeLesson;
  final Teacher? activeTeacher;
  final Lesson? nextLessonToday;

  bool get isOccupied => activeLesson != null;
}

// ---------------------------------------------------------------------------
// Core Configuration & Runtime Overrides
// ---------------------------------------------------------------------------

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  final repo = DemoRealtimeRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DemoAuthRepository();
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
});

final allowedEmailsProvider = StreamProvider<List<AllowedStaffEmail>>((ref) {
  return ref.watch(authRepositoryProvider).watchAllowedEmails();
});

final enableAmbientAnimationsProvider = Provider<bool>((ref) => true);
final enableLiveClockTickerProvider = Provider<bool>((ref) => true);

final liveClockProvider = StreamProvider<DateTime>((ref) {
  final tickerEnabled = ref.watch(enableLiveClockTickerProvider);
  if (!tickerEnabled) {
    return Stream.value(DateTime.now());
  }
  return Stream<DateTime>.multi((controller) {
    controller.add(DateTime.now());
    final timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => controller.add(DateTime.now()),
    );
    controller.onCancel = timer.cancel;
  });
});

// ---------------------------------------------------------------------------
// UI State Notifiers (Riverpod 3.x)
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'the_word_theme_mode';

  @override
  ThemeMode build() {
    final saved = readLocalPref(_prefKey);
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  void toggle() {
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setMode(ThemeMode mode) {
    state = mode;
    writeLocalPref(_prefKey, mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class FontScaleNotifier extends Notifier<double> {
  static const _prefKey = 'the_word_font_scale';
  static const List<double> presets = [1.0, 1.15, 1.30, 1.45];

  @override
  double build() {
    final raw = readLocalPref(_prefKey);
    final parsed = raw != null ? double.tryParse(raw) : null;
    if (parsed != null && parsed >= 0.85 && parsed <= 1.6) {
      return parsed;
    }
    return 1.0;
  }

  void setScale(double scale) {
    final clamped = scale.clamp(0.9, 1.5);
    state = clamped;
    writeLocalPref(_prefKey, clamped.toStringAsFixed(2));
  }
}

final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

class PortalLocaleNotifier extends Notifier<PortalLocale> {
  static const _prefKey = 'the_word_portal_locale';

  @override
  PortalLocale build() {
    return PortalLocale.fromCode(readLocalPref(_prefKey));
  }

  void setLocale(PortalLocale locale) {
    state = locale;
    writeLocalPref(_prefKey, locale.code);
  }
}

final portalLocaleProvider =
    NotifierProvider<PortalLocaleNotifier, PortalLocale>(
  PortalLocaleNotifier.new,
);

class NavigationTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.schedule;

  void select(AppTab tab) => state = tab;
}

final navigationTabProvider = NotifierProvider<NavigationTabNotifier, AppTab>(
  NavigationTabNotifier.new,
);

class InspectorSelectionNotifier extends Notifier<InspectorTarget?> {
  @override
  InspectorTarget? build() => null;

  void open(InspectorTarget selection) => state = selection;
  void close() => state = null;
}

final inspectorSelectionProvider =
    NotifierProvider<InspectorSelectionNotifier, InspectorTarget?>(
  InspectorSelectionNotifier.new,
);

class ScheduleFilterNotifier extends Notifier<ScheduleFilterState> {
  @override
  ScheduleFilterState build() {
    final now = DateTime.now();
    return ScheduleFilterState(
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  void setLanguage(CourseLanguage? language) {
    state = language == null
        ? state.copyWith(clearLanguage: true)
        : state.copyWith(language: language);
  }

  void setTeacher(String? teacherId) {
    state = teacherId == null
        ? state.copyWith(clearTeacher: true)
        : state.copyWith(teacherId: teacherId);
  }

  void setClassroom(String? classroomId) {
    state = classroomId == null
        ? state.copyWith(clearClassroom: true)
        : state.copyWith(classroomId: classroomId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    );
  }

  void jumpToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      selectedDate: DateTime(now.year, now.month, now.day),
    );
  }

  void shiftDate(int days) {
    state = state.copyWith(
      selectedDate: state.selectedDate.add(Duration(days: days)),
    );
  }

  void setViewMode(ScheduleViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void clearAllFilters() {
    state = state.copyWith(
      clearLanguage: true,
      clearTeacher: true,
      clearClassroom: true,
      searchQuery: '',
    );
  }
}

final scheduleFilterProvider =
    NotifierProvider<ScheduleFilterNotifier, ScheduleFilterState>(
  ScheduleFilterNotifier.new,
);

// ---------------------------------------------------------------------------
// Real-Time Data Streams
// ---------------------------------------------------------------------------

final lessonsStreamProvider = StreamProvider<List<Lesson>>((ref) {
  return ref.watch(dataRepositoryProvider).watchLessons();
});

final teachersStreamProvider = StreamProvider<List<Teacher>>((ref) {
  return ref.watch(dataRepositoryProvider).watchTeachers();
});

final publicTeachersStreamProvider = StreamProvider<List<Teacher>>((ref) {
  return ref.watch(dataRepositoryProvider).watchPublicTeachers();
});

final classroomsStreamProvider = StreamProvider<List<Classroom>>((ref) {
  return ref.watch(dataRepositoryProvider).watchClassrooms();
});

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(dataRepositoryProvider).watchStudents();
});

final myStudentRecordProvider = StreamProvider<Student?>((ref) {
  final email = ref.watch(authStateProvider).value?.email ?? '';
  if (email.trim().isEmpty) return Stream.value(null);
  return ref.watch(dataRepositoryProvider).watchMyStudentRecord(email);
});

final groupsStreamProvider = StreamProvider<List<StudyGroup>>((ref) {
  return ref.watch(dataRepositoryProvider).watchGroups();
});

final publicGroupsStreamProvider = StreamProvider<List<StudyGroup>>((ref) {
  return ref.watch(dataRepositoryProvider).watchPublicGroups();
});

final homeworksStreamProvider =
    StreamProvider<List<HomeworkAssignment>>((ref) {
  return ref.watch(dataRepositoryProvider).watchHomeworks();
});

final studentHomeworksProvider =
    StreamProvider<List<HomeworkAssignment>>((ref) {
  final ids =
      ref.watch(studentPortalProfileProvider).value?.selectedGroupIds ??
          const <String>[];
  return ref.watch(dataRepositoryProvider).watchHomeworksForGroups(ids);
});

final allHomeworkSubmissionsProvider =
    StreamProvider<List<HomeworkSubmission>>((ref) {
  return ref.watch(dataRepositoryProvider).watchAllHomeworkSubmissions();
});

final myHomeworkSubmissionsProvider =
    StreamProvider<List<HomeworkSubmission>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.value(const []);
  return ref.watch(dataRepositoryProvider).watchMyHomeworkSubmissions(uid);
});

final studentPortalProfileProvider =
    StreamProvider<StudentPortalProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(dataRepositoryProvider).watchStudentPortalProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
});

final attendanceStreamProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  return ref.watch(dataRepositoryProvider).watchAttendance();
});

final paymentsStreamProvider = StreamProvider<List<PaymentRecord>>((ref) {
  return ref.watch(dataRepositoryProvider).watchPayments();
});

final trialLeadsStreamProvider = StreamProvider<List<TrialLead>>((ref) {
  return ref.watch(dataRepositoryProvider).watchTrialLeads();
});

final rescheduleRequestsStreamProvider =
    StreamProvider<List<RescheduleRequest>>((ref) {
  return ref.watch(dataRepositoryProvider).watchRescheduleRequests();
});

final myRescheduleRequestsProvider =
    StreamProvider<List<RescheduleRequest>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.value(const []);
  return ref.watch(dataRepositoryProvider).watchMyRescheduleRequests(uid);
});

final activityLogsStreamProvider =
    StreamProvider<List<ActivityLogEntry>>((ref) {
  return ref.watch(dataRepositoryProvider).watchActivityLogs();
});

// ---------------------------------------------------------------------------
// Derived Lookup Maps & Live Metrics
// ---------------------------------------------------------------------------

final teachersMapProvider = Provider<Map<String, Teacher>>((ref) {
  final teachers = ref.watch(teachersStreamProvider).value ?? const [];
  return {for (final t in teachers) t.id: t};
});

final publicTeachersMapProvider = Provider<Map<String, Teacher>>((ref) {
  final teachers = ref.watch(publicTeachersStreamProvider).value ?? const [];
  return {for (final t in teachers) t.id: t};
});

final classroomsMapProvider = Provider<Map<String, Classroom>>((ref) {
  final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
  return {for (final c in classrooms) c.id: c};
});

final studentsMapProvider = Provider<Map<String, Student>>((ref) {
  final students = ref.watch(studentsStreamProvider).value ?? const [];
  return {for (final s in students) s.id: s};
});

final filteredLessonsProvider = Provider<List<Lesson>>((ref) {
  final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
  final filter = ref.watch(scheduleFilterProvider);
  final teachers = ref.watch(teachersMapProvider);
  final classrooms = ref.watch(classroomsMapProvider);
  final students = ref.watch(studentsMapProvider);
  final q = filter.searchQuery.trim().toLowerCase();

  return lessons.where((lesson) {
    if (filter.language != null && lesson.language != filter.language) {
      return false;
    }
    if (filter.teacherId != null &&
        !lesson.involvesTeacher(filter.teacherId!)) {
      return false;
    }
    if (filter.classroomId != null &&
        lesson.classroomId != filter.classroomId) {
      return false;
    }
    if (q.isNotEmpty) {
      final teacherNames = lesson.allTeacherIds
          .map((id) => teachers[id]?.fullName.toLowerCase() ?? '')
          .join(' ');
      final roomName = classrooms[lesson.classroomId]?.name.toLowerCase() ?? '';
      final studentNames = lesson.studentIds
          .map((id) => students[id]?.fullName.toLowerCase() ?? '')
          .join(' ');
      final haystack =
          '${lesson.title.toLowerCase()} $teacherNames $roomName $studentNames ${lesson.notes.toLowerCase()}';
      if (!haystack.contains(q)) return false;
    }
    return true;
  }).toList(growable: false);
});

final classroomOccupancyProvider =
    Provider<Map<String, ClassroomOccupancy>>((ref) {
  final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
  final rawLessons = ref.watch(lessonsStreamProvider).value ?? const [];
  final teachers = ref.watch(teachersMapProvider);
  final now = ref.watch(liveClockProvider).value ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayLessons = Lesson.expandAll(rawLessons, today, today);

  final result = <String, ClassroomOccupancy>{};
  for (final room in classrooms) {
    Lesson? active;
    Lesson? nextToday;

    for (final lesson in todayLessons) {
      if (lesson.classroomId != room.id) continue;
      if (lesson.isHappeningNowAt(now)) {
        active ??= lesson;
      } else if (lesson.status != LessonStatus.canceled &&
          lesson.status != LessonStatus.completed &&
          lesson.startTime.isAfter(now)) {
        if (nextToday == null ||
            lesson.startTime.isBefore(nextToday.startTime)) {
          nextToday = lesson;
        }
      }
    }

    result[room.id] = ClassroomOccupancy(
      classroom: room,
      activeLesson: active,
      activeTeacher: active != null ? teachers[active.teacherId] : null,
      nextLessonToday: nextToday,
    );
  }
  return result;
});

final todayPulseProvider = Provider<TodayPulseStats>((ref) {
  final rawLessons = ref.watch(lessonsStreamProvider).value ?? const [];
  final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
  final students = ref.watch(studentsStreamProvider).value ?? const [];
  final occupancy = ref.watch(classroomOccupancyProvider);
  final now = ref.watch(liveClockProvider).value ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayLessons = Lesson.expandAll(rawLessons, today, today);

  final activeNow = todayLessons.where((l) => l.isHappeningNowAt(now)).length;
  final todayTotal =
      todayLessons.where((l) => l.status != LessonStatus.canceled).length;
  final freeRooms =
      occupancy.values.where((item) => !item.isOccupied).length;

  return TodayPulseStats(
    activeNowCount: activeNow,
    todayTotalCount: todayTotal,
    freeClassroomsCount: freeRooms,
    totalClassroomsCount: classrooms.length,
    activeStudentsCount: students.length,
  );
});

/// Saturday Speaking Clubs (and any lesson marked as a Speaking Club) so staff
/// can inspect and change who is responsible in one tap.
final saturdayClubsProvider = Provider<List<Lesson>>((ref) {
  final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
  return lessons
      .where(
        (l) =>
            l.isSpeakingClub ||
            (l.isRecurring &&
                l.recurrenceWeekdays.contains(DateTime.saturday) &&
                l.title.toLowerCase().contains('club')),
      )
      .toList(growable: false);
});
