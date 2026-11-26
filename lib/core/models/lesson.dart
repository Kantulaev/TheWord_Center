import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'language_type.dart';

/// Represents a scheduled class session or recurring series in "The Word".
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
    this.recurrenceWeekdays = const [],
    this.recurrenceUntil,
    this.excludedDateKeys = const [],
    this.isSpeakingClub = false,
    this.coTeacherIds = const [],
  });

  final String id;
  final String title;
  final CourseLanguage language;
  final LessonType lessonType;
  final String teacherId;
  final List<String> coTeacherIds;
  final String classroomId;
  final List<String> studentIds;
  final DateTime startTime;
  final DateTime endTime;
  final LessonStatus status;
  final String notes;
  final DateTime createdAt;

  /// ISO weekday numbers (`DateTime.monday == 1` .. `DateTime.sunday == 7`).
  /// When non-empty, this lesson repeats weekly on the selected days.
  final List<int> recurrenceWeekdays;

  /// Optional inclusive end date for recurring lessons; null means ongoing ("Always").
  final DateTime? recurrenceUntil;

  /// `yyyy-MM-dd` keys for single occurrences canceled/skipped in a recurring series.
  final List<String> excludedDateKeys;

  /// Marks recurring community clubs (e.g., Saturday Chinese & English Speaking Clubs).
  final bool isSpeakingClub;

  bool get isSharing => language == CourseLanguage.sharing;

  List<String> get allTeacherIds => [
        if (teacherId.isNotEmpty) teacherId,
        for (final id in coTeacherIds)
          if (id.isNotEmpty && id != teacherId) id,
      ];

  bool involvesTeacher(String id) => allTeacherIds.contains(id);

  bool get isRecurring => recurrenceWeekdays.isNotEmpty;

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  static String dateKey(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  static String weekdayShortLabel(int weekday) => switch (weekday) {
        DateTime.monday => 'Mon',
        DateTime.tuesday => 'Tue',
        DateTime.wednesday => 'Wed',
        DateTime.thursday => 'Thu',
        DateTime.friday => 'Fri',
        DateTime.saturday => 'Sat',
        DateTime.sunday => 'Sun',
        _ => '',
      };

  String get recurrenceSummary {
    if (!isRecurring) return 'One-time';
    final sorted = [...recurrenceWeekdays]..sort();
    final daysText = sorted.map(weekdayShortLabel).join(', ');
    if (recurrenceUntil == null) {
      return 'Every $daysText • Always';
    }
    return 'Every $daysText • Until ${DateFormat('MMM d').format(recurrenceUntil!)}';
  }

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

  bool isHappeningNowAt(DateTime now) {
    if (status == LessonStatus.canceled || status == LessonStatus.completed) {
      return false;
    }
    if (!now.isBefore(startTime) && now.isBefore(endTime)) {
      return true;
    }
    if (status == LessonStatus.inProgress && isOnDate(now)) {
      return true;
    }
    return false;
  }

  bool isOnDate(DateTime date) =>
      startTime.year == date.year &&
      startTime.month == date.month &&
      startTime.day == date.day;

  bool overlapsWith(DateTime otherStart, DateTime otherEnd) =>
      startTime.isBefore(otherEnd) && otherStart.isBefore(endTime);

  /// Expands this lesson across every calendar day in `[rangeStart, rangeEnd]`.
  List<Lesson> expandIntoRange(DateTime rangeStart, DateTime rangeEnd) {
    final startDay = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
    final endDay = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
    if (endDay.isBefore(startDay)) return const [];

    if (!isRecurring) {
      final lessonDay =
          DateTime(startTime.year, startTime.month, startTime.day);
      if (!lessonDay.isBefore(startDay) && !lessonDay.isAfter(endDay)) {
        return [this];
      }
      return const [];
    }

    final seriesStartDay =
        DateTime(startTime.year, startTime.month, startTime.day);
    final untilDay = recurrenceUntil != null
        ? DateTime(
            recurrenceUntil!.year,
            recurrenceUntil!.month,
            recurrenceUntil!.day,
          )
        : null;
    final duration = endTime.difference(startTime);

    final effectiveStart =
        startDay.isAfter(seriesStartDay) ? startDay : seriesStartDay;
    final effectiveEnd = (untilDay != null && untilDay.isBefore(endDay))
        ? untilDay
        : endDay;
    if (effectiveEnd.isBefore(effectiveStart)) return const [];

    final out = <Lesson>[];
    var cursor = effectiveStart;
    while (!cursor.isAfter(effectiveEnd)) {
      if (recurrenceWeekdays.contains(cursor.weekday) &&
          !excludedDateKeys.contains(dateKey(cursor))) {
        final occStart = DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          startTime.hour,
          startTime.minute,
        );
        final occEnd = occStart.add(duration);
        out.add(
          copyWith(
            startTime: occStart,
            endTime: occEnd,
          ),
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  /// Expands all base lessons (one-time and recurring) into `[rangeStart, rangeEnd]`
  /// sorted chronologically.
  static List<Lesson> expandAll(
    List<Lesson> baseLessons,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final expanded = <Lesson>[];
    for (final lesson in baseLessons) {
      expanded.addAll(lesson.expandIntoRange(rangeStart, rangeEnd));
    }
    expanded.sort((a, b) => a.startTime.compareTo(b.startTime));
    return expanded;
  }

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
    List<int>? recurrenceWeekdays,
    DateTime? recurrenceUntil,
    bool clearRecurrenceUntil = false,
    List<String>? excludedDateKeys,
    bool? isSpeakingClub,
    List<String>? coTeacherIds,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      lessonType: lessonType ?? this.lessonType,
      teacherId: teacherId ?? this.teacherId,
      coTeacherIds: coTeacherIds ?? this.coTeacherIds,
      classroomId: classroomId ?? this.classroomId,
      studentIds: studentIds ?? this.studentIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      recurrenceUntil: clearRecurrenceUntil
          ? null
          : (recurrenceUntil ?? this.recurrenceUntil),
      excludedDateKeys: excludedDateKeys ?? this.excludedDateKeys,
      isSpeakingClub: isSpeakingClub ?? this.isSpeakingClub,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'title': title,
      'language': language.name,
      'lessonType': lessonType.name,
      'teacherId': teacherId,
      'coTeacherIds': coTeacherIds,
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
      'recurrenceWeekdays': recurrenceWeekdays,
      'recurrenceUntil': recurrenceUntil == null
          ? null
          : (useFirestoreTimestamp
              ? Timestamp.fromDate(recurrenceUntil!)
              : recurrenceUntil!.toIso8601String()),
      'excludedDateKeys': excludedDateKeys,
      'isSpeakingClub': isSpeakingClub,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawStudents = map['studentIds'];
    final students = rawStudents is Iterable
        ? rawStudents.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final rawCoTeachers = map['coTeacherIds'];
    final coTeachers = rawCoTeachers is Iterable
        ? rawCoTeachers
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final rawWeekdays = map['recurrenceWeekdays'];
    final weekdays = rawWeekdays is Iterable
        ? rawWeekdays
            .whereType<num>()
            .map((e) => e.toInt())
            .where((d) => d >= 1 && d <= 7)
            .toList()
        : <int>[];

    final rawExcluded = map['excludedDateKeys'];
    final excluded = rawExcluded is Iterable
        ? rawExcluded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
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
      coTeacherIds: coTeachers,
      classroomId: map['classroomId'] as String? ?? '',
      studentIds: students,
      startTime: start,
      endTime: end,
      status: LessonStatus.fromString(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
      recurrenceWeekdays: weekdays,
      recurrenceUntil: map['recurrenceUntil'] == null
          ? null
          : parseFlexibleDateTime(map['recurrenceUntil']),
      excludedDateKeys: excluded,
      isSpeakingClub: map['isSpeakingClub'] as bool? ?? false,
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
          listEquals(coTeacherIds, other.coTeacherIds) &&
          classroomId == other.classroomId &&
          listEquals(studentIds, other.studentIds) &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          status == other.status &&
          notes == other.notes &&
          createdAt == other.createdAt &&
          listEquals(recurrenceWeekdays, other.recurrenceWeekdays) &&
          recurrenceUntil == other.recurrenceUntil &&
          listEquals(excludedDateKeys, other.excludedDateKeys) &&
          isSpeakingClub == other.isSpeakingClub;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        language,
        lessonType,
        teacherId,
        Object.hashAll(coTeacherIds),
        classroomId,
        Object.hashAll(studentIds),
        startTime,
        endTime,
        status,
        notes,
        createdAt,
        Object.hashAll(recurrenceWeekdays),
        recurrenceUntil,
        Object.hashAll(excludedDateKeys),
        isSpeakingClub,
      );
}
