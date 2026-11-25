import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/schedule_conflict.dart';
import '../../../core/models/teacher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

/// Opens the Add/Edit Lesson form using an adaptive sheet on mobile or dialog on desktop.
Future<void> showLessonFormModal(
  BuildContext context, {
  Lesson? existing,
  DateTime? initialStartTime,
  String? initialClassroomId,
  String? initialTeacherId,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 680,
    builder: (_) => LessonFormDialog(
      existing: existing,
      initialStartTime: initialStartTime,
      initialClassroomId: initialClassroomId,
      initialTeacherId: initialTeacherId,
    ),
  );
}

class LessonFormDialog extends ConsumerStatefulWidget {
  const LessonFormDialog({
    super.key,
    this.existing,
    this.initialStartTime,
    this.initialClassroomId,
    this.initialTeacherId,
  });

  final Lesson? existing;
  final DateTime? initialStartTime;
  final String? initialClassroomId;
  final String? initialTeacherId;

  @override
  ConsumerState<LessonFormDialog> createState() => _LessonFormDialogState();
}

class _LessonFormDialogState extends ConsumerState<LessonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;

  late CourseLanguage _language;
  late LessonType _lessonType;
  late LessonStatus _status;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _teacherId;
  String? _classroomId;
  late Set<String> _studentIds;
  bool _filterStudentsByLanguage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final defaultStart = widget.initialStartTime ?? _defaultNextHour();

    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');
    _language = existing?.language ?? CourseLanguage.chinese;
    _lessonType = existing?.lessonType ?? LessonType.oneOnOne;
    _status = existing?.status ?? LessonStatus.scheduled;

    final start = existing?.startTime ?? defaultStart;
    final end = existing?.endTime ?? start.add(const Duration(minutes: 60));
    _date = DateTime(start.year, start.month, start.day);
    _startTime = TimeOfDay.fromDateTime(start);
    _endTime = TimeOfDay.fromDateTime(end);
    _teacherId = existing?.teacherId ?? widget.initialTeacherId;
    _classroomId = existing?.classroomId ?? widget.initialClassroomId;
    _studentIds = {...(existing?.studentIds ?? const <String>[])};
  }

  DateTime _defaultNextHour() {
    final now = DateTime.now();
    if (now.hour >= 22) {
      return DateTime(now.year, now.month, now.day, now.hour, 0);
    }
    return DateTime(now.year, now.month, now.day, now.hour + 1, 0);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  void _applyDurationMinutes(int minutes) {
    final start = _combine(_date, _startTime);
    final end = start.add(Duration(minutes: minutes));
    setState(() {
      _endTime = TimeOfDay.fromDateTime(end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
    final students = ref.watch(studentsStreamProvider).value ?? const [];
    final existingLessons = ref.watch(lessonsStreamProvider).value ?? const [];

    final teachersMap = ref.watch(teachersMapProvider);
    final classroomsMap = ref.watch(classroomsMapProvider);
    final studentsMap = ref.watch(studentsMapProvider);

    final effectiveTeacherId =
        (_teacherId != null && teachersMap.containsKey(_teacherId))
            ? _teacherId!
            : _pickDefaultTeacher(teachers)?.id ?? '';
    final effectiveClassroomId =
        (_classroomId != null && classroomsMap.containsKey(_classroomId))
            ? _classroomId!
            : (classrooms.isNotEmpty ? classrooms.first.id : '');

    final startDt = _combine(_date, _startTime);
    var endDt = _combine(_date, _endTime);
    // Keep end date on same day unless explicitly earlier
    final candidate = Lesson(
      id: widget.existing?.id ?? '__draft__',
      title: _titleCtrl.text.trim().isEmpty
          ? 'Draft Lesson'
          : _titleCtrl.text.trim(),
      language: _language,
      lessonType: _lessonType,
      teacherId: effectiveTeacherId,
      classroomId: effectiveClassroomId,
      studentIds: _studentIds.toList(),
      startTime: startDt,
      endTime: endDt,
      status: _status,
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final validation = ScheduleConflictDetector.validate(
      candidate: candidate,
      existingLessons: existingLessons,
      teachersById: teachersMap,
      classroomsById: classroomsMap,
      studentsById: studentsMap,
    );

    final invalidTimeWindow = !endDt.isAfter(startDt);
    final canSave = !validation.hasBlockingConflicts &&
        !invalidTimeWindow &&
        effectiveTeacherId.isNotEmpty &&
        effectiveClassroomId.isNotEmpty &&
        !_saving;

    final visibleStudents = _filterStudentsByLanguage
        ? students.where((s) => s.targetLanguage == _language).toList()
        : students;

    final accent = _language.accentColor(context);

    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 28,
      elevation: 1.4,
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: accent.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    widget.existing == null
                        ? CupertinoIcons.calendar_badge_plus
                        : CupertinoIcons.pencil_circle,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existing == null
                            ? 'Schedule New Lesson'
                            : 'Edit Lesson',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Live conflict detection checks rooms, teachers & students.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(CupertinoIcons.xmark_circle_fill),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Real-time Conflict & Warning Banners
                    if (validation.hasBlockingConflicts) ...[
                      _ValidationBanner(
                        title: 'Scheduling Conflict Detected',
                        messages: validation.blockingConflicts
                            .map((c) => '${c.resourceType.label}: ${c.message}')
                            .toList(),
                        color: AppColors.dangerRose,
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (invalidTimeWindow) ...[
                      const _ValidationBanner(
                        title: 'Invalid Time Range',
                        messages: [
                          'End time must be strictly after start time on the same day.',
                        ],
                        color: AppColors.dangerRose,
                        icon: CupertinoIcons.clock_fill,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (validation.hasWarnings) ...[
                      _ValidationBanner(
                        title: 'Scheduling Advisory',
                        messages: validation.softWarnings,
                        color: AppColors.warningAmber,
                        icon: CupertinoIcons.info_circle_fill,
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lesson / Course Title *',
                        hintText: 'e.g., HSK 4 Speaking Workshop',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a lesson title';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Language & Lesson Type
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Language',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final lang in CourseLanguage.values) ...[
                                  LiquidGlassPillButton(
                                    label: lang.label,
                                    selected: _language == lang,
                                    accentColor: lang.accentColor(context),
                                    onTap: () => setState(() => _language = lang),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lesson Type',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final t in LessonType.values) ...[
                                  LiquidGlassPillButton(
                                    label: t.label,
                                    selected: _lessonType == t,
                                    accentColor: accent,
                                    onTap: () {
                                      setState(() {
                                        _lessonType = t;
                                        if (t == LessonType.oneOnOne &&
                                            _studentIds.length > 1) {
                                          _studentIds = {_studentIds.first};
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date, Start Time, End Time & Duration Presets
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _PickerTile(
                            label: 'Date',
                            value: DateFormat('EEE, MMM d, y').format(_date),
                            icon: CupertinoIcons.calendar,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _date = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _PickerTile(
                            label: 'Start',
                            value: DateFormat('h:mm a').format(startDt),
                            icon: CupertinoIcons.clock,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _startTime,
                              );
                              if (picked != null) {
                                final prevDuration =
                                    endDt.difference(startDt).inMinutes;
                                final newStart = _combine(_date, picked);
                                final safeDur =
                                    prevDuration > 0 ? prevDuration : 60;
                                final newEnd = newStart.add(
                                  Duration(minutes: safeDur),
                                );
                                setState(() {
                                  _startTime = picked;
                                  if (newEnd.day == _date.day) {
                                    _endTime = TimeOfDay.fromDateTime(newEnd);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _PickerTile(
                            label: 'End',
                            value: DateFormat('h:mm a').format(endDt),
                            icon: CupertinoIcons.clock_fill,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _endTime,
                              );
                              if (picked != null) {
                                setState(() => _endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Quick duration:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        for (final mins in [45, 60, 90, 120])
                          LiquidGlassPillButton(
                            label: '$mins min',
                            selected: endDt.difference(startDt).inMinutes == mins,
                            accentColor: accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            onTap: () => _applyDurationMinutes(mins),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Teacher & Classroom Selectors
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: effectiveTeacherId.isEmpty
                                ? null
                                : effectiveTeacherId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Teacher *',
                            ),
                            items: [
                              for (final t in teachers)
                                DropdownMenuItem(
                                  value: t.id,
                                  child: Text(
                                    '${t.fullName} (${t.languages.label})${t.isActive ? '' : ' • On Leave'}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (val) => setState(() => _teacherId = val),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Select a teacher' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: effectiveClassroomId.isEmpty
                                ? null
                                : effectiveClassroomId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Classroom *',
                            ),
                            items: [
                              for (final c in classrooms)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    '${c.name} (Cap ${c.capacity})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (val) =>
                                setState(() => _classroomId = val),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Select a classroom'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Assigned Students Selector
                    Row(
                      children: [
                        Text(
                          'Assigned Students (${_studentIds.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        FilterChip(
                          label: Text('${_language.label} students only'),
                          selected: _filterStudentsByLanguage,
                          onSelected: (val) => setState(
                            () => _filterStudentsByLanguage = val,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (visibleStudents.isEmpty)
                      Text(
                        'No students match this filter. Toggle off the filter or add students first.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in visibleStudents)
                            FilterChip(
                              selected: _studentIds.contains(s.id),
                              selectedColor: s.targetLanguage
                                  .accentColor(context)
                                  .withValues(alpha: 0.18),
                              label: Text(
                                '${s.fullName} (${s.proficiencyLevel})',
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (_lessonType == LessonType.oneOnOne) {
                                    _studentIds = selected ? {s.id} : {};
                                  } else {
                                    if (selected) {
                                      _studentIds.add(s.id);
                                    } else {
                                      _studentIds.remove(s.id);
                                    }
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Status Selector
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final st in LessonStatus.values)
                          LiquidGlassPillButton(
                            label: st.label,
                            selected: _status == st,
                            accentColor: st.color(context),
                            onTap: () => setState(() => _status = st),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Notes',
                        hintText: 'Materials, homework, focus areas...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                LiquidPrimaryButton(
                  label: validation.hasBlockingConflicts
                      ? 'Resolve Conflict to Save'
                      : (widget.existing == null
                          ? 'Schedule Lesson'
                          : 'Save Changes'),
                  icon: validation.hasBlockingConflicts
                      ? CupertinoIcons.exclamationmark_circle
                      : CupertinoIcons.checkmark_alt,
                  color: validation.hasBlockingConflicts
                      ? AppColors.dangerRose
                      : accent,
                  onPressed: canSave
                      ? () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final toSave = candidate.copyWith(
                            id: widget.existing?.id ?? const Uuid().v4(),
                            title: _titleCtrl.text.trim(),
                            teacherId: effectiveTeacherId,
                            classroomId: effectiveClassroomId,
                            notes: _notesCtrl.text.trim(),
                          );
                          await ref
                              .read(dataRepositoryProvider)
                              .upsertLesson(toSave);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Teacher? _pickDefaultTeacher(List<Teacher> teachers) {
    if (teachers.isEmpty) return null;
    for (final t in teachers) {
      if (t.isActive && t.languages.supports(_language)) return t;
    }
    return teachers.first;
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 16,
      blurSigma: 12,
      elevation: 0.25,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textMuted(context)),
              const SizedBox(width: 5),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({
    required this.title,
    required this.messages,
    required this.color,
    required this.icon,
  });

  final String title;
  final List<String> messages;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                for (final msg in messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $msg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary(context),
                          ),
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
