import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';

/// A student's submitted answer/link and the teacher's feedback for a homework item.
@immutable
class HomeworkSubmission {
  const HomeworkSubmission({
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    required this.answerOrLink,
    required this.submittedAt,
    this.teacherFeedback = '',
    this.reviewed = false,
  });

  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String answerOrLink;
  final DateTime submittedAt;
  final String teacherFeedback;
  final bool reviewed;

  HomeworkSubmission copyWith({
    String? studentUid,
    String? studentName,
    String? studentEmail,
    String? answerOrLink,
    DateTime? submittedAt,
    String? teacherFeedback,
    bool? reviewed,
  }) {
    return HomeworkSubmission(
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      answerOrLink: answerOrLink ?? this.answerOrLink,
      submittedAt: submittedAt ?? this.submittedAt,
      teacherFeedback: teacherFeedback ?? this.teacherFeedback,
      reviewed: reviewed ?? this.reviewed,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'answerOrLink': answerOrLink,
      'submittedAt': useFirestoreTimestamp
          ? Timestamp.fromDate(submittedAt)
          : submittedAt.toIso8601String(),
      'teacherFeedback': teacherFeedback,
      'reviewed': reviewed,
    };
  }

  factory HomeworkSubmission.fromMap(Map<String, dynamic> map) {
    return HomeworkSubmission(
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Student',
      studentEmail: map['studentEmail'] as String? ?? '',
      answerOrLink: map['answerOrLink'] as String? ?? '',
      submittedAt: parseFlexibleDateTime(map['submittedAt']),
      teacherFeedback: map['teacherFeedback'] as String? ?? '',
      reviewed: map['reviewed'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkSubmission &&
          runtimeType == other.runtimeType &&
          studentUid == other.studentUid &&
          studentName == other.studentName &&
          studentEmail == other.studentEmail &&
          answerOrLink == other.answerOrLink &&
          submittedAt == other.submittedAt &&
          teacherFeedback == other.teacherFeedback &&
          reviewed == other.reviewed;

  @override
  int get hashCode => Object.hash(
        studentUid,
        studentName,
        studentEmail,
        answerOrLink,
        submittedAt,
        teacherFeedback,
        reviewed,
      );
}

/// Homework assignment sent by a teacher to a study group so enrolled students
/// see it directly in their Student Portal.
@immutable
class HomeworkAssignment {
  const HomeworkAssignment({
    required this.id,
    required this.title,
    required this.description,
    required this.groupId,
    required this.teacherId,
    required this.dueDate,
    required this.createdAt,
    this.completedByUids = const [],
    this.submissions = const [],
  });

  final String id;
  final String title;
  final String description;
  final String groupId;
  final String teacherId;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<String> completedByUids;
  final List<HomeworkSubmission> submissions;

  bool isCompletedBy(String uid) => completedByUids.contains(uid);

  HomeworkSubmission? submissionFor(String uid) {
    for (final s in submissions) {
      if (s.studentUid == uid) return s;
    }
    return null;
  }

  HomeworkAssignment copyWith({
    String? id,
    String? title,
    String? description,
    String? groupId,
    String? teacherId,
    DateTime? dueDate,
    DateTime? createdAt,
    List<String>? completedByUids,
    List<HomeworkSubmission>? submissions,
  }) {
    return HomeworkAssignment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      groupId: groupId ?? this.groupId,
      teacherId: teacherId ?? this.teacherId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedByUids: completedByUids ?? this.completedByUids,
      submissions: submissions ?? this.submissions,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'groupId': groupId,
      'teacherId': teacherId,
      'dueDate': useFirestoreTimestamp
          ? Timestamp.fromDate(dueDate)
          : dueDate.toIso8601String(),
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
      'completedByUids': completedByUids,
      'submissions': submissions
          .map((s) => s.toMap(useFirestoreTimestamp: useFirestoreTimestamp))
          .toList(),
    };
  }

  factory HomeworkAssignment.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawDone = map['completedByUids'];
    final done = rawDone is Iterable
        ? rawDone.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final rawSubs = map['submissions'];
    final subs = rawSubs is Iterable
        ? rawSubs
            .whereType<Map<String, dynamic>>()
            .map(HomeworkSubmission.fromMap)
            .toList()
        : <HomeworkSubmission>[];
    return HomeworkAssignment(
      id: documentId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? 'Homework',
      description: map['description'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      dueDate: parseFlexibleDateTime(map['dueDate']),
      createdAt: parseFlexibleDateTime(map['createdAt']),
      completedByUids: done,
      submissions: subs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkAssignment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          groupId == other.groupId &&
          teacherId == other.teacherId &&
          dueDate == other.dueDate &&
          createdAt == other.createdAt &&
          listEquals(completedByUids, other.completedByUids) &&
          listEquals(submissions, other.submissions);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        groupId,
        teacherId,
        dueDate,
        createdAt,
        Object.hashAll(completedByUids),
        Object.hashAll(submissions),
      );
}

/// Self-service Student Portal profile storing which HSK / English groups the student joined.
@immutable
class StudentPortalProfile {
  const StudentPortalProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    this.selectedGroupIds = const [],
  });

  final String uid;
  final String email;
  final String fullName;
  final List<String> selectedGroupIds;

  StudentPortalProfile copyWith({
    String? uid,
    String? email,
    String? fullName,
    List<String>? selectedGroupIds,
  }) {
    return StudentPortalProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      selectedGroupIds: selectedGroupIds ?? this.selectedGroupIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'selectedGroupIds': selectedGroupIds,
    };
  }

  factory StudentPortalProfile.fromMap(
    Map<String, dynamic> map, {
    required String uid,
    required String fallbackEmail,
    String? fallbackName,
  }) {
    final rawIds = map['selectedGroupIds'];
    final ids = rawIds is Iterable
        ? rawIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    return StudentPortalProfile(
      uid: uid,
      email: map['email'] as String? ?? fallbackEmail,
      fullName: map['fullName'] as String? ?? (fallbackName ?? 'Student'),
      selectedGroupIds: ids,
    );
  }
}
