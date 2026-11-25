import 'dart:async';

import '../models/classroom.dart';
import '../models/language_type.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import 'data_repository.dart';

/// In-memory reactive repository backed by replay-capable broadcast streams.
/// Powers instant browser testing when Firebase is not yet configured.
class DemoRealtimeRepository implements DataRepository {
  DemoRealtimeRepository({DateTime? referenceNow}) {
    _seedData(referenceNow ?? DateTime.now());
  }

  final _lessonsCtrl = StreamController<List<Lesson>>.broadcast();
  final _teachersCtrl = StreamController<List<Teacher>>.broadcast();
  final _classroomsCtrl = StreamController<List<Classroom>>.broadcast();
  final _studentsCtrl = StreamController<List<Student>>.broadcast();

  final Map<String, Lesson> _lessons = {};
  final Map<String, Teacher> _teachers = {};
  final Map<String, Classroom> _classrooms = {};
  final Map<String, Student> _students = {};

  bool _disposed = false;

  @override
  bool get isCloudSync => false;

  @override
  String get modeLabel => 'Demo Mode (Live Sync)';

  List<Lesson> _sortedLessons() {
    final list = _lessons.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return List.unmodifiable(list);
  }

  List<Teacher> _sortedTeachers() {
    final list = _teachers.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return List.unmodifiable(list);
  }

  List<Classroom> _sortedClassrooms() {
    final list = _classrooms.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(list);
  }

  List<Student> _sortedStudents() {
    final list = _students.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return List.unmodifiable(list);
  }

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
  Stream<List<Lesson>> watchLessons() =>
      _replayStream(_sortedLessons, _lessonsCtrl.stream);

  @override
  Stream<List<Teacher>> watchTeachers() =>
      _replayStream(_sortedTeachers, _teachersCtrl.stream);

  @override
  Stream<List<Classroom>> watchClassrooms() =>
      _replayStream(_sortedClassrooms, _classroomsCtrl.stream);

  @override
  Stream<List<Student>> watchStudents() =>
      _replayStream(_sortedStudents, _studentsCtrl.stream);

  void _emitLessons() {
    if (!_disposed) _lessonsCtrl.add(_sortedLessons());
  }

  void _emitTeachers() {
    if (!_disposed) _teachersCtrl.add(_sortedTeachers());
  }

  void _emitClassrooms() {
    if (!_disposed) _classroomsCtrl.add(_sortedClassrooms());
  }

  void _emitStudents() {
    if (!_disposed) _studentsCtrl.add(_sortedStudents());
  }

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
  Future<void> dispose() async {
    _disposed = true;
    await Future.wait([
      _lessonsCtrl.close(),
      _teachersCtrl.close(),
      _classroomsCtrl.close(),
      _studentsCtrl.close(),
    ]);
  }

