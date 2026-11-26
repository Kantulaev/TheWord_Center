import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'lesson_form_dialog.dart';

/// 7-day weekly overview showing Monday–Sunday with compact Liquid Glass lesson cards.
class WeekTimetableView extends ConsumerWidget {
  const WeekTimetableView({
    super.key,
    required this.lessons,
    required this.selectedDate,
    required this.onSelectLesson,
    required this.onOpenDay,
  });

  final List<Lesson> lessons;
  final DateTime selectedDate;
  final ValueChanged<Lesson> onSelectLesson;
  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    );

    final now = ref.watch(liveClockProvider).value ?? DateTime.now();
    final teachers = ref.watch(teachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final expandedWeek = Lesson.expandAll(
      lessons,
      days.first,
      days.last,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          return Column(
            children: [
              for (final day in days) ...[
                _buildDayGroupCard(
                  context,
                  day: day,
                  now: now,
                  dayLessons:
                      expandedWeek.where((l) => l.isOnDate(day)).toList(),
                  teachers: teachers,
                  classrooms: classrooms,
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        }

        return LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          elevation: 0.7,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < days.length; i++) ...[
                Expanded(
                  child: _buildDayColumn(
                    context,
                    day: days[i],
                    now: now,
                    dayLessons:
                        expandedWeek.where((l) => l.isOnDate(days[i])).toList(),
                    teachers: teachers,
                    classrooms: classrooms,
                  ),
                ),
                if (i < days.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayColumn(
    BuildContext context, {
    required DateTime day,
    required DateTime now,
    required List<Lesson> dayLessons,
    required Map<String, dynamic> teachers,
    required Map<String, dynamic> classrooms,
  }) {
    final isToday = _sameDay(day, now);
    final isSelected = _sameDay(day, selectedDate);
    final accent = isToday
        ? AppColors.liveEmerald
        : (isSelected ? AppColors.englishAccent(context) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidGlassContainer(
          borderRadius: 16,
          blurSigma: 12,
          elevation: isToday || isSelected ? 0.6 : 0.2,
          tintColor: accent,
          tintStrength: accent != null ? 0.14 : 0.0,
          isSelected: isToday || isSelected,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onTap: () => onOpenDay(day),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE').format(day).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accent ?? AppColors.textMuted(context),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      DateFormat('MMM d').format(day),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add lesson on ${DateFormat('MMM d').format(day)}',
                  icon: const Icon(CupertinoIcons.add_circled, size: 17),
                  onPressed: () {
                    showLessonFormModal(
                      context,
                      initialStartTime:
                          DateTime(day.year, day.month, day.day, 10, 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (dayLessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
            child: Text(
              'No lessons',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (final lesson in dayLessons) ...[
            _WeekLessonTile(
              lesson: lesson,
              now: now,
              teacherName:
                  (teachers[lesson.teacherId]?.fullName as String?) ??
                      'Teacher',
              roomName:
                  (classrooms[lesson.classroomId]?.name as String?) ?? 'Room',
              onTap: () => onSelectLesson(lesson),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildDayGroupCard(
    BuildContext context, {
    required DateTime day,
    required DateTime now,
    required List<Lesson> dayLessons,
    required Map<String, dynamic> teachers,
    required Map<String, dynamic> classrooms,
  }) {
    final isToday = _sameDay(day, now);
    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 18,
      elevation: isToday ? 0.85 : 0.45,
      tintColor: isToday ? AppColors.liveEmerald : null,
      tintStrength: isToday ? 0.08 : 0.0,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => onOpenDay(day),
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(day),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(
                        label: 'Today',
                        color: AppColors.liveEmerald,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showLessonFormModal(
                    context,
                    initialStartTime:
                        DateTime(day.year, day.month, day.day, 10, 0),
                  );
                },
                icon: const Icon(CupertinoIcons.plus, size: 15),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dayLessons.isEmpty)
            Text(
              'No lessons scheduled.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final lesson in dayLessons) ...[
              _WeekLessonTile(
                lesson: lesson,
                now: now,
                teacherName:
                    (teachers[lesson.teacherId]?.fullName as String?) ??
                        'Teacher',
                roomName:
                    (classrooms[lesson.classroomId]?.name as String?) ?? 'Room',
                onTap: () => onSelectLesson(lesson),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekLessonTile extends StatelessWidget {
  const _WeekLessonTile({
    required this.lesson,
    required this.now,
    required this.teacherName,
    required this.roomName,
    required this.onTap,
  });

  final Lesson lesson;
  final DateTime now;
  final String teacherName;
  final String roomName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLive = lesson.isHappeningNowAt(now);
    final accent = lesson.language.accentColor(context);
    final isCanceled = lesson.status == LessonStatus.canceled;

    return LiquidGlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      elevation: isLive ? 0.8 : 0.25,
      tintColor: isLive ? AppColors.liveEmerald : accent,
      tintStrength: isLive ? 0.15 : 0.09,
      isSelected: isLive,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Opacity(
        opacity: isCanceled ? 0.52 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('h:mm a').format(lesson.startTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLive ? AppColors.liveEmerald : accent,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (isLive)
                  const StatusBadge(
                    label: 'LIVE',
                    color: AppColors.liveEmerald,
                    glow: true,
                    compact: true,
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: accent.withValues(alpha: 0.14),
                    ),
                    child: Text(
                      lesson.language.code,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lesson.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12.5,
                    decoration: isCanceled ? TextDecoration.lineThrough : null,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$teacherName • $roomName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
