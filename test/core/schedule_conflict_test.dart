import 'package:flutter_test/flutter_test.dart';
import 'package:the_word/core/models/classroom.dart';
import 'package:the_word/core/models/language_type.dart';
import 'package:the_word/core/models/lesson.dart';
import 'package:the_word/core/models/schedule_conflict.dart';
import 'package:the_word/core/models/student.dart';
import 'package:the_word/core/models/teacher.dart';
import 'package:the_word/core/repositories/demo_realtime_repository.dart';

void main() {
  group('ScheduleConflictDetector', () {
    final day = DateTime(2026, 11, 25);

    final teacherA = Teacher(
      id: 't1',
      fullName: 'Mei Lin',
      avatarColorHex: 'D93848',
      languages: TeachingLanguageScope.chinese,
      specializations: const ['HSK 1-6'],
      isActive: true,
      createdAt: day,
    );
    final teacherOnLeave = Teacher(
      id: 't2',
      fullName: 'Daniel Wu',
      avatarColorHex: 'B45309',
      languages: TeachingLanguageScope.chinese,
      specializations: const ['Spoken Chinese'],
      isActive: false,
      createdAt: day,
    );

    final roomSmall = Classroom(
      id: 'r1',
      name: 'Room 1 - Beijing',
      capacity: 1,
      equipmentTags: const ['Whiteboard'],
      createdAt: day,
    );
    final roomAlt = Classroom(
      id: 'r2',
      name: 'Room 2 - Shanghai',
      capacity: 6,
      equipmentTags: const ['Smartboard'],
      createdAt: day,
    );

    final student1 = Student(
      id: 's1',
      fullName: 'Olivia Bennett',
      targetLanguage: CourseLanguage.chinese,
      proficiencyLevel: 'HSK 4',
      format: LessonType.oneOnOne,
      remainingCredits: 8,
      createdAt: day,
    );
    final student2 = Student(
      id: 's2',
      fullName: 'Liam Carter',
      targetLanguage: CourseLanguage.chinese,
      proficiencyLevel: 'HSK 2',
      format: LessonType.group,
      remainingCredits: 5,
      createdAt: day,
    );

    final existingLesson = Lesson(
      id: 'l1',
      title: 'HSK 4 Morning',
      language: CourseLanguage.chinese,
      lessonType: LessonType.oneOnOne,
      teacherId: 't1',
      classroomId: 'r1',
      studentIds: const ['s1'],
      startTime: DateTime(2026, 11, 25, 10, 0),
      endTime: DateTime(2026, 11, 25, 11, 0),
      status: LessonStatus.scheduled,
      createdAt: day,
    );

    final teachersMap = {'t1': teacherA, 't2': teacherOnLeave};
    final roomsMap = {'r1': roomSmall, 'r2': roomAlt};
    final studentsMap = {'s1': student1, 's2': student2};

    test('detects overlapping classroom, teacher, and student conflicts', () {
      final candidate = Lesson(
        id: 'new',
        title: 'Overlap Test',
        language: CourseLanguage.chinese,
        lessonType: LessonType.oneOnOne,
        teacherId: 't1',
        classroomId: 'r1',
        studentIds: const ['s1'],
        startTime: DateTime(2026, 11, 25, 10, 30),
        endTime: DateTime(2026, 11, 25, 11, 30),
        createdAt: day,
      );

      final result = ScheduleConflictDetector.validate(
        candidate: candidate,
        existingLessons: [existingLesson],
        teachersById: teachersMap,
        classroomsById: roomsMap,
        studentsById: studentsMap,
      );

      expect(result.hasBlockingConflicts, isTrue);
      expect(result.blockingConflicts.length, 3);
      expect(
        result.blockingConflicts.map((c) => c.resourceType),
        containsAll([
          ConflictResourceType.classroom,
          ConflictResourceType.teacher,
          ConflictResourceType.student,
        ]),
      );
    });

    test('allows back-to-back lessons without overlap', () {
      final backToBack = Lesson(
        id: 'new',
        title: 'Next Slot',
        language: CourseLanguage.chinese,
        lessonType: LessonType.oneOnOne,
        teacherId: 't1',
        classroomId: 'r1',
        studentIds: const ['s1'],
        startTime: DateTime(2026, 11, 25, 11, 0),
        endTime: DateTime(2026, 11, 25, 12, 0),
        createdAt: day,
      );

      final result = ScheduleConflictDetector.validate(
        candidate: backToBack,
        existingLessons: [existingLesson],
        teachersById: teachersMap,
        classroomsById: roomsMap,
        studentsById: studentsMap,
      );

      expect(result.hasBlockingConflicts, isFalse);
    });

    test('ignores self when editing existing lesson and ignores canceled lessons',
        () {
      final selfEdit = existingLesson.copyWith(title: 'Updated Title');
      final canceledOther = existingLesson.copyWith(
        id: 'l_canceled',
        status: LessonStatus.canceled,
      );

      final result = ScheduleConflictDetector.validate(
        candidate: selfEdit,
        existingLessons: [existingLesson, canceledOther],
        teachersById: teachersMap,
        classroomsById: roomsMap,
        studentsById: studentsMap,
      );

      expect(result.hasBlockingConflicts, isFalse);
    });

    test('surfaces soft warnings for capacity, language mismatch, and on-leave',
        () {
      final candidate = Lesson(
        id: 'warn',
        title: 'English Workshop',
        language: CourseLanguage.english,
        lessonType: LessonType.group,
        teacherId: 't2',
        classroomId: 'r1',
        studentIds: const ['s1', 's2'],
        startTime: DateTime(2026, 11, 25, 14, 0),
        endTime: DateTime(2026, 11, 25, 15, 0),
        createdAt: day,
      );

      final result = ScheduleConflictDetector.validate(
        candidate: candidate,
        existingLessons: [existingLesson],
        teachersById: teachersMap,
        classroomsById: roomsMap,
        studentsById: studentsMap,
      );

      expect(result.hasBlockingConflicts, isFalse);
      expect(result.softWarnings.length, 3);
    });
  });

  group('DemoRealtimeRepository & Lesson lifecycle', () {
    test('seeds initial data and streams live mutations', () async {
      final refTime = DateTime(2026, 11, 25, 14, 0);
      final repo = DemoRealtimeRepository(referenceNow: refTime);
      addTearDown(repo.dispose);

      final initialTeachers = await repo.watchTeachers().first;
      final initialRooms = await repo.watchClassrooms().first;
      final initialStudents = await repo.watchStudents().first;
      final initialLessons = await repo.watchLessons().first;

      expect(initialTeachers.length, greaterThanOrEqualTo(5));
      expect(initialRooms.length, greaterThanOrEqualTo(4));
      expect(initialStudents.length, greaterThanOrEqualTo(8));
      expect(
        initialLessons.where((l) => l.isHappeningNowAt(refTime)).length,
        greaterThanOrEqualTo(2),
      );

      final firstStudent = initialStudents.first;
      final initialCredits = firstStudent.remainingCredits;
      await repo.adjustStudentCredits(firstStudent.id, 1);
      final updatedStudents = await repo.watchStudents().first;
      expect(
        updatedStudents.firstWhere((s) => s.id == firstStudent.id).remainingCredits,
        initialCredits + 1,
      );
    });
  });
}
