import 'package:flutter_test/flutter_test.dart';
import 'package:the_word/core/data/center_info.dart';
import 'package:the_word/core/models/classroom.dart';
import 'package:the_word/core/models/community_models.dart';
import 'package:the_word/core/models/homework.dart';
import 'package:the_word/core/models/language_type.dart';
import 'package:the_word/core/models/lesson.dart';
import 'package:the_word/core/models/operations_models.dart';
import 'package:the_word/core/models/schedule_conflict.dart';
import 'package:the_word/core/models/student.dart';
import 'package:the_word/core/models/study_group.dart';
import 'package:the_word/core/models/teacher.dart';
import 'package:the_word/core/repositories/demo_realtime_repository.dart';
import 'package:the_word/core/utils/csv_exporter.dart';
import 'package:the_word/features/student_portal/l10n/student_portal_strings.dart';

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
      expect(initialRooms.length, greaterThanOrEqualTo(7));
      expect(initialStudents.length, greaterThanOrEqualTo(6));
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

      // Verify seeded classrooms & teachers match requested roster
      expect(
        initialRooms.map((c) => c.name),
        containsAll(['1', '2', '3', '4', '5', 'Hall', 'OldCenter']),
      );
      expect(
        initialTeachers.map((t) => t.fullName),
        containsAll(['Sharllote', 'Keith', 'Andrew', 'Sofia', 'Olga']),
      );
    });

    test('expands Mon/Wed/Fri and Saturday Speaking Clubs accurately', () {
      final mwf = Lesson(
        id: 'mwf',
        title: 'HSK 2 MWF',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_olga',
        classroomId: 'room_1',
        studentIds: const [],
        startTime: DateTime(2026, 11, 23, 18, 0), // Monday
        endTime: DateTime(2026, 11, 23, 19, 30),
        createdAt: DateTime(2026, 11, 23),
        recurrenceWeekdays: const [
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ],
      );

      final occurrences = mwf.expandIntoRange(
        DateTime(2026, 11, 23),
        DateTime(2026, 11, 29),
      );
      expect(occurrences.length, 3);
      expect(
        occurrences.map((o) => o.startTime.weekday),
        [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );
    });

    test('Sharing supports multiple co-teachers and detects co-teacher clashes',
        () {
      final day = DateTime(2026, 11, 26);
      final t1 = Teacher(
        id: 't1',
        fullName: 'Sharllote',
        avatarColorHex: 'D93848',
        languages: TeachingLanguageScope.english,
        specializations: const [],
        createdAt: day,
      );
      final t2 = Teacher(
        id: 't2',
        fullName: 'Keith',
        avatarColorHex: '1E66F5',
        languages: TeachingLanguageScope.english,
        specializations: const [],
        createdAt: day,
      );
      final hall = Classroom(
        id: 'hall',
        name: 'Hall',
        capacity: 20,
        equipmentTags: const [],
        createdAt: day,
      );
      final altRoom = Classroom(
        id: 'r2',
        name: '2',
        capacity: 6,
        equipmentTags: const [],
        createdAt: day,
      );

      final sharing = Lesson(
        id: 'sh1',
        title: 'Coffee Sharing',
        language: CourseLanguage.sharing,
        lessonType: LessonType.group,
        teacherId: 't1',
        coTeacherIds: const ['t2'],
        classroomId: 'hall',
        studentIds: const ['s1', 's2'],
        startTime: DateTime(2026, 11, 26, 19, 0),
        endTime: DateTime(2026, 11, 26, 20, 0),
        createdAt: day,
      );

      final clashWithCoTeacher = Lesson(
        id: 'l2',
        title: '1-on-1 IELTS',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't2',
        classroomId: 'r2',
        studentIds: const [],
        startTime: DateTime(2026, 11, 26, 19, 15),
        endTime: DateTime(2026, 11, 26, 20, 15),
        createdAt: day,
      );

      final result = ScheduleConflictDetector.validate(
        candidate: clashWithCoTeacher,
        existingLessons: [sharing],
        teachersById: {'t1': t1, 't2': t2},
        classroomsById: {'hall': hall, 'r2': altRoom},
        studentsById: const {},
      );

      expect(result.hasBlockingConflicts, isTrue);
      expect(
        result.blockingConflicts.first.resourceType,
        ConflictResourceType.teacher,
      );
    });
  });

  group('Operations suite & CSV exporter', () {
    test('CsvExporter quotes commas, quotes, and newlines properly', () {
      final csv = CsvExporter.encode([
        ['Student', 'Notes'],
        ['Olivia, "Oli"', 'Line1\nLine2'],
      ]);
      expect(
        csv,
        'Student,Notes\r\n"Olivia, ""Oli""","Line1\nLine2"',
      );
    });

    test('markAttendance deducts 1 credit on Present and refunds on Excused',
        () async {
      final repo = DemoRealtimeRepository(
        referenceNow: DateTime(2026, 11, 25, 12, 30),
      );
      addTearDown(repo.dispose);

      final students = await repo.watchStudents().first;
      final lessons = await repo.watchLessons().first;
      final student = students.first;
      final lesson = lessons.first;
      final initialCredits = student.remainingCredits;

      await repo.markAttendance(
        lesson: lesson,
        dateKey: '2026-11-25',
        studentId: student.id,
        studentName: student.fullName,
        status: AttendanceStatus.present,
      );

      final afterPresent = (await repo.watchStudents().first)
          .firstWhere((s) => s.id == student.id);
      expect(afterPresent.remainingCredits, initialCredits - 1);

      // Re-marking Present again should not double-deduct
      await repo.markAttendance(
        lesson: lesson,
        dateKey: '2026-11-25',
        studentId: student.id,
        studentName: student.fullName,
        status: AttendanceStatus.present,
      );
      final afterSecondPresent = (await repo.watchStudents().first)
          .firstWhere((s) => s.id == student.id);
      expect(afterSecondPresent.remainingCredits, initialCredits - 1);

      // Changing to Excused refunds 1 credit
      await repo.markAttendance(
        lesson: lesson,
        dateKey: '2026-11-25',
        studentId: student.id,
        studentName: student.fullName,
        status: AttendanceStatus.excused,
      );
      final afterExcused = (await repo.watchStudents().first)
          .firstWhere((s) => s.id == student.id);
      expect(afterExcused.remainingCredits, initialCredits);
    });

    test('recordPayment increments credits and persists payment history',
        () async {
      final repo = DemoRealtimeRepository(
        referenceNow: DateTime(2026, 11, 25, 12, 30),
      );
      addTearDown(repo.dispose);

      final student = (await repo.watchStudents().first).first;
      final beforeCredits = student.remainingCredits;

      await repo.recordPayment(
        PaymentRecord(
          id: 'pay-test-1',
          studentId: student.id,
          studentName: student.fullName,
          amount: 120,
          lessonsPurchased: 12,
          method: PaymentMethod.transfer,
          paidAt: DateTime(2026, 11, 26),
        ),
      );

      final afterCredits = (await repo.watchStudents().first)
          .firstWhere((s) => s.id == student.id)
          .remainingCredits;
      final payments = await repo.watchPayments().first;

      expect(afterCredits, beforeCredits + 12);
      expect(payments.any((p) => p.id == 'pay-test-1'), isTrue);
    });

    test('homework submission, review feedback, trial lead & reschedule round-trip',
        () async {
      final repo = DemoRealtimeRepository(
        referenceNow: DateTime(2026, 11, 25, 12, 30),
      );
      addTearDown(repo.dispose);

      final hw = (await repo.watchHomeworks().first).first;
      await repo.submitHomeworkResponse(
        homeworkId: hw.id,
        submission: HomeworkSubmission(
          studentUid: 'u1',
          studentName: 'Alex Student',
          studentEmail: 'student@gmail.com',
          answerOrLink: 'https://example.com/audio.mp3',
          submittedAt: DateTime(2026, 11, 26, 10, 0),
        ),
      );
      await repo.reviewHomeworkSubmission(
        homeworkId: hw.id,
        studentUid: 'u1',
        feedback: 'Nice tone clarity!',
        reviewed: true,
      );

      final updatedHw = (await repo.watchHomeworks().first)
          .firstWhere((h) => h.id == hw.id);
      final sub = updatedHw.submissionFor('u1');
      expect(sub, isNotNull);
      expect(sub!.reviewed, isTrue);
      expect(sub.teacherFeedback, 'Nice tone clarity!');

      final lead = TrialLead(
        id: 'lead-1',
        fullName: 'Timur Bekov',
        phone: '+996555000111',
        targetLanguage: CourseLanguage.chinese,
        preferredLevel: 'HSK 1',
        stage: LeadStage.trialScheduled,
        createdAt: DateTime(2026, 11, 26),
      );
      final decodedLead = TrialLead.fromMap(lead.toMap());
      expect(decodedLead.fullName, 'Timur Bekov');
      expect(decodedLead.stage, LeadStage.trialScheduled);

      await repo.submitRescheduleRequest(
        RescheduleRequest(
          id: 'req-1',
          studentUid: 'u1',
          studentName: 'Alex Student',
          studentEmail: 'student@gmail.com',
          groupId: 'g1',
          groupName: 'HSK 1 — Foundations',
          requestedDate: DateTime(2026, 11, 28),
          preferredSlot: '6:00 PM',
          reason: 'Exam conflict',
          createdAt: DateTime(2026, 11, 26),
        ),
      );
      await repo.resolveRescheduleRequest(
        requestId: 'req-1',
        status: RequestStatus.approved,
        staffNote: 'Moved to Saturday',
      );
      final reqs = await repo.watchRescheduleRequests().first;
      final resolved = reqs.firstWhere((r) => r.id == 'req-1');
      expect(resolved.status, RequestStatus.approved);
      expect(resolved.staffNote, 'Moved to Saturday');
    });
  });

  group('Security privacy & official center hours', () {
    test('CenterInfo enforces MWF 08:30-19:00, TTS 09:00-18:00, Sun Closed', () {
      final mon = DateTime(2026, 11, 23);
      final tue = DateTime(2026, 11, 24);
      final sun = DateTime(2026, 11, 29);

      expect(CenterInfo.hoursForDate(mon).displayRange, '08:30–19:00');
      expect(CenterInfo.hoursForDate(tue).displayRange, '09:00–18:00');
      expect(CenterInfo.hoursForDate(sun).isOpen, isFalse);

      expect(
        CenterInfo.isWithinWorkingHours(
          DateTime(2026, 11, 23, 8, 30),
          DateTime(2026, 11, 23, 19, 0),
        ),
        isTrue,
      );
      expect(
        CenterInfo.isWithinWorkingHours(
          DateTime(2026, 11, 24, 17, 30),
          DateTime(2026, 11, 24, 19, 0),
        ),
        isFalse,
      );
    });

    test('ScheduleConflictDetector warns when booking on Sunday or off-hours', () {
      final sunday = DateTime(2026, 11, 29, 12, 0);
      final candidate = Lesson(
        id: 'sun-lesson',
        title: 'Sunday Check',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't1',
        classroomId: 'r1',
        studentIds: const [],
        startTime: sunday,
        endTime: sunday.add(const Duration(hours: 1)),
        createdAt: sunday,
      );
      final result = ScheduleConflictDetector.validate(
        candidate: candidate,
        existingLessons: const [],
        teachersById: const {},
        classroomsById: const {},
        studentsById: const {},
      );
      expect(
        result.softWarnings.any((w) => w.contains('closed on Sundays')),
        isTrue,
      );
    });

    test('Public student streams hide Sharing groups, member PII, and teacher rates',
        () async {
      final repo = DemoRealtimeRepository(
        referenceNow: DateTime(2026, 11, 25, 12, 30),
      );
      addTearDown(repo.dispose);

      // Add a staff-only Sharing group
      await repo.upsertGroup(
        StudyGroup(
          id: 'grp_secret_sharing',
          name: 'Private Teacher Sharing Club',
          language: CourseLanguage.sharing,
          level: 'All Levels',
          teacherId: 't_sharllote',
          classroomId: 'room_hall',
          scheduleWeekdays: const [DateTime.friday],
          startHour: 17,
          startMinute: 0,
          members: const [
            GroupMemberPayment(
              memberId: 's1',
              fullName: 'Secret Student',
              email: 'secret@example.com',
              hasPaid: false,
            ),
          ],
          notes: 'Internal staff sharing notes',
          createdAt: DateTime(2026, 11, 26),
        ),
      );

      final staffGroups = await repo.watchGroups().first;
      expect(
        staffGroups.any((g) => g.id == 'grp_secret_sharing'),
        isTrue,
      );

      final studentVisibleGroups = await repo.watchPublicGroups().first;
      expect(
        studentVisibleGroups.any((g) => g.language == CourseLanguage.sharing),
        isFalse,
      );
      expect(
        studentVisibleGroups.every((g) => g.members.isEmpty && g.notes.isEmpty),
        isTrue,
      );

      final publicTeachers = await repo.watchPublicTeachers().first;
      expect(publicTeachers, isNotEmpty);
      expect(
        publicTeachers.every(
          (t) =>
              t.hourlyRate == 0 &&
              t.clubRate == 0 &&
              t.phone.isEmpty &&
              t.email.isEmpty &&
              t.notes.isEmpty,
        ),
        isTrue,
      );

      // Student homeworks returns empty with zero reads when no group joined
      expect(await repo.watchHomeworksForGroups(const []).first, isEmpty);
    });

    test('StudentPortalL10n supports all 6 languages & localized schedules', () {
      expect(PortalLocale.values.length, 6);
      final group = StudyGroup(
        id: 'g1',
        name: 'HSK 1',
        language: CourseLanguage.chinese,
        level: 'HSK 1',
        teacherId: 't1',
        classroomId: 'r1',
        scheduleWeekdays: const [DateTime.monday, DateTime.friday],
        startHour: 10,
        startMinute: 0,
        createdAt: DateTime(2026, 11, 26),
      );

      for (final loc in PortalLocale.values) {
        final l10n = StudentPortalL10n(loc);
        expect(l10n.text('portalTitle'), isNotEmpty);
        expect(l10n.text('creditsLeft', {'n': '5'}), contains('5'));
        expect(l10n.formatSchedule(group), contains('10:00'));
      }

      expect(
        const StudentPortalL10n(PortalLocale.ru).text('portalTitle'),
        'The Word • Кабинет ученика',
      );
      expect(
        const StudentPortalL10n(PortalLocale.zh).formatSchedule(group),
        contains('周一'),
      );
      expect(
        CenterInfo.twoGisUrl,
        contains('70000001036390791'),
      );
    });
  });

  group('Notifications, Events & Auto-Registration v1.7.0', () {
    test('ensureUserRegisteredOnSignIn creates records once without duplicates', () async {
      final repo = DemoRealtimeRepository(referenceNow: DateTime(2026, 11, 26));

      final createdStudent1 = await repo.ensureUserRegisteredOnSignIn(
        uid: 'uid_alice',
        email: 'Alice.Student@Gmail.com',
        displayName: 'Alice Wonderland',
        isStaff: false,
      );
      expect(createdStudent1, isTrue);

      final studentsAfterFirst = await repo.watchStudents().first;
      expect(
        studentsAfterFirst.where((s) => s.email == 'alice.student@gmail.com').length,
        1,
      );

      final createdStudentDup = await repo.ensureUserRegisteredOnSignIn(
        uid: 'uid_alice_second_login',
        email: 'ALICE.STUDENT@gmail.com',
        displayName: 'Alice',
        isStaff: false,
      );
      expect(createdStudentDup, isFalse);
      final studentsAfterDup = await repo.watchStudents().first;
      expect(
        studentsAfterDup.where((s) => s.email == 'alice.student@gmail.com').length,
        1,
      );

      final createdTeacher1 = await repo.ensureUserRegisteredOnSignIn(
        uid: 'uid_teacher_new',
        email: 'New.Staff@theword.kg',
        displayName: 'Elena Coach',
        isStaff: true,
      );
      expect(createdTeacher1, isTrue);

      final createdTeacherDup = await repo.ensureUserRegisteredOnSignIn(
        uid: 'uid_teacher_new',
        email: 'new.staff@theword.kg',
        displayName: 'Elena Coach',
        isStaff: true,
      );
      expect(createdTeacherDup, isFalse);
      await repo.dispose();
    });

    test('Notifications & Events isolate Teachers Only vs Student/Group/Selected targets', () async {
      final repo = DemoRealtimeRepository(referenceNow: DateTime(2026, 11, 26));
      final now = DateTime(2026, 11, 26, 12, 0);

      await repo.upsertNotification(
        AppNotification(
          id: 'n_teachers',
          title: 'Internal Staff Note',
          message: 'Salary & room audit',
          audience: AudienceType.teachersOnly,
          createdAt: now,
        ),
      );
      await repo.upsertNotification(
        AppNotification(
          id: 'n_selected',
          title: 'VIP Speaking Invitation',
          message: 'Room 2 at 16:00',
          audience: AudienceType.selectedUsers,
          targetEmails: const ['target@student.kg'],
          createdAt: now,
        ),
      );
      await repo.upsertNotification(
        AppNotification(
          id: 'n_club_topic',
          title: 'Chinese Club Topic',
          message: 'Come practice tones!',
          category: NotificationCategory.speakingClub,
          clubPreset: SpeakingClubPreset.chineseClub,
          clubTopic: 'Ordering Tea in Beijing',
          audience: AudienceType.studentsOnly,
          createdAt: now,
        ),
      );

      final targetStudentNotifs = await repo
          .watchStudentNotifications(
            uid: 'u_target',
            email: 'Target@Student.kg',
            joinedGroupIds: const ['grp_hsk1_morning'],
          )
          .first;
      final otherStudentNotifs = await repo
          .watchStudentNotifications(
            uid: 'u_other',
            email: 'other@student.kg',
            joinedGroupIds: const [],
          )
          .first;

      expect(targetStudentNotifs.any((n) => n.id == 'n_teachers'), isFalse);
      expect(targetStudentNotifs.any((n) => n.id == 'n_selected'), isTrue);
      expect(targetStudentNotifs.any((n) => n.id == 'n_club_topic'), isTrue);

      expect(otherStudentNotifs.any((n) => n.id == 'n_selected'), isFalse);
      expect(otherStudentNotifs.any((n) => n.id == 'n_teachers'), isFalse);
      expect(otherStudentNotifs.any((n) => n.id == 'n_club_topic'), isTrue);

      await repo.markNotificationRead(
        notificationId: 'n_club_topic',
        uid: 'u_other',
      );
      final afterRead = await repo
          .watchStudentNotifications(
            uid: 'u_other',
            email: 'other@student.kg',
            joinedGroupIds: const [],
          )
          .first;
      final readDoc = afterRead.firstWhere((n) => n.id == 'n_club_topic');
      expect(readDoc.isReadBy('u_other'), isTrue);

      final visibleEventsForStudent = await repo
          .watchStudentEvents(
            uid: 'u_other',
            email: 'other@student.kg',
            joinedGroupIds: const [],
          )
          .first;
      expect(
        visibleEventsForStudent.any((e) => e.audience == AudienceType.teachersOnly),
        isFalse,
      );
      expect(
        visibleEventsForStudent.any((e) => e.isUpcoming(now)),
        isTrue,
      );
      expect(
        visibleEventsForStudent.any((e) => e.isPast(now)),
        isTrue,
      );

      for (final loc in PortalLocale.values) {
        final l10n = StudentPortalL10n(loc);
        expect(l10n.text('notificationsTitle'), isNotEmpty);
        expect(l10n.text('eventsSectionTitle'), isNotEmpty);
      }

      await repo.dispose();
    });
  });
}
