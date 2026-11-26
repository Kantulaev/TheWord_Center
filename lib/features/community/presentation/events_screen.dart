import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/community_models.dart';
import '../../../core/models/operations_models.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firebase_extras_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/reminder_helper.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import 'audience_picker_section.dart';

enum _EventTimelineFilter { upcoming, history, all }

/// Staff Events & Event History workspace tab with date grouping, audience
/// access control, and 1-click event notifications.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  _EventTimelineFilter _timelineFilter = _EventTimelineFilter.upcoming;
  String? _tagFilter;
  String _searchQuery = '';

  Future<void> _sendOneClickNotification(CenterEvent event) async {
    final user = ref.read(authStateProvider).value;
    final repo = ref.read(dataRepositoryProvider);
    final rawName = (user?.displayName ?? '').trim();
    final senderName = rawName.isNotEmpty ? rawName : 'The Word Staff';

    final formattedDate = DateFormat('EEE, MMM d • HH:mm').format(event.eventDate);
    final notification = AppNotification(
      id: 'notif_evt_${const Uuid().v4()}',
      title: event.title,
      message: [
        if (event.description.isNotEmpty) event.description,
        'When: $formattedDate • Where: ${event.location}',
      ].join('\n'),
      category: event.tag.toLowerCase().contains('club')
          ? NotificationCategory.speakingClub
          : NotificationCategory.event,
      clubTopic: event.tag.toLowerCase().contains('club') ? event.description : '',
      scheduledAt: event.eventDate,
      audience: event.audience,
      targetGroupId: event.targetGroupId,
      targetGroupName: event.targetGroupName,
      targetEmails: event.targetEmails,
      targetUids: event.targetUids,
      createdByUid: user?.uid ?? '',
      createdByName: senderName,
      eventId: event.id,
      createdAt: DateTime.now(),
    );

    await repo.upsertNotification(notification);
    await repo.logActivity(
      ActivityLogEntry(
        id: 'act_${const Uuid().v4()}',
        actorEmail: user?.email ?? 'staff@theword.kg',
        category: 'Event Alert',
        summary: 'Sent notification for ${event.title} (${event.audience.label})',
        createdAt: DateTime.now(),
      ),
    );
    await FirebaseExtrasService.logEvent(
      'quick_event_notify',
      parameters: {'audience': event.audience.name, 'tag': event.tag},
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification sent for "${event.title}" (${event.audience.label})',
        ),
      ),
    );
  }

  Future<void> _deleteEvent(CenterEvent event) async {
    final ok = await showConfirmDeleteDialog(
      context,
      title: 'Delete Event',
      message: 'Remove "${event.title}" from Events & History?',
    );
    if (!ok || !mounted) return;
    await ref.read(dataRepositoryProvider).deleteEvent(event.id);
  }

  void _openEventForm([CenterEvent? existing]) {
    showDialog<void>(
      context: context,
      builder: (_) => EventFormDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEvents = ref.watch(eventsStreamProvider).value ?? const [];
    final now = DateTime.now();

    final upcomingCount = allEvents.where((e) => e.isUpcoming(now)).length;
    final historyCount = allEvents.where((e) => e.isPast(now)).length;

    final query = _searchQuery.trim().toLowerCase();
    final filtered = allEvents.where((e) {
      if (_timelineFilter == _EventTimelineFilter.upcoming && !e.isUpcoming(now)) {
        return false;
      }
      if (_timelineFilter == _EventTimelineFilter.history && !e.isPast(now)) {
        return false;
      }
      if (_tagFilter != null && e.tag != _tagFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchTitle = e.title.toLowerCase().contains(query);
        final matchDesc = e.description.toLowerCase().contains(query);
        final matchLoc = e.location.toLowerCase().contains(query);
        final matchTag = e.tag.toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchLoc && !matchTag) {
          return false;
        }
      }
      return true;
    }).toList();

    if (_timelineFilter == _EventTimelineFilter.upcoming) {
      filtered.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    } else {
      filtered.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    }

    // Group events cleanly by Month Year for chronological browsing
    final groupedByMonth = <String, List<CenterEvent>>{};
    for (final evt in filtered) {
      final monthKey = DateFormat('MMMM yyyy').format(evt.eventDate);
      groupedByMonth.putIfAbsent(monthKey, () => []).add(evt);
    }

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
                  'Events & Event History',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Schedule center workshops & Speaking Clubs by date, control audience visibility, and notify participants in 1 click.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final action = LiquidPrimaryButton(
              label: 'New Event',
              icon: CupertinoIcons.calendar_badge_plus,
              onPressed: () => _openEventForm(),
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Upcoming ($upcomingCount)'),
              selected: _timelineFilter == _EventTimelineFilter.upcoming,
              onSelected: (_) =>
                  setState(() => _timelineFilter = _EventTimelineFilter.upcoming),
            ),
            ChoiceChip(
              label: Text('History ($historyCount)'),
              selected: _timelineFilter == _EventTimelineFilter.history,
              onSelected: (_) =>
                  setState(() => _timelineFilter = _EventTimelineFilter.history),
            ),
            ChoiceChip(
              label: Text('All (${allEvents.length})'),
              selected: _timelineFilter == _EventTimelineFilter.all,
              onSelected: (_) =>
                  setState(() => _timelineFilter = _EventTimelineFilter.all),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final searchField = TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                hintText: 'Search events, clubs, locations...',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            );
            final tagChips = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Tags'),
                    selected: _tagFilter == null,
                    onSelected: (_) => setState(() => _tagFilter = null),
                  ),
                  const SizedBox(width: 6),
                  for (final tag in CenterEvent.suggestedTags) ...[
                    ChoiceChip(
                      label: Text(tag),
                      selected: _tagFilter == tag,
                      onSelected: (_) => setState(
                        () => _tagFilter = _tagFilter == tag ? null : tag,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [searchField, const SizedBox(height: 10), tagChips],
              );
            }
            return Row(
              children: [
                SizedBox(width: 280, child: searchField),
                const SizedBox(width: 14),
                Expanded(child: tagChips),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          LiquidGlassContainer(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 40,
                  color: AppColors.textMuted(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'No events match the selected filter',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new club meetup, HSK exam, or cultural day to populate the timeline.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          for (final entry in groupedByMonth.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppColors.englishAccent(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            for (final evt in entry.value) ...[
              _EventCard(
                event: evt,
                isUpcoming: evt.isUpcoming(now),
                onNotify: () => _sendOneClickNotification(evt),
                onEdit: () => _openEventForm(evt),
                onDelete: () => _deleteEvent(evt),
              ),
              const SizedBox(height: 12),
            ],
          ],
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isUpcoming,
    required this.onNotify,
    required this.onEdit,
    required this.onDelete,
  });

  final CenterEvent event;
  final bool isUpcoming;
  final VoidCallback onNotify;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = isUpcoming
        ? AppColors.englishAccent(context)
        : AppColors.completedSlate;
    final dayLabel = DateFormat('d').format(event.eventDate);
    final monthLabel = DateFormat('MMM').format(event.eventDate).toUpperCase();
    final timeLabel = DateFormat('EEE, HH:mm').format(event.eventDate);
    final visibilityLabel = event.audience == AudienceType.specificGroup &&
            event.targetGroupName.isNotEmpty
        ? 'Group: ${event.targetGroupName}'
        : event.audience.label;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.32)),
                ),
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary(context),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SmallBadge(
                          label: isUpcoming ? 'Upcoming' : 'Past Event',
                          color: isUpcoming
                              ? AppColors.liveEmerald
                              : AppColors.completedSlate,
                        ),
                        _SmallBadge(
                          label: event.tag,
                          color: AppColors.sharingAccent(context),
                        ),
                        _SmallBadge(
                          label: visibilityLabel,
                          color: event.audience == AudienceType.teachersOnly
                              ? AppColors.warningAmber
                              : AppColors.englishAccent(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.location,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onNotify,
                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                label: const Text('Send Event Notification'),
              ),
              if (event.linkOrImageUrl.trim().startsWith('http'))
                OutlinedButton.icon(
                  onPressed: () => ReminderHelper.openExternalUrl(
                    context,
                    event.linkOrImageUrl.trim(),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open Link'),
                ),
              IconButton(
                tooltip: 'Edit Event',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'Delete Event',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class EventFormDialog extends ConsumerStatefulWidget {
  const EventFormDialog({super.key, this.existing});

  final CenterEvent? existing;

  @override
  ConsumerState<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<EventFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _linkController;

  late DateTime _eventDate;
  late String _tag;
  late AudienceType _audience;
  String _targetGroupId = '';
  String _targetGroupName = '';
  List<String> _targetEmails = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleController = TextEditingController(text: ex?.title ?? '');
    _descController = TextEditingController(text: ex?.description ?? '');
    _locationController =
        TextEditingController(text: ex?.location ?? 'Main Hall');
    _linkController = TextEditingController(text: ex?.linkOrImageUrl ?? '');
    _eventDate = ex?.eventDate ??
        DateTime.now().add(const Duration(days: 2)).copyWith(minute: 0);
    _tag = ex?.tag ?? CenterEvent.suggestedTags.first;
    _audience = ex?.audience ?? AudienceType.all;
    _targetGroupId = ex?.targetGroupId ?? '';
    _targetGroupName = ex?.targetGroupName ?? '';
    _targetEmails = ex?.targetEmails ?? const [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventDate),
    );
    if (!mounted) return;
    final pickedTime = time ?? TimeOfDay.fromDateTime(_eventDate);
    setState(() {
      _eventDate = DateTime(
        date.year,
        date.month,
        date.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event title is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    final user = ref.read(authStateProvider).value;
    final repo = ref.read(dataRepositoryProvider);
    final rawName = (user?.displayName ?? '').trim();
    final author = rawName.isNotEmpty ? rawName : 'The Word Staff';

    final event = CenterEvent(
      id: widget.existing?.id ?? 'evt_${const Uuid().v4()}',
      title: title,
      description: _descController.text.trim(),
      eventDate: _eventDate,
      location: _locationController.text.trim().isEmpty
          ? 'Main Hall'
          : _locationController.text.trim(),
      tag: _tag,
      linkOrImageUrl: _linkController.text.trim(),
      createdByUid: widget.existing?.createdByUid ?? (user?.uid ?? ''),
      createdByName: widget.existing?.createdByName ?? author,
      audience: _audience,
      targetGroupId: _targetGroupId,
      targetGroupName: _targetGroupName,
      targetEmails: _targetEmails,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await repo.upsertEvent(event);
    await repo.logActivity(
      ActivityLogEntry(
        id: 'act_${const Uuid().v4()}',
        actorEmail: user?.email ?? 'staff@theword.kg',
        category: 'Events',
        summary:
            '${widget.existing == null ? 'Created' : 'Updated'} event ${event.title} (${event.audience.label})',
        createdAt: DateTime.now(),
      ),
    );
    await FirebaseExtrasService.logEvent(
      'create_event',
      parameters: {'tag': _tag, 'audience': _audience.name},
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsStreamProvider).value ?? const [];
    final teachers = ref.watch(teachersStreamProvider).value ?? const [];
    final students = ref.watch(studentsStreamProvider).value ?? const [];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'Create Event' : 'Edit Event',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Event Title *',
                          hintText: 'e.g. Saturday Cultural Tea & Speaking Club',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description / Topic',
                          hintText: 'What will participants learn or do?',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickDateTime,
                            icon: const Icon(Icons.event_rounded, size: 16),
                            label: Text(
                              DateFormat('EEE, MMM d, yyyy • HH:mm')
                                  .format(_eventDate),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location / Classroom',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Event Tag',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in CenterEvent.suggestedTags)
                            ChoiceChip(
                              label: Text(t),
                              selected: _tag == t,
                              onSelected: (_) => setState(() => _tag = t),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          labelText: 'Photo / Poster Link (Optional)',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                      ),
                      const Divider(height: 24),
                      AudiencePickerSection(
                        audience: _audience,
                        targetGroupId: _targetGroupId,
                        targetEmails: _targetEmails,
                        groups: groups,
                        teachers: teachers,
                        students: students,
                        onChanged: ({
                          required audience,
                          required targetGroupId,
                          required targetGroupName,
                          required targetEmails,
                        }) {
                          setState(() {
                            _audience = audience;
                            _targetGroupId = targetGroupId;
                            _targetGroupName = targetGroupName;
                            _targetEmails = targetEmails;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  LiquidPrimaryButton(
                    label: _saving ? 'Saving...' : 'Save Event',
                    icon: Icons.check_rounded,
                    onPressed: _saving ? () {} : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
