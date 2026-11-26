import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Course and session categories offered by "The Word".
enum CourseLanguage {
  chinese,
  english,
  sharing;

  String get label => switch (this) {
        CourseLanguage.chinese => 'Chinese',
        CourseLanguage.english => 'English',
        CourseLanguage.sharing => 'Sharing',
      };

  String get nativeSublabel => switch (this) {
        CourseLanguage.chinese => 'Mandarin',
        CourseLanguage.english => 'English',
        CourseLanguage.sharing => 'Open Chat',
      };

  String get code => switch (this) {
        CourseLanguage.chinese => 'ZH',
        CourseLanguage.english => 'EN',
        CourseLanguage.sharing => 'SH',
      };

  Color accentColor(BuildContext context) => switch (this) {
        CourseLanguage.chinese => AppColors.chineseAccent(context),
        CourseLanguage.english => AppColors.englishAccent(context),
        CourseLanguage.sharing => AppColors.sharingAccent(context),
      };

  Color get secondaryAccent => switch (this) {
        CourseLanguage.chinese => AppColors.chineseCoralGold,
        CourseLanguage.english => AppColors.englishCyan,
        CourseLanguage.sharing => AppColors.sharingTeal,
      };

  static CourseLanguage fromString(String? value) {
    return CourseLanguage.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CourseLanguage.chinese,
    );
  }
}

/// Languages a teacher is qualified to teach.
enum TeachingLanguageScope {
  chinese,
  english,
  both;

  String get label => switch (this) {
        TeachingLanguageScope.chinese => 'Chinese',
        TeachingLanguageScope.english => 'English',
        TeachingLanguageScope.both => 'Both',
      };

  bool supports(CourseLanguage language) => switch (this) {
        TeachingLanguageScope.chinese =>
          language == CourseLanguage.chinese ||
              language == CourseLanguage.sharing,
        TeachingLanguageScope.english =>
          language == CourseLanguage.english ||
              language == CourseLanguage.sharing,
        TeachingLanguageScope.both => true,
      };

  Color accentColor(BuildContext context) => switch (this) {
        TeachingLanguageScope.chinese => AppColors.chineseAccent(context),
        TeachingLanguageScope.english => AppColors.englishAccent(context),
        TeachingLanguageScope.both => AppColors.bilingualIndigo,
      };

  static TeachingLanguageScope fromString(String? value) {
    return TeachingLanguageScope.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TeachingLanguageScope.both,
    );
  }
}

/// Delivery format of a lesson or student enrollment.
enum LessonType {
  oneOnOne,
  group;

  String get label => switch (this) {
        LessonType.oneOnOne => '1-on-1',
        LessonType.group => 'Group',
      };

  String get studentFormatLabel => switch (this) {
        LessonType.oneOnOne => 'Individual',
        LessonType.group => 'Group',
      };

  static LessonType fromString(String? value) {
    return LessonType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LessonType.oneOnOne,
    );
  }
}

/// Lifecycle state of a scheduled lesson.
enum LessonStatus {
  scheduled,
  inProgress,
  completed,
  canceled;

  String get label => switch (this) {
        LessonStatus.scheduled => 'Scheduled',
        LessonStatus.inProgress => 'In Progress',
        LessonStatus.completed => 'Completed',
        LessonStatus.canceled => 'Canceled',
      };

  Color color(BuildContext context) => switch (this) {
        LessonStatus.scheduled => AppColors.englishAccent(context),
        LessonStatus.inProgress => AppColors.liveEmerald,
        LessonStatus.completed => AppColors.completedSlate,
        LessonStatus.canceled => AppColors.dangerRose,
      };

  static LessonStatus fromString(String? value) {
    return LessonStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LessonStatus.scheduled,
    );
  }
}

/// Standard proficiency levels for Chinese (HSK) and English (CEFR).
abstract final class ProficiencyLevels {
  static const List<String> chinese = [
    'HSK 1',
    'HSK 2',
    'HSK 3',
    'HSK 4',
    'HSK 5',
    'HSK 6',
  ];

  static const List<String> english = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];

  static List<String> forLanguage(CourseLanguage language) => switch (language) {
        CourseLanguage.chinese => chinese,
        CourseLanguage.english => english,
        CourseLanguage.sharing => const ['All Levels'],
      };

  static String defaultFor(CourseLanguage language) => switch (language) {
        CourseLanguage.chinese => 'HSK 1',
        CourseLanguage.english => 'A1',
        CourseLanguage.sharing => 'All Levels',
      };
}

/// Safely parses Firestore [Timestamp], ISO strings, milliseconds, or [DateTime].
DateTime parseFlexibleDateTime(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  }
  return fallback ?? DateTime.now();
}
