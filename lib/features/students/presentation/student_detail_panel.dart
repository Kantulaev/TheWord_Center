import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/student.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'student_form_dialog.dart';

/// Student detail card showing credits, contact details, and upcoming/past lessons.
class StudentDetailPanel extends ConsumerWidget {
  const StudentDetailPanel({
    super.key,
    required this.studentId,
    this.onClose,
  });

  final String studentId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsStreamProvider).value ?? const [];
    final student = students.cast<Student?>().firstWhere(
          (s) => s?.id == studentId,
          orElse: () => null,
        );

    if (student == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Student record is no longer available.'),
        ),
      );
    }

    final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
    final teachers = ref.watch(teachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();

    final primaryTeacher = student.primaryTeacherId != null
        ? teachers[student.primaryTeacherId!]
        : null;
    final accent = student.targetLanguage.accentColor(context);

    final studentLessons = lessons
        .where((l) => l.studentIds.contains(student.id))
        .toList();
    final upcoming = studentLessons
        .where(
          (l) =>
              l.status != LessonStatus.canceled &&
              l.status != LessonStatus.completed &&
              l.endTime.isAfter(now),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final past = studentLessons
        .where(
          (l) =>
              l.status == LessonStatus.completed ||
              !l.endTime.isAfter(now),
        )
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final isLowCredits = student.remainingCredits <= 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                initials: student.initials,
                color: accent,
                size: 54,
                badgeText: student.targetLanguage.code,
                badgeColor: accent,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        LanguageBadge(
                          language: student.targetLanguage,
                          compact: true,
                        ),
                        GlassInfoTag(label: student.proficiencyLevel),
                        GlassInfoTag(label: student.format.studentFormatLabel),
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

          // Lesson Credits Quick Adjuster
          LiquidGlassContainer(
            borderRadius: 20,
            blurSigma: 14,
            elevation: 0.45,
            tintColor: isLowCredits ? AppColors.warningAmber : accent,
            tintStrength: 0.08,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining Lesson Credits',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${student.remainingCredits}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: isLowCredits
                                      ? AppColors.warningAmber
                                      : null,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (isLowCredits) ...[
                            const SizedBox(width: 8),
                            const StatusBadge(
                              label: 'Low Balance',
                              color: AppColors.warningAmber,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Subtract 1 credit',
                  onPressed: student.remainingCredits > 0
                      ? () => ref
                          .read(dataRepositoryProvider)
                          .adjustStudentCredits(student.id, -1)
                      : null,
                  icon: const Icon(CupertinoIcons.minus, size: 16),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Add 1 credit',
                  onPressed: () => ref
                      .read(dataRepositoryProvider)
                      .adjustStudentCredits(student.id, 1),
                  icon: const Icon(CupertinoIcons.plus, size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          LiquidGlassContainer(
            borderRadius: 20,
            blurSigma: 12,
            elevation: 0.3,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_crop_circle,
                      size: 16,
                      color: AppColors.textMuted(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Primary Teacher: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Text(
                        primaryTeacher?.fullName ?? 'Unassigned',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                if (student.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.phone,
                        size: 15,
                        color: AppColors.textMuted(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        student.phone,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
                if (student.email.isNotEmpty) ...[
                  const SizedBox(height: 8),
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
                          student.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (student.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: Text(
                student.notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],

          const SizedBox(height: 18),
          Text(
            'Upcoming Lessons (${upcoming.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            Text(
              'No upcoming lessons scheduled.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final l in upcoming) ...[
              _MiniLessonItem(
                lessonTitle: l.title,
                subtitle:
                    '${DateFormat('EEE, MMM d • h:mm a').format(l.startTime)} • ${teachers[l.teacherId]?.fullName ?? 'Teacher'} • ${classrooms[l.classroomId]?.name ?? 'Room'}',
                isLive: l.isHappeningNowAt(now),
                accent: l.language.accentColor(context),
                onTap: () {
                  ref
                      .read(inspectorSelectionProvider.notifier)
                      .open(InspectorTarget.lesson(l.id));
                },
              ),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 14),
          Text(
            'Past Lessons (${past.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (past.isEmpty)
            Text(
              'No past lessons recorded yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final l in past) ...[
              _MiniLessonItem(
                lessonTitle: l.title,
                subtitle:
                    '${DateFormat('MMM d, y • h:mm a').format(l.startTime)} • ${l.status.label}',
                isLive: false,
                accent: AppColors.completedSlate,
                onTap: () {
                  ref
                      .read(inspectorSelectionProvider.notifier)
                      .open(InspectorTarget.lesson(l.id));
                },
              ),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    showStudentFormModal(context, existing: student);
                  },
                  icon: const Icon(CupertinoIcons.pencil, size: 17),
                  label: const Text('Edit Student'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showConfirmDeleteDialog(
                    context,
                    title: 'Delete Student',
                    message:
                        'Remove ${student.fullName} from the student roster?',
                  );
                  if (!confirmed || !context.mounted) return;
                  await ref
                      .read(dataRepositoryProvider)
                      .deleteStudent(student.id);
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

class _MiniLessonItem extends StatelessWidget {
  const _MiniLessonItem({
    required this.lessonTitle,
    required this.subtitle,
    required this.isLive,
    required this.accent,
    required this.onTap,
  });

  final String lessonTitle;
  final String subtitle;
  final bool isLive;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      elevation: 0.25,
      tintColor: isLive ? AppColors.liveEmerald : accent,
      tintStrength: 0.06,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lessonTitle, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (isLive)
            const StatusBadge(
              label: 'LIVE',
              color: AppColors.liveEmerald,
              glow: true,
              compact: true,
            ),
        ],
      ),
    );
  }
}
