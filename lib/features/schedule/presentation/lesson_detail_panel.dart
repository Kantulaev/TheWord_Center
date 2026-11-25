import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'lesson_form_dialog.dart';

/// Slide-over / sheet detail inspector for a single scheduled lesson.
class LessonDetailPanel extends ConsumerWidget {
  const LessonDetailPanel({
    super.key,
    required this.lessonId,
    this.onClose,
  });

  final String lessonId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
    final lesson = lessons.cast<Lesson?>().firstWhere(
          (l) => l?.id == lessonId,
          orElse: () => null,
        );

    if (lesson == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Lesson was deleted or is no longer available.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final teachers = ref.watch(teachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final students = ref.watch(studentsMapProvider);
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();

    final teacher = teachers[lesson.teacherId];
    final classroom = classrooms[lesson.classroomId];
    final effectiveStatus = lesson.effectiveStatusAt(now);
    final isLive = lesson.isHappeningNowAt(now);
    final accent = lesson.language.accentColor(context);

    final dateStr = DateFormat('EEEE, MMM d, y').format(lesson.startTime);
    final timeStr =
        '${DateFormat('h:mm a').format(lesson.startTime)} – ${DateFormat('h:mm a').format(lesson.endTime)}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LanguageBadge(language: lesson.language),
              const SizedBox(width: 8),
              GlassInfoTag(label: lesson.lessonType.label),
              const Spacer(),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close Inspector',
                  onPressed: onClose,
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lesson.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          StatusBadge(
            label: effectiveStatus.label,
            color: effectiveStatus.color(context),
            glow: isLive,
          ),
          const SizedBox(height: 18),
          LiquidGlassContainer(
            borderRadius: 20,
            blurSigma: 14,
            elevation: 0.4,
            tintColor: accent,
            tintStrength: 0.05,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _DetailRow(
                  icon: CupertinoIcons.calendar,
                  label: 'Date',
                  value: dateStr,
                ),
                const Divider(height: 18),
                _DetailRow(
                  icon: CupertinoIcons.clock,
                  label: 'Time',
                  value: '$timeStr (${lesson.durationMinutes} min)',
                ),
                const Divider(height: 18),
                _DetailRow(
                  icon: CupertinoIcons.building_2_fill,
                  label: 'Classroom',
                  value: classroom?.name ?? 'Unassigned Room',
                  onTap: classroom == null
                      ? null
                      : () {
                          ref
                              .read(inspectorSelectionProvider.notifier)
                              .open(InspectorTarget.classroom(classroom.id));
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Instructor',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          LiquidGlassContainer(
            borderRadius: 20,
            blurSigma: 14,
            elevation: 0.4,
            padding: const EdgeInsets.all(12),
            onTap: teacher == null
                ? null
                : () {
                    ref
                        .read(inspectorSelectionProvider.notifier)
                        .open(InspectorTarget.teacher(teacher.id));
                  },
            child: Row(
              children: [
                EntityAvatar(
                  initials: teacher?.initials ?? '?',
                  color: teacher != null
                      ? AppColors.fromHex(teacher.avatarColorHex)
                      : AppColors.completedSlate,
                  size: 40,
                  isActiveDot: teacher?.isActive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher?.fullName ?? 'Unassigned Teacher',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        teacher == null
                            ? 'No teacher selected'
                            : '${teacher.languages.label} • ${teacher.specializations.take(2).join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (teacher != null)
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Assigned Students (${lesson.studentIds.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (lesson.studentIds.isEmpty)
            Text(
              'No students assigned yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              children: [
                for (final sid in lesson.studentIds) ...[
                  Builder(
                    builder: (context) {
                      final student = students[sid];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LiquidGlassContainer(
                          borderRadius: 18,
                          blurSigma: 12,
                          elevation: 0.3,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onTap: student == null
                              ? null
                              : () {
                                  ref
                                      .read(inspectorSelectionProvider.notifier)
                                      .open(
                                        InspectorTarget.student(student.id),
                                      );
                                },
                          child: Row(
                            children: [
                              EntityAvatar(
                                initials: student?.initials ?? '?',
                                color: student?.targetLanguage
                                        .accentColor(context) ??
                                    accent,
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student?.fullName ?? 'Unknown Student',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    if (student != null)
                                      Text(
                                        '${student.proficiencyLevel} • ${student.remainingCredits} credits left',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              if (student != null)
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 15,
                                  color: AppColors.textMuted(context),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Quick Status Update',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final st in LessonStatus.values)
                LiquidGlassPillButton(
                  label: st.label,
                  selected: lesson.status == st,
                  accentColor: st.color(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  onTap: () async {
                    await ref
                        .read(dataRepositoryProvider)
                        .upsertLesson(lesson.copyWith(status: st));
                  },
                ),
            ],
          ),
          if (lesson.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              child: Text(
                lesson.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    showLessonFormModal(context, existing: lesson);
                  },
                  icon: const Icon(CupertinoIcons.pencil, size: 17),
                  label: const Text('Edit Lesson'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showConfirmDeleteDialog(
                    context,
                    title: 'Delete Lesson',
                    message:
                        'Remove "${lesson.title}" from the timetable? This updates all connected devices immediately.',
                  );
                  if (!confirmed || !context.mounted) return;
                  await ref
                      .read(dataRepositoryProvider)
                      .deleteLesson(lesson.id);
                  onClose?.call();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dangerRose,
                  side: BorderSide(
                    color: AppColors.dangerRose.withValues(alpha: 0.45),
                  ),
                ),
                icon: const Icon(CupertinoIcons.trash, size: 17),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted(context)),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: AppColors.textMuted(context),
          ),
        ],
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
  }
}
