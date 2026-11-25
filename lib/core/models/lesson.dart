import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';

/// Represents a scheduled class session in "The Word" live timetable.
@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.language,
    required this.lessonType,
    required this.teacherId,
    required this.classroomId,
    required this.studentIds,
    required this.startTime,
    required this.endTime,
    this.status = LessonStatus.scheduled,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String title;
  final CourseLanguage language;
  final LessonType lessonType;
  final String teacherId;
  final String classroomId;
  final List<String> studentIds;
  final DateTime startTime;
  final DateTime endTime;
  final LessonStatus status;
  final String notes;
  final DateTime createdAt;

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Computes the live status at [now], automatically elevating [LessonStatus.scheduled]
  /// lessons within `[startTime, endTime)` to [LessonStatus.inProgress].
  LessonStatus effectiveStatusAt(DateTime now) {
    if (status == LessonStatus.canceled || status == LessonStatus.completed) {
      return status;
    }
    if (status == LessonStatus.inProgress) {
      return LessonStatus.inProgress;
    }
    if (!now.isBefore(startTime) && now.isBefore(endTime)) {
      return LessonStatus.inProgress;
    }
    return LessonStatus.scheduled;
  }

  bool isHappeningNowAt(DateTime now) =>
      effectiveStatusAt(now) == LessonStatus.inProgress;

  bool isOnDate(DateTime date) =>
      startTime.year == date.year &&
      startTime.month == date.month &&
      startTime.day == date.day;

  bool overlapsWith(DateTime otherStart, DateTime otherEnd) =>
      startTime.isBefore(otherEnd) && otherStart.isBefore(endTime);

  Lesson copyWith({
    String? id,
    String? title,
    CourseLanguage? language,
    LessonType? lessonType,
    String? teacherId,
    String? classroomId,
    List<String>? studentIds,
    DateTime? startTime,
    DateTime? endTime,
    LessonStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      lessonType: lessonType ?? this.lessonType,
      teacherId: teacherId ?? this.teacherId,
      classroomId: classroomId ?? this.classroomId,
      studentIds: studentIds ?? this.studentIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'title': title,
      'language': language.name,
      'lessonType': lessonType.name,
      'teacherId': teacherId,
      'classroomId': classroomId,
      'studentIds': studentIds,
      'startTime': useFirestoreTimestamp
          ? Timestamp.fromDate(startTime)
          : startTime.toIso8601String(),
      'endTime': useFirestoreTimestamp
          ? Timestamp.fromDate(endTime)
          : endTime.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawStudents = map['studentIds'];
    final students = rawStudents is Iterable
        ? rawStudents.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final start = parseFlexibleDateTime(map['startTime']);
    final end = parseFlexibleDateTime(
      map['endTime'],
      fallback: start.add(const Duration(minutes: 60)),
    );

    return Lesson(
      id: documentId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? 'Untitled Lesson',
      language: CourseLanguage.fromString(map['language'] as String?),
      lessonType: LessonType.fromString(map['lessonType'] as String?),
      teacherId: map['teacherId'] as String? ?? '',
      classroomId: map['classroomId'] as String? ?? '',
      studentIds: students,
      startTime: start,
      endTime: end,
      status: LessonStatus.fromString(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          language == other.language &&
          lessonType == other.lessonType &&
          teacherId == other.teacherId &&
          classroomId == other.classroomId &&
          listEquals(studentIds, other.studentIds) &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          status == other.status &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        language,
        lessonType,
        teacherId,
        classroomId,
        Object.hashAll(studentIds),
        startTime,
        endTime,
        status,
        notes,
        createdAt,
      );
}
