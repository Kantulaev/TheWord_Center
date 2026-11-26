import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/teacher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../../../shared/widgets/todays_pulse_strip.dart';
import 'agenda_list_view.dart';
import 'day_timetable_view.dart';
import 'lesson_detail_panel.dart';
import 'lesson_form_dialog.dart';
import 'week_timetable_view.dart';

/// Live Master Schedule hub visible to everyone at "The Word".
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(
      text: ref.read(scheduleFilterProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openLessonInspector(BuildContext context, Lesson lesson) {
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
            child: LessonDetailPanel(
              lessonId: lesson.id,
              onClose: () => Navigator.of(sheetCtx).pop(),
            ),
          ),
        ),
      );
      return;
    }
    ref
        .read(inspectorSelectionProvider.notifier)
        .open(InspectorTarget.lesson(lesson.id));
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(scheduleFilterProvider);
    final filterCtrl = ref.read(scheduleFilterProvider.notifier);
    final filteredLessons = ref.watch(filteredLessonsProvider);
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Header + Primary CTA
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Master Schedule',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-time classroom, teacher & student timetable across Chinese and English courses.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );

            final cta = LiquidPrimaryButton(
              label: 'New Lesson',
              icon: CupertinoIcons.plus,
              onPressed: () => showLessonFormModal(
                context,
                initialStartTime: DateTime(
                  filter.selectedDate.year,
                  filter.selectedDate.month,
                  filter.selectedDate.day,
                  DateTime.now().hour.clamp(8, 20),
                ),
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  cta,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                cta,
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Today's Pulse Summary Strip
        const TodaysPulseStrip(),
        const SizedBox(height: 16),

        // Saturday Speaking Clubs (Weekly Recurring + Responsible Teacher Selector)
        _SaturdayClubsStrip(
          teachers: teachers,
          onInspectClub: (club) => _openLessonInspector(context, club),
        ),
        const SizedBox(height: 18),

        // Controls Bar: View Switcher + Date Navigator + Filters
        LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          elevation: 0.65,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Day / Week / Agenda Switcher
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final mode in ScheduleViewMode.values)
                        LiquidGlassPillButton(
                          label: mode.label,
                          selected: filter.viewMode == mode,
                          onTap: () => filterCtrl.setViewMode(mode),
                        ),
                    ],
                  ),

                  // Date Navigation Controls
                  Wrap(
                    spacing: 4,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous',
                        onPressed: () => filterCtrl.shiftDate(
                          filter.viewMode == ScheduleViewMode.week ? -7 : -1,
                        ),
                        icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                      ),
                      LiquidGlassPillButton(
                        label: 'Today',
                        icon: CupertinoIcons.scope,
                        onTap: filterCtrl.jumpToToday,
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: filter.selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            filterCtrl.setSelectedDate(picked);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Text(
                            _dateBannerLabel(filter),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: () => filterCtrl.shiftDate(
                          filter.viewMode == ScheduleViewMode.week ? 7 : 1,
                        ),
                        icon:
                            const Icon(CupertinoIcons.chevron_right, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search & Filter Row
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 248,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: filterCtrl.setSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search student, lesson, teacher...',
                        prefixIcon:
                            const Icon(CupertinoIcons.search, size: 18),
                        suffixIcon: filter.searchQuery.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear Search',
                                icon: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  filterCtrl.setSearchQuery('');
                                },
                              )
                            : null,
                        isDense: true,
                      ),
                    ),
                  ),

                  // Language & Category Chips (All / Chinese / English / Sharing)
                  LiquidGlassPillButton(
                    label: 'All',
                    selected: filter.language == null,
                    onTap: () => filterCtrl.setLanguage(null),
                  ),
                  for (final lang in CourseLanguage.values)
                    LiquidGlassPillButton(
                      label: lang.label,
                      selected: filter.language == lang,
                      accentColor: lang.accentColor(context),
                      onTap: () => filterCtrl.setLanguage(lang),
                    ),

                  // Teacher Dropdown Filter
                  SizedBox(
                    width: 195,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filter.teacherId,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Teacher',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Teachers',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final t in teachers)
                          DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(
                              t.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: filterCtrl.setTeacher,
                    ),
                  ),

                  // Classroom Dropdown Filter
                  SizedBox(
                    width: 195,
                    child: DropdownButtonFormField<String?>(
                      initialValue: filter.classroomId,
                      isExpanded: true,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Classroom',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'All Classrooms',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final c in classrooms)
                          DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: filterCtrl.setClassroom,
                    ),
                  ),

                  if (filter.hasActiveFilters)
                    TextButton.icon(
                      onPressed: () {
                        _searchCtrl.clear();
                        filterCtrl.clearAllFilters();
                      },
                      icon: const Icon(CupertinoIcons.clear_circled, size: 16),
                      label: const Text('Reset Filters'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main Schedule Visualization
        switch (filter.viewMode) {
          ScheduleViewMode.day => DayTimetableView(
              lessons: filteredLessons,
              selectedDate: filter.selectedDate,
              onSelectLesson: (l) => _openLessonInspector(context, l),
            ),
          ScheduleViewMode.week => WeekTimetableView(
              lessons: filteredLessons,
              selectedDate: filter.selectedDate,
              onSelectLesson: (l) => _openLessonInspector(context, l),
              onOpenDay: (day) {
                filterCtrl.setSelectedDate(day);
                filterCtrl.setViewMode(ScheduleViewMode.day);
              },
            ),
          ScheduleViewMode.agenda => AgendaListView(
              lessons: filteredLessons,
              anchorDate: filter.selectedDate,
              onSelectLesson: (l) => _openLessonInspector(context, l),
            ),
        },
      ],
    );
  }

  String _dateBannerLabel(ScheduleFilterState filter) {
    if (filter.viewMode == ScheduleViewMode.week) {
      final start = filter.selectedDate
          .subtract(Duration(days: filter.selectedDate.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(end)}';
    }
    return DateFormat('EEE, MMM d, y').format(filter.selectedDate);
  }
}

