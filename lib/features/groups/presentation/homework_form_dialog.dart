import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/homework.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

Future<void> showHomeworkFormModal(
  BuildContext context, {
  String? initialGroupId,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 540,
    builder: (_) => HomeworkFormDialog(initialGroupId: initialGroupId),
  );
}

class HomeworkFormDialog extends ConsumerStatefulWidget {
  const HomeworkFormDialog({super.key, this.initialGroupId});

  final String? initialGroupId;

  @override
  ConsumerState<HomeworkFormDialog> createState() => _HomeworkFormDialogState();
}

class _HomeworkFormDialogState extends ConsumerState<HomeworkFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _groupId;
  late DateTime _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _groupId = widget.initialGroupId;
    final now = DateTime.now();
    _dueDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsStreamProvider).value ?? const [];
    final selectedGroupId = (_groupId != null &&
            groups.any((g) => g.id == _groupId))
        ? _groupId
        : (groups.isNotEmpty ? groups.first.id : null);

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
                    CupertinoIcons.doc_text_fill,
                    color: AppColors.englishSapphire,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Homework',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Delivered directly to students in the selected group.',
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
                    DropdownButtonFormField<String>(
                      initialValue: selectedGroupId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Target Study Group *',
                      ),
                      items: [
                        for (final g in groups)
                          DropdownMenuItem(
                            value: g.id,
                            child: Text(
                              '${g.name} (${g.level})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _groupId = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Select a group' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Homework Title *',
                        hintText: 'e.g., HSK 1 Character Practice & Audio',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter a homework title'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Instructions *',
                        hintText: 'Pages, audio exercises, writing prompts...',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter instructions for students'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    LiquidGlassContainer(
                      borderRadius: 16,
                      blurSigma: 10,
                      elevation: 0.25,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.calendar,
                            size: 16,
                            color: AppColors.textMuted(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Due Date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('EEE, MMM d, y').format(_dueDate),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
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
                  label: _saving ? 'Sending...' : 'Send Homework',
                  icon: CupertinoIcons.paperplane_fill,
                  onPressed: _saving || selectedGroupId == null
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final group = groups
                              .firstWhere((g) => g.id == selectedGroupId);
                          final hw = HomeworkAssignment(
                            id: const Uuid().v4(),
                            title: _titleCtrl.text.trim(),
                            description: _descCtrl.text.trim(),
                            groupId: group.id,
                            teacherId: group.teacherId,
                            dueDate: _dueDate,
                            createdAt: DateTime.now(),
                          );
                          await ref
                              .read(dataRepositoryProvider)
                              .upsertHomework(hw);
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
