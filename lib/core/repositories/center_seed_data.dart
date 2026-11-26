import '../models/classroom.dart';
import '../models/homework.dart';
import '../models/language_type.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/teacher.dart';

/// Canonical classrooms, teachers, students, and recurring Saturday Speaking Clubs
/// for "The Word" language center.
abstract final class CenterSeedData {
  static const String clubChineseId = 'club_sat_chinese';
  static const String clubEnglishId = 'club_sat_english';

  static List<Classroom> buildClassrooms(DateTime now) {
    final created = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 90));
    return [
      Classroom(
        id: 'room_1',
        name: '1',
        capacity: 6,
        equipmentTags: const ['Whiteboard', 'Audio System'],
        notes: 'Classroom 1 — compact group and 1-on-1 study room.',
        createdAt: created,
      ),
      Classroom(
        id: 'room_2',
        name: '2',
        capacity: 6,
        equipmentTags: const ['TV Screen', 'Whiteboard'],
        notes: 'Classroom 2 — bright seminar room.',
        createdAt: created,
      ),
      Classroom(
        id: 'room_3',
        name: '3',
        capacity: 8,
        equipmentTags: const ['Smartboard', 'Whiteboard'],
        notes: 'Classroom 3 — interactive smartboard setup.',
        createdAt: created,
      ),
      Classroom(
        id: 'room_4',
        name: '4',
        capacity: 6,
        equipmentTags: const ['Whiteboard', 'Audio System'],
        notes: 'Classroom 4 — quiet acoustic study room.',
        createdAt: created,
      ),
      Classroom(
        id: 'room_5',
        name: '5',
        capacity: 8,
        equipmentTags: const ['TV Screen', 'Audio System', 'Whiteboard'],
        notes: 'Classroom 5 — multimedia speaking practice room.',
        createdAt: created,
      ),
      Classroom(
        id: 'room_hall',
        name: 'Hall',
        capacity: 20,
        equipmentTags: const ['Smartboard', 'Audio System', 'TV Screen'],
        notes: 'Main Hall — Saturday Chinese & English Speaking Clubs and workshops.',
        createdAt: created,
      ),
      Classroom(
        id: 'room_old_center',
        name: 'OldCenter',
        capacity: 10,
        equipmentTags: const ['Whiteboard', 'TV Screen'],
        notes: 'OldCenter annex classroom.',
        createdAt: created,
      ),
    ];
  }

  static List<Teacher> buildTeachers(DateTime now) {
    final created = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 90));
    return [
      Teacher(
        id: 't_sharllote',
        fullName: 'Sharllote',
        avatarColorHex: 'D93848',
        languages: TeachingLanguageScope.both,
        specializations: const ['Spoken English', 'HSK 1-6', 'Speaking Club'],
        isActive: true,
        createdAt: created,
      ),
      Teacher(
        id: 't_keith',
        fullName: 'Keith',
        avatarColorHex: '1E66F5',
        languages: TeachingLanguageScope.english,
        specializations: const ['IELTS', 'Business English', 'Speaking Club'],
        isActive: true,
        createdAt: created,
      ),
      Teacher(
        id: 't_andrew',
        fullName: 'Andrew',
        avatarColorHex: '06B6D4',
        languages: TeachingLanguageScope.english,
        specializations: const ['Conversational English', 'Pronunciation', 'Kids'],
        isActive: true,
        createdAt: created,
      ),
      Teacher(
        id: 't_sofia',
        fullName: 'Sofia',
        avatarColorHex: '6366F1',
        languages: TeachingLanguageScope.both,
        specializations: const ['Business English', 'Spoken Chinese', 'Teens'],
        isActive: true,
        createdAt: created,
      ),
      Teacher(
        id: 't_olga',
        fullName: 'Olga',
        avatarColorHex: 'F59E42',
        languages: TeachingLanguageScope.chinese,
        specializations: const ['HSK 1-6', 'Spoken Chinese', 'Speaking Club'],
        isActive: true,
        createdAt: created,
      ),
    ];
  }

  static List<Student> buildDemoStudents(DateTime now) {
    final created = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 45));
    return [
      Student(
        id: 's_olivia',
        fullName: 'Olivia Bennett',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 4',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_olga',
        remainingCredits: 12,
        notes: 'Preparing for HSK 4 exam.',
        createdAt: created,
      ),
      Student(
        id: 's_liam',
        fullName: 'Liam Carter',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 2',
        format: LessonType.group,
        primaryTeacherId: 't_sharllote',
        remainingCredits: 6,
        notes: 'Focused on daily conversational Mandarin.',
        createdAt: created,
      ),
      Student(
        id: 's_chloe',
        fullName: 'Chloe Park',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'C1',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_keith',
        remainingCredits: 9,
        notes: 'IELTS speaking and academic writing.',
        createdAt: created,
      ),
      Student(
        id: 's_ethan',
        fullName: 'Ethan Zhao',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'B2',
        format: LessonType.group,
        primaryTeacherId: 't_andrew',
        remainingCredits: 2,
        notes: 'Low credit balance — remind before renewal.',
        createdAt: created,
      ),
      Student(
        id: 's_maya',
        fullName: 'Maya Patel',
        targetLanguage: CourseLanguage.chinese,
        proficiencyLevel: 'HSK 5',
        format: LessonType.oneOnOne,
        primaryTeacherId: 't_olga',
        remainingCredits: 16,
        createdAt: created,
      ),
      Student(
        id: 's_noah',
        fullName: 'Noah Kim',
        targetLanguage: CourseLanguage.english,
        proficiencyLevel: 'B1',
        format: LessonType.group,
        primaryTeacherId: 't_sofia',
        remainingCredits: 8,
        createdAt: created,
      ),
    ];
  }

  /// Always-recurring Saturday Speaking Clubs:
  /// - Saturday 11:00 AM: Chinese Speaking Club (Hall)
  /// - Saturday 3:00 PM: English Speaking Club (Hall)
  static List<Lesson> buildSaturdayClubs(DateTime now) {
    final anchorSaturday = _mostRecentOrTodaySaturday(now);
    return [
      Lesson(
        id: clubChineseId,
        title: 'Chinese Speaking Club',
        language: CourseLanguage.chinese,
        lessonType: LessonType.group,
        teacherId: 't_olga',
        classroomId: 'room_hall',
        studentIds: const [],
        startTime: DateTime(
          anchorSaturday.year,
          anchorSaturday.month,
          anchorSaturday.day,
          11,
          0,
        ),
        endTime: DateTime(
          anchorSaturday.year,
          anchorSaturday.month,
          anchorSaturday.day,
          12,
          30,
        ),
        status: LessonStatus.scheduled,
        notes: 'Weekly Saturday Chinese conversation club — open to all levels.',
        createdAt: anchorSaturday,
        recurrenceWeekdays: const [DateTime.saturday],
        recurrenceUntil: null,
        isSpeakingClub: true,
      ),
      Lesson(
        id: clubEnglishId,
        title: 'English Speaking Club',
        language: CourseLanguage.english,
        lessonType: LessonType.group,
        teacherId: 't_keith',
        classroomId: 'room_hall',
        studentIds: const [],
        startTime: DateTime(
          anchorSaturday.year,
          anchorSaturday.month,
          anchorSaturday.day,
          15,
          0,
        ),
        endTime: DateTime(
          anchorSaturday.year,
          anchorSaturday.month,
          anchorSaturday.day,
          16,
          30,
        ),
        status: LessonStatus.scheduled,
        notes: 'Weekly Saturday English speaking club — debates, games & fluency.',
        createdAt: anchorSaturday,
        recurrenceWeekdays: const [DateTime.saturday],
        recurrenceUntil: null,
        isSpeakingClub: true,
      ),
    ];
  }

  static DateTime _mostRecentOrTodaySaturday(DateTime ref) {
    final day = DateTime(ref.year, ref.month, ref.day);
    final diff = (day.weekday - DateTime.saturday) % 7;
    return day.subtract(Duration(days: diff));
  }

  static List<StudyGroup> buildStudyGroups(DateTime now) {
    final created = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    return [
      StudyGroup(
        id: 'grp_hsk1_morning',
        name: 'HSK 1 — Foundations',
        language: CourseLanguage.chinese,
        level: 'HSK 1',
        teacherId: 't_olga',
        classroomId: 'room_1',
        scheduleWeekdays: const [
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ],
        startHour: 10,
        startMinute: 0,
        durationMinutes: 90,
        members: const [
          GroupMemberPayment(
            memberId: 's_liam',
            fullName: 'Liam Carter',
            totalPaidLessons: 12,
            lessonsRemaining: 9,
            hasPaid: true,
          ),
        ],
        notes: 'Beginner pinyin, tones, and first 150 HSK 1 characters.',
        createdAt: created,
      ),
      StudyGroup(
        id: 'grp_hsk2_mwf',
        name: 'HSK 2 — Spoken Mandarin',
        language: CourseLanguage.chinese,
        level: 'HSK 2',
        teacherId: 't_sharllote',
        classroomId: 'room_2',
        scheduleWeekdays: const [
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
        ],
        startHour: 17,
        startMinute: 30,
        durationMinutes: 90,
        members: const [
          GroupMemberPayment(
            memberId: 's_olivia',
            fullName: 'Olivia Bennett',
            totalPaidLessons: 12,
            lessonsRemaining: 6,
            hasPaid: true,
          ),
          GroupMemberPayment(
            memberId: 's_maya',
            fullName: 'Maya Patel',
            totalPaidLessons: 12,
            lessonsRemaining: 12,
            hasPaid: false,
          ),
        ],
        notes: 'Steady MWF evening cohort.',
        createdAt: created,
      ),
      StudyGroup(
        id: 'grp_eng_b2',
        name: 'English B2 — Fluency',
        language: CourseLanguage.english,
        level: 'B2',
        teacherId: 't_andrew',
        classroomId: 'room_4',
        scheduleWeekdays: const [DateTime.tuesday, DateTime.thursday],
        startHour: 16,
        startMinute: 30,
        durationMinutes: 90,
        members: const [
          GroupMemberPayment(
            memberId: 's_ethan',
            fullName: 'Ethan Zhao',
            totalPaidLessons: 12,
            lessonsRemaining: 2,
            hasPaid: true,
          ),
          GroupMemberPayment(
            memberId: 's_noah',
            fullName: 'Noah Kim',
            totalPaidLessons: 12,
            lessonsRemaining: 8,
            hasPaid: true,
          ),
        ],
        notes: 'Tuesday & Thursday fluency and debate practice.',
        createdAt: created,
      ),
    ];
  }

  static List<HomeworkAssignment> buildDemoHomeworks(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      HomeworkAssignment(
        id: 'hw_hsk1_tones',
        title: 'HSK 1 Unit 3 Tone Drills & Audio',
        description:
            'Listen to tracks 12–15, practice 3rd-tone sandhi pairs out loud, and write 15 new characters 5 times each.',
        groupId: 'grp_hsk1_morning',
        teacherId: 't_olga',
        dueDate: today.add(const Duration(days: 2)),
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      HomeworkAssignment(
        id: 'hw_hsk2_dialogue',
        title: 'HSK 2 Shopping & Ordering Dialogue',
        description:
            'Prepare a 2-minute roleplay using "多少", "太贵了", and "便宜一点" for Wednesday class.',
        groupId: 'grp_hsk2_mwf',
        teacherId: 't_sharllote',
        dueDate: today.add(const Duration(days: 3)),
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
