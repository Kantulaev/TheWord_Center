import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/study_group.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'group_detail_panel.dart';
import 'group_form_dialog.dart';
import 'homework_form_dialog.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  void _openInspector(BuildContext context, WidgetRef ref, StudyGroup group) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      showAdaptiveGlassModal<void>(
        context,
        builder: (sheetCtx) => LiquidGlassContainer(
          borderRadius: 28,
          blurSigma: 28,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetCtx).height * 0.85,
            child: GroupDetailPanel(
              groupId: group.id,
              onClose: () => Navigator.of(sheetCtx).pop(),
            ),
          ),
        ),
      );
      return;
    }
    ref
        .read(inspectorSelectionProvider.notifier)
        .open(InspectorTarget.group(group.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsStreamProvider);
    final teachers = ref.watch(teachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final homeworks = ref.watch(homeworksStreamProvider).value ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Groups (HSK & CEFR)',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage cohorts, steady weekly schedules, 12-lesson payment packages, and student homework.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final actions = Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => showHomeworkFormModal(context),
                  icon: const Icon(CupertinoIcons.doc_text_fill, size: 17),
                  label: const Text('Assign Homework'),
                ),
                LiquidPrimaryButton(
                  label: 'New Group',
                  icon: CupertinoIcons.plus,
                  onPressed: () => showGroupFormModal(context),
                ),
              ],
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 12), actions],
              );
            }
            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        groupsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => LiquidGlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load groups: $err'),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return LiquidGlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No study groups created yet.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      LiquidPrimaryButton(
                        label: 'Create First HSK Group',
                        icon: CupertinoIcons.plus,
                        onPressed: () => showGroupFormModal(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount =
                    width >= 1100 ? 3 : (width >= 660 ? 2 : 1);
                const spacing = 14.0;
                final cardWidth =
                    (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final g in groups)
                      SizedBox(
                        width: crossAxisCount == 1 ? width : cardWidth,
                        child: _GroupCard(
                          group: g,
                          teacherName:
                              teachers[g.teacherId]?.fullName ?? 'Unassigned',
                          roomName:
                              classrooms[g.classroomId]?.name ?? 'Unassigned',
                          homeworkCount:
                              homeworks.where((h) => h.groupId == g.id).length,
                          onTap: () => _openInspector(context, ref, g),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.teacherName,
    required this.roomName,
    required this.homeworkCount,
    required this.onTap,
  });

  final StudyGroup group;
  final String teacherName;
  final String roomName;
  final int homeworkCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = group.language.accentColor(context);
    final paidCount = group.members.where((m) => m.hasPaid).length;
    final unpaidCount = group.members.length - paidCount;

    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      elevation: 0.75,
      tintColor: accent,
      tintStrength: 0.06,
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
                  children: [
                    LanguageBadge(language: group.language, compact: true),
                    GlassInfoTag(label: group.level),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit Group',
                icon: const Icon(CupertinoIcons.pencil, size: 17),
                onPressed: () =>
                    showGroupFormModal(context, existing: group),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            group.scheduleSummary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Teacher: $teacherName • Room: $roomName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              GlassInfoTag(
                icon: CupertinoIcons.person_2,
                label: '${group.members.length} students',
              ),
              StatusBadge(
                label: '$paidCount Paid',
                color: AppColors.liveEmerald,
                compact: true,
              ),
              if (unpaidCount > 0)
                StatusBadge(
                  label: '$unpaidCount Unpaid',
                  color: AppColors.dangerRose,
                  compact: true,
                ),
              GlassInfoTag(
                icon: CupertinoIcons.doc_text,
                label: '$homeworkCount HW',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
