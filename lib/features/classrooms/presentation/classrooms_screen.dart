import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/classroom.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'classroom_detail_panel.dart';
import 'classroom_form_dialog.dart';

class ClassroomsScreen extends ConsumerWidget {
  const ClassroomsScreen({super.key});

  void _openInspector(BuildContext context, WidgetRef ref, Classroom room) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      showAdaptiveGlassModal<void>(
        context,
        builder: (sheetCtx) => LiquidGlassContainer(
          borderRadius: 28,
          blurSigma: 28,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetCtx).height * 0.80,
            child: ClassroomDetailPanel(
              classroomId: room.id,
              onClose: () => Navigator.of(sheetCtx).pop(),
            ),
          ),
        ),
      );
      return;
    }
    ref
        .read(inspectorSelectionProvider.notifier)
        .open(InspectorTarget.classroom(room.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
    final occupancyMap = ref.watch(classroomOccupancyProvider);

    final freeCount =
        occupancyMap.values.where((o) => !o.isOccupied).length;
    final occupiedCount = occupancyMap.values.where((o) => o.isOccupied).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classrooms & Live Status',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Live room occupancy automatically updates from the active lesson schedule ($freeCount Free • $occupiedCount Occupied).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final cta = LiquidPrimaryButton(
              label: 'Add Classroom',
              icon: CupertinoIcons.plus,
              onPressed: () => showClassroomFormModal(context),
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 12), cta],
              );
            }
            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                cta,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        if (classrooms.isEmpty)
          LiquidGlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No classrooms configured yet. Add your first teaching room.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100 ? 3 : (width >= 660 ? 2 : 1);
              const spacing = 14.0;
              final cardWidth =
                  (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final room in classrooms)
                    SizedBox(
                      width: crossAxisCount == 1 ? width : cardWidth,
                      child: _ClassroomCard(
                        classroom: room,
                        occupancy: occupancyMap[room.id],
                        onTap: () => _openInspector(context, ref, room),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.classroom,
    required this.occupancy,
    required this.onTap,
  });

  final Classroom classroom;
  final ClassroomOccupancy? occupancy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOccupied = occupancy?.isOccupied ?? false;
    final activeLesson = occupancy?.activeLesson;
    final activeTeacher = occupancy?.activeTeacher;
    final nextLesson = occupancy?.nextLessonToday;

    final statusColor =
        isOccupied ? AppColors.chineseAccent(context) : AppColors.liveEmerald;

    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      elevation: 0.75,
      tintColor: statusColor,
      tintStrength: isOccupied ? 0.11 : 0.06,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: isOccupied ? 'Occupied' : 'Free',
                      color: statusColor,
                      glow: true,
                    ),
                    GlassInfoTag(
                      icon: CupertinoIcons.person_2,
                      label: 'Seats ${classroom.capacity}',
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit Classroom',
                icon: const Icon(CupertinoIcons.pencil, size: 17),
                onPressed: () =>
                    showClassroomFormModal(context, existing: classroom),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            classroom.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),

          if (isOccupied && activeLesson != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: statusColor.withValues(alpha: 0.10),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeLesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Teacher: ${activeTeacher?.fullName ?? 'Unassigned'} • Until ${DateFormat('h:mm a').format(activeLesson.endTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            Text(
              nextLesson != null
                  ? 'Next today: ${nextLesson.title} at ${DateFormat('h:mm a').format(nextLesson.startTime)}'
                  : 'Available for immediate booking today.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),

          const SizedBox(height: 14),
          if (classroom.equipmentTags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in classroom.equipmentTags.take(4))
                  GlassInfoTag(label: tag),
              ],
            ),
        ],
      ),
    );
  }
}