  void _seedData(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    // Teachers
    final teachers = [
      Teacher(
        id: 't_mei',
        fullName: 'Mei Lin',
        avatarColorHex: 'D93848',
        languages: TeachingLanguageScope.chinese,
        specializations: const ['HSK 1-6', 'Business Mandarin', 'Tone Coaching'],
        phone: '+1 (415) 555-0142',
        email: 'mei.lin@theword.center',
        isActive: true,
        notes: 'Lead Mandarin curriculum specialist with 9 years of HSK prep experience.',
        createdAt: today.subtract(const Duration(days: 120)),
      ),
      Teacher(
        id: 't_wei',
        fullName: 'Wei Zhang',
        avatarColorHex: 'F59E42',
        languages: TeachingLanguageScope.chinese,
        specializations: const ['Spoken Chinese', 'HSK 1-6', 'Kids'],
        phone: '+1 (415) 555-0188',
        email: 'wei.zhang@theword.center',
        isActive: true,
        notes: 'Focuses on rapid spoken fluency and interactive storytelling.',
        createdAt: today.subtract(const Duration(days: 95)),
      ),
      Teacher(
        id: 't_eleanor',
        fullName: 'Eleanor Vance',
        avatarColorHex: '1E66F5',
        languages: TeachingLanguageScope.english,
        specializations: const ['IELTS', 'Academic Writing', 'Pronunciation'],
        phone: '+1 (415) 555-0164',
        email: 'eleanor.vance@theword.center',
        isActive: true,
        notes: 'Former IELTS examiner coaching C1-C2 speaking and essay structure.',
        createdAt: today.subtract(const Duration(days: 110)),
      ),
      Teacher(
        id: 't_marcus',
        fullName: 'Marcus Chen',
        avatarColorHex: '6366F1',
        languages: TeachingLanguageScope.both,
        specializations: const ['Business English', 'Spoken Chinese', 'HSK 1-6'],
        phone: '+1 (415) 555-0191',
        email: 'marcus.chen@theword.center',
        isActive: true,
        notes: 'Bilingual executive coach teaching cross-border communication.',
        createdAt: today.subtract(const Duration(days: 80)),
      ),
      Teacher(
        id: 't_sofia',
        fullName: 'Sofia Alvarez',
        avatarColorHex: '06B6D4',
        languages: TeachingLanguageScope.english,
        specializations: const ['Business English', 'Kids', 'Pronunciation'],
        phone: '+1 (415) 555-0123',
        email: 'sofia.alvarez@theword.center',
        isActive: true,
        notes: 'Specializes in confidence-building workshops and young learners.',
        createdAt: today.subtract(const Duration(days: 60)),
      ),
      Teacher(
        id: 't_daniel',
        fullName: 'Daniel Wu',
        avatarColorHex: 'B45309',
        languages: TeachingLanguageScope.chinese,
        specializations: const ['Spoken Chinese', 'Business Mandarin'],
        phone: '+1 (415) 555-0177',
        email: 'daniel.wu@theword.center',
        isActive: false,
        notes: 'On short sabbatical; returns next Monday.',
        createdAt: today.subtract(const Duration(days: 50)),
      ),
    ];
    for (final t in teachers) {
      _teachers[t.id] = t;
    }

    // Classrooms
    final classrooms = [
      Classroom(
        id: 'r_beijing',
        name: 'Room 1 - Beijing',
        capacity: 8,
        equipmentTags: const ['Smartboard', 'Audio System', 'Whiteboard'],
        notes: 'Acoustic studio ideal for Chinese tone drills and small groups.',
        createdAt: today.subtract(const Duration(days: 180)),
      ),
      Classroom(
        id: 'r_shanghai',
        name: 'Room 2 - Shanghai',
        capacity: 6,
        equipmentTags: const ['TV Screen', 'Whiteboard'],
        notes: 'Sunlit seminar room suited for HSK prep and conversation circles.',
        createdAt: today.subtract(const Duration(days: 180)),
      ),
      Classroom(
        id: 'r_london',
        name: 'Room 3 - London',
        capacity: 10,
        equipmentTags: const ['Smartboard', 'TV Screen', 'Audio System'],
        notes: 'Flagship English room with dual displays for IELTS simulations.',
        createdAt: today.subtract(const Duration(days: 180)),
      ),
      Classroom(
        id: 'r_oxford',
        name: 'Room 4 - Oxford',
        capacity: 4,
        equipmentTags: const ['Whiteboard', 'Audio System'],
        notes: 'Quiet 1-on-1 coaching suite.',
        createdAt: today.subtract(const Duration(days: 150)),
      ),
      Classroom(
        id: 'r_online',
        name: 'Online Room',
        capacity: 12,
        equipmentTags: const ['Smartboard', 'Audio System'],
        notes: 'HD Zoom & interactive whiteboard studio for remote learners.',
        createdAt: today.subtract(const Duration(days: 140)),
      ),
    ];
    for (final c in classrooms) {
      _classrooms[c.id] = c;
    }

    // Students
    final students = [
      Student(
        id: 's_olivia',
        fullName: 'Olivia Bennett',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 4',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_mei',
        remainingCredits: 12,
        phone: '+1 (415) 555-0201',
        email: 'olivia.b@example.com',
        notes: 'Preparing for HSK 4 exam in June; strong reading comprehension.',
        createdAt: today.subtract(const Duration(days: 70)),
      ),
      Student(
        id: 's_liam',
        fullName: 'Liam Carter',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 2',
        format: LessonType.group,
        primaryTeacherId: 't_wei',
        remainingCredits: 6,
        phone: '+1 (415) 555-0202',
        email: 'liam.carter@example.com',
        notes: 'Relocating to Shanghai; prioritizing daily conversational Mandarin.',
        createdAt: today.subtract(const Duration(days: 65)),
      ),
      Student(
        id: 's_chloe',
        fullName: 'Chloe Park',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'C1',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_eleanor',
        remainingCredits: 9,
        phone: '+1 (415) 555-0203',
        email: 'chloe.park@example.com',
        notes: 'Targeting IELTS Band 8.0 overall.',
        createdAt: today.subtract(const Duration(days: 55)),
      ),
      Student(
        id: 's_ethan',
        fullName: 'Ethan Zhao',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'B2',
        format: LessonType.group,
        primaryTeacherId: 't_sofia',
        remainingCredits: 2,
        phone: '+1 (415) 555-0204',
        email: 'ethan.zhao@example.com',
        notes: 'Low credit balance — remind before Friday renewal.',
        createdAt: today.subtract(const Duration(days: 45)),
      ),
      Student(
        id: 's_maya',
        fullName: 'Maya Patel',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 5',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_mei',
        remainingCredits: 16,
        phone: '+1 (415) 555-0205',
        email: 'maya.patel@example.com',
        notes: 'Product lead working with Shenzhen hardware partners.',
        createdAt: today.subtract(const Duration(days: 40)),
      ),
      Student(
        id: 's_noah',
        fullName: 'Noah Kim',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'B1',
        format: LessonType.group,
        primaryTeacherId: 't_marcus',
        remainingCredits: 8,
        phone: '+1 (415) 555-0206',
        email: 'noah.kim@example.com',
        notes: 'Attending evening Business English cohort.',
        createdAt: today.subtract(const Duration(days: 35)),
      ),
      Student(
        id: 's_hana',
        fullName: 'Hana Sato',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 3',
        format: LessonType.group,
        primaryTeacherId: 't_wei',
        remainingCredits: 10,
        phone: '+1 (415) 555-0207',
        email: 'hana.sato@example.com',
        notes: 'Very consistent attendance; enjoys character etymology.',
        createdAt: today.subtract(const Duration(days: 28)),
      ),
      Student(
        id: 's_lucas',
        fullName: 'Lucas Meyer',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'A2',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_sofia',
        remainingCredits: 5,
        phone: '+1 (415) 555-0208',
        email: 'lucas.meyer@example.com',
        notes: 'Building foundational fluency and listening comprehension.',
        createdAt: today.subtract(const Duration(days: 21)),
      ),
      Student(
        id: 's_grace',
        fullName: 'Grace Liu',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'C2',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_eleanor',
        remainingCredits: 14,
        phone: '+1 (415) 555-0209',
        email: 'grace.liu@example.com',
        notes: 'Executive presentation and persuasive rhetoric coaching.',
        createdAt: today.subtract(const Duration(days: 15)),
      ),
      Student(
        id: 's_alex',
        fullName: 'Alex Rivera',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 1',
        format: LessonType.group,
        primaryTeacherId: 't_marcus',
        remainingCredits: 7,
        phone: '+1 (415) 555-0210',
        email: 'alex.rivera@example.com',
        notes: 'Beginner Mandarin cohort; focused on pinyin and tones.',
        createdAt: today.subtract(const Duration(days: 10)),
      ),
    ];
    for (final s in students) {
      _students[s.id] = s;
    }

    // Build two live "Happening Now" slots cleanly inside today's calendar day.
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
      // Happening Right Now #1 (Chinese)
      Lesson(
        id: 'l_live_1',
        title: 'HSK 4 Intensive Reading & Tones',
        language: CourseLanguage.chinese,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_mei',
        classroomId: 'r_beijing',
        studentIds: const ['s_olivia'],
        startTime: liveStart1,
        endTime: liveEnd1,
        status: LessonStatus.inProgress,
        notes: 'Mock Section 2 reading drills and tone pair polishing.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      // Happening Right Now #2 (English)
      Lesson(
        id: 'l_live_2',
        title: 'IELTS Band 8 Speaking Lab',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_eleanor',
        classroomId: 'r_london',
        studentIds: const ['s_chloe'],
        startTime: liveStart2,
        endTime: liveEnd2,
        status: LessonStatus.inProgress,
        notes: 'Part 2 cue cards & lexical cohesion feedback.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      // Earlier & Later Today (non-overlapping with live slots where same resource)
      ..._buildNonConflictingTodayLessons(today, liveStart1, liveEnd2),
      // Tomorrow & Week lessons
      Lesson(
        id: 'l_tom_1',
        title: 'Business Mandarin Negotiation',
        language: CourseLanguage.chinese,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_mei',
        classroomId: 'r_beijing',
        studentIds: const ['s_maya'],
        startTime: today.add(const Duration(days: 1, hours: 10)),
        endTime: today.add(const Duration(days: 1, hours: 11, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Contract terminology and polite disagreement phrases.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Lesson(
        id: 'l_tom_2',
        title: 'B2 Spoken Fluency Workshop',
        language: CourseLanguage.english,
        lessonType: LessonType.group,
        teacherId: 't_sofia',
        classroomId: 'r_london',
        studentIds: const ['s_ethan', 's_noah'],
        startTime: today.add(const Duration(days: 1, hours: 14)),
        endTime: today.add(const Duration(days: 1, hours: 15, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Real-world case debates and idiom practice.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Lesson(
        id: 'l_day2_1',
        title: 'Mandarin Foundations: Pinyin & Tones',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_marcus',
        classroomId: 'r_shanghai',
        studentIds: const ['s_alex', 's_liam'],
        startTime: today.add(const Duration(days: 2, hours: 16)),
        endTime: today.add(const Duration(days: 2, hours: 17)),
        status: LessonStatus.scheduled,
        notes: 'Tone sandhi rules and everyday greetings.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      Lesson(
        id: 'l_day3_1',
        title: 'Executive English Rhetoric',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_eleanor',
        classroomId: 'r_online',
        studentIds: const ['s_grace'],
        startTime: today.add(const Duration(days: 3, hours: 11)),
        endTime: today.add(const Duration(days: 3, hours: 12)),
        status: LessonStatus.scheduled,
        notes: 'Keynote delivery pacing and executive Q&A.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      Lesson(
        id: 'l_day4_1',
        title: 'HSK 2-3 Conversation Circle',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_wei',
        classroomId: 'r_beijing',
        studentIds: const ['s_liam', 's_hana'],
        startTime: today.add(const Duration(days: 4, hours: 15)),
        endTime: today.add(const Duration(days: 4, hours: 16, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Travel, dining, and metro navigation roleplay.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ];

    for (final l in lessons) {
      _lessons[l.id] = l;
    }
  }

  List<Lesson> _buildNonConflictingTodayLessons(
    DateTime today,
    DateTime liveStart1,
    DateTime liveEnd2,
  ) {
    final candidates = [
      Lesson(
        id: 'l_today_early_1',
        title: 'HSK 5 Business Vocabulary',
        language: CourseLanguage.chinese,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_mei',
        classroomId: 'r_shanghai',
        studentIds: const ['s_maya'],
        startTime: today.add(const Duration(hours: 9)),
        endTime: today.add(const Duration(hours: 10)),
        status: LessonStatus.completed,
        notes: 'Completed supply-chain case reading.',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      Lesson(
        id: 'l_today_early_2',
        title: 'A2 Everyday English Foundations',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_sofia',
        classroomId: 'r_oxford',
        studentIds: const ['s_lucas'],
        startTime: today.add(const Duration(hours: 10, minutes: 30)),
        endTime: today.add(const Duration(hours: 11, minutes: 30)),
        status: LessonStatus.completed,
        notes: 'Past continuous storytelling exercises.',
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      Lesson(
        id: 'l_today_mid_1',
        title: 'HSK 2–3 Spoken Mandarin Lab',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_wei',
        classroomId: 'r_shanghai',
        studentIds: const ['s_liam', 's_hana'],
        startTime: today.add(const Duration(hours: 14)),
        endTime: today.add(const Duration(hours: 15, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Interactive roleplay and tone cadence check.',
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      Lesson(
        id: 'l_today_mid_2',
        title: 'Business English Writing Sprint',
        language: CourseLanguage.english,
        lessonType: LessonType.group,
        teacherId: 't_marcus',
        classroomId: 'r_online',
        studentIds: const ['s_ethan', 's_noah'],
        startTime: today.add(const Duration(hours: 16)),
        endTime: today.add(const Duration(hours: 17, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Executive email clarity & concise summaries.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Lesson(
        id: 'l_today_eve_1',
        title: 'HSK 1 Pinyin Bootcamp',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_wei',
        classroomId: 'r_beijing',
        studentIds: const ['s_alex'],
        startTime: today.add(const Duration(hours: 18, minutes: 30)),
        endTime: today.add(const Duration(hours: 19, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Initials, finals, and 4-tone recognition drill.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      Lesson(
        id: 'l_today_eve_2',
        title: 'C2 Executive Rhetoric Coaching',
        language: CourseLanguage.english,
        lessonType: LessonType.oneOnOne,
        teacherId: 't_eleanor',
        classroomId: 'r_oxford',
        studentIds: const ['s_grace'],
        startTime: today.add(const Duration(hours: 19, minutes: 30)),
        endTime: today.add(const Duration(hours: 20, minutes: 30)),
        status: LessonStatus.scheduled,
        notes: 'Board presentation dry-run.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    ];

    // Ensure none of the fixed-hour lessons overlap with the dynamic live slots.
    final now = DateTime.now();
    return candidates.where((c) {
      final overlapsLive = c.overlapsWith(liveStart1, liveEnd2);
      return !overlapsLive;
    }).map((c) {
      if (c.status == LessonStatus.completed && c.startTime.isAfter(now)) {
        return c.copyWith(status: LessonStatus.scheduled);
      }
      if (c.status == LessonStatus.scheduled && c.endTime.isBefore(now)) {
        return c.copyWith(status: LessonStatus.completed);
      }
      return c;
    }).toList();
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
