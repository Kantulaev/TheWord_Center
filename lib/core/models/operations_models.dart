import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'language_type.dart';

/// Attendance state for a single student on a specific lesson date.
enum AttendanceStatus {
  unmarked,
  present,
  absent,
  excused;

  String get label => switch (this) {
        AttendanceStatus.unmarked => 'Unmarked',
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.excused => 'Excused',
      };

  static AttendanceStatus fromString(String? value) =>
      AttendanceStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AttendanceStatus.unmarked,
      );
}

@immutable
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.lessonId,
    required this.lessonTitle,
    required this.dateKey,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
    required this.status,
    required this.creditDeducted,
    required this.recordedAt,
  });

  final String id;
  final String lessonId;
  final String lessonTitle;
  final String dateKey;
  final String studentId;
  final String studentName;
  final String teacherId;
  final AttendanceStatus status;
  final bool creditDeducted;
  final DateTime recordedAt;

  static String buildId(String lessonId, String dateKey, String studentId) =>
      '${lessonId}_${dateKey}_$studentId';

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    bool? creditDeducted,
    DateTime? recordedAt,
  }) {
    return AttendanceRecord(
      id: id,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      dateKey: dateKey,
      studentId: studentId,
      studentName: studentName,
      teacherId: teacherId,
      status: status ?? this.status,
      creditDeducted: creditDeducted ?? this.creditDeducted,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
      'dateKey': dateKey,
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'status': status.name,
      'creditDeducted': creditDeducted,
      'recordedAt': useFirestoreTimestamp
          ? Timestamp.fromDate(recordedAt)
          : recordedAt.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return AttendanceRecord(
      id: documentId ?? (map['id'] as String? ?? ''),
      lessonId: map['lessonId'] as String? ?? '',
      lessonTitle: map['lessonTitle'] as String? ?? '',
      dateKey: map['dateKey'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Student',
      teacherId: map['teacherId'] as String? ?? '',
      status: AttendanceStatus.fromString(map['status'] as String?),
      creditDeducted: map['creditDeducted'] as bool? ?? false,
      recordedAt: parseFlexibleDateTime(map['recordedAt']),
    );
  }
}

enum PaymentMethod {
  cash,
  transfer,
  card;

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.transfer => 'Bank Transfer',
        PaymentMethod.card => 'Card',
      };

  static PaymentMethod fromString(String? value) =>
      PaymentMethod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentMethod.transfer,
      );
}

@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.groupId,
    required this.amount,
    this.currency = 'USD',
    this.lessonsPurchased = 12,
    this.method = PaymentMethod.transfer,
    this.notes = '',
    required this.paidAt,
    this.recordedBy = '',
  });

  final String id;
  final String studentId;
  final String studentName;
  final String? groupId;
  final double amount;
  final String currency;
  final int lessonsPurchased;
  final PaymentMethod method;
  final String notes;
  final DateTime paidAt;
  final String recordedBy;

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'groupId': groupId,
      'amount': amount,
      'currency': currency,
      'lessonsPurchased': lessonsPurchased,
      'method': method.name,
      'notes': notes,
      'paidAt': useFirestoreTimestamp
          ? Timestamp.fromDate(paidAt)
          : paidAt.toIso8601String(),
      'recordedBy': recordedBy,
    };
  }

  factory PaymentRecord.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return PaymentRecord(
      id: documentId ?? (map['id'] as String? ?? ''),
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Student',
      groupId: map['groupId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'USD',
      lessonsPurchased: (map['lessonsPurchased'] as num?)?.toInt() ?? 12,
      method: PaymentMethod.fromString(map['method'] as String?),
      notes: map['notes'] as String? ?? '',
      paidAt: parseFlexibleDateTime(map['paidAt']),
      recordedBy: map['recordedBy'] as String? ?? '',
    );
  }
}

enum LeadStage {
  newLead,
  trialScheduled,
  attended,
  enrolled,
  lost;

  String get label => switch (this) {
        LeadStage.newLead => 'New Lead',
        LeadStage.trialScheduled => 'Trial Scheduled',
        LeadStage.attended => 'Trial Attended',
        LeadStage.enrolled => 'Enrolled',
        LeadStage.lost => 'Closed / Lost',
      };

  static LeadStage fromString(String? value) => LeadStage.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LeadStage.newLead,
      );
}

