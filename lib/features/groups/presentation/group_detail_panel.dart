import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/homework.dart';
import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/operations_models.dart';
import '../../../core/models/study_group.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'group_form_dialog.dart';
import 'homework_form_dialog.dart';

/// Inspector panel for a [StudyGroup]:
/// - 12-lesson payment & remaining balance tracker per student
/// - Quick "Mark Class Held (-1)" attendance deduction
/// - Sync steady weekly schedule to the Master Timetable
/// - Assign & manage Homework delivered to students' portals
class GroupDetailPanel extends ConsumerWidget {
  const GroupDetailPanel({
    super.key,
    required this.groupId,
    this.onClose,
  });

  final String groupId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsStreamProvider).value ?? const [];
    final group = groups.cast<StudyGroup?>().firstWhere(
          (g) => g?.id == groupId,
          orElse: () => null,
        );

    if (group == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Group record is no longer available.'),
        ),
      );
    }

    final teachers = ref.watch(teachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final students = ref.watch(studentsStreamProvider).value ?? const [];
    final homeworks = (ref.watch(homeworksStreamProvider).value ?? const [])
        .where((h) => h.groupId == group.id)
        .toList();

    final teacher = teachers[group.teacherId];
    final room = classrooms[group.classroomId];
    final accent = group.language.accentColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LanguageBadge(language: group.language),
              const SizedBox(width: 8),
              GlassInfoTag(label: group.level),
              const Spacer(),
              if (onClose != null)
                IconButton(
                  tooltip: 'Close Inspector',
                  onPressed: onClose,
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            '${group.scheduleSummary} • ${room?.name ?? 'Room'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Teacher: ${teacher?.fullName ?? 'Unassigned'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _syncGroupToSchedule(context, ref, group),
                icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 16),
                label: const Text('Sync Schedule'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    showHomeworkFormModal(context, initialGroupId: group.id),
                icon: const Icon(CupertinoIcons.doc_text_fill, size: 16),
                label: const Text('Assign Homework'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Students & 12-Lesson Payment Tracker
          Row(
            children: [
              Expanded(
                child: Text(
                  'Students & 12-Lesson Payments (${group.members.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (group.members.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final updatedMembers = group.members
                        .map(
                          (m) => m.copyWith(
                            lessonsRemaining:
                                (m.lessonsRemaining - 1).clamp(0, 999),
                          ),
                        )
                        .toList();
                    await ref.read(dataRepositoryProvider).upsertGroup(
                          group.copyWith(members: updatedMembers),
                        );
                  },
                  child: const Text('Lesson Held (-1 all)'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (group.members.isEmpty)
            Text(
              'No students added to this group yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (int i = 0; i < group.members.length; i++) ...[
              _MemberPaymentTile(
                member: group.members[i],
                accent: accent,
                onUpdate: (updated) async {
                  final next = [...group.members];
                  next[i] = updated;
                  await ref
                      .read(dataRepositoryProvider)
                      .upsertGroup(group.copyWith(members: next));
                },
                onRemove: () async {
                  final next = [...group.members]..removeAt(i);
                  await ref
                      .read(dataRepositoryProvider)
                      .upsertGroup(group.copyWith(members: next));
                },
              ),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showAddMemberDialog(context, ref, group, students),
            icon: const Icon(CupertinoIcons.person_add, size: 16),
            label: const Text('Add Student to Group'),
          ),
          const SizedBox(height: 20),

          // Assigned Homework Section
          Text(
            'Group Homework (${homeworks.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (homeworks.isEmpty)
            Text(
              'No homework assigned to this group yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (final hw in homeworks) ...[
              LiquidGlassContainer(
                borderRadius: 18,
                blurSigma: 12,
                elevation: 0.3,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hw.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Delete Homework',
                          icon: const Icon(
                            CupertinoIcons.trash,
                            size: 16,
                            color: AppColors.dangerRose,
                          ),
                          onPressed: () => ref
                              .read(dataRepositoryProvider)
                              .deleteHomework(hw.id),
                        ),
                      ],
                    ),
                    Text(
                      hw.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Due ${DateFormat('MMM d').format(hw.dueDate)} • ${hw.completedByUids.length} completed • ${hw.submissions.length} submitted',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.liveEmerald,
                          ),
                    ),
                    if (hw.submissions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final sub in hw.submissions) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white.withValues(alpha: 0.72),
                            border: Border.all(
                              color: (sub.reviewed
                                      ? AppColors.liveEmerald
                                      : accent)
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sub.studentName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  StatusBadge(
                                    label: sub.reviewed
                                        ? 'Reviewed'
                                        : 'Needs Review',
                                    color: sub.reviewed
                                        ? AppColors.liveEmerald
                                        : AppColors.warningAmber,
                                    compact: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                sub.answerOrLink,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (sub.teacherFeedback.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Feedback: ${sub.teacherFeedback}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.liveEmerald,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => _showFeedbackDialog(
                                  context,
                                  ref,
                                  homework: hw,
                                  submission: sub,
                                ),
                                icon: const Icon(
                                  CupertinoIcons.chat_bubble_text,
                                  size: 14,
                                ),
                                label: Text(
                                  sub.reviewed
                                      ? 'Edit Feedback'
                                      : 'Leave Feedback',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      showGroupFormModal(context, existing: group),
                  icon: const Icon(CupertinoIcons.pencil, size: 17),
                  label: const Text('Edit Group'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showConfirmDeleteDialog(
                    context,
                    title: 'Delete Group',
                    message: 'Delete ${group.name}?',
                  );
                  if (!ok || !context.mounted) return;
                  await ref.read(dataRepositoryProvider).deleteGroup(group.id);
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

  Future<void> _showFeedbackDialog(
    BuildContext context,
    WidgetRef ref, {
    required HomeworkAssignment homework,
    required HomeworkSubmission submission,
  }) async {
    final feedbackCtrl =
        TextEditingController(text: submission.teacherFeedback);
    var reviewed = true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Text('Review ${submission.studentName}\'s Work'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submitted:',
                style: Theme.of(dialogCtx).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(
                submission.answerOrLink,
                style: Theme.of(dialogCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Teacher Feedback',
                  hintText: 'Great pronunciation! Review tone 3 on word #4.',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: reviewed,
                title: const Text('Mark as Reviewed'),
                onChanged: (v) => setState(() => reviewed = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Save Feedback'),
            ),
          ],
        ),
      ),
    );
    final feedback = feedbackCtrl.text.trim();
    feedbackCtrl.dispose();
    if (saved != true) return;

    final repo = ref.read(dataRepositoryProvider);
    await repo.reviewHomeworkSubmission(
      homeworkId: homework.id,
      studentUid: submission.studentUid,
      feedback: feedback,
      reviewed: reviewed,
    );
    final actor = ref.read(authStateProvider).value?.email ?? 'staff';
    await repo.logActivity(
      ActivityLogEntry(
        id: const Uuid().v4(),
        actorEmail: actor,
        category: 'Homework',
        summary:
            'Reviewed "${homework.title}" for ${submission.studentName}',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _syncGroupToSchedule(
    BuildContext context,
    WidgetRef ref,
    StudyGroup group,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      today.year,
      today.month,
      today.day,
      group.startHour,
      group.startMinute,
    );
    final end = start.add(Duration(minutes: group.durationMinutes));
    final lesson = Lesson(
      id: 'series_${group.id}',
      title: group.name,
      language: group.language,
      lessonType: LessonType.group,
      teacherId: group.teacherId,
      classroomId: group.classroomId,
      studentIds: group.members.map((m) => m.memberId).toList(),
      startTime: start,
      endTime: end,
      status: LessonStatus.scheduled,
      notes: group.notes,
      createdAt: today,
      recurrenceWeekdays: group.scheduleWeekdays,
      recurrenceUntil: null,
    );
    await ref.read(dataRepositoryProvider).upsertLesson(lesson);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced ${group.name} steady schedule to Master Timetable'),
        ),
      );
    }
  }

  Future<void> _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
    StudyGroup group,
    List<dynamic> existingStudents,
  ) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final totalCtrl = TextEditingController(text: '12');
    bool paid = true;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: LiquidGlassContainer(
              borderRadius: 24,
              blurSigma: 26,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Student to ${group.name}',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (existingStudents.isNotEmpty) ...[
                    Text(
                      'Quick pick from Roster:',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final s in existingStudents.take(6))
                          ActionChip(
                            label: Text(s.fullName as String),
                            onPressed: () {
                              nameCtrl.text = s.fullName as String;
                              emailCtrl.text = s.email as String;
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Student Name *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Student Google Email (optional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Lesson Package Size (e.g. 12)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Paid'),
                    value: paid,
                    onChanged: (v) => setModalState(() => paid = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final total =
                              int.tryParse(totalCtrl.text.trim()) ?? 12;
                          final member = GroupMemberPayment(
                            memberId: const Uuid().v4(),
                            fullName: name,
                            email: emailCtrl.text.trim().toLowerCase(),
                            totalPaidLessons: total,
                            lessonsRemaining: total,
                            hasPaid: paid,
                          );
                          await ref.read(dataRepositoryProvider).upsertGroup(
                                group.copyWith(
                                  members: [...group.members, member],
                                ),
                              );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberPaymentTile extends StatelessWidget {
  const _MemberPaymentTile({
    required this.member,
    required this.accent,
    required this.onUpdate,
    required this.onRemove,
  });

  final GroupMemberPayment member;
  final Color accent;
  final ValueChanged<GroupMemberPayment> onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final low = member.lessonsRemaining <= 2;
    return LiquidGlassContainer(
      borderRadius: 18,
      blurSigma: 12,
      elevation: 0.3,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (member.email.isNotEmpty)
                      Text(
                        member.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              LiquidGlassPillButton(
                label: member.hasPaid ? 'Paid' : 'Unpaid',
                selected: true,
                accentColor: member.hasPaid
                    ? AppColors.liveEmerald
                    : AppColors.dangerRose,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                onTap: () => onUpdate(
                  member.copyWith(hasPaid: !member.hasPaid),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove from group',
                onPressed: onRemove,
                icon: const Icon(CupertinoIcons.xmark, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${member.lessonsRemaining} / ${member.totalPaidLessons} lessons left',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: low ? AppColors.warningAmber : accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: 'Deduct 1 lesson',
                onPressed: member.lessonsRemaining > 0
                    ? () => onUpdate(
                          member.copyWith(
                            lessonsRemaining: member.lessonsRemaining - 1,
                          ),
                        )
                    : null,
                icon: const Icon(CupertinoIcons.minus, size: 14),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                tooltip: 'Add 1 lesson',
                onPressed: () => onUpdate(
                  member.copyWith(
                    lessonsRemaining: member.lessonsRemaining + 1,
                  ),
                ),
                icon: const Icon(CupertinoIcons.plus, size: 14),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => onUpdate(
                  member.copyWith(
                    totalPaidLessons: 12,
                    lessonsRemaining: 12,
                    hasPaid: true,
                  ),
                ),
                child: const Text('Renew 12'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
