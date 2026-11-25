import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/teacher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'teacher_detail_panel.dart';
import 'teacher_form_dialog.dart';

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  TeachingLanguageScope? _langFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openInspector(BuildContext context, Teacher teacher) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      showAdaptiveGlassModal<void>(
        context,
        builder: (sheetCtx) => LiquidGlassContainer(
          borderRadius: 28,
          blurSigma: 28,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetCtx).height * 0.82,
            child: TeacherDetailPanel(
              teacherId: teacher.id,
              onClose: () => Navigator.of(sheetCtx).pop(),
            ),
          ),
        ),
      );
      return;
    }
    ref
        .read(inspectorSelectionProvider.notifier)
        .open(InspectorTarget.teacher(teacher.id));
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final lessons = ref.watch(lessonsStreamProvider).value ?? const [];
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();

    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final filtered = teachers.where((t) {
      if (_langFilter != null && t.languages != _langFilter) return false;
      if (_query.trim().isNotEmpty) {
        final q = _query.trim().toLowerCase();
        final haystack =
            '${t.fullName} ${t.specializations.join(' ')} ${t.email}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList(growable: false);

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
                  'Teachers Directory',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage Mandarin & English instructors, specializations, availability, and weekly teaching load.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final cta = LiquidPrimaryButton(
              label: 'Add Teacher',
              icon: CupertinoIcons.person_badge_plus,
              onPressed: () => showTeacherFormModal(context),
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
        const SizedBox(height: 16),

        // Search + Language Scope Filters
        LiquidGlassContainer(
          borderRadius: 22,
          blurSigma: 18,
          elevation: 0.55,
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 248,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search teacher or specialization...',
                    prefixIcon: const Icon(CupertinoIcons.search, size: 18),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear Search',
                            icon: const Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 16,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
              ),
              LiquidGlassPillButton(
                label: 'All (${teachers.length})',
                selected: _langFilter == null,
                onTap: () => setState(() => _langFilter = null),
              ),
              for (final scope in TeachingLanguageScope.values)
                LiquidGlassPillButton(
                  label: scope.label,
                  selected: _langFilter == scope,
                  accentColor: scope.accentColor(context),
                  onTap: () => setState(() => _langFilter = scope),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          LiquidGlassContainer(
            borderRadius: 24,
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No teachers match your search.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100 ? 3 : (width >= 660 ? 2 : 1);
              final spacing = 14.0;
              final cardWidth =
                  (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final teacher in filtered)
                    SizedBox(
                      width: crossAxisCount == 1 ? width : cardWidth,
                      child: _TeacherCard(
                        teacher: teacher,
                        weeklyHours: _weeklyHoursFor(
                          teacher.id,
                          lessons,
                          weekStart,
                          weekEnd,
                        ),
                        isTeachingNow: lessons.any(
                          (l) =>
                              l.teacherId == teacher.id &&
                              l.isHappeningNowAt(now),
                        ),
                        onTap: () => _openInspector(context, teacher),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  double _weeklyHoursFor(
    String teacherId,
    List<dynamic> lessons,
    DateTime weekStart,
    DateTime weekEnd,
  ) {
    var mins = 0;
    for (final l in lessons) {
      if (l.teacherId == teacherId &&
          l.status != LessonStatus.canceled &&
          !(l.startTime as DateTime).isBefore(weekStart) &&
          (l.startTime as DateTime).isBefore(weekEnd)) {
        mins += (l.durationMinutes as int);
      }
    }
    return mins / 60.0;
  }
}

class _TeacherCard extends ConsumerWidget {
  const _TeacherCard({
    required this.teacher,
    required this.weeklyHours,
    required this.isTeachingNow,
    required this.onTap,
  });

  final Teacher teacher;
  final double weeklyHours;
  final bool isTeachingNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.fromHex(teacher.avatarColorHex);

    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      elevation: 0.7,
      tintColor: isTeachingNow ? AppColors.liveEmerald : color,
      tintStrength: isTeachingNow ? 0.10 : 0.05,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                initials: teacher.initials,
                color: color,
                size: 46,
                isActiveDot: teacher.isActive,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
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
                        if (isTeachingNow)
                          const StatusBadge(
                            label: 'In Class',
                            color: AppColors.liveEmerald,
                            glow: true,
                            compact: true,
                          )
                        else if (!teacher.isActive)
                          const StatusBadge(
                            label: 'On Leave',
                            color: AppColors.warningAmber,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit Teacher',
                icon: const Icon(CupertinoIcons.pencil, size: 17),
                onPressed: () =>
                    showTeacherFormModal(context, existing: teacher),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final spec in teacher.specializations.take(3))
                GlassInfoTag(label: spec),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 14,
                color: AppColors.textMuted(context),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${weeklyHours.toStringAsFixed(1)} hrs this week',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                teacher.isActive ? 'Active' : 'On Leave',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: teacher.isActive
                          ? AppColors.liveEmerald
                          : AppColors.warningAmber,
                    ),
              ),
              const SizedBox(width: 6),
              Switch(
                value: teacher.isActive,
                onChanged: (active) async {
                  await ref
                      .read(dataRepositoryProvider)
                      .upsertTeacher(teacher.copyWith(isActive: active));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
