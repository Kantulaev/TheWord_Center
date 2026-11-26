import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

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

/// Production Cloud Firestore repository with:
/// - Strict staff vs student role isolation (hiding Sharing groups, teacher salaries/PII,
///   classmate rosters, and raw 1-on-1 lessons from student queries)
/// - Quota-conscious query limits and single-doc seed/migration check
class FirestoreRepository implements DataRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _lessonsCol =>
      _db.collection('lessons');
  CollectionReference<Map<String, dynamic>> get _teachersCol =>
      _db.collection('teachers');
  CollectionReference<Map<String, dynamic>> get _publicTeachersCol =>
      _db.collection('public_teachers');
  CollectionReference<Map<String, dynamic>> get _classroomsCol =>
      _db.collection('classrooms');
  CollectionReference<Map<String, dynamic>> get _studentsCol =>
      _db.collection('students');
  CollectionReference<Map<String, dynamic>> get _groupsCol =>
      _db.collection('groups');
  CollectionReference<Map<String, dynamic>> get _rostersCol =>
      _db.collection('group_rosters');
  CollectionReference<Map<String, dynamic>> get _homeworksCol =>
      _db.collection('homeworks');
  CollectionReference<Map<String, dynamic>> get _homeworkSubmissionsCol =>
      _db.collection('homework_submissions');
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
  DocumentReference<Map<String, dynamic>> get _metaDoc =>
      _db.collection('center_config').doc('meta');

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
  Stream<List<Teacher>> watchPublicTeachers() {
    return _publicTeachersCol.orderBy('fullName').snapshots().map(
          (snap) => snap.docs
              .map(
                (doc) => Teacher.fromMap(
                  {...doc.data(), 'hourlyRate': 0, 'clubRate': 0},
                  documentId: doc.id,
                ),
              )
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
  Stream<Student?> watchMyStudentRecord(String email) {
    final norm = email.trim().toLowerCase();
    if (norm.isEmpty) return Stream.value(null);
    return _studentsCol
        .where('email', isEqualTo: norm)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return Student.fromMap(doc.data(), documentId: doc.id);
    });
  }

  /// Staff cohort listener merging public `/groups` metadata with staff-only
  /// `/group_rosters` payment data (gracefully supporting un-migrated legacy docs).
  @override
  Stream<List<StudyGroup>> watchGroups() {
    return Stream<List<StudyGroup>>.multi((controller) {
      List<StudyGroup> latestGroups = const [];
      Map<String, Map<String, dynamic>> latestRosters = const {};
      var hasGroups = false;

      void emitMerged() {
        if (!hasGroups) return;
        final merged = latestGroups.map((g) {
          final rosterData = latestRosters[g.id];
          if (rosterData == null) return g;
          final rawMembers = rosterData['members'];
          final members = rawMembers is Iterable
              ? rawMembers
                  .whereType<Map<String, dynamic>>()
                  .map(GroupMemberPayment.fromMap)
                  .toList()
              : g.members;
          final notes = rosterData['notes'] as String? ?? g.notes;
          return g.copyWith(members: members, notes: notes);
        }).toList(growable: false);
        controller.add(merged);
      }

      final groupSub = _groupsCol.orderBy('name').snapshots().listen(
        (snap) {
          hasGroups = true;
          latestGroups = snap.docs
              .map((doc) => StudyGroup.fromMap(doc.data(), documentId: doc.id))
              .toList(growable: false);
          emitMerged();
        },
        onError: controller.addError,
      );

      final rosterSub = _rostersCol.snapshots().listen(
        (snap) {
          latestRosters = {
            for (final doc in snap.docs) doc.id: doc.data(),
          };
          emitMerged();
        },
        onError: (_) {},
      );

      controller.onCancel = () async {
        await groupSub.cancel();
        await rosterSub.cancel();
      };
    });
  }

  /// Safe public group list for students: strictly excludes `sharing` groups
  /// and strips classmate payment rosters.
  @override
  Stream<List<StudyGroup>> watchPublicGroups() {
    return _groupsCol
        .where(
          'language',
          whereIn: [CourseLanguage.chinese.name, CourseLanguage.english.name],
        )
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => StudyGroup.fromMap(doc.data(), documentId: doc.id))
              .where((g) => g.language != CourseLanguage.sharing)
              .map((g) => g.copyWith(members: const [], notes: ''))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return List.unmodifiable(list);
        });
  }

  @override
  Stream<List<HomeworkAssignment>> watchHomeworks() {
    return _homeworksCol
        .orderBy('createdAt', descending: true)
        .limit(120)
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
  Stream<List<HomeworkAssignment>> watchHomeworksForGroups(
    List<String> groupIds,
  ) {
    final cleanIds = groupIds.where((id) => id.isNotEmpty).take(10).toList();
    if (cleanIds.isEmpty) return Stream.value(const []);
    return _homeworksCol
        .where('groupId', whereIn: cleanIds)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(
            (doc) => HomeworkAssignment.fromMap(
              doc.data(),
              documentId: doc.id,
            ),
          )
          .where((h) => h.language != CourseLanguage.sharing)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(list);
    });
  }

  @override
  Stream<List<HomeworkSubmission>> watchAllHomeworkSubmissions() {
    return _homeworkSubmissionsCol
        .orderBy('submittedAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => HomeworkSubmission.fromMap(doc.data()))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<HomeworkSubmission>> watchMyHomeworkSubmissions(
    String studentUid,
  ) {
    if (studentUid.isEmpty) return Stream.value(const []);
    return _homeworkSubmissionsCol
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => HomeworkSubmission.fromMap(doc.data()))
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
        .limit(200)
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
        .limit(150)
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
        .limit(150)
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
        .limit(100)
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
  Stream<List<RescheduleRequest>> watchMyRescheduleRequests(
    String studentUid,
  ) {
    if (studentUid.isEmpty) return Stream.value(const []);
    return _requestsCol
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(
            (doc) => RescheduleRequest.fromMap(
              doc.data(),
              documentId: doc.id,
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(list);
    });
  }

  @override
  Stream<List<ActivityLogEntry>> watchActivityLogs() {
    return _activityCol
        .orderBy('createdAt', descending: true)
        .limit(60)
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
  Future<void> upsertTeacher(Teacher teacher) async {
    final batch = _db.batch();
    batch.set(
      _teachersCol.doc(teacher.id),
      teacher.toMap(useFirestoreTimestamp: true),
      SetOptions(merge: true),
    );
    batch.set(
      _publicTeachersCol.doc(teacher.id),
      teacher.toPublicMap(),
    );
    await batch.commit();
  }

  @override
  Future<void> deleteTeacher(String teacherId) async {
    final batch = _db.batch();
    batch.delete(_teachersCol.doc(teacherId));
    batch.delete(_publicTeachersCol.doc(teacherId));
    await batch.commit();
  }

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
    final normalized = student.email.trim().toLowerCase();
    return _studentsCol.doc(student.id).set(
          student
              .copyWith(email: normalized)
              .toMap(useFirestoreTimestamp: true),
          SetOptions(merge: true),
        );
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
  Future<void> upsertGroup(StudyGroup group) async {
    final batch = _db.batch();
    batch.set(
      _groupsCol.doc(group.id),
      group.toPublicMap(useFirestoreTimestamp: true),
    );
    batch.set(
      _rostersCol.doc(group.id),
      group.toRosterMap(useFirestoreTimestamp: true),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final batch = _db.batch();
    batch.delete(_groupsCol.doc(groupId));
    batch.delete(_rostersCol.doc(groupId));
    await batch.commit();
  }

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
    final docId = HomeworkSubmission.docId(homeworkId, submission.studentUid);
    final payload = submission
        .copyWith(homeworkId: homeworkId)
        .toMap(useFirestoreTimestamp: true);
    await _homeworkSubmissionsCol.doc(docId).set(payload, SetOptions(merge: true));
    await toggleHomeworkCompletion(
      homeworkId: homeworkId,
      uid: submission.studentUid,
      completed: true,
    );
  }

  @override
  Future<void> reviewHomeworkSubmission({
    required String homeworkId,
    required String studentUid,
    required String feedback,
    required bool reviewed,
  }) {
    final docId = HomeworkSubmission.docId(homeworkId, studentUid);
    return _homeworkSubmissionsCol.doc(docId).set(
      {
        'homeworkId': homeworkId,
        'studentUid': studentUid,
        'teacherFeedback': feedback,
        'reviewed': reviewed,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> saveStudentPortalProfile(StudentPortalProfile profile) {
    return _profilesCol.doc(profile.uid).set(
          profile
              .copyWith(email: profile.email.trim().toLowerCase())
              .toMap(),
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

  /// Single-document metadata check (1 read total when already migrated/seeded)
  /// saving Firebase Spark quota while keeping `public_teachers` and split
  /// `group_rosters` synchronized on upgrades.
  @override
  Future<void> seedInitialCenterDataIfNeeded({bool force = false}) async {
    if (_seedAttempted && !force) return;
    _seedAttempted = true;
    try {
      final metaSnap = await _metaDoc.get();
      final schemaVersion =
          (metaSnap.data()?['schemaVersion'] as num?)?.toInt() ?? 0;
      if (!force && metaSnap.exists && schemaVersion >= 2) {
        return;
      }

      final now = DateTime.now();
      final roomsSnap = await _classroomsCol.limit(1).get();
      final teachersSnap = await _teachersCol.get();
      final groupsSnap = await _groupsCol.get();
      final clubSnap =
          await _lessonsCol.doc(CenterSeedData.clubChineseId).get();

      final batch = _db.batch();

      if (force || roomsSnap.docs.isEmpty) {
        for (final room in CenterSeedData.buildClassrooms(now)) {
          batch.set(
            _classroomsCol.doc(room.id),
            room.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      }

      if (force || teachersSnap.docs.isEmpty) {
        for (final teacher in CenterSeedData.buildTeachers(now)) {
          batch.set(
            _teachersCol.doc(teacher.id),
            teacher.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
          batch.set(_publicTeachersCol.doc(teacher.id), teacher.toPublicMap());
        }
      } else {
        for (final doc in teachersSnap.docs) {
          final teacher = Teacher.fromMap(doc.data(), documentId: doc.id);
          batch.set(_publicTeachersCol.doc(teacher.id), teacher.toPublicMap());
        }
      }

      if (force || groupsSnap.docs.isEmpty) {
        for (final group in CenterSeedData.buildStudyGroups(now)) {
          batch.set(
            _groupsCol.doc(group.id),
            group.toPublicMap(useFirestoreTimestamp: true),
          );
          batch.set(
            _rostersCol.doc(group.id),
            group.toRosterMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      } else {
        for (final doc in groupsSnap.docs) {
          final data = doc.data();
          final group = StudyGroup.fromMap(data, documentId: doc.id);
          if (data.containsKey('members') || data.containsKey('notes')) {
            batch.set(
              _rostersCol.doc(group.id),
              group.toRosterMap(useFirestoreTimestamp: true),
              SetOptions(merge: true),
            );
            batch.set(
              _groupsCol.doc(group.id),
              group.toPublicMap(useFirestoreTimestamp: true),
            );
          }
        }
      }

      if (force || !clubSnap.exists) {
        for (final club in CenterSeedData.buildSaturdayClubs(now)) {
          batch.set(
            _lessonsCol.doc(club.id),
            club.toMap(useFirestoreTimestamp: true),
            SetOptions(merge: true),
          );
        }
      }

      batch.set(_metaDoc, {
        'seeded': true,
        'schemaVersion': 2,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (_) {
      _seedAttempted = false;
      if (force) rethrow;
    }
  }

  @override
  Future<void> dispose() async {}
}
