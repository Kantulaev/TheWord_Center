import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';

/// Represents an instructor at "The Word" language center.
@immutable
class Teacher {
  const Teacher({
    required this.id,
    required this.fullName,
    required this.avatarColorHex,
    required this.languages,
    required this.specializations,
    this.phone = '',
    this.email = '',
    this.isActive = true,
    this.notes = '',
    this.hourlyRate = 25.0,
    this.clubRate = 35.0,
    required this.createdAt,
  });

  static const List<String> suggestedSpecializations = [
    'HSK 1-6',
    'Spoken Chinese',
    'Business Mandarin',
    'IELTS',
    'Business English',
    'Academic Writing',
    'Kids',
    'Pronunciation',
  ];

  final String id;
  final String fullName;
  final String avatarColorHex;
  final TeachingLanguageScope languages;
  final List<String> specializations;
  final String phone;
  final String email;
  final bool isActive;
  final String notes;
  final double hourlyRate;
  final double clubRate;
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

  Teacher copyWith({
    String? id,
    String? fullName,
    String? avatarColorHex,
    TeachingLanguageScope? languages,
    List<String>? specializations,
    String? phone,
    String? email,
    bool? isActive,
    String? notes,
    double? hourlyRate,
    double? clubRate,
    DateTime? createdAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      clubRate: clubRate ?? this.clubRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'fullName': fullName,
      'avatarColorHex': avatarColorHex,
      'languages': languages.name,
      'specializations': specializations,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'notes': notes,
      'hourlyRate': hourlyRate,
      'clubRate': clubRate,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawSpecs = map['specializations'];
    final specs = rawSpecs is Iterable
        ? rawSpecs.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return Teacher(
      id: documentId ?? (map['id'] as String? ?? ''),
      fullName: map['fullName'] as String? ?? 'Unnamed Teacher',
      avatarColorHex: map['avatarColorHex'] as String? ?? '1E66F5',
      languages: TeachingLanguageScope.fromString(map['languages'] as String?),
      specializations: specs,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String? ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 25.0,
      clubRate: (map['clubRate'] as num?)?.toDouble() ?? 35.0,
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Teacher &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          avatarColorHex == other.avatarColorHex &&
          languages == other.languages &&
          listEquals(specializations, other.specializations) &&
          phone == other.phone &&
          email == other.email &&
          isActive == other.isActive &&
          notes == other.notes &&
          hourlyRate == other.hourlyRate &&
          clubRate == other.clubRate &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        avatarColorHex,
        languages,
        Object.hashAll(specializations),
        phone,
        email,
        isActive,
        notes,
        hourlyRate,
        clubRate,
        createdAt,
      );
}
