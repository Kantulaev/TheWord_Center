import 'package:material_ui/material_ui.dart';

import '../../../core/models/community_models.dart';
import '../../../core/models/language_type.dart';
import '../../../core/models/student.dart';
import '../../../core/models/study_group.dart';
import '../../../core/models/teacher.dart';
import '../../../core/theme/app_colors.dart';

/// Shared audience selector used across Notifications and Events creation dialogs.
class AudiencePickerSection extends StatefulWidget {
  const AudiencePickerSection({
    super.key,
    required this.audience,
    required this.targetGroupId,
    required this.targetEmails,
    required this.groups,
    required this.teachers,
    required this.students,
    required this.onChanged,
  });

  final AudienceType audience;
  final String targetGroupId;
  final List<String> targetEmails;
  final List<StudyGroup> groups;
  final List<Teacher> teachers;
  final List<Student> students;
  final void Function({
    required AudienceType audience,
    required String targetGroupId,
    required String targetGroupName,
    required List<String> targetEmails,
  }) onChanged;

  @override
  State<AudiencePickerSection> createState() => _AudiencePickerSectionState();
}

class _AudiencePickerSectionState extends State<AudiencePickerSection> {
  final TextEditingController _customEmailController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void dispose() {
    _customEmailController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  List<String> _emailsForGroup(String groupId) {
    final group = widget.groups.cast<StudyGroup?>().firstWhere(
          (g) => g?.id == groupId,
          orElse: () => null,
        );
    if (group == null) return const [];
    final emails = <String>{};
    for (final member in group.members) {
      final norm = member.email.trim().toLowerCase();
      if (norm.isNotEmpty) emails.add(norm);
    }
    final memberIds = group.members.map((m) => m.memberId).toSet();
    for (final student in widget.students) {
      if (memberIds.contains(student.id)) {
        final norm = student.email.trim().toLowerCase();
        if (norm.isNotEmpty) emails.add(norm);
      }
    }
    return emails.toList(growable: false);
  }

  String _groupNameFor(String groupId) {
    final group = widget.groups.cast<StudyGroup?>().firstWhere(
          (g) => g?.id == groupId,
          orElse: () => null,
        );
    return group?.name ?? '';
  }

  void _selectAudience(AudienceType next) {
    if (next == AudienceType.specificGroup) {
      final eligibleGroups = widget.groups
          .where((g) => g.language != CourseLanguage.sharing)
          .toList();
      final chosenId = widget.targetGroupId.isNotEmpty
          ? widget.targetGroupId
          : (eligibleGroups.isNotEmpty ? eligibleGroups.first.id : '');
      widget.onChanged(
        audience: next,
        targetGroupId: chosenId,
        targetGroupName: _groupNameFor(chosenId),
        targetEmails: _emailsForGroup(chosenId),
      );
      return;
    }

    if (next == AudienceType.selectedUsers) {
      widget.onChanged(
        audience: next,
        targetGroupId: '',
        targetGroupName: '',
        targetEmails: widget.targetEmails,
      );
      return;
    }

    widget.onChanged(
      audience: next,
      targetGroupId: '',
      targetGroupName: '',
      targetEmails: const [],
    );
  }

  void _toggleEmail(String email) {
    final norm = email.trim().toLowerCase();
    if (norm.isEmpty) return;
    final next = widget.targetEmails.toSet();
    if (next.contains(norm)) {
      next.remove(norm);
    } else {
      next.add(norm);
    }
    widget.onChanged(
      audience: widget.audience,
      targetGroupId: '',
      targetGroupName: '',
      targetEmails: next.toList(growable: false),
    );
  }

  void _addCustomEmails() {
    final raw = _customEmailController.text.trim();
    if (raw.isEmpty) return;
    final next = widget.targetEmails.toSet();
    for (final part in raw.split(RegExp(r'[,;\s]+'))) {
      final cleaned = part.trim().toLowerCase();
      if (cleaned.contains('@')) {
        next.add(cleaned);
      }
    }
    _customEmailController.clear();
    widget.onChanged(
      audience: widget.audience,
      targetGroupId: '',
      targetGroupName: '',
      targetEmails: next.toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nonSharingGroups = widget.groups
        .where((g) => g.language != CourseLanguage.sharing)
        .toList();

    final directory = <({String name, String email, String role})>[];
    final seenEmails = <String>{};
    for (final t in widget.teachers) {
      final norm = t.email.trim().toLowerCase();
      if (norm.isNotEmpty && seenEmails.add(norm)) {
        directory.add((name: t.fullName, email: norm, role: 'Teacher'));
      }
    }
    for (final s in widget.students) {
      final norm = s.email.trim().toLowerCase();
      if (norm.isNotEmpty && seenEmails.add(norm)) {
        directory.add((name: s.fullName, email: norm, role: 'Student'));
      }
    }

    final query = _userSearchController.text.trim().toLowerCase();
    final filteredDirectory = query.isEmpty
        ? directory
        : directory
            .where(
              (u) =>
                  u.name.toLowerCase().contains(query) ||
                  u.email.contains(query),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience / Visibility',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in AudienceType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: widget.audience == type,
                onSelected: (_) => _selectAudience(type),
              ),
          ],
        ),
        if (widget.audience == AudienceType.specificGroup) ...[
          const SizedBox(height: 12),
          if (nonSharingGroups.isEmpty)
            Text(
              'No HSK / English study groups available yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grp in nonSharingGroups)
                  ChoiceChip(
                    label: Text('${grp.name} (${grp.level})'),
                    selected: widget.targetGroupId == grp.id,
                    onSelected: (_) => widget.onChanged(
                      audience: AudienceType.specificGroup,
                      targetGroupId: grp.id,
                      targetGroupName: grp.name,
                      targetEmails: _emailsForGroup(grp.id),
                    ),
                  ),
              ],
            ),
        ],
        if (widget.audience == AudienceType.selectedUsers) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Add emails (comma-separated)',
                    hintText: 'student@gmail.com, teacher@gmail.com',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addCustomEmails(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _addCustomEmails,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (widget.targetEmails.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final email in widget.targetEmails)
                  InputChip(
                    label: Text(email, style: const TextStyle(fontSize: 12)),
                    onDeleted: () => _toggleEmail(email),
                  ),
              ],
            ),
          ],
          if (directory.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _userSearchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                hintText: 'Filter registered teachers & students...',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted(context).withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredDirectory.length,
                itemBuilder: (context, index) {
                  final item = filteredDirectory[index];
                  final selected = widget.targetEmails.contains(item.email);
                  return CheckboxListTile(
                    dense: true,
                    value: selected,
                    onChanged: (_) => _toggleEmail(item.email),
                    title: Text(
                      '${item.name} (${item.role})',
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.email,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }
}