@immutable
class TrialLead {
  const TrialLead({
    required this.id,
    required this.fullName,
    this.phone = '',
    this.email = '',
    required this.targetLanguage,
    required this.preferredLevel,
    this.stage = LeadStage.newLead,
    this.trialDate,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final CourseLanguage targetLanguage;
  final String preferredLevel;
  final LeadStage stage;
  final DateTime? trialDate;
  final String notes;
  final DateTime createdAt;

  TrialLead copyWith({
    String? fullName,
    String? phone,
    String? email,
    CourseLanguage? targetLanguage,
    String? preferredLevel,
    LeadStage? stage,
    DateTime? trialDate,
    String? notes,
  }) {
    return TrialLead(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      preferredLevel: preferredLevel ?? this.preferredLevel,
      stage: stage ?? this.stage,
      trialDate: trialDate ?? this.trialDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'targetLanguage': targetLanguage.name,
      'preferredLevel': preferredLevel,
      'stage': stage.name,
      'trialDate': trialDate == null
          ? null
          : (useFirestoreTimestamp
              ? Timestamp.fromDate(trialDate!)
              : trialDate!.toIso8601String()),
      'notes': notes,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory TrialLead.fromMap(Map<String, dynamic> map, {String? documentId}) {
    final lang = CourseLanguage.fromString(map['targetLanguage'] as String?);
    return TrialLead(
      id: documentId ?? (map['id'] as String? ?? ''),
      fullName: map['fullName'] as String? ?? 'Unnamed Lead',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      targetLanguage: lang,
      preferredLevel:
          map['preferredLevel'] as String? ?? ProficiencyLevels.defaultFor(lang),
      stage: LeadStage.fromString(map['stage'] as String?),
      trialDate: map['trialDate'] == null
          ? null
          : parseFlexibleDateTime(map['trialDate']),
      notes: map['notes'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }
}

enum RequestStatus {
  pending,
  approved,
  declined;

  String get label => switch (this) {
        RequestStatus.pending => 'Pending',
        RequestStatus.approved => 'Approved',
        RequestStatus.declined => 'Declined',
      };

  static RequestStatus fromString(String? value) =>
      RequestStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => RequestStatus.pending,
      );
}

@immutable
class RescheduleRequest {
  const RescheduleRequest({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    required this.groupId,
    required this.groupName,
    required this.requestedDate,
    required this.preferredSlot,
    required this.reason,
    this.status = RequestStatus.pending,
    this.staffNote = '',
    required this.createdAt,
  });

  final String id;
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String groupId;
  final String groupName;
  final DateTime requestedDate;
  final String preferredSlot;
  final String reason;
  final RequestStatus status;
  final String staffNote;
  final DateTime createdAt;

  RescheduleRequest copyWith({
    RequestStatus? status,
    String? staffNote,
  }) {
    return RescheduleRequest(
      id: id,
      studentUid: studentUid,
      studentName: studentName,
      studentEmail: studentEmail,
      groupId: groupId,
      groupName: groupName,
      requestedDate: requestedDate,
      preferredSlot: preferredSlot,
      reason: reason,
      status: status ?? this.status,
      staffNote: staffNote ?? this.staffNote,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'studentUid': studentUid,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'groupId': groupId,
      'groupName': groupName,
      'requestedDate': useFirestoreTimestamp
          ? Timestamp.fromDate(requestedDate)
          : requestedDate.toIso8601String(),
      'preferredSlot': preferredSlot,
      'reason': reason,
      'status': status.name,
      'staffNote': staffNote,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory RescheduleRequest.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return RescheduleRequest(
      id: documentId ?? (map['id'] as String? ?? ''),
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? 'Student',
      studentEmail: map['studentEmail'] as String? ?? '',
      groupId: map['groupId'] as String? ?? '',
      groupName: map['groupName'] as String? ?? '',
      requestedDate: parseFlexibleDateTime(map['requestedDate']),
      preferredSlot: map['preferredSlot'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      status: RequestStatus.fromString(map['status'] as String?),
      staffNote: map['staffNote'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }
}

@immutable
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.actorEmail,
    required this.category,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String actorEmail;
  final String category;
  final String summary;
  final DateTime createdAt;

  Map<String, dynamic> toMap({bool useFirestoreTimestamp = false}) {
    return {
      'id': id,
      'actorEmail': actorEmail,
      'category': category,
      'summary': summary,
      'createdAt': useFirestoreTimestamp
          ? Timestamp.fromDate(createdAt)
          : createdAt.toIso8601String(),
    };
  }

  factory ActivityLogEntry.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ActivityLogEntry(
      id: documentId ?? (map['id'] as String? ?? ''),
      actorEmail: map['actorEmail'] as String? ?? 'system',
      category: map['category'] as String? ?? 'General',
      summary: map['summary'] as String? ?? '',
      createdAt: parseFlexibleDateTime(map['createdAt']),
    );
  }
}
