import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';

/// Represents a physical or virtual classroom at "The Word".
@immutable
class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    required this.capacity,
    required this.equipmentTags,
    this.notes = '',
    required this.createdAt,
  });

  static const List<String> standardEquipment = [
    'Smartboard',
    'TV Screen',
    'Audio System',
    'Whiteboard',
  ];

  final String id;
  final String name;
  final int capacity;
  final List<String> equipmentTags;
  final String notes;
  final DateTime createdAt;

  Classroom copyWith({
    String? id,
    String? name,
    int? capacity,
    List<String>? equipmentTags,
    String? notes,
    DateTime? createdAt,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      equipmentTags: equipmentTags ?? this.equipmentTags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'equipmentTags': equipmentTags,
      'notes': notes,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory Classroom.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final rawTags = map['equipmentTags'];
    final tags = rawTags is Iterable
        ? rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return Classroom(
      id: documentId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? 'Unnamed Room',
      capacity: (map['capacity'] as num?)?.toInt() ?? 4,
      equipmentTags: tags,
      notes: map['notes'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Classroom &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          capacity == other.capacity &&
          listEquals(equipmentTags, other.equipmentTags) &&
          notes == other.notes &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        capacity,
        Object.hashAll(equipmentTags),
        notes,
        createdAt,
      );
}
