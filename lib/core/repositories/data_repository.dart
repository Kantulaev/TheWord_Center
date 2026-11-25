import '../models/classroom.dart';
import '../models/lesson.dart';
import '../models/student.dart';
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

  Future<void> upsertLesson(Lesson lesson);
  Future<void> deleteLesson(String lessonId);

  Future<void> upsertTeacher(Teacher teacher);
  Future<void> deleteTeacher(String teacherId);

  Future<void> upsertClassroom(Classroom classroom);
  Future<void> deleteClassroom(String classroomId);

  Future<void> upsertStudent(Student student);
  Future<void> adjustStudentCredits(String studentId, int delta);
  Future<void> deleteStudent(String studentId);

  Future<void> dispose();
}
