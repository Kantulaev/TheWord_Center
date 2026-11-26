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
import '../../../shared/widgets/liquid_glass_container.dart';
import 'audience_picker_section.dart';

/// UI strings for the Notification Inbox so Staff (English) and 6-language
/// Student Portal both render natively.
@immutable
class NotificationsInboxLabels {
  const NotificationsInboxLabels({
    this.title = 'Notifications Center',
    this.emptyTitle = 'No notifications yet',
    this.emptySubtitle = 'Speaking club alerts and announcements appear here.',
    this.markAllRead = 'Mark all read',
    this.enablePush = 'Enable Push',
    this.pushEnabled = 'Push Active',
    this.clubTopicPrefix = 'Topic',
    this.unreadLabel = 'unread',
    this.composeLabel = 'Send Alert',
  });

  final String title;
  final String emptyTitle;
  final String emptySubtitle;
  final String markAllRead;
  final String enablePush;
  final String pushEnabled;
  final String clubTopicPrefix;
  final String unreadLabel;
  final String composeLabel;
}

/// Top-bar bell icon with real-time unread red badge counter.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({
    super.key,
    this.labels = const NotificationsInboxLabels(),
    this.tooltip = 'Notifications',
    this.compact = false,
  });

  final NotificationsInboxLabels labels;
  final String tooltip;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: const ValueKey('notification_bell_button'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => showNotificationsCenterDialog(
          context,
          labels: labels,
        ),
        child: Padding(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                unread > 0
                    ? CupertinoIcons.bell_fill
                    : CupertinoIcons.bell,
                size: 22,
                color: unread > 0
                    ? AppColors.chineseAccent(context)
                    : AppColors.textPrimary(context),
              ),
              if (unread > 0)
                Positioned(
                  right: -6,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerRose,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
}

/// Opens the Notifications Inbox drawer/dialog.
Future<void> showNotificationsCenterDialog(
  BuildContext context, {
  NotificationsInboxLabels labels = const NotificationsInboxLabels(),
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => NotificationsInboxDialog(labels: labels),
  );
}

/// Opens the Staff Compose Notification dialog (supports quick Speaking Club
/// templates and 1-click prefill from an existing [CenterEvent]).
Future<void> showComposeNotificationDialog(
  BuildContext context, {
  CenterEvent? prefillEvent,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ComposeNotificationDialog(prefillEvent: prefillEvent),
  );
}

class NotificationsInboxDialog extends ConsumerStatefulWidget {
  const NotificationsInboxDialog({
    super.key,
    this.labels = const NotificationsInboxLabels(),
  });

  final NotificationsInboxLabels labels;

  @override
  ConsumerState<NotificationsInboxDialog> createState() =>
      _NotificationsInboxDialogState();
}

class _NotificationsInboxDialogState
    extends ConsumerState<NotificationsInboxDialog> {
  String _pushStatus = '';
  bool _checkingPush = false;
  bool _pushGranted = false;

  @override
  void initState() {
    super.initState();
    _syncPush(requestPermission: false);
  }

  Future<void> _syncPush({required bool requestPermission}) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() => _checkingPush = true);
    final res = await FirebaseExtrasService.syncMessagingPermissionAndToken(
      user: user,
      repository: ref.read(dataRepositoryProvider),
      requestPermission: requestPermission,
    );
    if (!mounted) return;
    setState(() {
      _checkingPush = false;
      _pushGranted = res.permissionGranted;
      _pushStatus = res.statusText;
    });
  }

  Color _categoryColor(BuildContext context, NotificationCategory category) =>
      switch (category) {
        NotificationCategory.speakingClub => AppColors.sharingAccent(context),
        NotificationCategory.announcement => AppColors.englishAccent(context),
        NotificationCategory.event => AppColors.liveEmerald,
        NotificationCategory.reminder => AppColors.warningAmber,
      };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final items = ref.watch(notificationsStreamProvider).value ?? const [];
    final uid = user?.uid ?? '';
    final isStaff = user?.isStaff ?? false;
    final unreadIds =
        items.where((n) => !n.isReadBy(uid)).map((n) => n.id).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.englishAccent(context)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      CupertinoIcons.bell_fill,
                      color: AppColors.englishAccent(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.labels.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (unreadIds.isNotEmpty)
                          Text(
                            '${unreadIds.length} ${widget.labels.unreadLabel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.chineseAccent(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isStaff)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: LiquidPrimaryButton(
                        label: widget.labels.composeLabel,
                        icon: Icons.send_rounded,
                        onPressed: () {
                          showComposeNotificationDialog(context);
                        },
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _checkingPush
                        ? null
                        : () => _syncPush(requestPermission: true),
                    icon: Icon(
                      _pushGranted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 16,
                      color: _pushGranted
                          ? AppColors.liveEmerald
                          : AppColors.englishAccent(context),
                    ),
                    label: Text(
                      _pushGranted
                          ? widget.labels.pushEnabled
                          : widget.labels.enablePush,
                    ),
                  ),
                  if (unreadIds.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => ref
                          .read(dataRepositoryProvider)
                          .markAllNotificationsRead(
                            notificationIds: unreadIds,
                            uid: uid,
                          ),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text(widget.labels.markAllRead),
                    ),
                  if (_pushStatus.isNotEmpty)
                    Text(
                      _pushStatus,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.bell_slash,
                              size: 42,
                              color: AppColors.textMuted(context),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.labels.emptyTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.labels.emptySubtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = items[index];
                          final unread = !n.isReadBy(uid);
                          final color = _categoryColor(context, n.category);
                          final audienceTag =
                              n.audience == AudienceType.specificGroup &&
                                      n.targetGroupName.isNotEmpty
                                  ? n.targetGroupName
                                  : n.audience.shortLabel;

                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: unread && uid.isNotEmpty
                                ? () => ref
                                    .read(dataRepositoryProvider)
                                    .markNotificationRead(
                                      notificationId: n.id,
                                      uid: uid,
                                    )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: unread
                                    ? color.withValues(alpha: isDark ? 0.14 : 0.08)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.04)
                                        : Colors.black.withValues(alpha: 0.025)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: unread
                                      ? color.withValues(alpha: 0.4)
                                      : AppColors.textMuted(context)
                                          .withValues(alpha: 0.18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(n.category.icon, size: 16, color: color),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          n.category.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.textMuted(context)
                                              .withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          audienceTag,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (unread)
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerRose,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (isStaff)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          tooltip: 'Delete notification',
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () => ref
                                              .read(dataRepositoryProvider)
                                              .deleteNotification(n.id),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    n.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (n.clubTopic.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.chineseAccent(context)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.topic_rounded,
                                            size: 14,
                                            color: AppColors.chineseAccent(context),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              '${widget.labels.clubTopicPrefix}: ${n.clubTopic}',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.chineseAccent(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (n.message.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      n.message,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      if (n.scheduledAt != null)
                                        Text(
                                          DateFormat('EEE, MMM d • HH:mm')
                                              .format(n.scheduledAt!),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.englishAccent(context),
                                          ),
                                        ),
                                      Text(
                                        '${n.createdByName} • ${DateFormat('MMM d, HH:mm').format(n.createdAt)}',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComposeNotificationDialog extends ConsumerStatefulWidget {
  const ComposeNotificationDialog({
    super.key,
    this.prefillEvent,
  });

  final CenterEvent? prefillEvent;

  @override
  ConsumerState<ComposeNotificationDialog> createState() =>
      _ComposeNotificationDialogState();
}

class _ComposeNotificationDialogState
    extends ConsumerState<ComposeNotificationDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _topicController = TextEditingController();

  late NotificationCategory _category;
  SpeakingClubPreset? _clubPreset;
  DateTime? _scheduledAt;
  late AudienceType _audience;
  String _targetGroupId = '';
  String _targetGroupName = '';
  List<String> _targetEmails = const [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final event = widget.prefillEvent;
    if (event != null) {
      _category = event.tag.toLowerCase().contains('club')
          ? NotificationCategory.speakingClub
          : NotificationCategory.event;
      _titleController.text = event.title;
      _messageController.text =
          '${event.description}\nWhere: ${event.location}'.trim();
      _scheduledAt = event.eventDate;
      _audience = event.audience;
      _targetGroupId = event.targetGroupId;
      _targetGroupName = event.targetGroupName;
      _targetEmails = event.targetEmails;
    } else {
      _category = NotificationCategory.speakingClub;
      _audience = AudienceType.all;
      _applyClubPreset(SpeakingClubPreset.chineseClub);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _applyClubPreset(SpeakingClubPreset preset) {
    final now = DateTime.now();
    final satOffset = (DateTime.saturday - now.weekday + 7) % 7;
    final nextSat = DateTime(now.year, now.month, now.day).add(
      Duration(days: satOffset == 0 ? 7 : satOffset),
    );
    final hour = switch (preset) {
      SpeakingClubPreset.kidsClub => 13,
      SpeakingClubPreset.chineseClub => 15,
      SpeakingClubPreset.englishClub => 17,
    };

    setState(() {
      _category = NotificationCategory.speakingClub;
      _clubPreset = preset;
      _titleController.text = '${preset.defaultTitle} Coming Soon!';
      _topicController.text = preset.defaultTopic;
      _scheduledAt = DateTime(nextSat.year, nextSat.month, nextSat.day, hour, 0);
      _messageController.text =
          'Join us in ${preset.defaultLocation}! Come ready to speak and practice together.';
    });
  }

  Future<void> _pickScheduleDateTime() async {
    final initial = _scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    final time = pickedTime ?? TimeOfDay.fromDateTime(initial);
    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a notification title.')),
      );
      return;
    }

    setState(() => _sending = true);
    final user = ref.read(authStateProvider).value;
    final repo = ref.read(dataRepositoryProvider);
    final rawName = (user?.displayName ?? '').trim();
    final senderName = rawName.isNotEmpty ? rawName : 'The Word Staff';

    final notification = AppNotification(
      id: 'notif_${const Uuid().v4()}',
      title: title,
      message: message,
      category: _category,
      clubPreset: _clubPreset,
      clubTopic: _topicController.text.trim(),
      scheduledAt: _scheduledAt,
      audience: _audience,
      targetGroupId: _targetGroupId,
      targetGroupName: _targetGroupName,
      targetEmails: _targetEmails,
      createdByUid: user?.uid ?? '',
      createdByName: senderName,
      eventId: widget.prefillEvent?.id ?? '',
      createdAt: DateTime.now(),
    );

    await repo.upsertNotification(notification);
    await repo.logActivity(
      ActivityLogEntry(
        id: 'act_${const Uuid().v4()}',
        actorEmail: user?.email ?? 'staff@theword.kg',
        category: 'Notifications',
        summary: 'Sent "${notification.title}" (${_audience.label})',
        createdAt: DateTime.now(),
      ),
    );
    await FirebaseExtrasService.logEvent(
      'send_notification',
      parameters: {
        'category': _category.name,
        'audience': _audience.name,
      },
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent to ${_audience.label}'),
      ),
    );
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
                      'Send Notification / Club Alert',
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
                      Text(
                        'Notification Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final cat in NotificationCategory.values)
                            ChoiceChip(
                              avatar: Icon(cat.icon, size: 16),
                              label: Text(cat.label),
                              selected: _category == cat,
                              onSelected: (_) => setState(() => _category = cat),
                            ),
                        ],
                      ),
                      if (_category == NotificationCategory.speakingClub) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Quick Speaking Club Templates',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final preset in SpeakingClubPreset.values)
                              ActionChip(
                                avatar: Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: _clubPreset == preset
                                      ? AppColors.chineseAccent(context)
                                      : null,
                                ),
                                label: Text(preset.label),
                                onPressed: () => _applyClubPreset(preset),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g. Chinese Speaking Club This Saturday!',
                        ),
                      ),
                      if (_category == NotificationCategory.speakingClub ||
                          _topicController.text.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            labelText: 'Club Topic (Тема клуба)',
                            hintText: 'e.g. Street Food & Tea Culture',
                            prefixIcon: Icon(Icons.topic_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _messageController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText:
                              'Details, classroom, or preparation instructions...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickScheduleDateTime,
                            icon: const Icon(Icons.schedule_rounded, size: 16),
                            label: Text(
                              _scheduledAt == null
                                  ? 'Set Date & Time (Optional)'
                                  : DateFormat('EEE, MMM d • HH:mm')
                                      .format(_scheduledAt!),
                            ),
                          ),
                          if (_scheduledAt != null)
                            IconButton(
                              tooltip: 'Clear date',
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _scheduledAt = null),
                            ),
                        ],
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
                    onPressed: _sending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  LiquidPrimaryButton(
                    label: _sending ? 'Sending...' : 'Send Notification',
                    icon: Icons.send_rounded,
                    onPressed: _sending ? () {} : _send,
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
