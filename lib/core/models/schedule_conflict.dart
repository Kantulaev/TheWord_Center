import 'package:intl/intl.dart';

import 'classroom.dart';
import 'language_type.dart';
import 'lesson.dart';
import 'student.dart';
import 'teacher.dart';

enum ConflictResourceType {
  classroom,
  teacher,
  student;

  String get label => switch (this) {
        ConflictResourceType.classroom => 'Classroom Conflict',
        ConflictResourceType.teacher => 'Teacher Conflict',
        ConflictResourceType.student => 'Student Conflict',
      };
}

class ScheduleConflict {
  const ScheduleConflict({
    required this.resourceType,
    required this.resourceId,
    required this.resourceName,
    required this.conflictingLesson,
    required this.message,
  });

  final ConflictResourceType resourceType;
  final String resourceId;
  final String resourceName;
  final Lesson conflictingLesson;
  final String message;
}

class ScheduleValidationResult {
  const ScheduleValidationResult({
    required this.blockingConflicts,
    required this.softWarnings,
  });

  final List<ScheduleConflict> blockingConflicts;
  final List<String> softWarnings;

  bool get hasBlockingConflicts => blockingConflicts.isNotEmpty;
  bool get hasWarnings => softWarnings.isNotEmpty;
}

/// Validates proposed one-time or recurring lesson scheduling in real time to
/// prevent double-booking of classrooms, teachers, and students.
abstract final class ScheduleConflictDetector {
  static final DateFormat _timeFmt = DateFormat('h:mm a');
  static final DateFormat _dateFmt = DateFormat('EEE, MMM d');

  static ScheduleValidationResult validate({
    required Lesson candidate,
    required List<Lesson> existingLessons,
    required Map<String, Teacher> teachersById,
    required Map<String, Classroom> classroomsById,
    required Map<String, Student> studentsById,
  }) {
    final conflicts = <ScheduleConflict>[];
    final warnings = <String>[];

    if (!candidate.endTime.isAfter(candidate.startTime)) {
      warnings.add('End time must be after start time.');
      return ScheduleValidationResult(
        blockingConflicts: conflicts,
        softWarnings: warnings,
      );
    }

    final classroom = classroomsById[candidate.classroomId];

    for (final tid in candidate.allTeacherIds) {
      final t = teachersById[tid];
      if (t != null && !t.isActive) {
        warnings.add('${t.fullName} is currently marked as On Leave.');
      }
      if (t != null && !t.languages.supports(candidate.language)) {
        warnings.add(
          '${t.fullName} is listed under ${t.languages.label} rather than ${candidate.language.label}.',
        );
      }
    }
    if (classroom != null && candidate.studentIds.length > classroom.capacity) {
      warnings.add(
        '${classroom.name} seats ${classroom.capacity}, but ${candidate.studentIds.length} students are selected.',
      );
    }

    if (candidate.status == LessonStatus.canceled) {
      return ScheduleValidationResult(
        blockingConflicts: conflicts,
        softWarnings: warnings,
      );
    }

    // Expand candidate across up to 8 weeks if recurring so recurring clashes are caught.
    final candStartDay = DateTime(
      candidate.startTime.year,
      candidate.startTime.month,
      candidate.startTime.day,
    );
    final checkEndDay = candidate.isRecurring
        ? (candidate.recurrenceUntil != null &&
                candidate.recurrenceUntil!
                    .isBefore(candStartDay.add(const Duration(days: 56)))
            ? candidate.recurrenceUntil!
            : candStartDay.add(const Duration(days: 56)))
        : candStartDay;

    final candidateOccurrences =
        candidate.expandIntoRange(candStartDay, checkEndDay);
    if (candidateOccurrences.isEmpty) {
      return ScheduleValidationResult(
        blockingConflicts: conflicts,
        softWarnings: warnings,
      );
    }

    final seenKeys = <String>{};

    for (final existing in existingLessons) {
      if (existing.id == candidate.id) continue;
      if (existing.status == LessonStatus.canceled) continue;

      final existingOccurrences =
          existing.expandIntoRange(candStartDay, checkEndDay);

      for (final candOcc in candidateOccurrences) {
        for (final existOcc in existingOccurrences) {
          if (!existOcc.overlapsWith(candOcc.startTime, candOcc.endTime)) {
            continue;
          }

          final timeWindow =
              '${_dateFmt.format(existOcc.startTime)} • ${_timeFmt.format(existOcc.startTime)}–${_timeFmt.format(existOcc.endTime)}';

          if (candidate.classroomId.isNotEmpty &&
              existing.classroomId == candidate.classroomId) {
            final key = 'room_${existing.id}';
            if (seenKeys.add(key)) {
              final roomName = classroom?.name ?? 'Selected classroom';
              conflicts.add(
                ScheduleConflict(
                  resourceType: ConflictResourceType.classroom,
                  resourceId: candidate.classroomId,
                  resourceName: roomName,
                  conflictingLesson: existOcc,
                  message:
                      '$roomName is already booked for "${existing.title}" ($timeWindow).',
                ),
              );
            }
          }

          for (final tid in candidate.allTeacherIds) {
            if (existing.involvesTeacher(tid)) {
              final key = 'teacher_${tid}_${existing.id}';
              if (seenKeys.add(key)) {
                final teacherName =
                    teachersById[tid]?.fullName ?? 'Selected teacher';
                conflicts.add(
                  ScheduleConflict(
                    resourceType: ConflictResourceType.teacher,
                    resourceId: tid,
                    resourceName: teacherName,
                    conflictingLesson: existOcc,
                    message:
                        '$teacherName is already assigned to "${existing.title}" ($timeWindow).',
                  ),
                );
              }
            }
          }

          for (final studentId in candidate.studentIds) {
            if (existing.studentIds.contains(studentId)) {
              final key = 'student_${studentId}_${existing.id}';
              if (seenKeys.add(key)) {
                final studentName =
                    studentsById[studentId]?.fullName ?? 'Selected student';
                conflicts.add(
                  ScheduleConflict(
                    resourceType: ConflictResourceType.student,
                    resourceId: studentId,
                    resourceName: studentName,
                    conflictingLesson: existOcc,
                    message:
                        '$studentName is already scheduled in "${existing.title}" ($timeWindow).',
                  ),
                );
              }
            }
          }
        }
      }
    }

    return ScheduleValidationResult(
      blockingConflicts: conflicts,
      softWarnings: warnings,
    );
  }
}
