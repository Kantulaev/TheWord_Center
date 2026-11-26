import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/lesson.dart';
import '../../../core/models/study_group.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

Future<void> showGroupFormModal(
  BuildContext context, {
  StudyGroup? existing,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 600,
    builder: (_) => GroupFormDialog(existing: existing),
  );
}

class GroupFormDialog extends ConsumerStatefulWidget {
  const GroupFormDialog({super.key, this.existing});

  final StudyGroup? existing;

  @override
  ConsumerState<GroupFormDialog> createState() => _GroupFormDialogState();
}

class _GroupFormDialogState extends ConsumerState<GroupFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;

  late CourseLanguage _language;
  late String _level;
  String? _teacherId;
  String? _classroomId;
  late Set<int> _weekdays;
  late TimeOfDay _startTime;
  late int _durationMinutes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _language = e?.language ?? CourseLanguage.chinese;
    _level = e?.level ?? ProficiencyLevels.defaultFor(_language);
    _teacherId = e?.teacherId;
    _classroomId = e?.classroomId;
    _weekdays = {
      ...(e?.scheduleWeekdays ??
          const [DateTime.monday, DateTime.wednesday, DateTime.friday]),
    };
    _startTime = TimeOfDay(
      hour: e?.startHour ?? 18,
      minute: e?.startMinute ?? 0,
    );
    _durationMinutes = e?.durationMinutes ?? 90;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final classrooms = ref.watch(classroomsStreamProvider).value ?? const [];
    final teachersMap = ref.watch(teachersMapProvider);
    final classroomsMap = ref.watch(classroomsMapProvider);

    final validTeacherId =
        (_teacherId != null && teachersMap.containsKey(_teacherId))
            ? _teacherId
            : (teachers.isNotEmpty ? teachers.first.id : null);
    final validRoomId =
        (_classroomId != null && classroomsMap.containsKey(_classroomId))
            ? _classroomId
            : (classrooms.isNotEmpty ? classrooms.first.id : null);

    final levels = ProficiencyLevels.forLanguage(_language);
    if (!levels.contains(_level)) {
      _level = ProficiencyLevels.defaultFor(_language);
    }

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
                    CupertinoIcons.person_3_fill,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Create Study Group'
                        : 'Edit Study Group',
                    style: Theme.of(context).textTheme.titleLarge,
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
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Group Name *',
                        hintText: 'e.g., HSK 1 — Morning Cohort',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Enter a group name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Category / Language',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lang in CourseLanguage.values)
                          LiquidGlassPillButton(
                            label: lang == CourseLanguage.sharing
                                ? 'Sharing (Staff Only)'
                                : lang.label,
                            selected: _language == lang,
                            accentColor: lang.accentColor(context),
                            onTap: () => setState(() {
                              _language = lang;
                              _level = ProficiencyLevels.defaultFor(lang);
                            }),
                          ),
                      ],
                    ),
                    if (_language == CourseLanguage.sharing) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.sharingViolet.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.sharingViolet.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.lock_shield_fill,
                              size: 16,
                              color: AppColors.sharingViolet,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Private for teachers only: hidden from students in both the Student Portal and Firestore Security Rules.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Level',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lvl in levels)
                          LiquidGlassPillButton(
                            label: lvl,
                            selected: _level == lvl,
                            accentColor: accent,
                            onTap: () => setState(() => _level = lvl),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: validTeacherId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Teacher *',
                            ),
                            items: [
                              for (final t in teachers)
                                DropdownMenuItem(
                                  value: t.id,
                                  child: Text(
                                    t.fullName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _teacherId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: validRoomId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Classroom *',
                            ),
                            items: [
                              for (final c in classrooms)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _classroomId = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Steady Weekly Schedule',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int wd = DateTime.monday;
                            wd <= DateTime.sunday;
                            wd++)
                          FilterChip(
                            label: Text(Lesson.weekdayShortLabel(wd)),
                            selected: _weekdays.contains(wd),
                            selectedColor: accent.withValues(alpha: 0.18),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _weekdays.add(wd);
                                } else {
                                  _weekdays.remove(wd);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        LiquidGlassPillButton(
                          label: 'Start: ${_startTime.format(context)}',
                          icon: CupertinoIcons.clock,
                          accentColor: accent,
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (picked != null) {
                              setState(() => _startTime = picked);
                            }
                          },
                        ),
                        for (final mins in [60, 90, 120])
                          LiquidGlassPillButton(
                            label: '$mins min',
                            selected: _durationMinutes == mins,
                            accentColor: accent,
                            onTap: () =>
                                setState(() => _durationMinutes = mins),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Textbook unit, cohort details...',
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
                  label:
                      widget.existing == null ? 'Save Group' : 'Update Group',
                  icon: CupertinoIcons.checkmark_alt,
                  color: accent,
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final sortedDays = _weekdays.toList()..sort();
                          final group = StudyGroup(
                            id: widget.existing?.id ?? const Uuid().v4(),
                            name: _nameCtrl.text.trim(),
                            language: _language,
                            level: _level,
                            teacherId: validTeacherId ?? '',
                            classroomId: validRoomId ?? '',
                            scheduleWeekdays: sortedDays,
                            startHour: _startTime.hour,
                            startMinute: _startTime.minute,
                            durationMinutes: _durationMinutes,
                            members: widget.existing?.members ?? const [],
                            notes: _notesCtrl.text.trim(),
                            createdAt:
                                widget.existing?.createdAt ?? DateTime.now(),
                          );
                          await ref
                              .read(dataRepositoryProvider)
                              .upsertGroup(group);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
