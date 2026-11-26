import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/student.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

Future<void> showStudentFormModal(
  BuildContext context, {
  Student? existing,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 580,
    builder: (_) => StudentFormDialog(existing: existing),
  );
}

class StudentFormDialog extends ConsumerStatefulWidget {
  const StudentFormDialog({super.key, this.existing});

  final Student? existing;

  @override
  ConsumerState<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends ConsumerState<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _creditsCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;

  late CourseLanguage _targetLanguage;
  late String _proficiencyLevel;
  late LessonType _format;
  String? _primaryTeacherId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.fullName ?? '');
    _creditsCtrl = TextEditingController(
      text: (e?.remainingCredits ?? 8).toString(),
    );
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');

    _targetLanguage = e?.targetLanguage ?? CourseLanguage.chinese;
    _proficiencyLevel = e?.proficiencyLevel ??
        ProficiencyLevels.defaultFor(_targetLanguage);
    _format = e?.format ?? LessonType.oneOnOne;
    _primaryTeacherId = e?.primaryTeacherId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _creditsCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final teachersMap = ref.watch(teachersMapProvider);
    final validTeacherId =
        (_primaryTeacherId != null && teachersMap.containsKey(_primaryTeacherId))
            ? _primaryTeacherId
            : null;
    final levels = ProficiencyLevels.forLanguage(_targetLanguage);
    if (!levels.contains(_proficiencyLevel)) {
      _proficiencyLevel = ProficiencyLevels.defaultFor(_targetLanguage);
    }

    final accent = _targetLanguage.accentColor(context);

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
                    CupertinoIcons.person_add_solid,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existing == null ? 'Add Student' : 'Edit Student',
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
                        labelText: 'Full Name *',
                        hintText: 'e.g., Olivia Bennett',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter the student\'s full name'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Language',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final lang in const [
                                  CourseLanguage.chinese,
                                  CourseLanguage.english,
                                ]) ...[
                                  LiquidGlassPillButton(
                                    label: lang.label,
                                    selected: _targetLanguage == lang,
                                    accentColor: lang.accentColor(context),
                                    onTap: () {
                                      setState(() {
                                        _targetLanguage = lang;
                                        _proficiencyLevel =
                                            ProficiencyLevels.defaultFor(lang);
                                      });
                                    },
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
                              'Enrollment Format',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final fmt in LessonType.values) ...[
                                  LiquidGlassPillButton(
                                    label: fmt.studentFormatLabel,
                                    selected: _format == fmt,
                                    accentColor: accent,
                                    onTap: () => setState(() => _format = fmt),
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

                    Text(
                      _targetLanguage == CourseLanguage.chinese
                          ? 'Proficiency Level (HSK 1–6)'
                          : 'Proficiency Level (CEFR A1–C2)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lvl in levels)
                          LiquidGlassPillButton(
                            label: lvl,
                            selected: _proficiencyLevel == lvl,
                            accentColor: accent,
                            onTap: () =>
                                setState(() => _proficiencyLevel = lvl),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            initialValue: validTeacherId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Primary Teacher',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Unassigned'),
                              ),
                              for (final t in teachers)
                                DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(
                                    '${t.fullName} (${t.languages.label})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _primaryTeacherId = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _creditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Lesson Credits *',
                            ),
                            validator: (v) {
                              final parsed = int.tryParse(v?.trim() ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Enter 0 or more';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              hintText: '+1 (415) 555-0200',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'student@example.com',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Learning goals, exam target date...',
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
                  label: widget.existing == null
                      ? 'Save Student'
                      : 'Update Student',
                  icon: CupertinoIcons.checkmark_alt,
                  color: accent,
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final student = Student(
                            id: widget.existing?.id ?? const Uuid().v4(),
                            fullName: _nameCtrl.text.trim(),
                            targetLanguage: _targetLanguage,
                            proficiencyLevel: _proficiencyLevel,
                            format: _format,
                            primaryTeacherId: validTeacherId,
                            remainingCredits:
                                int.parse(_creditsCtrl.text.trim()),
                            phone: _phoneCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                            notes: _notesCtrl.text.trim(),
                            createdAt:
                                widget.existing?.createdAt ?? DateTime.now(),
                          );
                          await ref
                              .read(dataRepositoryProvider)
                              .upsertStudent(student);
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
