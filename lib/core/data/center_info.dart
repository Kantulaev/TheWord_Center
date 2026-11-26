import 'package:flutter/foundation.dart';

/// Official branch metadata and operating schedule for The Word Language Center.
@immutable
class WeekdayHours {
  const WeekdayHours({
    required this.weekday,
    required this.shortDay,
    required this.isOpen,
    this.openHour = 0,
    this.openMinute = 0,
    this.closeHour = 0,
    this.closeMinute = 0,
  });

  final int weekday;
  final String shortDay;
  final bool isOpen;
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;

  int get openMinutes => openHour * 60 + openMinute;
  int get closeMinutes => closeHour * 60 + closeMinute;

  String get displayRange {
    if (!isOpen) return 'Closed';
    final oh = openHour.toString().padLeft(2, '0');
    final om = openMinute.toString().padLeft(2, '0');
    final ch = closeHour.toString().padLeft(2, '0');
    final cm = closeMinute.toString().padLeft(2, '0');
    return '$oh:$om–$ch:$cm';
  }
}

abstract final class CenterInfo {
  static const String centerName = 'The Word Language Center';
  static const String instagramHandle = '@the_word_bishkek';
  static const String address = 'Ogonbaeva 222, Bishkek, Kyrgyzstan, 720000';
  static const String landmarks = 'Near Victory Business Center (280 m) & Detsky Mir (3 min)';
  static const String primaryPhone = '+996 703 870 008';
  static const String secondaryPhone = '+996 702 825 925';
  static const String whatsappPhone = '996703870008';

  static const Map<int, WeekdayHours> schedule = {
    DateTime.monday: WeekdayHours(
      weekday: DateTime.monday,
      shortDay: 'Mon',
      isOpen: true,
      openHour: 8,
      openMinute: 30,
      closeHour: 19,
      closeMinute: 0,
    ),
    DateTime.tuesday: WeekdayHours(
      weekday: DateTime.tuesday,
      shortDay: 'Tue',
      isOpen: true,
      openHour: 9,
      openMinute: 0,
      closeHour: 18,
      closeMinute: 0,
    ),
    DateTime.wednesday: WeekdayHours(
      weekday: DateTime.wednesday,
      shortDay: 'Wed',
      isOpen: true,
      openHour: 8,
      openMinute: 30,
      closeHour: 19,
      closeMinute: 0,
    ),
    DateTime.thursday: WeekdayHours(
      weekday: DateTime.thursday,
      shortDay: 'Thu',
      isOpen: true,
      openHour: 9,
      openMinute: 0,
      closeHour: 18,
      closeMinute: 0,
    ),
    DateTime.friday: WeekdayHours(
      weekday: DateTime.friday,
      shortDay: 'Fri',
      isOpen: true,
      openHour: 8,
      openMinute: 30,
      closeHour: 19,
      closeMinute: 0,
    ),
    DateTime.saturday: WeekdayHours(
      weekday: DateTime.saturday,
      shortDay: 'Sat',
      isOpen: true,
      openHour: 9,
      openMinute: 0,
      closeHour: 18,
      closeMinute: 0,
    ),
    DateTime.sunday: WeekdayHours(
      weekday: DateTime.sunday,
      shortDay: 'Sun',
      isOpen: false,
    ),
  };

  static WeekdayHours hoursForDate(DateTime date) =>
      schedule[date.weekday] ?? schedule[DateTime.monday]!;

  static bool isWithinWorkingHours(DateTime start, DateTime end) {
    final hours = hoursForDate(start);
    if (!hours.isOpen) return false;
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    return startMins >= hours.openMinutes && endMins <= hours.closeMinutes;
  }

  static const String compactHoursSummary =
      'Mon/Wed/Fri 08:30–19:00 • Tue/Thu/Sat 09:00–18:00 • Sun Closed';
}
