import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/classroom.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

Future<void> showClassroomFormModal(
  BuildContext context, {
  Classroom? existing,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 540,
    builder: (_) => ClassroomFormDialog(existing: existing),
  );
}

class ClassroomFormDialog extends ConsumerStatefulWidget {
  const ClassroomFormDialog({super.key, this.existing});

  final Classroom? existing;

  @override
  ConsumerState<ClassroomFormDialog> createState() =>
      _ClassroomFormDialogState();
}

class _ClassroomFormDialogState extends ConsumerState<ClassroomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _customTagCtrl;
  late Set<String> _equipmentTags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _capacityCtrl = TextEditingController(
      text: (e?.capacity ?? 6).toString(),
    );
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _customTagCtrl = TextEditingController();
    _equipmentTags = {...(e?.equipmentTags ?? const ['Whiteboard'])};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    _customTagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTags = {
      ...Classroom.standardEquipment,
      ..._equipmentTags,
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: AppColors.englishSapphire.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    color: AppColors.englishSapphire,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Add Classroom'
                        : 'Edit Classroom',
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
                        labelText: 'Room Name / Number *',
                        hintText: 'e.g., Room 1 - Beijing',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter a room name'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Seating Capacity *',
                        hintText: 'e.g., 8',
                      ),
                      validator: (v) {
                        final parsed = int.tryParse(v?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid capacity (1 or more)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Equipment Tags',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in allTags)
                          FilterChip(
                            label: Text(tag),
                            selected: _equipmentTags.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _equipmentTags.add(tag);
                                } else {
                                  _equipmentTags.remove(tag);
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
                              hintText: 'Add custom equipment tag...',
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Floor, acoustics, camera setup...',
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
                      ? 'Save Classroom'
                      : 'Update Classroom',
                  icon: CupertinoIcons.checkmark_alt,
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final room = Classroom(
                            id: widget.existing?.id ?? const Uuid().v4(),
                            name: _nameCtrl.text.trim(),
                            capacity: int.parse(_capacityCtrl.text.trim()),
                            equipmentTags: _equipmentTags.toList(),
                            notes: _notesCtrl.text.trim(),
                            createdAt:
                                widget.existing?.createdAt ?? DateTime.now(),
                          );
                          await ref
                              .read(dataRepositoryProvider)
                              .upsertClassroom(room);
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
      _equipmentTags.add(tag);
      _customTagCtrl.clear();
    });
  }
}
