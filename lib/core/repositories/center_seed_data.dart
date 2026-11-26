import '../models/classroom.dart';
import '../models/community_models.dart';
import '../models/homework.dart';
import '../models/language_type.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/teacher.dart';

/// Canonical classrooms, teachers, students, and recurring Saturday Speaking Clubs
/// for "The Word" language center.
abstract final class CenterSeedData {
  static const String clubKidsId = 'club_sat_kids';
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
  /// - Saturday 9:30 AM: Saturday Kids Club (Hall)
  /// - Saturday 11:00 AM: Chinese Speaking Club (Hall)
  /// - Saturday 3:00 PM: English Speaking Club (Hall)
  static List<Lesson> buildSaturdayClubs(DateTime now) {
    final anchorSaturday = _mostRecentOrTodaySaturday(now);
    return [
      Lesson(
        id: clubKidsId,
        title: 'Saturday Kids Club',
        language: CourseLanguage.english,
        lessonType: LessonType.group,
        teacherId: 't_andrew',
        classroomId: 'room_hall',
        studentIds: const [],
        startTime: DateTime(
          anchorSaturday.year,
          anchorSaturday.month,
          anchorSaturday.day,
          9,
          30,
        ),
        endTime: DateTime(
          anchorSaturday.year,
          anchorSaturday.month,
          anchorSaturday.day,
          11,
          0,
        ),
        status: LessonStatus.scheduled,
        notes: 'Weekly Saturday 09:30 Kids Club — games, speaking & fun activities.',
        createdAt: anchorSaturday,
        recurrenceWeekdays: const [DateTime.saturday],
        recurrenceUntil: null,
        isSpeakingClub: true,
      ),
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

  static List<AppNotification> buildDemoNotifications(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final saturdayOffset = (DateTime.saturday - now.weekday + 7) % 7;
    final nextSat = today.add(
      Duration(days: saturdayOffset == 0 ? 7 : saturdayOffset),
    );
    return [
      AppNotification(
        id: 'notif_sat_chinese_club',
        title: 'Chinese Speaking Club This Saturday!',
        message:
            'Join Sharllote in the Main Hall for tea table conversation and fun speaking prompts.',
        category: NotificationCategory.speakingClub,
        clubPreset: SpeakingClubPreset.chineseClub,
        clubTopic: 'Ordering Street Food & Tea Culture in Beijing',
        scheduledAt: DateTime(nextSat.year, nextSat.month, nextSat.day, 15, 0),
        audience: AudienceType.all,
        createdByName: 'Sharllote',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'notif_sat_english_club',
        title: 'English Speaking Club Topic Announced',
        message:
            'All CEFR levels welcome in Main Hall! Warm-up games + small group discussions.',
        category: NotificationCategory.speakingClub,
        clubPreset: SpeakingClubPreset.englishClub,
        clubTopic: 'Travel Stories & Cultural Shocks Around the World',
        scheduledAt: DateTime(nextSat.year, nextSat.month, nextSat.day, 17, 0),
        audience: AudienceType.studentsOnly,
        createdByName: 'Keith',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 'notif_hsk1_reminder',
        title: 'HSK 1 Morning: Tone Drills Reminder',
        message:
            'Don\'t forget to submit Unit 3 audio drills in your Student Portal before class.',
        category: NotificationCategory.reminder,
        audience: AudienceType.specificGroup,
        targetGroupId: 'grp_hsk1_morning',
        targetGroupName: 'HSK 1 Morning',
        targetEmails: const ['liam@student.kg', 'aisha@student.kg'],
        createdByName: 'Olga',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      AppNotification(
        id: 'notif_staff_briefing',
        title: 'Teachers Sync: Monthly HSK Mock Tests',
        message:
            'Please verify attendance credits and readiness tags before Friday evening.',
        category: NotificationCategory.announcement,
        audience: AudienceType.teachersOnly,
        createdByName: 'Admin Desk',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<CenterEvent> buildDemoEvents(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final saturdayOffset = (DateTime.saturday - now.weekday + 7) % 7;
    final nextSat = today.add(
      Duration(days: saturdayOffset == 0 ? 7 : saturdayOffset),
    );
    return [
      CenterEvent(
        id: 'evt_tea_speaking_club',
        title: 'Saturday Chinese Tea & Speaking Club',
        description:
            'Topic: Ordering Street Food & Tea Culture. Open to all HSK students and guests.',
        eventDate: DateTime(nextSat.year, nextSat.month, nextSat.day, 15, 0),
        location: 'Main Hall (Ogonbaeva 222)',
        tag: 'Speaking Club',
        createdByName: 'Sharllote',
        audience: AudienceType.all,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      CenterEvent(
        id: 'evt_english_movie_club',
        title: 'English Cinema & Debate Evening',
        description:
            'Watch short cinema clips, discuss idioms with Keith & Andrew, and practice spontaneous speaking.',
        eventDate: today.add(const Duration(days: 5, hours: 18, minutes: 30)),
        location: 'Main Hall',
        tag: 'Movie Night',
        createdByName: 'Keith',
        audience: AudienceType.studentsOnly,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CenterEvent(
        id: 'evt_hsk1_vocab_bootcamp',
        title: 'HSK 1 Morning Character Bootcamp',
        description:
            'Extra stroke-order and radical mastery session for our HSK 1 Morning cohort.',
        eventDate: today.add(const Duration(days: 3, hours: 11)),
        location: 'Classroom 3',
        tag: 'Workshop',
        createdByName: 'Olga',
        audience: AudienceType.specificGroup,
        targetGroupId: 'grp_hsk1_morning',
        targetGroupName: 'HSK 1 Morning',
        targetEmails: const ['liam@student.kg', 'aisha@student.kg'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CenterEvent(
        id: 'evt_staff_curriculum_review',
        title: 'Staff Curriculum Alignment Briefing',
        description:
            'Internal instructors sync on Q2 HSK 2 & IELTS syllabi and club schedules.',
        eventDate: today.add(const Duration(days: 4, hours: 13)),
        location: 'Classroom 1',
        tag: 'Staff Meeting',
        createdByName: 'Sharllote',
        audience: AudienceType.teachersOnly,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      CenterEvent(
        id: 'evt_past_calligraphy_day',
        title: 'Spring Chinese Calligraphy & Dumpling Day',
        description:
            'Hands-on brush calligraphy workshop and cultural celebration with 28 students.',
        eventDate: today.subtract(const Duration(days: 12, hours: 9)),
        location: 'Main Hall',
        tag: 'Cultural Day',
        createdByName: 'Masha',
        audience: AudienceType.all,
        createdAt: today.subtract(const Duration(days: 20)),
      ),
      CenterEvent(
        id: 'evt_past_ielts_mock',
        title: 'April Full IELTS Speaking Mock Exam',
        description:
            '1-on-1 simulated Band 7.5+ interviews with individualized feedback notes.',
        eventDate: today.subtract(const Duration(days: 27, hours: 10)),
        location: 'Classroom 4 & 5',
        tag: 'HSK Exam',
        createdByName: 'Andrew',
        audience: AudienceType.studentsOnly,
        createdAt: today.subtract(const Duration(days: 35)),
      ),
    ];
  }
}
