import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';

/// Represents an enrolled student studying Chinese or English at "The Word".
@immutable
class Student {
  const Student({
    required this.id,
    required this.fullName,
    required this.targetLanguage,
    required this.proficiencyLevel,
    required this.format,
    this.primaryTeacherId,
    required this.remainingCredits,
    this.phone = '',
    this.email = '',
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final CourseLanguage targetLanguage;
  final String proficiencyLevel;
  final LessonType format;
  final String? primaryTeacherId;
  final int remainingCredits;
  final String phone;
  final String email;
  final String notes;
  final DateTime createdAt;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Student copyWith({
    String? id,
    String? fullName,
    CourseLanguage? targetLanguage,
    String? proficiencyLevel,
    LessonType? format,
    String? primaryTeacherId,
    bool clearPrimaryTeacher = false,
    int? remainingCredits,
    String? phone,
    String? email,
    String? notes,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      format: format ?? this.format,
      primaryTeacherId: clearPrimaryTeacher
          ? null
          : (primaryTeacherId ?? this.primaryTeacherId),
      remainingCredits: remainingCredits ?? this.remainingCredits,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'fullName': fullName,
      'targetLanguage': targetLanguage.name,
      'proficiencyLevel': proficiencyLevel,
      'format': format.name,
      'primaryTeacherId': primaryTeacherId,
      'remainingCredits': remainingCredits,
      'phone': phone,
      'email': email,
      'notes': notes,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final lang = CourseLanguage.fromString(map['targetLanguage'] as String?);
    return Student(
      id: documentId ?? (map['id'] as String? ?? ''),
      fullName: map['fullName'] as String? ?? 'Unnamed Student',
      targetLanguage: lang,
      proficiencyLevel: map['proficiencyLevel'] as String? ??
          ProficiencyLevels.defaultFor(lang),
      format: LessonType.fromString(map['format'] as String?),
      primaryTeacherId: map['primaryTeacherId'] as String?,
      remainingCredits: (map['remainingCredits'] as num?)?.toInt() ?? 0,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          targetLanguage == other.targetLanguage &&
          proficiencyLevel == other.proficiencyLevel &&
          format == other.format &&
          primaryTeacherId == other.primaryTeacherId &&
          remainingCredits == other.remainingCredits &&
          phone == other.phone &&
          email == other.email &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        targetLanguage,
        proficiencyLevel,
        format,
        primaryTeacherId,
        remainingCredits,
        phone,
        email,
        notes,
        createdAt,
      );
}
