import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/classroom.dart';
import '../models/homework.dart';
import '../models/lesson.dart';
import '../models/operations_models.dart';
import '../models/student.dart';
import '../models/study_group.dart';
import '../models/teacher.dart';
import 'center_seed_data.dart';
import 'data_repository.dart';

/// Production Cloud Firestore repository with real-time `.snapshots()` listeners.
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
  CollectionReference<Map<String, dynamic>> get _groupsCol =>
      _db.collection('groups');
  CollectionReference<Map<String, dynamic>> get _homeworksCol =>
      _db.collection('homeworks');
  CollectionReference<Map<String, dynamic>> get _profilesCol =>
      _db.collection('student_profiles');
  CollectionReference<Map<String, dynamic>> get _attendanceCol =>
      _db.collection('attendance');
  CollectionReference<Map<String, dynamic>> get _paymentsCol =>
      _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get _leadsCol =>
      _db.collection('trial_leads');
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _db.collection('reschedule_requests');
  CollectionReference<Map<String, dynamic>> get _activityCol =>
      _db.collection('activity_logs');

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
  Stream<List<StudyGroup>> watchGroups() {
    return _groupsCol.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((doc) => StudyGroup.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<HomeworkAssignment>> watchHomeworks() {
    return _homeworksCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => HomeworkAssignment.fromMap(
                  doc.data(),
                  documentId: doc.id,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<StudentPortalProfile> watchStudentPortalProfile({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return _profilesCol.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) {
        return StudentPortalProfile(
          uid: uid,
          email: email,
          fullName: displayName ?? 'Student',
        );
      }
      return StudentPortalProfile.fromMap(
        data,
        uid: uid,
        fallbackEmail: email,
        fallbackName: displayName,
      );
    });
  }

  @override
  Stream<List<AttendanceRecord>> watchAttendance() {
    return _attendanceCol
        .orderBy('recordedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => AttendanceRecord.fromMap(
                  doc.data(),
                  documentId: doc.id,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<PaymentRecord>> watchPayments() {
    return _paymentsCol
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PaymentRecord.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<TrialLead>> watchTrialLeads() {
    return _leadsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TrialLead.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<RescheduleRequest>> watchRescheduleRequests() {
    return _requestsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => RescheduleRequest.fromMap(
                  doc.data(),
                  documentId: doc.id,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<ActivityLogEntry>> watchActivityLogs() {
    return _activityCol
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ActivityLogEntry.fromMap(
                  doc.data(),
                  documentId: doc.id,
                ),
              )
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
  Future<void> deleteLesson(String lessonId) =>
      _lessonsCol.doc(lessonId).delete();

  @override
  Future<void> upsertTeacher(Teacher teacher) {
    return _teachersCol
        .doc(teacher.id)
        .set(teacher.toMap(useFirestoreTimestamp: true), SetOptions(merge: true));
  }

  @override
  Future<void> deleteTeacher(String teacherId) =>
      _teachersCol.doc(teacherId).delete();

  @override
  Future<void> upsertClassroom(Classroom classroom) {
    return _classroomsCol.doc(classroom.id).set(
          classroom.toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteClassroom(String classroomId) =>
      _classroomsCol.doc(classroomId).delete();

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
      final current =
          (snapshot.data()?['remainingCredits'] as num?)?.toInt() ?? 0;
      final updated = (current + delta).clamp(0, 999);
      tx.update(docRef, {'remainingCredits': updated});
    });
  }

  @override
  Future<void> deleteStudent(String studentId) =>
      _studentsCol.doc(studentId).delete();

  @override
  Future<void> upsertGroup(StudyGroup group) {
    return _groupsCol
        .doc(group.id)
        .set(group.toMap(useFirestoreTimestamp: true), SetOptions(merge: true));
  }

  @override
  Future<void> deleteGroup(String groupId) => _groupsCol.doc(groupId).delete();

  @override
  Future<void> upsertHomework(HomeworkAssignment homework) {
    return _homeworksCol.doc(homework.id).set(
          homework.toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteHomework(String homeworkId) =>
      _homeworksCol.doc(homeworkId).delete();

  @override
  Future<void> toggleHomeworkCompletion({
    required String homeworkId,
    required String uid,
    required bool completed,
  }) {
    return _homeworksCol.doc(homeworkId).update({
      'completedByUids': completed
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> submitHomeworkResponse({
    required String homeworkId,
    required HomeworkSubmission submission,
  }) async {
    final docRef = _homeworksCol.doc(homeworkId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists || snap.data() == null) return;
      final hw = HomeworkAssignment.fromMap(snap.data()!, documentId: snap.id);
      final subs = hw.submissions
          .where((s) => s.studentUid != submission.studentUid)
          .toList()
        ..add(submission);
      final done = {...hw.completedByUids, submission.studentUid}.toList();
      tx.update(docRef, {
        'submissions':
            subs.map((s) => s.toMap(useFirestoreTimestamp: true)).toList(),
        'completedByUids': done,
      });
    });
  }

  @override
  Future<void> reviewHomeworkSubmission({
    required String homeworkId,
    required String studentUid,
    required String feedback,
    required bool reviewed,
  }) async {
    final docRef = _homeworksCol.doc(homeworkId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists || snap.data() == null) return;
      final hw = HomeworkAssignment.fromMap(snap.data()!, documentId: snap.id);
      final subs = hw.submissions.map((s) {
        if (s.studentUid != studentUid) return s;
        return s.copyWith(teacherFeedback: feedback, reviewed: reviewed);
      }).toList();
      tx.update(docRef, {
        'submissions':
            subs.map((s) => s.toMap(useFirestoreTimestamp: true)).toList(),
      });
    });
  }

  @override
  Future<void> saveStudentPortalProfile(StudentPortalProfile profile) {
    return _profilesCol.doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
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
    final attRef = _attendanceCol.doc(id);
    final studentRef = _studentsCol.doc(studentId);

    await _db.runTransaction((tx) async {
      final attSnap = await tx.get(attRef);
      final studentSnap = await tx.get(studentRef);
      final wasDeducted =
          (attSnap.data()?['creditDeducted'] as bool?) ?? false;
      final shouldDeduct = status == AttendanceStatus.present;

      if (studentSnap.exists) {
        final currentCredits =
            (studentSnap.data()?['remainingCredits'] as num?)?.toInt() ?? 0;
        if (!wasDeducted && shouldDeduct) {
          tx.update(
            studentRef,
            {'remainingCredits': (currentCredits - 1).clamp(0, 999)},
          );
        } else if (wasDeducted && !shouldDeduct) {
          tx.update(
            studentRef,
            {'remainingCredits': (currentCredits + 1).clamp(0, 999)},
          );
        }
      }

      final record = AttendanceRecord(
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
      tx.set(
        attRef,
        record.toMap(useFirestoreTimestamp: true),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> recordPayment(
    PaymentRecord payment, {
    bool addCreditsToStudent = true,
  }) async {
    await _paymentsCol.doc(payment.id).set(
          payment.toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
    if (addCreditsToStudent &&
        payment.studentId.isNotEmpty &&
        payment.lessonsPurchased > 0) {
      await adjustStudentCredits(payment.studentId, payment.lessonsPurchased);
    }
  }

  @override
  Future<void> upsertTrialLead(TrialLead lead) {
    return _leadsCol.doc(lead.id).set(
          lead.toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteTrialLead(String leadId) => _leadsCol.doc(leadId).delete();

  @override
  Future<void> submitRescheduleRequest(RescheduleRequest request) {
    return _requestsCol.doc(request.id).set(
          request.toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> resolveRescheduleRequest({
    required String requestId,
    required RequestStatus status,
    required String staffNote,
  }) {
    return _requestsCol.doc(requestId).update({
      'status': status.name,
      'staffNote': staffNote,
    });
  }

  @override
  Future<void> logActivity(ActivityLogEntry entry) async {
    try {
      await _activityCol
          .doc(entry.id)
          .set(entry.toMap(useFirestoreTimestamp: true));
    } catch (_) {
      // Never fail primary user mutation if audit logging hits transient error.
    }
  }

  bool _seedAttempted = false;

  @override
  Future<void> seedInitialCenterDataIfNeeded({bool force = false}) async {
    if (_seedAttempted && !force) return;
    _seedAttempted = true;
    try {
      final now = DateTime.now();
      final roomsSnap = await _classroomsCol.limit(1).get();
      final teachersSnap = await _teachersCol.limit(1).get();
      final groupsSnap = await _groupsCol.limit(1).get();
      final clubSnap =
          await _lessonsCol.doc(CenterSeedData.clubChineseId).get();

      final needRooms = force || roomsSnap.docs.isEmpty;
      final needTeachers = force || teachersSnap.docs.isEmpty;
      final needGroups = force || groupsSnap.docs.isEmpty;
      final needClubs = force || !clubSnap.exists;

      if (!needRooms && !needTeachers && !needGroups && !needClubs) {
        return;
      }

      final batch = _db.batch();
      if (needRooms) {
        for (final room in CenterSeedData.buildClassrooms(now)) {
          batch.set(
            _classroomsCol.doc(room.id),
            room.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      }
      if (needTeachers) {
        for (final teacher in CenterSeedData.buildTeachers(now)) {
          batch.set(
            _teachersCol.doc(teacher.id),
            teacher.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      }
      if (needGroups) {
        for (final group in CenterSeedData.buildStudyGroups(now)) {
          batch.set(
            _groupsCol.doc(group.id),
            group.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      }
      if (needClubs) {
        for (final club in CenterSeedData.buildSaturdayClubs(now)) {
          batch.set(
            _lessonsCol.doc(club.id),
            club.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();
    } catch (_) {
      _seedAttempted = false;
      if (force) rethrow;
    }
  }

  @override
  Future<void> dispose() async {}
}
