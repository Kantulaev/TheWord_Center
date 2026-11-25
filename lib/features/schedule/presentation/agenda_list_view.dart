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

/// Chronological grouped Agenda list with a live "Happening Now" spotlight.
class AgendaListView extends ConsumerWidget {
  const AgendaListView({
    super.key,
    required this.lessons,
    required this.onSelectLesson,
  });

  final List<Lesson> lessons;
  final ValueChanged<Lesson> onSelectLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();
    final teachers = ref.watch(teachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final students = ref.watch(studentsMapProvider);

    if (lessons.isEmpty) {
      return LiquidGlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.calendar_badge_minus,
                size: 38,
                color: AppColors.textMuted(context),
              ),
              const SizedBox(height: 12),
              Text(
                'No lessons match the current filters',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Try clearing filters or schedule a new Chinese or English session.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final liveLessons =
        lessons.where((l) => l.isHappeningNowAt(now)).toList(growable: false);

    // Group all matching lessons by calendar day
    final grouped = <DateTime, List<Lesson>>{};
    for (final lesson in lessons) {
      final dayKey = DateTime(
        lesson.startTime.year,
        lesson.startTime.month,
        lesson.startTime.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(lesson);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (liveLessons.isNotEmpty) ...[
          Row(
            children: [
              const StatusBadge(
                label: 'Happening Now',
                color: AppColors.liveEmerald,
                glow: true,
              ),
              const SizedBox(width: 8),
              Text(
                '${liveLessons.length} active ${liveLessons.length == 1 ? 'session' : 'sessions'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final lesson in liveLessons) ...[
            _AgendaLessonCard(
              lesson: lesson,
              now: now,
              teacherName:
                  teachers[lesson.teacherId]?.fullName ?? 'Unassigned',
              roomName: classrooms[lesson.classroomId]?.name ?? 'Unassigned',
              studentNames: lesson.studentIds
                  .map((id) => students[id]?.fullName ?? 'Student')
                  .toList(),
              onTap: () => onSelectLesson(lesson),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
        ],
        for (final day in sortedDays) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Row(
              children: [
                Text(
                  _dayHeading(day, now),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                GlassInfoTag(label: '${grouped[day]!.length} lessons'),
              ],
            ),
          ),
          for (final lesson in grouped[day]!) ...[
            _AgendaLessonCard(
              lesson: lesson,
              now: now,
              teacherName:
                  teachers[lesson.teacherId]?.fullName ?? 'Unassigned',
              roomName: classrooms[lesson.classroomId]?.name ?? 'Unassigned',
              studentNames: lesson.studentIds
                  .map((id) => students[id]?.fullName ?? 'Student')
                  .toList(),
              onTap: () => onSelectLesson(lesson),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  String _dayHeading(DateTime day, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today • ${DateFormat('EEE, MMM d').format(day)}';
    if (day == today.add(const Duration(days: 1))) {
      return 'Tomorrow • ${DateFormat('EEE, MMM d').format(day)}';
    }
    return DateFormat('EEEE, MMM d, y').format(day);
  }
}

class _AgendaLessonCard extends StatelessWidget {
  const _AgendaLessonCard({
    required this.lesson,
    required this.now,
    required this.teacherName,
    required this.roomName,
    required this.studentNames,
    required this.onTap,
  });

  final Lesson lesson;
  final DateTime now;
  final String teacherName;
  final String roomName;
  final List<String> studentNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLive = lesson.isHappeningNowAt(now);
    final effectiveStatus = lesson.effectiveStatusAt(now);
    final accent = lesson.language.accentColor(context);
    final isCanceled = lesson.status == LessonStatus.canceled;

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 18,
      elevation: isLive ? 1.0 : 0.55,
      tintColor: isLive ? AppColors.liveEmerald : accent,
      tintStrength: isLive ? 0.12 : 0.06,
      isSelected: isLive,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Opacity(
        opacity: isCanceled ? 0.55 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time rail
            SizedBox(
              width: 96,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('h:mm a').format(lesson.startTime),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isLive ? AppColors.liveEmerald : accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'to ${DateFormat('h:mm a').format(lesson.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${lesson.durationMinutes} min',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted(context),
                        ),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: isLive ? AppColors.liveEmerald : accent,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LanguageBadge(language: lesson.language, compact: true),
                      GlassInfoTag(label: lesson.lessonType.label),
                      StatusBadge(
                        label: effectiveStatus.label,
                        color: effectiveStatus.color(context),
                        glow: isLive,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration:
                              isCanceled ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _MetaChip(
                        icon: CupertinoIcons.person_crop_circle,
                        label: teacherName,
                      ),
                      _MetaChip(
                        icon: CupertinoIcons.building_2_fill,
                        label: roomName,
                      ),
                      _MetaChip(
                        icon: CupertinoIcons.person_2,
                        label: studentNames.isEmpty
                            ? 'No students'
                            : studentNames.join(', '),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted(context)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
