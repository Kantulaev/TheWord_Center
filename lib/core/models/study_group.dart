import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';
import 'lesson.dart';

/// Tracks an enrolled learner's 12-lesson package & payment status inside a [StudyGroup].
@immutable
class GroupMemberPayment {
  const GroupMemberPayment({
    required this.memberId,
    required this.fullName,
    this.email = '',
    this.totalPaidLessons = 12,
    this.lessonsRemaining = 12,
    this.hasPaid = true,
  });

  final String memberId;
  final String fullName;
  final String email;
  final int totalPaidLessons;
  final int lessonsRemaining;
  final bool hasPaid;

  GroupMemberPayment copyWith({
    String? memberId,
    String? fullName,
    String? email,
    int? totalPaidLessons,
    int? lessonsRemaining,
    bool? hasPaid,
  }) {
    return GroupMemberPayment(
      memberId: memberId ?? this.memberId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      totalPaidLessons: totalPaidLessons ?? this.totalPaidLessons,
      lessonsRemaining: lessonsRemaining ?? this.lessonsRemaining,
      hasPaid: hasPaid ?? this.hasPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'fullName': fullName,
      'email': email,
      'totalPaidLessons': totalPaidLessons,
      'lessonsRemaining': lessonsRemaining,
      'hasPaid': hasPaid,
    };
  }

  factory GroupMemberPayment.fromMap(Map<String, dynamic> map) {
    return GroupMemberPayment(
      memberId: map['memberId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? 'Student',
      email: map['email'] as String? ?? '',
      totalPaidLessons: (map['totalPaidLessons'] as num?)?.toInt() ?? 12,
      lessonsRemaining: (map['lessonsRemaining'] as num?)?.toInt() ?? 12,
      hasPaid: map['hasPaid'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMemberPayment &&
          runtimeType == other.runtimeType &&
          memberId == other.memberId &&
          fullName == other.fullName &&
          email == other.email &&
          totalPaidLessons == other.totalPaidLessons &&
          lessonsRemaining == other.lessonsRemaining &&
          hasPaid == other.hasPaid;

  @override
  int get hashCode => Object.hash(
        memberId,
        fullName,
        email,
        totalPaidLessons,
        lessonsRemaining,
        hasPaid,
      );
}

/// Represents an HSK or CEFR study cohort with a steady teacher, weekly schedule,
/// and 12-lesson payment tracking for enrolled students.
@immutable
class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.language,
    required this.level,
    required this.teacherId,
    required this.classroomId,
    required this.scheduleWeekdays,
    required this.startHour,
    required this.startMinute,
    this.durationMinutes = 90,
    this.members = const [],
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final CourseLanguage language;
  final String level;
  final String teacherId;
  final String classroomId;
  final List<int> scheduleWeekdays;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final List<GroupMemberPayment> members;
  final String notes;
  final DateTime createdAt;

  String get scheduleSummary {
    if (scheduleWeekdays.isEmpty) return 'Flexible schedule';
    final sorted = [...scheduleWeekdays]..sort();
    final days = sorted.map(Lesson.weekdayShortLabel).join(', ');
    final h = startHour % 12 == 0 ? 12 : startHour % 12;
    final m = startMinute.toString().padLeft(2, '0');
    final period = startHour >= 12 ? 'PM' : 'AM';
    return '$days • $h:$m $period (${durationMinutes}m)';
  }

  StudyGroup copyWith({
    String? id,
    String? name,
    CourseLanguage? language,
    String? level,
    String? teacherId,
    String? classroomId,
    List<int>? scheduleWeekdays,
    int? startHour,
    int? startMinute,
    int? durationMinutes,
    List<GroupMemberPayment>? members,
    String? notes,
    DateTime? createdAt,
  }) {
    return StudyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      language: language ?? this.language,
      level: level ?? this.level,
      teacherId: teacherId ?? this.teacherId,
      classroomId: classroomId ?? this.classroomId,
      scheduleWeekdays: scheduleWeekdays ?? this.scheduleWeekdays,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      members: members ?? this.members,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'name': name,
      'language': language.name,
      'level': level,
      'teacherId': teacherId,
      'classroomId': classroomId,
      'scheduleWeekdays': scheduleWeekdays,
      'startHour': startHour,
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'members': members.map((m) => m.toMap()).toList(),
      'notes': notes,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  /// Public group metadata stored in `groups/{id}` with NO classmate emails,
  /// payment records, or private teacher notes.
  Map<String, dynamic> toPublicMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'name': name,
      'language': language.name,
      'level': level,
      'teacherId': teacherId,
      'classroomId': classroomId,
      'scheduleWeekdays': scheduleWeekdays,
      'startHour': startHour,
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  /// Staff-only cohort member roster & payment balances stored in `group_rosters/{id}`.
  Map<String, dynamic> toRosterMap({bool useFirestoreTimestamp = false}) {
    return {
      'groupId': id,
      'members': members.map((m) => m.toMap()).toList(),
      'notes': notes,
      'updatedAt': useFirestoreTimestamp
          ? FieldValue.serverTimestamp()
          : DateTime.now().toIso8601String(),
    };
  }

  factory StudyGroup.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final lang = CourseLanguage.fromString(map['language'] as String?);
    final rawDays = map['scheduleWeekdays'];
    final days = rawDays is Iterable
        ? rawDays
            .whereType<num>()
            .map((e) => e.toInt())
            .where((d) => d >= 1 && d <= 7)
            .toList()
        : <int>[];
    final rawMembers = map['members'];
    final members = rawMembers is Iterable
        ? rawMembers
            .whereType<Map<String, dynamic>>()
            .map(GroupMemberPayment.fromMap)
            .toList()
        : <GroupMemberPayment>[];

    return StudyGroup(
      id: documentId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? 'Unnamed Group',
      language: lang,
      level: map['level'] as String? ?? ProficiencyLevels.defaultFor(lang),
      teacherId: map['teacherId'] as String? ?? '',
      classroomId: map['classroomId'] as String? ?? '',
      scheduleWeekdays: days,
      startHour: (map['startHour'] as num?)?.toInt() ?? 18,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 90,
      members: members,
      notes: map['notes'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          language == other.language &&
          level == other.level &&
          teacherId == other.teacherId &&
          classroomId == other.classroomId &&
          listEquals(scheduleWeekdays, other.scheduleWeekdays) &&
          startHour == other.startHour &&
          startMinute == other.startMinute &&
          durationMinutes == other.durationMinutes &&
          listEquals(members, other.members) &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        language,
        level,
        teacherId,
        classroomId,
        Object.hashAll(scheduleWeekdays),
        startHour,
        startMinute,
        durationMinutes,
        Object.hashAll(members),
        notes,
        createdAt,
      );
}
