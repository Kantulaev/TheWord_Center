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

/// Validates proposed lesson scheduling in real time to prevent double-booking
/// of classrooms, teachers, and students.
abstract final class ScheduleConflictDetector {
  static final DateFormat _timeFmt = DateFormat('h:mm a');

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

    final teacher = teachersById[candidate.teacherId];
    final classroom = classroomsById[candidate.classroomId];

    if (teacher != null && !teacher.isActive) {
      warnings.add('${teacher.fullName} is currently marked as On Leave.');
    }
    if (teacher != null && !teacher.languages.supports(candidate.language)) {
      warnings.add(
        '${teacher.fullName} is listed under ${teacher.languages.label} rather than ${candidate.language.label}.',
      );
    }
    if (classroom != null && candidate.studentIds.length > classroom.capacity) {
      warnings.add(
        '${classroom.name} seats ${classroom.capacity}, but ${candidate.studentIds.length} students are selected.',
      );
    }

    // Canceled lessons do not block rooms, teachers, or students.
    if (candidate.status == LessonStatus.canceled) {
      return ScheduleValidationResult(
        blockingConflicts: conflicts,
        softWarnings: warnings,
      );
    }

    for (final existing in existingLessons) {
      if (existing.id == candidate.id) continue;
      if (existing.status == LessonStatus.canceled) continue;
      if (!existing.overlapsWith(candidate.startTime, candidate.endTime)) {
        continue;
      }

      final timeWindow =
          '${_timeFmt.format(existing.startTime)}–${_timeFmt.format(existing.endTime)}';

      if (candidate.classroomId.isNotEmpty &&
          existing.classroomId == candidate.classroomId) {
        final roomName = classroom?.name ?? 'Selected classroom';
        conflicts.add(
          ScheduleConflict(
            resourceType: ConflictResourceType.classroom,
            resourceId: candidate.classroomId,
            resourceName: roomName,
            conflictingLesson: existing,
            message:
                '$roomName is already booked for "${existing.title}" ($timeWindow).',
          ),
        );
      }

      if (candidate.teacherId.isNotEmpty &&
          existing.teacherId == candidate.teacherId) {
        final teacherName = teacher?.fullName ?? 'Selected teacher';
        conflicts.add(
          ScheduleConflict(
            resourceType: ConflictResourceType.teacher,
            resourceId: candidate.teacherId,
            resourceName: teacherName,
            conflictingLesson: existing,
            message:
                '$teacherName is already teaching "${existing.title}" ($timeWindow).',
          ),
        );
      }

      for (final studentId in candidate.studentIds) {
        if (existing.studentIds.contains(studentId)) {
          final studentName =
              studentsById[studentId]?.fullName ?? 'Selected student';
          conflicts.add(
            ScheduleConflict(
              resourceType: ConflictResourceType.student,
              resourceId: studentId,
              resourceName: studentName,
              conflictingLesson: existing,
              message:
                  '$studentName is already scheduled in "${existing.title}" ($timeWindow).',
            ),
          );
        }
      }
    }

    return ScheduleValidationResult(
      blockingConflicts: conflicts,
      softWarnings: warnings,
    );
  }
}