class _SaturdayClubsStrip extends ConsumerWidget {
  const _SaturdayClubsStrip({
    required this.teachers,
    required this.onInspectClub,
  });

  final List<Teacher> teachers;
  final ValueChanged<Lesson> onInspectClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(saturdayClubsProvider);
    if (clubs.isEmpty) return const SizedBox.shrink();

    final classrooms = ref.watch(classroomsMapProvider);
    final teacherIds = {for (final t in teachers) t.id};

    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      elevation: 0.65,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                size: 18,
                color: AppColors.chineseCoralGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saturday Speaking Clubs (Every Saturday)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cols = width >= 1060 ? 3 : (width >= 660 ? 2 : 1);
              const gap = 12.0;
              final itemWidth = (width - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final club in clubs)
                    SizedBox(
                      width: cols == 1 ? width : itemWidth,
                      child: _ClubCard(
                        club: club,
                        roomName: classrooms[club.classroomId]?.name ?? 'Hall',
                        teachers: teachers,
                        validTeacherIds: teacherIds,
                        onInspect: () => onInspectClub(club),
                        onAssignResponsible: (teacherId) async {
                          await ref.read(dataRepositoryProvider).upsertLesson(
                                club.copyWith(teacherId: teacherId),
                              );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.club,
    required this.roomName,
    required this.teachers,
    required this.validTeacherIds,
    required this.onInspect,
    required this.onAssignResponsible,
  });

  final Lesson club;
  final String roomName;
  final List<Teacher> teachers;
  final Set<String> validTeacherIds;
  final VoidCallback onInspect;
  final ValueChanged<String> onAssignResponsible;

  @override
  Widget build(BuildContext context) {
    final accent = club.language.accentColor(context);
    final selectedTeacherId =
        validTeacherIds.contains(club.teacherId) ? club.teacherId : null;

    return LiquidGlassContainer(
      borderRadius: 18,
      blurSigma: 12,
      elevation: 0.35,
      tintColor: accent,
      tintStrength: 0.08,
      padding: const EdgeInsets.all(14),
      onTap: onInspect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LanguageBadge(language: club.language, compact: true),
              GlassInfoTag(
                icon: CupertinoIcons.clock,
                label:
                    'Sat ${DateFormat('h:mm a').format(club.startTime)} • $roomName',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            club.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedTeacherId,
            isExpanded: true,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Responsible Teacher',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              for (final t in teachers)
                DropdownMenuItem<String>(
                  value: t.id,
                  child: Text(
                    t.fullName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (val) {
              if (val != null) {
                onAssignResponsible(val);
              }
            },
          ),
        ],
      ),
    );
  }
}
