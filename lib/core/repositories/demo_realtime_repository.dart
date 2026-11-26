import 'dart:async';

import '../models/classroom.dart';
import '../models/homework.dart';
import '../models/language_type.dart';
import '../models/lesson.dart';
import '../models/operations_models.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/teacher.dart';
import 'center_seed_data.dart';
import 'data_repository.dart';

/// In-memory reactive repository backed by replay-capable broadcast streams.
class DemoRealtimeRepository implements DataRepository {
  DemoRealtimeRepository({DateTime? referenceNow}) {
    _seedData(referenceNow ?? DateTime.now());
  }

  final _lessonsCtrl = StreamController<List<Lesson>>.broadcast();
  final _teachersCtrl = StreamController<List<Teacher>>.broadcast();
  final _classroomsCtrl = StreamController<List<Classroom>>.broadcast();
  final _studentsCtrl = StreamController<List<Student>>.broadcast();
  final _groupsCtrl = StreamController<List<StudyGroup>>.broadcast();
  final _homeworksCtrl = StreamController<List<HomeworkAssignment>>.broadcast();
  final _profilesCtrl = StreamController<Map<String, StudentPortalProfile>>.broadcast();
  final _attendanceCtrl = StreamController<List<AttendanceRecord>>.broadcast();
  final _paymentsCtrl = StreamController<List<PaymentRecord>>.broadcast();
  final _leadsCtrl = StreamController<List<TrialLead>>.broadcast();
  final _requestsCtrl = StreamController<List<RescheduleRequest>>.broadcast();
  final _activityCtrl = StreamController<List<ActivityLogEntry>>.broadcast();

  final Map<String, Lesson> _lessons = {};
  final Map<String, Teacher> _teachers = {};
  final Map<String, Classroom> _classrooms = {};
  final Map<String, Student> _students = {};
  final Map<String, StudyGroup> _groups = {};
  final Map<String, HomeworkAssignment> _homeworks = {};
  final Map<String, StudentPortalProfile> _profiles = {};
  final Map<String, AttendanceRecord> _attendance = {};
  final Map<String, PaymentRecord> _payments = {};
  final Map<String, TrialLead> _leads = {};
  final Map<String, RescheduleRequest> _requests = {};
  final List<ActivityLogEntry> _activity = [];

  bool _disposed = false;

  @override
  bool get isCloudSync => false;

  @override
  String get modeLabel => 'Demo Mode (Live Sync)';

