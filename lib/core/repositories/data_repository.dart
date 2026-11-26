import '../models/classroom.dart';
import '../models/homework.dart';
import '../models/lesson.dart';
import '../models/operations_models.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/teacher.dart';

/// Abstraction for real-time persistence supporting both Firebase Cloud Firestore
/// and the zero-config in-memory Demo Realtime mode.
abstract class DataRepository {
  bool get isCloudSync;
  String get modeLabel;

  Stream<List<Lesson>> watchLessons();
  Stream<List<Teacher>> watchTeachers();
  Stream<List<Classroom>> watchClassrooms();
  Stream<List<Student>> watchStudents();
  Stream<List<StudyGroup>> watchGroups();
  Stream<List<HomeworkAssignment>> watchHomeworks();
  Stream<StudentPortalProfile> watchStudentPortalProfile({
    required String uid,
    required String email,
    String? displayName,
  });

  Stream<List<AttendanceRecord>> watchAttendance();
  Stream<List<PaymentRecord>> watchPayments();
  Stream<List<TrialLead>> watchTrialLeads();
  Stream<List<RescheduleRequest>> watchRescheduleRequests();
  Stream<List<ActivityLogEntry>> watchActivityLogs();

  Future<void> upsertLesson(Lesson lesson);
  Future<void> deleteLesson(String lessonId);

  Future<void> upsertTeacher(Teacher teacher);
  Future<void> deleteTeacher(String teacherId);

  Future<void> upsertClassroom(Classroom classroom);
  Future<void> deleteClassroom(String classroomId);

  Future<void> upsertStudent(Student student);
  Future<void> adjustStudentCredits(String studentId, int delta);
  Future<void> deleteStudent(String studentId);

  Future<void> upsertGroup(StudyGroup group);
  Future<void> deleteGroup(String groupId);

  Future<void> upsertHomework(HomeworkAssignment homework);
  Future<void> deleteHomework(String homeworkId);
  Future<void> toggleHomeworkCompletion({
    required String homeworkId,
    required String uid,
    required bool completed,
  });
  Future<void> submitHomeworkResponse({
    required String homeworkId,
    required HomeworkSubmission submission,
  });
  Future<void> reviewHomeworkSubmission({
    required String homeworkId,
    required String studentUid,
    required String feedback,
    required bool reviewed,
  });

  Future<void> saveStudentPortalProfile(StudentPortalProfile profile);

  /// Marks student attendance for a lesson occurrence and automatically deducts (-1)
  /// or refunds (+1) a remaining lesson credit when transitioning to/from [AttendanceStatus.present].
  Future<void> markAttendance({
    required Lesson lesson,
    required String dateKey,
    required String studentId,
    required String studentName,
    required AttendanceStatus status,
  });

  Future<void> recordPayment(
    PaymentRecord payment, {
    bool addCreditsToStudent = true,
  });

  Future<void> upsertTrialLead(TrialLead lead);
  Future<void> deleteTrialLead(String leadId);

  Future<void> submitRescheduleRequest(RescheduleRequest request);
  Future<void> resolveRescheduleRequest({
    required String requestId,
    required RequestStatus status,
    required String staffNote,
  });

  Future<void> logActivity(ActivityLogEntry entry);

  Future<void> seedInitialCenterDataIfNeeded({bool force = false});

  Future<void> dispose();
}
