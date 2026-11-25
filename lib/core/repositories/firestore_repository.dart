import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/classroom.dart';
import '../models/lesson.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import 'data_repository.dart';

/// Production Cloud Firestore repository with real-time `.snapshots()` listeners
/// so edits on one device synchronize instantly across all connected browsers and apps.
class FirestoreRepository implements DataRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _lessonsCol =>
      _db.collection('lessons');
  CollectionReference<Map<String, dynamic>> get _teachersCol =>
      _db.collection('teachers');
  CollectionReference<Map<String, dynamic>> get _classroomsCol =>
      _db.collection('classrooms');
  CollectionReference<Map<String, dynamic>> get _studentsCol =>
      _db.collection('students');

  @override
  bool get isCloudSync => true;

  @override
  String get modeLabel => 'Cloud Sync (Firestore)';

  @override
  Stream<List<Lesson>> watchLessons() {
    return _lessonsCol.orderBy('startTime').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Lesson.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Teacher>> watchTeachers() {
    return _teachersCol.orderBy('fullName').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Teacher.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Classroom>> watchClassrooms() {
    return _classroomsCol.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Classroom.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Student>> watchStudents() {
    return _studentsCol.orderBy('fullName').snapshots().map(
          (snap) => snap.docs
              .map((doc) => Student.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Future<void> upsertLesson(Lesson lesson) {
    return _lessonsCol
        .doc(lesson.id)
        .set(lesson.toMap(useFirestoreTimestamp: true), SetOptions(merge: true));
  }

  @override
  Future<void> deleteLesson(String lessonId) {
    return _lessonsCol.doc(lessonId).delete();
  }

  @override
  Future<void> upsertTeacher(Teacher teacher) {
    return _teachersCol
        .doc(teacher.id)
        .set(teacher.toMap(useFirestoreTimestamp: true), SetOptions(merge: true));
  }

  @override
  Future<void> deleteTeacher(String teacherId) {
    return _teachersCol.doc(teacherId).delete();
  }

  @override
  Future<void> upsertClassroom(Classroom classroom) {
    return _classroomsCol.doc(classroom.id).set(
          classroom.toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteClassroom(String classroomId) {
    return _classroomsCol.doc(classroomId).delete();
  }

  @override
  Future<void> upsertStudent(Student student) {
    return _studentsCol
        .doc(student.id)
        .set(student.toMap(useFirestoreTimestamp: true), SetOptions(merge: true));
  }

  @override
  Future<void> adjustStudentCredits(String studentId, int delta) async {
    final docRef = _studentsCol.doc(studentId);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;
      final current = (snapshot.data()?['remainingCredits'] as num?)?.toInt() ?? 0;
      final updated = (current + delta).clamp(0, 999);
      tx.update(docRef, {'remainingCredits': updated});
    });
  }

  @override
  Future<void> deleteStudent(String studentId) {
    return _studentsCol.doc(studentId).delete();
  }

  @override
  Future<void> dispose() async {}
}
