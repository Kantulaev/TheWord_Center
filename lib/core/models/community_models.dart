import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'language_type.dart';

/// Category of an announcement or push notification in "The Word".
enum NotificationCategory {
  speakingClub,
  announcement,
  event,
  reminder;

  String get label => switch (this) {
        NotificationCategory.speakingClub => 'Speaking Club',
        NotificationCategory.announcement => 'Announcement',
        NotificationCategory.event => 'Event',
        NotificationCategory.reminder => 'Reminder',
      };

  IconData get icon => switch (this) {
        NotificationCategory.speakingClub => Icons.forum_rounded,
        NotificationCategory.announcement => Icons.campaign_rounded,
        NotificationCategory.event => Icons.celebration_rounded,
        NotificationCategory.reminder => Icons.alarm_rounded,
      };

  static NotificationCategory fromString(String? value) {
    return NotificationCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationCategory.announcement,
    );
  }
}

/// Quick presets for the center's weekly Speaking Clubs.
enum SpeakingClubPreset {
  kidsClub,
  chineseClub,
  englishClub;

  String get label => switch (this) {
        SpeakingClubPreset.kidsClub => 'Kids Club',
        SpeakingClubPreset.chineseClub => 'Chinese Club',
        SpeakingClubPreset.englishClub => 'English Club',
      };

  String get defaultTitle => switch (this) {
        SpeakingClubPreset.kidsClub => 'Kids Speaking Club',
        SpeakingClubPreset.chineseClub => 'Chinese Speaking Club',
        SpeakingClubPreset.englishClub => 'English Speaking Club',
      };

  String get defaultTopic => switch (this) {
        SpeakingClubPreset.kidsClub => 'Interactive Games & Everyday Vocabulary',
        SpeakingClubPreset.chineseClub => 'Daily Chinese Conversation & Tea Table',
        SpeakingClubPreset.englishClub => 'Fluency Circle, Debate & Real Stories',
      };

  String get defaultLocation => switch (this) {
        SpeakingClubPreset.kidsClub => 'Classroom 5',
        SpeakingClubPreset.chineseClub => 'Main Hall',
        SpeakingClubPreset.englishClub => 'Main Hall',
      };

  CourseLanguage get courseLanguage => switch (this) {
        SpeakingClubPreset.kidsClub => CourseLanguage.english,
        SpeakingClubPreset.chineseClub => CourseLanguage.chinese,
        SpeakingClubPreset.englishClub => CourseLanguage.english,
      };

  static SpeakingClubPreset? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final item in SpeakingClubPreset.values) {
      if (item.name == value) return item;
    }
    return null;
  }
}

/// Controls which users can view a notification or event.
enum AudienceType {
  all,
  teachersOnly,
  studentsOnly,
  specificGroup,
  selectedUsers;

  String get label => switch (this) {
        AudienceType.all => 'All Users',
        AudienceType.teachersOnly => 'Teachers Only',
        AudienceType.studentsOnly => 'Students Only',
        AudienceType.specificGroup => 'Specific Group',
        AudienceType.selectedUsers => 'Selected Users',
      };

  String get shortLabel => switch (this) {
        AudienceType.all => 'All',
        AudienceType.teachersOnly => 'Teachers',
        AudienceType.studentsOnly => 'Students',
        AudienceType.specificGroup => 'Group',
        AudienceType.selectedUsers => 'Selected',
      };

  static AudienceType fromString(String? value) {
    return AudienceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AudienceType.all,
    );
  }
}

/// Checks whether an item with [audience] and target filters is visible to a student.
bool isAudienceVisibleToStudent({
  required AudienceType audience,
  required String targetGroupId,
  required List<String> targetEmails,
  required List<String> targetUids,
  required String studentUid,
  required String studentEmail,
  required List<String> joinedGroupIds,
}) {
  final normEmail = studentEmail.trim().toLowerCase();
  final hasDirectMatch = (normEmail.isNotEmpty && targetEmails.contains(normEmail)) ||
      (studentUid.isNotEmpty && targetUids.contains(studentUid));

  return switch (audience) {
    AudienceType.all => true,
    AudienceType.studentsOnly => true,
    AudienceType.teachersOnly => false,
    AudienceType.specificGroup =>
      (targetGroupId.isNotEmpty && joinedGroupIds.contains(targetGroupId)) ||
          hasDirectMatch,
    AudienceType.selectedUsers => hasDirectMatch,
  };
}

