import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/teacher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../presentation/teacher_form_dialog.dart';
import '../../schedule/presentation/lesson_form_dialog.dart';

/// Personal profile card for a teacher showing weekly schedule & total hours.
class TeacherDetailPanel extends ConsumerWidget {
  const TeacherDetailPanel({
    super.key,
    required this.teacherId,
    this.onClose,
  });

  final String teacherId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final teacher = teachers.cast<Teacher?>().firstWhere(
          (t) => t?.id == teacherId,
          orElse: () => null,
        );

    if (teacher == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Teacher record is no longer available.'),
        ),
      );
    }

    final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
    final classrooms = ref.watch(classroomsMapProvider);
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();

    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weeklyLessons = lessons
        .where(
          (l) =>
              l.teacherId == teacher.id &&
              l.status != LessonStatus.canceled &&
              !l.startTime.isBefore(weekStart) &&
              l.startTime.isBefore(weekEnd),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final totalMinutesThisWeek = weeklyLessons.fold<int>(
      0,
      (sum, l) => sum + l.durationMinutes,
    );
    final totalHoursText = (totalMinutesThisWeek / 60.0).toStringAsFixed(1);
    final color = AppColors.fromHex(teacher.avatarColorHex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                initials: teacher.initials,
                color: color,
                size: 56,
                isActiveDot: teacher.isActive,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusBadge(
                          label: teacher.languages.label,
                          color: teacher.languages.accentColor(context),
                          compact: true,
                        ),
                        StatusBadge(
                          label: teacher.isActive ? 'Active' : 'On Leave',
                          color: teacher.isActive
                              ? AppColors.liveEmerald
                              : AppColors.warningAmber,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close Inspector',
                  onPressed: onClose,
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly Teaching Hours & Active Toggle
          LiquidGlassContainer(
            borderRadius: 20,
            blurSigma: 14,
            elevation: 0.4,
            tintColor: color,
            tintStrength: 0.06,
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Scheduled Hours',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalHoursText hrs (${weeklyLessons.length} lessons)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: teacher.isActive,
                      onChanged: (active) async {
                        await ref.read(dataRepositoryProvider).upsertTeacher(
                              teacher.copyWith(isActive: active),
                            );
                      },
                    ),
                  ],
                ),
                if (teacher.email.isNotEmpty || teacher.phone.isNotEmpty) ...[
                  const Divider(height: 18),
                  if (teacher.email.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.mail,
                          size: 15,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            teacher.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  if (teacher.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.phone,
                          size: 15,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            teacher.phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Specializations',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (teacher.specializations.isEmpty)
            Text(
              'No specialization tags added.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in teacher.specializations)
                  GlassInfoTag(label: tag, color: color),
              ],
            ),

          if (teacher.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: Text(
                teacher.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],

          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Live Weekly Schedule',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showLessonFormModal(
                    context,
                    initialTeacherId: teacher.id,
                  );
                },
                icon: const Icon(CupertinoIcons.plus, size: 15),
                label: const Text('Assign Lesson'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (weeklyLessons.isEmpty)
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'No lessons scheduled this week.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final lesson in weeklyLessons) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassContainer(
                  borderRadius: 18,
                  blurSigma: 12,
                  elevation: 0.3,
                  tintColor: lesson.isHappeningNowAt(now)
                      ? AppColors.liveEmerald
                      : lesson.language.accentColor(context),
                  tintStrength: 0.08,
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    ref
                        .read(inspectorSelectionProvider.notifier)
                        .open(InspectorTarget.lesson(lesson.id));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormat('EEE, MMM d').format(lesson.startTime),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const Spacer(),
                          if (lesson.isHappeningNowAt(now))
                            const StatusBadge(
                              label: 'In Progress',
                              color: AppColors.liveEmerald,
                              glow: true,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('h:mm a').format(lesson.startTime)} – ${DateFormat('h:mm a').format(lesson.endTime)} • ${classrooms[lesson.classroomId]?.name ?? 'Room'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    showTeacherFormModal(context, existing: teacher);
                  },
                  icon: const Icon(CupertinoIcons.pencil, size: 17),
                  label: const Text('Edit Teacher'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showConfirmDeleteDialog(
                    context,
                    title: 'Delete Teacher',
                    message:
                        'Remove ${teacher.fullName} from the staff directory?',
                  );
                  if (!confirmed || !context.mounted) return;
                  await ref
                      .read(dataRepositoryProvider)
                      .deleteTeacher(teacher.id);
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