  List<Lesson> _sortedLessons() =>
      List.unmodifiable(_lessons.values.toList()..sort((a, b) => a.startTime.compareTo(b.startTime)));
  List<Teacher> _sortedTeachers() =>
      List.unmodifiable(_teachers.values.toList()..sort((a, b) => a.fullName.compareTo(b.fullName)));
  List<Classroom> _sortedClassrooms() =>
      List.unmodifiable(_classrooms.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
  List<Student> _sortedStudents() =>
      List.unmodifiable(_students.values.toList()..sort((a, b) => a.fullName.compareTo(b.fullName)));
  List<StudyGroup> _sortedGroups() =>
      List.unmodifiable(_groups.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
  List<HomeworkAssignment> _sortedHomeworks() =>
      List.unmodifiable(_homeworks.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  List<AttendanceRecord> _sortedAttendance() =>
      List.unmodifiable(_attendance.values.toList()..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)));
  List<PaymentRecord> _sortedPayments() =>
      List.unmodifiable(_payments.values.toList()..sort((a, b) => b.paidAt.compareTo(a.paidAt)));
  List<TrialLead> _sortedLeads() =>
      List.unmodifiable(_leads.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  List<RescheduleRequest> _sortedRequests() =>
      List.unmodifiable(_requests.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  List<ActivityLogEntry> _sortedActivity() =>
      List.unmodifiable(_activity);

  Stream<T> _replayStream<T>(T Function() snapshot, Stream<T> updates) {
    return Stream<T>.multi((controller) {
      controller.add(snapshot());
      final sub = updates.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<Lesson>> watchLessons() => _replayStream(_sortedLessons, _lessonsCtrl.stream);
  @override
  Stream<List<Teacher>> watchTeachers() => _replayStream(_sortedTeachers, _teachersCtrl.stream);
  @override
  Stream<List<Teacher>> watchPublicTeachers() => _replayStream(
        () => _sortedTeachers()
            .map(
              (t) => Teacher(
                id: t.id,
                fullName: t.fullName,
                avatarColorHex: t.avatarColorHex,
                languages: t.languages,
                specializations: const [],
                isActive: t.isActive,
                hourlyRate: 0,
                clubRate: 0,
                createdAt: t.createdAt,
              ),
            )
            .toList(growable: false),
        _teachersCtrl.stream.map(
          (list) => list
              .map(
                (t) => Teacher(
                  id: t.id,
                  fullName: t.fullName,
                  avatarColorHex: t.avatarColorHex,
                  languages: t.languages,
                  specializations: const [],
                  isActive: t.isActive,
                  hourlyRate: 0,
                  clubRate: 0,
                  createdAt: t.createdAt,
                ),
              )
              .toList(growable: false),
        ),
      );
  @override
  Stream<List<Classroom>> watchClassrooms() => _replayStream(_sortedClassrooms, _classroomsCtrl.stream);
  @override
  Stream<List<Student>> watchStudents() => _replayStream(_sortedStudents, _studentsCtrl.stream);
  @override
  Stream<Student?> watchMyStudentRecord(String email) {
    final norm = email.trim().toLowerCase();
    if (norm.isEmpty) return Stream.value(null);
    Student? match(List<Student> list) {
      for (final s in list) {
        if (s.email.trim().toLowerCase() == norm) return s;
      }
      return null;
    }
    return _replayStream(
      () => match(_sortedStudents()),
      _studentsCtrl.stream.map(match),
    );
  }
  @override
  Stream<List<StudyGroup>> watchGroups() => _replayStream(_sortedGroups, _groupsCtrl.stream);
  @override
  Stream<List<StudyGroup>> watchPublicGroups() {
    List<StudyGroup> filter(List<StudyGroup> list) => list
        .where((g) => g.language != CourseLanguage.sharing)
        .map((g) => g.copyWith(members: const [], notes: ''))
        .toList(growable: false);
    return _replayStream(
      () => filter(_sortedGroups()),
      _groupsCtrl.stream.map(filter),
    );
  }
  @override
  Stream<List<HomeworkAssignment>> watchHomeworks() => _replayStream(_sortedHomeworks, _homeworksCtrl.stream);
  @override
  Stream<List<HomeworkAssignment>> watchHomeworksForGroups(List<String> groupIds) {
    final idSet = groupIds.where((e) => e.isNotEmpty).toSet();
    if (idSet.isEmpty) return Stream.value(const []);
    List<HomeworkAssignment> filter(List<HomeworkAssignment> list) => list
        .where((h) => h.language != CourseLanguage.sharing && idSet.contains(h.groupId))
        .toList(growable: false);
    return _replayStream(
      () => filter(_sortedHomeworks()),
      _homeworksCtrl.stream.map(filter),
    );
  }
  @override
  Stream<List<HomeworkSubmission>> watchAllHomeworkSubmissions() {
    List<HomeworkSubmission> collect(List<HomeworkAssignment> list) => [
          for (final h in list)
            for (final s in h.submissions) s.copyWith(homeworkId: h.id),
        ];
    return _replayStream(
      () => collect(_sortedHomeworks()),
      _homeworksCtrl.stream.map(collect),
    );
  }
  @override
  Stream<List<HomeworkSubmission>> watchMyHomeworkSubmissions(String studentUid) {
    if (studentUid.isEmpty) return Stream.value(const []);
    List<HomeworkSubmission> collect(List<HomeworkAssignment> list) => [
          for (final h in list)
            for (final s in h.submissions)
              if (s.studentUid == studentUid) s.copyWith(homeworkId: h.id),
        ];
    return _replayStream(
      () => collect(_sortedHomeworks()),
      _homeworksCtrl.stream.map(collect),
    );
  }
  @override
  Stream<List<AttendanceRecord>> watchAttendance() => _replayStream(_sortedAttendance, _attendanceCtrl.stream);
  @override
  Stream<List<PaymentRecord>> watchPayments() => _replayStream(_sortedPayments, _paymentsCtrl.stream);
  @override
  Stream<List<TrialLead>> watchTrialLeads() => _replayStream(_sortedLeads, _leadsCtrl.stream);
  @override
  Stream<List<RescheduleRequest>> watchRescheduleRequests() => _replayStream(_sortedRequests, _requestsCtrl.stream);
  @override
  Stream<List<RescheduleRequest>> watchMyRescheduleRequests(String studentUid) {
    if (studentUid.isEmpty) return Stream.value(const []);
    List<RescheduleRequest> filter(List<RescheduleRequest> list) => list
        .where((r) => r.studentUid == studentUid)
        .toList(growable: false);
    return _replayStream(
      () => filter(_sortedRequests()),
      _requestsCtrl.stream.map(filter),
    );
  }
  @override
  Stream<List<ActivityLogEntry>> watchActivityLogs() => _replayStream(_sortedActivity, _activityCtrl.stream);

  @override
  Stream<StudentPortalProfile> watchStudentPortalProfile({
    required String uid,
    required String email,
    String? displayName,
  }) {
    StudentPortalProfile current() =>
        _profiles[uid] ??
        StudentPortalProfile(
          uid: uid,
          email: email,
          fullName: displayName ?? 'Student',
        );
    return _replayStream(current, _profilesCtrl.stream.map((_) => current()));
  }

  void _emitLessons() { if (!_disposed) _lessonsCtrl.add(_sortedLessons()); }
  void _emitTeachers() { if (!_disposed) _teachersCtrl.add(_sortedTeachers()); }
  void _emitClassrooms() { if (!_disposed) _classroomsCtrl.add(_sortedClassrooms()); }
  void _emitStudents() { if (!_disposed) _studentsCtrl.add(_sortedStudents()); }
  void _emitGroups() { if (!_disposed) _groupsCtrl.add(_sortedGroups()); }
  void _emitHomeworks() { if (!_disposed) _homeworksCtrl.add(_sortedHomeworks()); }
  void _emitAttendance() { if (!_disposed) _attendanceCtrl.add(_sortedAttendance()); }
  void _emitPayments() { if (!_disposed) _paymentsCtrl.add(_sortedPayments()); }
  void _emitLeads() { if (!_disposed) _leadsCtrl.add(_sortedLeads()); }
  void _emitRequests() { if (!_disposed) _requestsCtrl.add(_sortedRequests()); }
  void _emitActivity() { if (!_disposed) _activityCtrl.add(_sortedActivity()); }

  @override
  Future<void> upsertLesson(Lesson lesson) async {
    _lessons[lesson.id] = lesson;
    _emitLessons();
  }

  @override
  Future<void> deleteLesson(String lessonId) async {
    _lessons.remove(lessonId);
    _emitLessons();
  }

  @override
  Future<void> upsertTeacher(Teacher teacher) async {
    _teachers[teacher.id] = teacher;
    _emitTeachers();
  }

  @override
  Future<void> deleteTeacher(String teacherId) async {
    _teachers.remove(teacherId);
    _emitTeachers();
  }

  @override
  Future<void> upsertClassroom(Classroom classroom) async {
    _classrooms[classroom.id] = classroom;
    _emitClassrooms();
  }

  @override
  Future<void> deleteClassroom(String classroomId) async {
    _classrooms.remove(classroomId);
    _emitClassrooms();
  }

  @override
  Future<void> upsertStudent(Student student) async {
    _students[student.id] = student;
    _emitStudents();
  }

  @override
  Future<void> adjustStudentCredits(String studentId, int delta) async {
    final student = _students[studentId];
    if (student == null) return;
    final nextCredits = (student.remainingCredits + delta).clamp(0, 999);
    _students[studentId] = student.copyWith(remainingCredits: nextCredits);
    _emitStudents();
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    _students.remove(studentId);
    _emitStudents();
  }

  @override
  Future<void> upsertGroup(StudyGroup group) async {
    _groups[group.id] = group;
    _emitGroups();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _groups.remove(groupId);
    _emitGroups();
  }

  @override
  Future<void> upsertHomework(HomeworkAssignment homework) async {
    _homeworks[homework.id] = homework;
    _emitHomeworks();
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    _homeworks.remove(homeworkId);
    _emitHomeworks();
  }

  @override
  Future<void> toggleHomeworkCompletion({
    required String homeworkId,
    required String uid,
    required bool completed,
  }) async {
    final hw = _homeworks[homeworkId];
    if (hw == null) return;
    final set = {...hw.completedByUids};
    if (completed) {
      set.add(uid);
    } else {
      set.remove(uid);
    }
    _homeworks[homeworkId] = hw.copyWith(completedByUids: set.toList());
    _emitHomeworks();
  }

  @override
  Future<void> submitHomeworkResponse({
    required String homeworkId,
    required HomeworkSubmission submission,
  }) async {
    final hw = _homeworks[homeworkId];
    if (hw == null) return;
    final subs = hw.submissions
        .where((s) => s.studentUid != submission.studentUid)
        .toList()
      ..add(submission);
    final done = {...hw.completedByUids, submission.studentUid}.toList();
    _homeworks[homeworkId] = hw.copyWith(
      submissions: subs,
      completedByUids: done,
    );
    _emitHomeworks();
  }

  @override
  Future<void> reviewHomeworkSubmission({
    required String homeworkId,
    required String studentUid,
    required String feedback,
    required bool reviewed,
  }) async {
    final hw = _homeworks[homeworkId];
    if (hw == null) return;
    final subs = hw.submissions.map((s) {
      if (s.studentUid != studentUid) return s;
      return s.copyWith(teacherFeedback: feedback, reviewed: reviewed);
    }).toList();
    _homeworks[homeworkId] = hw.copyWith(submissions: subs);
    _emitHomeworks();
  }

  @override
  Future<void> saveStudentPortalProfile(StudentPortalProfile profile) async {
    _profiles[profile.uid] = profile;
    if (!_disposed) _profilesCtrl.add(Map.unmodifiable(_profiles));
  }

  @override
  Future<void> markAttendance({
    required Lesson lesson,
    required String dateKey,
    required String studentId,
    required String studentName,
    required AttendanceStatus status,
  }) async {
    final id = AttendanceRecord.buildId(lesson.id, dateKey, studentId);
    final prev = _attendance[id];
    final wasDeducted = prev?.creditDeducted ?? false;
    final shouldDeduct = status == AttendanceStatus.present;

    if (!wasDeducted && shouldDeduct) {
      await adjustStudentCredits(studentId, -1);
    } else if (wasDeducted && !shouldDeduct) {
      await adjustStudentCredits(studentId, 1);
    }

    _attendance[id] = AttendanceRecord(
      id: id,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      dateKey: dateKey,
      studentId: studentId,
      studentName: studentName,
      teacherId: lesson.teacherId,
      status: status,
      creditDeducted: shouldDeduct,
      recordedAt: DateTime.now(),
    );
    _emitAttendance();
  }

  @override
  Future<void> recordPayment(
    PaymentRecord payment, {
    bool addCreditsToStudent = true,
  }) async {
    _payments[payment.id] = payment;
    if (addCreditsToStudent &&
        payment.studentId.isNotEmpty &&
        payment.lessonsPurchased > 0) {
      await adjustStudentCredits(payment.studentId, payment.lessonsPurchased);
    }
    _emitPayments();
  }

  @override
  Future<void> upsertTrialLead(TrialLead lead) async {
    _leads[lead.id] = lead;
    _emitLeads();
  }

  @override
  Future<void> deleteTrialLead(String leadId) async {
    _leads.remove(leadId);
    _emitLeads();
  }

  @override
  Future<void> submitRescheduleRequest(RescheduleRequest request) async {
    _requests[request.id] = request;
    _emitRequests();
  }

  @override
  Future<void> resolveRescheduleRequest({
    required String requestId,
    required RequestStatus status,
    required String staffNote,
  }) async {
    final existing = _requests[requestId];
    if (existing == null) return;
    _requests[requestId] = existing.copyWith(
      status: status,
      staffNote: staffNote,
    );
    _emitRequests();
  }

  @override
  Future<void> logActivity(ActivityLogEntry entry) async {
    _activity.insert(0, entry);
    if (_activity.length > 200) _activity.removeLast();
    _emitActivity();
  }

  @override
  Future<void> seedInitialCenterDataIfNeeded({bool force = false}) async {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    await Future.wait([
      _lessonsCtrl.close(),
      _teachersCtrl.close(),
      _classroomsCtrl.close(),
      _studentsCtrl.close(),
      _groupsCtrl.close(),
      _homeworksCtrl.close(),
      _profilesCtrl.close(),
      _attendanceCtrl.close(),
      _paymentsCtrl.close(),
      _leadsCtrl.close(),
      _requestsCtrl.close(),
      _activityCtrl.close(),
    ]);
  }

  void _seedData(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    for (final t in CenterSeedData.buildTeachers(now)) {
      _teachers[t.id] = t;
    }
    for (final c in CenterSeedData.buildClassrooms(now)) {
      _classrooms[c.id] = c;
    }
    for (final s in CenterSeedData.buildDemoStudents(now)) {
      _students[s.id] = s;
    }
    for (final g in CenterSeedData.buildStudyGroups(now)) {
      _groups[g.id] = g;
    }
    for (final hw in CenterSeedData.buildDemoHomeworks(now)) {
      _homeworks[hw.id] = hw;
    }
    for (final club in CenterSeedData.buildSaturdayClubs(now)) {
      _lessons[club.id] = club;
    }

    final liveStart1 = _clampSameDay(
      now.subtract(const Duration(minutes: 20)),
      today,
      fallbackHour: 10,
    );
    final liveEnd1 = _clampSameDayEnd(
      liveStart1.add(const Duration(minutes: 60)),
      today,
    );

    final liveStart2 = _clampSameDay(
      now.subtract(const Duration(minutes: 10)),
      today,
      fallbackHour: 11,
    );
    final liveEnd2 = _clampSameDayEnd(
      liveStart2.add(const Duration(minutes: 55)),
      today,
    );

    final lessons = <Lesson>[
      Lesson(
        id: 'l_live_1',
        title: 'HSK 4 Intensive Reading & Tones',
        language: CourseLanguage.chinese,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_olga',
        classroomId: 'room_1',
        studentIds: const ['s_olivia'],
        startTime: liveStart1,
        endTime: liveEnd1,
        status: LessonStatus.inProgress,
        notes: 'Tone pair polishing and reading drills.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      Lesson(
        id: 'l_live_2',
        title: 'IELTS Speaking Lab',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_keith',
        classroomId: 'room_3',
        studentIds: const ['s_chloe'],
        startTime: liveStart2,
        endTime: liveEnd2,
        status: LessonStatus.inProgress,
        notes: 'Part 2 cue cards & fluency feedback.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      Lesson(
        id: 'l_mwf_mandarin',
        title: 'HSK 2 Spoken Mandarin (MWF)',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_sharllote',
        classroomId: 'room_2',
        studentIds: const ['s_liam'],
        startTime: DateTime(today.year, today.month, today.day, 18, 0)
            .subtract(const Duration(days: 7)),
        endTime: DateTime(today.year, today.month, today.day, 19, 30)
            .subtract(const Duration(days: 7)),
        status: LessonStatus.scheduled,
        notes: 'Recurring Monday / Wednesday / Friday evening group.',
        createdAt: today.subtract(const Duration(days: 7)),
        recurrenceWeekdays: const [
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ],
      ),
      Lesson(
        id: 'l_tth_english',
        title: 'B2 Business English (Tue/Thu)',
        language: CourseLanguage.english,
        lessonType: LessonType.group,
        teacherId: 't_andrew',
        classroomId: 'room_4',
        studentIds: const ['s_ethan', 's_noah'],
        startTime: DateTime(today.year, today.month, today.day, 16, 30)
            .subtract(const Duration(days: 7)),
        endTime: DateTime(today.year, today.month, today.day, 18, 0)
            .subtract(const Duration(days: 7)),
        status: LessonStatus.scheduled,
        notes: 'Recurring Tuesday / Thursday conversation workshop.',
        createdAt: today.subtract(const Duration(days: 7)),
        recurrenceWeekdays: const [DateTime.tuesday, DateTime.thursday],
      ),
      Lesson(
        id: 'l_sharing_1',
        title: 'Student Coffee & Life Sharing',
        language: CourseLanguage.sharing,
        lessonType: LessonType.group,
        teacherId: 't_sharllote',
        coTeacherIds: const ['t_andrew'],
        classroomId: 'room_hall',
        studentIds: const ['s_olivia', 's_liam', 's_chloe', 's_ethan'],
        startTime: today.add(const Duration(hours: 17)),
        endTime: today.add(const Duration(hours: 18)),
        status: LessonStatus.scheduled,
        notes: 'Open casual chat session (Sharing — visible to teachers only).',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ];

    for (final l in lessons) {
      _lessons[l.id] = l;
    }

    // Seed sample payments, trial leads, reschedule request, and activity logs
    _payments['pay_1'] = PaymentRecord(
      id: 'pay_1',
      studentId: 's_olivia',
      studentName: 'Olivia Bennett',
      groupId: 'grp_hsk2_mwf',
      amount: 180,
      lessonsPurchased: 12,
      method: PaymentMethod.transfer,
      notes: 'HSK 2 12-lesson package',
      paidAt: today.subtract(const Duration(days: 2)),
      recordedBy: 'staff@theword.center',
    );
    _payments['pay_2'] = PaymentRecord(
      id: 'pay_2',
      studentId: 's_chloe',
      studentName: 'Chloe Park',
      amount: 240,
      lessonsPurchased: 12,
      method: PaymentMethod.card,
      notes: '1-on-1 IELTS coaching package',
      paidAt: today.subtract(const Duration(days: 1)),
      recordedBy: 'staff@theword.center',
    );

    _leads['lead_1'] = TrialLead(
      id: 'lead_1',
      fullName: 'Daniel Park',
      phone: '+1 (415) 555-0311',
      email: 'daniel.p@example.com',
      targetLanguage: CourseLanguage.chinese,
      preferredLevel: 'HSK 1',
      stage: LeadStage.trialScheduled,
      trialDate: today.add(const Duration(days: 1, hours: 15)),
      notes: 'Interested in HSK 1 morning cohort.',
      createdAt: today.subtract(const Duration(days: 1)),
    );
    _leads['lead_2'] = TrialLead(
      id: 'lead_2',
      fullName: 'Emma Lin',
      phone: '+1 (415) 555-0398',
      targetLanguage: CourseLanguage.english,
      preferredLevel: 'B2',
      stage: LeadStage.newLead,
      notes: 'Looking for evening speaking practice.',
      createdAt: today,
    );

    _requests['req_1'] = RescheduleRequest(
      id: 'req_1',
      studentUid: 's_liam',
      studentName: 'Liam Carter',
      studentEmail: 'liam.carter@example.com',
      groupId: 'grp_hsk1_morning',
      groupName: 'HSK 1 — Foundations',
      requestedDate: today.add(const Duration(days: 2)),
      preferredSlot: 'Friday 4:00 PM',
      reason: 'University lab conflict this Wednesday.',
      status: RequestStatus.pending,
      createdAt: today,
    );

    _activity.addAll([
      ActivityLogEntry(
        id: 'act_1',
        actorEmail: 'olga@theword.center',
        category: 'Homework',
        summary: 'Assigned "HSK 1 Unit 3 Tone Drills & Audio" to HSK 1 — Foundations',
        createdAt: today.subtract(const Duration(hours: 3)),
      ),
      ActivityLogEntry(
        id: 'act_2',
        actorEmail: 'keith@theword.center',
        category: 'Finance',
        summary: 'Recorded \$240 payment (12 lessons) for Chloe Park',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  DateTime _clampSameDay(
    DateTime candidate,
    DateTime dayStart, {
    required int fallbackHour,
  }) {
    if (candidate.year == dayStart.year &&
        candidate.month == dayStart.month &&
        candidate.day == dayStart.day) {
      return candidate;
    }
    return dayStart.add(Duration(hours: fallbackHour));
  }

  DateTime _clampSameDayEnd(DateTime candidate, DateTime dayStart) {
    final dayEnd = DateTime(dayStart.year, dayStart.month, dayStart.day, 23, 59);
    if (candidate.isAfter(dayEnd)) {
      return dayEnd;
    }
    return candidate;
  }
}
