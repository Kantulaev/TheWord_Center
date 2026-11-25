import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/classroom.dart';
import '../../../core/models/language_type.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../../schedule/presentation/lesson_form_dialog.dart';
import 'classroom_form_dialog.dart';

/// Slide-over / sheet detail view for a classroom showing live occupancy and today's bookings.
class ClassroomDetailPanel extends ConsumerWidget {
  const ClassroomDetailPanel({
    super.key,
    required this.classroomId,
    this.onClose,
  });

  final String classroomId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
    final room = classrooms.cast<Classroom?>().firstWhere(
          (c) => c?.id == classroomId,
          orElse: () => null,
        );

    if (room == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Classroom record is no longer available.'),
        ),
      );
    }

    final occupancy = ref.watch(classroomOccupancyProvider)[room.id];
    final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
    final teachers = ref.watch(teachersMapProvider);
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();

    final todayRoomLessons = lessons
        .where(
          (l) =>
              l.classroomId == room.id &&
              l.isOnDate(now) &&
              l.status != LessonStatus.canceled,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final isOccupied = occupancy?.isOccupied ?? false;
    final activeLesson = occupancy?.activeLesson;
    final activeTeacher = occupancy?.activeTeacher;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: isOccupied ? 'Occupied Now' : 'Free Now',
                color: isOccupied
                    ? AppColors.chineseAccent(context)
                    : AppColors.liveEmerald,
                glow: true,
              ),
              const SizedBox(width: 8),
              GlassInfoTag(
                icon: CupertinoIcons.person_2,
                label: 'Capacity ${room.capacity}',
              ),
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
            room.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),

          if (isOccupied && activeLesson != null) ...[
            LiquidGlassContainer(
              borderRadius: 20,
              blurSigma: 14,
              elevation: 0.6,
              tintColor: AppColors.liveEmerald,
              tintStrength: 0.12,
              padding: const EdgeInsets.all(14),
              onTap: () {
                ref
                    .read(inspectorSelectionProvider.notifier)
                    .open(InspectorTarget.lesson(activeLesson.id));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatusBadge(
                    label: 'Current Session',
                    color: AppColors.liveEmerald,
                    glow: true,
                    compact: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeLesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Teacher: ${activeTeacher?.fullName ?? 'Unassigned'} • Ends ${DateFormat('h:mm a').format(activeLesson.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            'Equipment & Amenities',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (room.equipmentTags.isEmpty)
            Text(
              'No equipment tags listed.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in room.equipmentTags)
                  GlassInfoTag(
                    icon: CupertinoIcons.checkmark_seal,
                    label: tag,
                  ),
              ],
            ),

          if (room.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: Text(room.notes, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],

          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                "Today's Room Schedule",
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showLessonFormModal(
                    context,
                    initialClassroomId: room.id,
                  );
                },
                icon: const Icon(CupertinoIcons.plus, size: 15),
                label: const Text('Book Room'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (todayRoomLessons.isEmpty)
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'No lessons booked in this room today.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final l in todayRoomLessons) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LiquidGlassContainer(
                  borderRadius: 18,
                  blurSigma: 12,
                  elevation: 0.3,
                  tintColor: l.isHappeningNowAt(now)
                      ? AppColors.liveEmerald
                      : l.language.accentColor(context),
                  tintStrength: 0.08,
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    ref
                        .read(inspectorSelectionProvider.notifier)
                        .open(InspectorTarget.lesson(l.id));
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('h:mm a').format(l.startTime)} – ${DateFormat('h:mm a').format(l.endTime)} • ${teachers[l.teacherId]?.fullName ?? 'Teacher'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (l.isHappeningNowAt(now))
                        const StatusBadge(
                          label: 'LIVE',
                          color: AppColors.liveEmerald,
                          glow: true,
                          compact: true,
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
                    showClassroomFormModal(context, existing: room);
                  },
                  icon: const Icon(CupertinoIcons.pencil, size: 17),
                  label: const Text('Edit Room'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showConfirmDeleteDialog(
                    context,
                    title: 'Delete Classroom',
                    message:
                        'Delete ${room.name}? Existing lessons referencing this room will remain in history.',
                  );
                  if (!confirmed || !context.mounted) return;
                  await ref
                      .read(dataRepositoryProvider)
                      .deleteClassroom(room.id);
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
