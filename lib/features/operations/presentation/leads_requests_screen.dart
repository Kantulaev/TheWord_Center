import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/language_type.dart';
import '../../../core/models/operations_models.dart';
import '../../../core/models/student.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/reminder_helper.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

class LeadsRequestsScreen extends ConsumerStatefulWidget {
  const LeadsRequestsScreen({super.key});

  @override
  ConsumerState<LeadsRequestsScreen> createState() =>
      _LeadsRequestsScreenState();
}

class _LeadsRequestsScreenState extends ConsumerState<LeadsRequestsScreen> {
  LeadStage? _stageFilter;

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(trialLeadsStreamProvider).value ?? const [];
    final requests =
        ref.watch(rescheduleRequestsStreamProvider).value ?? const [];

    final filteredLeads = _stageFilter == null
        ? leads
        : leads.where((l) => l.stage == _stageFilter).toList();
    final pendingCount =
        requests.where((r) => r.status == RequestStatus.pending).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 620;
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trial Leads & Student Requests',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Convert prospective trial learners into enrolled students and review live reschedule requests from the Student Portal.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final action = LiquidPrimaryButton(
              label: 'New Trial Lead',
              icon: CupertinoIcons.person_badge_plus,
              onPressed: () => _showLeadFormModal(context),
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [header, const SizedBox(height: 12), action],
              );
            }
            return Row(
              children: [
                Expanded(child: header),
                const SizedBox(width: 16),
                action,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Reschedule Requests Queue
        LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          tintColor: pendingCount > 0
              ? AppColors.warningAmber
              : AppColors.englishAccent(context),
          tintStrength: 0.05,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.arrow_2_circlepath_circle_fill,
                    color: pendingCount > 0
                        ? AppColors.warningAmber
                        : AppColors.englishAccent(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student Reschedule Requests ($pendingCount pending)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Students submit date/time change requests from their portal. Approving updates the student immediately in real time.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (requests.isEmpty)
                Text(
                  'No reschedule requests submitted yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final req in requests) ...[
                  _RescheduleRequestCard(
                    request: req,
                    onApprove: () => _resolveRequest(
                      context,
                      request: req,
                      status: RequestStatus.approved,
                    ),
                    onDecline: () => _resolveRequest(
                      context,
                      request: req,
                      status: RequestStatus.declined,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Trial Leads Section
        LiquidGlassContainer(
          borderRadius: 24,
          blurSigma: 20,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: AppColors.sharingAccent(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trial Pipeline (${filteredLeads.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    LiquidGlassPillButton(
                      label: 'All (${leads.length})',
                      selected: _stageFilter == null,
                      onTap: () => setState(() => _stageFilter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final stage in LeadStage.values) ...[
                      LiquidGlassPillButton(
                        label: stage.label,
                        selected: _stageFilter == stage,
                        accentColor: _stageColor(context, stage),
                        onTap: () => setState(() => _stageFilter = stage),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filteredLeads.isEmpty)
                Text(
                  'No leads in this stage yet. Click "New Trial Lead" to log an inquiry.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final lead in filteredLeads) ...[
                  _TrialLeadCard(
                    lead: lead,
                    stageColor: _stageColor(context, lead.stage),
                    onEdit: () => _showLeadFormModal(context, existing: lead),
                    onConvert: () => _convertLeadToStudent(context, lead),
                    onChangeStage: (newStage) => _updateStage(lead, newStage),
                    onDelete: () => _deleteLead(context, lead),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Color _stageColor(BuildContext context, LeadStage stage) => switch (stage) {
        LeadStage.newLead => AppColors.englishAccent(context),
        LeadStage.trialScheduled => AppColors.sharingAccent(context),
        LeadStage.attended => AppColors.warningAmber,
        LeadStage.enrolled => AppColors.liveEmerald,
        LeadStage.lost => AppColors.completedSlate,
      };

  Future<void> _updateStage(TrialLead lead, LeadStage stage) async {
    final repo = ref.read(dataRepositoryProvider);
    await repo.upsertTrialLead(lead.copyWith(stage: stage));
    final actor = ref.read(authStateProvider).value?.email ?? 'staff';
    await repo.logActivity(
      ActivityLogEntry(
        id: const Uuid().v4(),
        actorEmail: actor,
        category: 'Lead',
        summary: 'Moved ${lead.fullName} to "${stage.label}"',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _convertLeadToStudent(
    BuildContext context,
    TrialLead lead,
  ) async {
    final repo = ref.read(dataRepositoryProvider);
    final actor = ref.read(authStateProvider).value?.email ?? 'staff';
    final newStudent = Student(
      id: const Uuid().v4(),
      fullName: lead.fullName,
      targetLanguage: lead.targetLanguage,
      proficiencyLevel: lead.preferredLevel,
      format: LessonType.group,
      remainingCredits: 12,
      phone: lead.phone,
      email: lead.email,
      notes: 'Converted from Trial Lead. ${lead.notes}'.trim(),
      createdAt: DateTime.now(),
    );
    await repo.upsertStudent(newStudent);
    await repo.upsertTrialLead(lead.copyWith(stage: LeadStage.enrolled));
    await repo.logActivity(
      ActivityLogEntry(
        id: const Uuid().v4(),
        actorEmail: actor,
        category: 'Lead',
        summary:
            'Converted lead ${lead.fullName} into enrolled student (${lead.targetLanguage.label} ${lead.preferredLevel})',
        createdAt: DateTime.now(),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Converted ${lead.fullName} to an enrolled student with 12 starting credits',
        ),
      ),
    );
  }

  Future<void> _deleteLead(BuildContext context, TrialLead lead) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete Lead',
      message: 'Remove "${lead.fullName}" from the trial pipeline?',
    );
    if (!confirmed) return;
    await ref.read(dataRepositoryProvider).deleteTrialLead(lead.id);
  }

  Future<void> _resolveRequest(
    BuildContext context, {
    required RescheduleRequest request,
    required RequestStatus status,
  }) async {
    final noteCtrl = TextEditingController(
      text: status == RequestStatus.approved
          ? 'Approved — please check updated class time in your schedule.'
          : '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          status == RequestStatus.approved
              ? 'Approve Reschedule'
              : 'Decline Reschedule',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.studentName} • ${request.groupName}',
              style: Theme.of(dialogCtx).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Requested: ${DateFormat('EEE, MMM d').format(request.requestedDate)} (${request.preferredSlot})',
              style: Theme.of(dialogCtx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reply note for student (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: status == RequestStatus.approved
                  ? AppColors.liveEmerald
                  : AppColors.dangerRose,
            ),
            child: Text(
              status == RequestStatus.approved ? 'Approve' : 'Decline',
            ),
          ),
        ],
      ),
    );
    final note = noteCtrl.text.trim();
    noteCtrl.dispose();
    if (confirmed != true) return;

    final repo = ref.read(dataRepositoryProvider);
    final actor = ref.read(authStateProvider).value?.email ?? 'staff';
    await repo.resolveRescheduleRequest(
      requestId: request.id,
      status: status,
      staffNote: note,
    );
    await repo.logActivity(
      ActivityLogEntry(
        id: const Uuid().v4(),
        actorEmail: actor,
        category: 'Schedule',
        summary:
            '${status.label} reschedule request from ${request.studentName} (${request.groupName})',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _showLeadFormModal(
    BuildContext context, {
    TrialLead? existing,
  }) {
    return showAdaptiveGlassModal<void>(
      context,
      maxWidth: 540,
      builder: (_) => _LeadFormDialog(existing: existing),
    );
  }
}

class _RescheduleRequestCard extends StatelessWidget {
  const _RescheduleRequestCard({
    required this.request,
    required this.onApprove,
    required this.onDecline,
  });

  final RescheduleRequest request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      RequestStatus.pending => AppColors.warningAmber,
      RequestStatus.approved => AppColors.liveEmerald,
      RequestStatus.declined => AppColors.dangerRose,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.studentName} • ${request.groupName}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Preferred: ${DateFormat('EEE, MMM d').format(request.requestedDate)} at ${request.preferredSlot}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: request.status.label,
                color: statusColor,
                compact: true,
              ),
            ],
          ),
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${request.reason}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (request.staffNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Staff reply: ${request.staffNote}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.liveEmerald,
                  foregroundColor: Colors.white,
                ),
                onPressed: onApprove,
                icon: const Icon(CupertinoIcons.checkmark_alt, size: 15),
                label: const Text('Approve'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.dangerRose,
                ),
                onPressed: onDecline,
                icon: const Icon(CupertinoIcons.xmark, size: 15),
                label: const Text('Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrialLeadCard extends StatelessWidget {
  const _TrialLeadCard({
    required this.lead,
    required this.stageColor,
    required this.onEdit,
    required this.onConvert,
    required this.onChangeStage,
    required this.onDelete,
  });

  final TrialLead lead;
  final Color stageColor;
  final VoidCallback onEdit;
  final VoidCallback onConvert;
  final ValueChanged<LeadStage> onChangeStage;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final msg =
        'Hello ${lead.fullName}! Thank you for your interest in ${lead.targetLanguage.label} (${lead.preferredLevel}) at The Word Language Center. Let us know what time works best for your trial lesson!';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: stageColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.fullName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (lead.phone.isNotEmpty) lead.phone,
                        if (lead.email.isNotEmpty) lead.email,
                        if (lead.trialDate != null)
                          'Trial: ${DateFormat('MMM d, h:mm a').format(lead.trialDate!)}',
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LanguageBadge(language: lead.targetLanguage, compact: true),
              const SizedBox(width: 6),
              StatusBadge(
                label: lead.stage.label,
                color: stageColor,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Level: ${lead.preferredLevel}${lead.notes.isNotEmpty ? ' • ${lead.notes}' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PopupMenuButton<LeadStage>(
                onSelected: onChangeStage,
                itemBuilder: (_) => [
                  for (final s in LeadStage.values)
                    PopupMenuItem(value: s, child: Text(s.label)),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: stageColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stage: ${lead.stage.label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: stageColor,
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_down,
                          size: 13, color: stageColor),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => ReminderHelper.openWhatsApp(
                  context,
                  phone: lead.phone,
                  message: msg,
                ),
                icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 14),
                label: const Text('WhatsApp'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => ReminderHelper.openTelegram(
                  context,
                  message: msg,
                ),
                icon: const Icon(CupertinoIcons.paperplane_fill, size: 14),
                label: const Text('Telegram'),
              ),
              if (lead.stage != LeadStage.enrolled)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.liveEmerald,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onConvert,
                  icon: const Icon(CupertinoIcons.person_add_solid, size: 14),
                  label: const Text('Convert to Student'),
                ),
              IconButton(
                tooltip: 'Edit Lead',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(CupertinoIcons.pencil, size: 16),
              ),
              IconButton(
                tooltip: 'Delete Lead',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  CupertinoIcons.trash,
                  size: 16,
                  color: AppColors.dangerRose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadFormDialog extends ConsumerStatefulWidget {
  const _LeadFormDialog({this.existing});

  final TrialLead? existing;

  @override
  ConsumerState<_LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends ConsumerState<_LeadFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;

  late CourseLanguage _language;
  late String _level;
  late LeadStage _stage;
  DateTime? _trialDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _language = e?.targetLanguage ?? CourseLanguage.chinese;
    _level = e?.preferredLevel ?? ProficiencyLevels.defaultFor(_language);
    _stage = e?.stage ?? LeadStage.newLead;
    _trialDate = e?.trialDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = ProficiencyLevels.forLanguage(_language);
    if (!levels.contains(_level)) _level = levels.first;

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
                Icon(
                  CupertinoIcons.person_badge_plus_fill,
                  color: _language.accentColor(context),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Add Trial Lead'
                        : 'Edit Trial Lead',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
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
                        hintText: 'e.g., Alina Pak',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please enter name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone / WhatsApp',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final lang in CourseLanguage.values)
                          LiquidGlassPillButton(
                            label: lang.label,
                            selected: _language == lang,
                            accentColor: lang.accentColor(context),
                            onTap: () => setState(() {
                              _language = lang;
                              _level = ProficiencyLevels.defaultFor(lang);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _level,
                            decoration: const InputDecoration(
                              labelText: 'Target Level',
                            ),
                            items: [
                              for (final lv in levels)
                                DropdownMenuItem(value: lv, child: Text(lv)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _level = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<LeadStage>(
                            initialValue: _stage,
                            decoration:
                                const InputDecoration(labelText: 'Stage'),
                            items: [
                              for (final s in LeadStage.values)
                                DropdownMenuItem(value: s, child: Text(s.label)),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _stage = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _trialDate ?? now,
                          firstDate: now.subtract(const Duration(days: 30)),
                          lastDate: now.add(const Duration(days: 180)),
                        );
                        if (picked != null && context.mounted) {
                          setState(() {
                            _trialDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              15,
                              0,
                            );
                          });
                        }
                      },
                      icon: const Icon(CupertinoIcons.calendar, size: 16),
                      label: Text(
                        _trialDate == null
                            ? 'Set Trial Date (Optional)'
                            : 'Trial: ${DateFormat('MMM d, yyyy').format(_trialDate!)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Preferred schedule, goals, referral source...',
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
                  label: widget.existing == null ? 'Save Lead' : 'Update Lead',
                  icon: CupertinoIcons.checkmark_alt,
                  color: _language.accentColor(context),
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setState(() => _saving = true);
                          final lead = TrialLead(
                            id: widget.existing?.id ?? const Uuid().v4(),
                            fullName: _nameCtrl.text.trim(),
                            phone: _phoneCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                            targetLanguage: _language,
                            preferredLevel: _level,
                            stage: _stage,
                            trialDate: _trialDate,
                            notes: _notesCtrl.text.trim(),
                            createdAt:
                                widget.existing?.createdAt ?? DateTime.now(),
                          );
                          final repo = ref.read(dataRepositoryProvider);
                          await repo.upsertTrialLead(lead);
                          final actor =
                              ref.read(authStateProvider).value?.email ??
                                  'staff';
                          await repo.logActivity(
                            ActivityLogEntry(
                              id: const Uuid().v4(),
                              actorEmail: actor,
                              category: 'Lead',
                              summary:
                                  '${widget.existing == null ? "Added" : "Updated"} trial lead ${lead.fullName} (${lead.stage.label})',
                              createdAt: DateTime.now(),
                            ),
                          );
                          if (context.mounted) Navigator.of(context).pop();
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