/// Center notification / Speaking Club alert delivered in real time via Firestore & FCM.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.category = NotificationCategory.announcement,
    this.clubPreset,
    this.clubTopic = '',
    this.scheduledAt,
    this.audience = AudienceType.all,
    this.targetGroupId = '',
    this.targetGroupName = '',
    this.targetEmails = const [],
    this.targetUids = const [],
    this.readByUids = const [],
    this.createdByUid = '',
    this.createdByName = 'The Word Staff',
    this.eventId = '',
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final SpeakingClubPreset? clubPreset;
  final String clubTopic;
  final DateTime? scheduledAt;
  final AudienceType audience;
  final String targetGroupId;
  final String targetGroupName;
  final List<String> targetEmails;
  final List<String> targetUids;
  final List<String> readByUids;
  final String createdByUid;
  final String createdByName;
  final String eventId;
  final DateTime createdAt;

  bool isReadBy(String uid) => uid.isNotEmpty && readByUids.contains(uid);

  bool isVisibleToStudent({
    required String studentUid,
    required String studentEmail,
    required List<String> joinedGroupIds,
  }) =>
      isAudienceVisibleToStudent(
        audience: audience,
        targetGroupId: targetGroupId,
        targetEmails: targetEmails,
        targetUids: targetUids,
        studentUid: studentUid,
        studentEmail: studentEmail,
        joinedGroupIds: joinedGroupIds,
      );

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    SpeakingClubPreset? clubPreset,
    String? clubTopic,
    DateTime? scheduledAt,
    AudienceType? audience,
    String? targetGroupId,
    String? targetGroupName,
    List<String>? targetEmails,
    List<String>? targetUids,
    List<String>? readByUids,
    String? createdByUid,
    String? createdByName,
    String? eventId,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      clubPreset: clubPreset ?? this.clubPreset,
      clubTopic: clubTopic ?? this.clubTopic,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      audience: audience ?? this.audience,
      targetGroupId: targetGroupId ?? this.targetGroupId,
      targetGroupName: targetGroupName ?? this.targetGroupName,
      targetEmails: targetEmails ?? this.targetEmails,
      targetUids: targetUids ?? this.targetUids,
      readByUids: readByUids ?? this.readByUids,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    final normalizedEmails = targetEmails
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final uniqueUids =
        targetUids.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.name,
      if (clubPreset != null) 'clubPreset': clubPreset!.name,
      'clubTopic': clubTopic,
      'scheduledAt': scheduledAt == null
          ? null
          : (useFirestoreTimestamp
              ? Timestamp.fromDate(scheduledAt!)
              : scheduledAt!.toIso8601String()),
      'audience': audience.name,
      'targetGroupId': targetGroupId,
      'targetGroupName': targetGroupName,
      // Populated strictly for group-targeted notifications to support indexed queries.
      'publicGroupId': (audience == AudienceType.specificGroup &&
              targetGroupId.isNotEmpty)
          ? targetGroupId
          : null,
      'targetEmails': normalizedEmails,
      'targetUids': uniqueUids,
      'readByUids': readByUids.toSet().toList(),
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'eventId': eventId,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawEmails = map['targetEmails'];
    final emails = rawEmails is Iterable
        ? rawEmails
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    final rawUids = map['targetUids'];
    final uids = rawUids is Iterable
        ? rawUids.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final rawRead = map['readByUids'];
    final readBy = rawRead is Iterable
        ? rawRead.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return AppNotification(
      id: documentId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      category: NotificationCategory.fromString(map['category'] as String?),
      clubPreset: SpeakingClubPreset.fromString(map['clubPreset'] as String?),
      clubTopic: map['clubTopic'] as String? ?? '',
      scheduledAt: map['scheduledAt'] == null
          ? null
          : parseFlexibleDateTime(map['scheduledAt']),
      audience: AudienceType.fromString(map['audience'] as String?),
      targetGroupId: map['targetGroupId'] as String? ?? '',
      targetGroupName: map['targetGroupName'] as String? ?? '',
      targetEmails: emails,
      targetUids: uids,
      readByUids: readBy,
      createdByUid: map['createdByUid'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? 'The Word Staff',
      eventId: map['eventId'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          message == other.message &&
          category == other.category &&
          clubPreset == other.clubPreset &&
          clubTopic == other.clubTopic &&
          scheduledAt == other.scheduledAt &&
          audience == other.audience &&
          targetGroupId == other.targetGroupId &&
          targetGroupName == other.targetGroupName &&
          listEquals(targetEmails, other.targetEmails) &&
          listEquals(targetUids, other.targetUids) &&
          listEquals(readByUids, other.readByUids) &&
          createdByUid == other.createdByUid &&
          createdByName == other.createdByName &&
          eventId == other.eventId &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        message,
        category,
        clubPreset,
        clubTopic,
        scheduledAt,
        audience,
        targetGroupId,
        targetGroupName,
        Object.hashAll(targetEmails),
        Object.hashAll(targetUids),
        Object.hashAll(readByUids),
        createdByUid,
        createdByName,
        eventId,
        createdAt,
      );
}

/// Center event or workshop with date-based upcoming/history filtering and audience access control.
@immutable
class CenterEvent {
  const CenterEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.eventDate,
    this.location = 'Main Hall',
    this.tag = 'Speaking Club',
    this.linkOrImageUrl = '',
    this.createdByUid = '',
    this.createdByName = 'The Word Staff',
    this.audience = AudienceType.all,
    this.targetGroupId = '',
    this.targetGroupName = '',
    this.targetEmails = const [],
    this.targetUids = const [],
    required this.createdAt,
  });

  static const List<String> suggestedTags = [
    'Speaking Club',
    'Workshop',
    'HSK Exam',
    'Cultural Day',
    'Movie Night',
    'Staff Meeting',
  ];

  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String tag;
  final String linkOrImageUrl;
  final String createdByUid;
  final String createdByName;
  final AudienceType audience;
  final String targetGroupId;
  final String targetGroupName;
  final List<String> targetEmails;
  final List<String> targetUids;
  final DateTime createdAt;

  /// Events starting within the past 2 hours or later stay in "Upcoming".
  bool isUpcoming([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return eventDate.isAfter(now.subtract(const Duration(hours: 2)));
  }

  bool isPast([DateTime? reference]) => !isUpcoming(reference);

  bool isVisibleToStudent({
    required String studentUid,
    required String studentEmail,
    required List<String> joinedGroupIds,
  }) =>
      isAudienceVisibleToStudent(
        audience: audience,
        targetGroupId: targetGroupId,
        targetEmails: targetEmails,
        targetUids: targetUids,
        studentUid: studentUid,
        studentEmail: studentEmail,
        joinedGroupIds: joinedGroupIds,
      );

  CenterEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    String? tag,
    String? linkOrImageUrl,
    String? createdByUid,
    String? createdByName,
    AudienceType? audience,
    String? targetGroupId,
    String? targetGroupName,
    List<String>? targetEmails,
    List<String>? targetUids,
    DateTime? createdAt,
  }) {
    return CenterEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      tag: tag ?? this.tag,
      linkOrImageUrl: linkOrImageUrl ?? this.linkOrImageUrl,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
      audience: audience ?? this.audience,
      targetGroupId: targetGroupId ?? this.targetGroupId,
      targetGroupName: targetGroupName ?? this.targetGroupName,
      targetEmails: targetEmails ?? this.targetEmails,
      targetUids: targetUids ?? this.targetUids,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    final normalizedEmails = targetEmails
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final uniqueUids =
        targetUids.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': useFirestoreTimestamp
          ? Timestamp.fromDate(eventDate)
          : eventDate.toIso8601String(),
      'location': location,
      'tag': tag,
      'linkOrImageUrl': linkOrImageUrl,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'audience': audience.name,
      'targetGroupId': targetGroupId,
      'targetGroupName': targetGroupName,
      'publicGroupId': (audience == AudienceType.specificGroup &&
              targetGroupId.isNotEmpty)
          ? targetGroupId
          : null,
      'targetEmails': normalizedEmails,
      'targetUids': uniqueUids,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory CenterEvent.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawEmails = map['targetEmails'];
    final emails = rawEmails is Iterable
        ? rawEmails
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    final rawUids = map['targetUids'];
    final uids = rawUids is Iterable
        ? rawUids.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    return CenterEvent(
      id: documentId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      eventDate: parseFlexibleDateTime(map['eventDate']),
      location: map['location'] as String? ?? 'Main Hall',
      tag: map['tag'] as String? ?? 'Event',
      linkOrImageUrl: map['linkOrImageUrl'] as String? ?? '',
      createdByUid: map['createdByUid'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? 'The Word Staff',
      audience: AudienceType.fromString(map['audience'] as String?),
      targetGroupId: map['targetGroupId'] as String? ?? '',
      targetGroupName: map['targetGroupName'] as String? ?? '',
      targetEmails: emails,
      targetUids: uids,
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CenterEvent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          eventDate == other.eventDate &&
          location == other.location &&
          tag == other.tag &&
          linkOrImageUrl == other.linkOrImageUrl &&
          createdByUid == other.createdByUid &&
          createdByName == other.createdByName &&
          audience == other.audience &&
          targetGroupId == other.targetGroupId &&
          targetGroupName == other.targetGroupName &&
          listEquals(targetEmails, other.targetEmails) &&
          listEquals(targetUids, other.targetUids) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        eventDate,
        location,
        tag,
        linkOrImageUrl,
        createdByUid,
        createdByName,
        audience,
        targetGroupId,
        targetGroupName,
        Object.hashAll(targetEmails),
        Object.hashAll(targetUids),
        createdAt,
      );
}
