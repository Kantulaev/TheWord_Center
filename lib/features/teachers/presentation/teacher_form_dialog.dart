import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/operations_models.dart';
import '../../../core/models/teacher.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/entity_avatar.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

Future<void> showTeacherFormModal(
  BuildContext context, {
  Teacher? existing,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 580,
    builder: (_) => TeacherFormDialog(existing: existing),
  );
}

class TeacherFormDialog extends ConsumerStatefulWidget {
  const TeacherFormDialog({super.key, this.existing});

  final Teacher? existing;

  @override
  ConsumerState<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends ConsumerState<TeacherFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _hourlyRateCtrl;
  late final TextEditingController _clubRateCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _customTagCtrl;

  late String _avatarHex;
  late TeachingLanguageScope _languages;
  late Set<String> _specializations;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _hourlyRateCtrl = TextEditingController(
      text: (e?.hourlyRate ?? 25.0).toStringAsFixed(0),
    );
    _clubRateCtrl = TextEditingController(
      text: (e?.clubRate ?? 35.0).toStringAsFixed(0),
    );
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _customTagCtrl = TextEditingController();
    _avatarHex = e?.avatarColorHex ?? AppColors.avatarColorHexes.first;
    _languages = e?.languages ?? TeachingLanguageScope.chinese;
    _specializations = {...(e?.specializations ?? const <String>[])};
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _hourlyRateCtrl.dispose();
    _clubRateCtrl.dispose();
    _notesCtrl.dispose();
    _customTagCtrl.dispose();
    super.dispose();
  }

  String _previewInitials() {
    final parts = _nameCtrl.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'TW';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.fromHex(_avatarHex);
    final allSuggestions = {
      ...Teacher.suggestedSpecializations,
      ..._specializations,
    }.toList();

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
                EntityAvatar(
                  initials: _previewInitials(),
                  color: selectedColor,
                  size: 46,
                  isActiveDot: _isActive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existing == null ? 'Add Teacher' : 'Edit Teacher',
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
                        hintText: 'e.g., Mei Lin',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter the teacher\'s full name'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Avatar Color',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        for (final hex in AppColors.avatarColorHexes)
                          GestureDetector(
                            onTap: () => setState(() => _avatarHex = hex),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.fromHex(hex),
                                border: Border.all(
                                  color: _avatarHex == hex
                                      ? AppColors.textPrimary(context)
                                      : Colors.white.withValues(alpha: 0.7),
                                  width: _avatarHex == hex ? 2.5 : 1.5,
                                ),
                              ),
                              child: _avatarHex == hex
                                  ? const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Teaching Languages',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final scope in TeachingLanguageScope.values)
                          LiquidGlassPillButton(
                            label: scope.label,
                            selected: _languages == scope,
                            accentColor: scope.accentColor(context),
                            onTap: () => setState(() => _languages = scope),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Specializations',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in allSuggestions)
                          FilterChip(
                            label: Text(tag),
                            selected: _specializations.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _specializations.add(tag);
                                } else {
                                  _specializations.remove(tag);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customTagCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Add custom specialization tag...',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addCustomTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _addCustomTag,
                          child: const Text('Add Tag'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              hintText: '+1 (415) 555-0100',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'name@theword.center',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hourlyRateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Class Hourly Rate (\$)',
                              hintText: '25',
                            ),
                            validator: (v) {
                              final val = double.tryParse(v?.trim() ?? '');
                              if (val == null || val < 0) return 'Valid rate';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _clubRateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Club Session Rate (\$)',
                              hintText: '35',
                            ),
                            validator: (v) {
                              final val = double.tryParse(v?.trim() ?? '');
                              if (val == null || val < 0) return 'Valid rate';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _isActive ? 'Active & Available' : 'On Leave',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Available for regular lesson assignment'
                            : 'Shows an advisory notice when scheduling',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Bio, teaching background, availability...',
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
                      ? 'Save Teacher'
                      : 'Update Teacher',
                  icon: CupertinoIcons.checkmark_alt,
                  color: selectedColor,
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final teacher = Teacher(
                            id: widget.existing?.id ?? const Uuid().v4(),
                            fullName: _nameCtrl.text.trim(),
                            avatarColorHex: _avatarHex,
                            languages: _languages,
                            specializations: _specializations.toList(),
                            phone: _phoneCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                            isActive: _isActive,
                            notes: _notesCtrl.text.trim(),
                            hourlyRate:
                                double.tryParse(_hourlyRateCtrl.text.trim()) ??
                                    25.0,
                            clubRate:
                                double.tryParse(_clubRateCtrl.text.trim()) ??
                                    35.0,
                            createdAt:
                                widget.existing?.createdAt ?? DateTime.now(),
                          );
                          final repo = ref.read(dataRepositoryProvider);
                          await repo.upsertTeacher(teacher);
                          final actor =
                              ref.read(authStateProvider).value?.email ??
                                  'staff';
                          await repo.logActivity(
                            ActivityLogEntry(
                              id: const Uuid().v4(),
                              actorEmail: actor,
                              category: 'Teacher',
                              summary:
                                  '${widget.existing == null ? "Added" : "Updated"} teacher ${teacher.fullName} (\$${teacher.hourlyRate.toStringAsFixed(0)}/h)',
                              createdAt: DateTime.now(),
                            ),
                          );
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

  void _addCustomTag() {
    final tag = _customTagCtrl.text.trim();
    if (tag.isEmpty) return;
    setState(() {
      _specializations.add(tag);
      _customTagCtrl.clear();
    });
  }
}
