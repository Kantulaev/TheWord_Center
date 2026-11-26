import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/classroom.dart';
import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'lesson_form_dialog.dart';

/// Day View:
/// - Tablet & Desktop (>= 600px): Hourly classroom matrix with a live current-time line.
/// - Mobile (< 600px): Swipeable classroom/all-rooms daily timeline cards.
class DayTimetableView extends ConsumerStatefulWidget {
  const DayTimetableView({
    super.key,
    required this.lessons,
    required this.selectedDate,
    required this.onSelectLesson,
  });

  final List<Lesson> lessons;
  final DateTime selectedDate;
  final ValueChanged<Lesson> onSelectLesson;

  @override
  ConsumerState<DayTimetableView> createState() => _DayTimetableViewState();
}

class _DayTimetableViewState extends ConsumerState<DayTimetableView> {
  final PageController _mobilePageCtrl = PageController();
  int _mobilePageIndex = 0;

  @override
  void dispose() {
    _mobilePageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
    final selectedDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );
    final dayLessons = Lesson.expandAll(
      widget.lessons,
      selectedDay,
      selectedDay,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _buildMobileSwipeTimeline(context, classrooms, dayLessons);
        }
        return _buildMatrixGrid(
          context,
          constraints.maxWidth,
          classrooms,
          dayLessons,
        );
      },
    );
  }

  Widget _buildMatrixGrid(
    BuildContext context,
    double availableWidth,
    List<Classroom> classrooms,
    List<Lesson> dayLessons,
  ) {
    if (classrooms.isEmpty) {
      return const Center(
        child: Text('Add a classroom to display the hourly timetable matrix.'),
      );
    }

    final now = ref.watch(liveClockProvider).value ?? DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;

    // Expand hour range dynamically if any lesson or current time falls outside 08:00-22:00.
    var startHour = 8;
    var endHour = 22;
    for (final l in dayLessons) {
      startHour = math.min(startHour, l.startTime.hour);
      final endH = l.endTime.minute > 0 ? l.endTime.hour + 1 : l.endTime.hour;
      endHour = math.max(endHour, endH.clamp(1, 24));
    }
    if (isToday) {
      startHour = math.min(startHour, now.hour);
      endHour = math.max(endHour, (now.hour + 1).clamp(1, 24));
    }

    const hourHeight = 82.0;
    const timeColumnWidth = 74.0;
    final totalHours = endHour - startHour;
    final gridHeight = totalHours * hourHeight;

    final minColWidth = 205.0;
    final computedColWidth = math.max(
      minColWidth,
      (availableWidth - timeColumnWidth - 28) / classrooms.length,
    );
    final totalGridWidth = timeColumnWidth + computedColWidth * classrooms.length;

    final occupancy = ref.watch(classroomOccupancyProvider);
    final teachers = ref.watch(teachersMapProvider);
    final students = ref.watch(studentsMapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double? currentMinutesOffset;
    if (isToday) {
      final minsFromStart =
          (now.hour - startHour) * 60 + now.minute;
      if (minsFromStart >= 0 && minsFromStart <= totalHours * 60) {
        currentMinutesOffset = (minsFromStart / 60.0) * hourHeight;
      }
    }

    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      elevation: 0.7,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalGridWidth,
          child: Column(
            children: [
              // Sticky Classroom Header Row
              Row(
                children: [
                  SizedBox(
                    width: timeColumnWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'TIME',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted(context),
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  for (final room in classrooms)
                    SizedBox(
                      width: computedColWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _ClassroomColumnHeader(
                          classroom: room,
                          isOccupied: occupancy[room.id]?.isOccupied ?? false,
                          onTap: () {
                            ref
                                .read(inspectorSelectionProvider.notifier)
                                .open(InspectorTarget.classroom(room.id));
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Scrollable Hourly Rows
              SizedBox(
                height: math.min(gridHeight, 680),
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: gridHeight,
                    child: Stack(
                      children: [
                        // Hourly horizontal grid lines & time labels
                        for (int h = 0; h <= totalHours; h++)
                          Positioned(
                            top: h * hourHeight,
                            left: 0,
                            right: 0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: timeColumnWidth,
                                  child: Transform.translate(
                                    offset: const Offset(0, -8),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: Text(
                                        _formatHourLabel(startHour + h),
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  AppColors.textMuted(context),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : AppColors.lightTextPrimary
                                            .withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Classroom Columns (clickable empty hour slots + lessons)
                        Positioned.fill(
                          left: timeColumnWidth,
                          child: Row(
                            children: [
                              for (final room in classrooms)
                                SizedBox(
                                  width: computedColWidth,
                                  height: gridHeight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.06)
                                              : AppColors.lightTextPrimary
                                                  .withValues(alpha: 0.06),
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Empty slot tap targets
                                        for (int h = 0; h < totalHours; h++)
                                          Positioned(
                                            top: h * hourHeight,
                                            left: 0,
                                            right: 0,
                                            height: hourHeight,
                                            child: InkWell(
                                              hoverColor: AppColors
                                                  .englishSapphire
                                                  .withValues(alpha: 0.05),
                                              onTap: () {
                                                final slotStart = DateTime(
                                                  widget.selectedDate.year,
                                                  widget.selectedDate.month,
                                                  widget.selectedDate.day,
                                                  startHour + h,
                                                );
                                                showLessonFormModal(
                                                  context,
                                                  initialStartTime: slotStart,
                                                  initialClassroomId: room.id,
                                                );
                                              },
                                            ),
                                          ),
                                        // Lesson blocks for this classroom
                                        for (final lesson in dayLessons.where(
                                          (l) => l.classroomId == room.id,
                                        ))
                                          _buildPositionedLessonCard(
                                            context,
                                            lesson: lesson,
                                            startHour: startHour,
                                            hourHeight: hourHeight,
                                            gridHeight: gridHeight,
                                            now: now,
                                            teacherName:
                                                teachers[lesson.teacherId]
                                                        ?.fullName ??
                                                    'Unassigned',
                                            studentSummary: _studentSummary(
                                              lesson,
                                              students,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Happening Now Live Current-Time Line
                        if (currentMinutesOffset != null)
                          Positioned(
                            top: currentMinutesOffset,
                            left: 6,
                            right: 0,
                            child: IgnorePointer(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.liveEmerald,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.liveEmerald
                                              .withValues(alpha: 0.55),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      DateFormat('HH:mm').format(now),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.liveEmerald,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.liveEmerald
                                                .withValues(alpha: 0.55),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionedLessonCard(
    BuildContext context, {
    required Lesson lesson,
    required int startHour,
    required double hourHeight,
    required double gridHeight,
    required DateTime now,
    required String teacherName,
    required String studentSummary,
  }) {
    final startMinutes =
        (lesson.startTime.hour - startHour) * 60 + lesson.startTime.minute;
    final durationMinutes = math.max(30, lesson.durationMinutes);
    final top = ((startMinutes / 60.0) * hourHeight).clamp(0.0, gridHeight - 36);
    final height =
        ((durationMinutes / 60.0) * hourHeight).clamp(44.0, gridHeight - top);

    final isLive = lesson.isHappeningNowAt(now);
    final accent = lesson.language.accentColor(context);
    final isCanceled = lesson.status == LessonStatus.canceled;

    return Positioned(
      top: top + 2,
      left: 6,
      right: 6,
      height: height - 4,
      child: LiquidGlassContainer(
        borderRadius: 16,
        blurSigma: 14,
        elevation: isLive ? 1.1 : 0.45,
        tintColor: isLive ? AppColors.liveEmerald : accent,
        tintStrength: isLive ? 0.16 : 0.12,
        isSelected: isLive,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        onTap: () => widget.onSelectLesson(lesson),
        child: Opacity(
          opacity: isCanceled ? 0.52 : 1.0,
          child: LayoutBuilder(
            builder: (context, cardBox) {
              final innerHeight = cardBox.maxHeight;
              final showMeta = innerHeight >= 54;
              final twoLineTitle = innerHeight >= 76;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLive ? AppColors.liveEmerald : accent,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${DateFormat('h:mm').format(lesson.startTime)}–${DateFormat('h:mm a').format(lesson.endTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isLive ? AppColors.liveEmerald : accent,
                          ),
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
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      lesson.title,
                      maxLines: twoLineTitle ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: 12.5,
                            height: 1.15,
                            decoration:
                                isCanceled ? TextDecoration.lineThrough : null,
                          ),
                    ),
                  ),
                  if (showMeta) ...[
                    const Spacer(),
                    Text(
                      '$teacherName • $studentSummary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSwipeTimeline(
    BuildContext context,
    List<Classroom> classrooms,
    List<Lesson> dayLessons,
  ) {
    final now = ref.watch(liveClockProvider).value ?? DateTime.now();
    final teachers = ref.watch(teachersMapProvider);
    final classroomsMap = ref.watch(classroomsMapProvider);
    final students = ref.watch(studentsMapProvider);
    final occupancy = ref.watch(classroomOccupancyProvider);

    final pageTabs = <String>['All Rooms', ...classrooms.map((c) => c.name)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Swipeable classroom filter tabs
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pageTabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = _mobilePageIndex == index;
              final room = index == 0 ? null : classrooms[index - 1];
              final occupied =
                  room != null && (occupancy[room.id]?.isOccupied ?? false);
              return LiquidGlassPillButton(
                label: pageTabs[index],
                selected: selected,
                accentColor: occupied ? AppColors.liveEmerald : null,
                onTap: () {
                  setState(() => _mobilePageIndex = index);
                  _mobilePageCtrl.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: _mobilePageCtrl,
            itemCount: pageTabs.length,
            onPageChanged: (i) => setState(() => _mobilePageIndex = i),
            itemBuilder: (context, index) {
              final roomLessons = index == 0
                  ? dayLessons
                  : dayLessons
                      .where((l) => l.classroomId == classrooms[index - 1].id)
                      .toList();

              if (roomLessons.isEmpty) {
                return Center(
                  child: LiquidGlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          size: 34,
                          color: AppColors.textMuted(context),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No lessons in ${pageTabs[index]} on this day',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        LiquidPrimaryButton(
                          label: 'Add Lesson',
                          icon: CupertinoIcons.plus,
                          compact: true,
                          onPressed: () {
                            showLessonFormModal(
                              context,
                              initialStartTime: DateTime(
                                widget.selectedDate.year,
                                widget.selectedDate.month,
                                widget.selectedDate.day,
                                10,
                              ),
                              initialClassroomId: index == 0
                                  ? null
                                  : classrooms[index - 1].id,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: roomLessons.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final lesson = roomLessons[i];
                  final isLive = lesson.isHappeningNowAt(now);
                  final status = lesson.effectiveStatusAt(now);
                  final accent = lesson.language.accentColor(context);
                  final teacher = teachers[lesson.teacherId];
                  final room = classroomsMap[lesson.classroomId];

                  return LiquidGlassContainer(
                    borderRadius: 22,
                    blurSigma: 18,
                    tintColor: isLive ? AppColors.liveEmerald : accent,
                    tintStrength: isLive ? 0.14 : 0.08,
                    isSelected: isLive,
                    padding: const EdgeInsets.all(14),
                    onTap: () => widget.onSelectLesson(lesson),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            LanguageBadge(
                              language: lesson.language,
                              compact: true,
                            ),
                            const SizedBox(width: 6),
                            GlassInfoTag(label: lesson.lessonType.label),
                            const Spacer(),
                            StatusBadge(
                              label: status.label,
                              color: status.color(context),
                              glow: isLive,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${DateFormat('h:mm a').format(lesson.startTime)} – ${DateFormat('h:mm a').format(lesson.endTime)} • ${room?.name ?? 'Room'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teacher: ${teacher?.fullName ?? 'Unassigned'} • ${_studentSummary(lesson, students)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatHourLabel(int hour) {
    if (hour == 24) return '12 AM';
    final dt = DateTime(2026, 1, 1, hour);
    return DateFormat('h a').format(dt);
  }

  String _studentSummary(Lesson lesson, Map<String, dynamic> students) {
    if (lesson.studentIds.isEmpty) return 'No students';
    if (lesson.studentIds.length == 1) {
      final s = students[lesson.studentIds.first];
      return s?.fullName as String? ?? '1 student';
    }
    return '${lesson.studentIds.length} students';
  }
}

class _ClassroomColumnHeader extends StatelessWidget {
  const _ClassroomColumnHeader({
    required this.classroom,
    required this.isOccupied,
    required this.onTap,
  });

  final Classroom classroom;
  final bool isOccupied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      elevation: 0.3,
      tintColor: isOccupied ? AppColors.liveEmerald : null,
      tintStrength: isOccupied ? 0.12 : 0.0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOccupied
                  ? AppColors.liveEmerald
                  : AppColors.textMuted(context).withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classroom.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                      ),
                ),
                Text(
                  isOccupied
                      ? 'Occupied • Cap ${classroom.capacity}'
                      : 'Free • Cap ${classroom.capacity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        color: isOccupied
                            ? AppColors.liveEmerald
                            : AppColors.textMuted(context),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
