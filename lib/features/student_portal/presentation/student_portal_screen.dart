import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/center_info.dart';
import '../../../core/models/homework.dart';
import '../../../core/models/language_type.dart';
import '../../../core/models/operations_models.dart';
import '../../../core/models/student.dart';
import '../../../core/models/study_group.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_background.dart';
import '../../../core/utils/reminder_helper.dart';
import '../../../shared/widgets/appearance_settings_dialog.dart';
import '../../../shared/widgets/center_action_buttons.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../l10n/student_portal_strings.dart';

/// Self-service localized Student Portal accessible via Google Sign-In.
/// Supports English, Russian, Kyrgyz, Kazakh, Uzbek, and Chinese, plus
/// font scaling, theme selection, 2GIS route & direct WhatsApp/phone contact.
class StudentPortalScreen extends ConsumerWidget {
  const StudentPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profileAsync = ref.watch(studentPortalProfileProvider);
    final groupsAsync = ref.watch(publicGroupsStreamProvider);
    final homeworksAsync = ref.watch(studentHomeworksProvider);
    final mySubsList = ref.watch(myHomeworkSubmissionsProvider).value ?? const [];
    final teachers = ref.watch(publicTeachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final matchedStudent = ref.watch(myStudentRecordProvider).value;
    final myRequests = ref.watch(myRescheduleRequestsProvider).value ?? const [];
    final animateBg = ref.watch(enableAmbientAnimationsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final locale = ref.watch(portalLocaleProvider);
    final l10n = StudentPortalL10n(locale);

    final profile = profileAsync.value ??
        StudentPortalProfile(
          uid: user?.uid ?? '',
          email: user?.email ?? '',
          fullName: user?.displayName ?? 'Student',
        );

    final selectedIds = profile.selectedGroupIds.toSet();
    final allGroups = (groupsAsync.value ?? const <StudyGroup>[])
        .where((g) => g.language != CourseLanguage.sharing)
        .toList(growable: false);
    final allHomeworks = homeworksAsync.value ?? const <HomeworkAssignment>[];
    final mySubsByHwId = {
      for (final s in mySubsList)
        if (s.homeworkId.isNotEmpty) s.homeworkId: s,
    };

    final myHomeworks = allHomeworks
        .where((h) => selectedIds.contains(h.groupId))
        .toList(growable: false);

    return LiquidAuroraBackground(
      animate: animateBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                children: [
                  // Top Bar
                  LiquidGlassContainer(
                    borderRadius: 24,
                    blurSigma: 22,
                    elevation: 0.85,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.chineseCrimson,
                                    AppColors.englishSapphire,
                                  ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'W',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.text('portalTitle'),
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    '${profile.fullName} (${profile.email})',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PopupMenuButton<PortalLocale>(
                              tooltip: l10n.text('languageLabel'),
                              onSelected: (loc) => ref
                                  .read(portalLocaleProvider.notifier)
                                  .setLocale(loc),
                              itemBuilder: (_) => [
                                for (final loc in PortalLocale.values)
                                  PopupMenuItem(
                                    value: loc,
                                    child: Row(
                                      children: [
                                        Text(
                                          loc.shortTag,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(loc.nativeName)),
                                        if (loc == locale)
                                          const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColors.englishAccent(context)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.globe,
                                      size: 15,
                                      color: AppColors.englishAccent(context),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      locale.shortTag,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.englishAccent(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.text('settings'),
                              onPressed: () => showAppearanceSettingsModal(
                                context,
                                showLanguagePicker: true,
                              ),
                              icon: const Icon(CupertinoIcons.textformat_size),
                            ),
                            IconButton(
                              tooltip: l10n.text('themeLabel'),
                              onPressed: () =>
                                  ref.read(themeModeProvider.notifier).toggle(),
                              icon: Icon(
                                isDark
                                    ? CupertinoIcons.moon_stars_fill
                                    : CupertinoIcons.sun_max_fill,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.read(authRepositoryProvider).signOut(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.dangerRose,
                              ),
                              icon: const Icon(
                                CupertinoIcons.square_arrow_right,
                                size: 17,
                              ),
                              label: Text(l10n.text('signOut')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (matchedStudent != null) ...[
                    _StudentProgressCard(
                      student: matchedStudent,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Official Center Contacts, Call, WhatsApp & 2GIS Directions
                  LiquidGlassContainer(
                    borderRadius: 22,
                    blurSigma: 18,
                    elevation: 0.5,
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${CenterInfo.centerName} • ${CenterInfo.instagramHandle}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${CenterInfo.address} (${l10n.text('landmarks')})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.text('hoursSummary'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const PhoneCallBadgeButton(
                              phoneDisplay: CenterInfo.primaryPhone,
                              phoneTel: CenterInfo.primaryPhoneTel,
                            ),
                            const PhoneCallBadgeButton(
                              phoneDisplay: CenterInfo.secondaryPhone,
                              phoneTel: CenterInfo.secondaryPhoneTel,
                            ),
                            WhatsAppBadgeButton(
                              label: l10n.text('whatsapp'),
                              onPressed: () => ReminderHelper.openWhatsApp(
                                context,
                                phone: CenterInfo.whatsappPhone,
                                message:
                                    'Hello The Word Center! I am ${profile.fullName} (${profile.email}).',
                              ),
                            ),
                            TwoGisRouteButton(
                              label: l10n.text('twoGisRoute'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 1: Choose Your HSK / English Group
                  Text(
                    l10n.text('step1Title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.text('step1Subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  if (groupsAsync.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (allGroups.isEmpty)
                    LiquidGlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(20),
                      child: Text(l10n.text('noGroups')),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final cols = w >= 720 ? 2 : 1;
                        const gap = 12.0;
                        final itemWidth = (w - gap * (cols - 1)) / cols;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final g in allGroups)
                              SizedBox(
                                width: cols == 1 ? w : itemWidth,
                                child: _StudentGroupSelectCard(
                                  group: g,
                                  l10n: l10n,
                                  isJoined: selectedIds.contains(g.id),
                                  teacherName:
                                      teachers[g.teacherId]?.fullName ??
                                          l10n.text('teacher'),
                                  roomName:
                                      classrooms[g.classroomId]?.name ??
                                          l10n.text('room'),
                                  onToggle: () async {
                                    final nextIds = {...selectedIds};
                                    if (nextIds.contains(g.id)) {
                                      nextIds.remove(g.id);
                                    } else {
                                      nextIds.add(g.id);
                                    }
                                    await ref
                                        .read(dataRepositoryProvider)
                                        .saveStudentPortalProfile(
                                          profile.copyWith(
                                            selectedGroupIds: nextIds.toList(),
                                          ),
                                        );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Step 2: Homework Inbox
                  Text(
                    l10n.text('step2Title', {'n': '${myHomeworks.length}'}),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.text('step2Subtitle'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  if (selectedIds.isEmpty)
                    LiquidGlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.text('selectGroupHint'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else if (myHomeworks.isEmpty)
                    LiquidGlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.text('noHomeworkHint'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final hw in myHomeworks) ...[
                          _StudentHomeworkCard(
                            homework: hw,
                            l10n: l10n,
                            group: allGroups.cast<StudyGroup?>().firstWhere(
                                  (g) => g?.id == hw.groupId,
                                  orElse: () => null,
                                ),
                            teacherName: teachers[hw.teacherId]?.fullName ??
                                l10n.text('teacher'),
                            isDone: hw.isCompletedBy(profile.uid),
                            submission:
                                mySubsByHwId[hw.id] ?? hw.submissionFor(profile.uid),
                            onToggleDone: (done) async {
                              await ref
                                  .read(dataRepositoryProvider)
                                  .toggleHomeworkCompletion(
                                    homeworkId: hw.id,
                                    uid: profile.uid,
                                    completed: done,
                                  );
                            },
                            onSubmitWork: () => _showSubmitHomeworkDialog(
                              context,
                              ref,
                              l10n: l10n,
                              homework: hw,
                              existing: mySubsByHwId[hw.id] ??
                                  hw.submissionFor(profile.uid),
                              profile: profile,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Step 3: Schedule Reschedule Requests
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.text(
                                'step3Title',
                                {'n': '${myRequests.length}'},
                              ),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.text('step3Subtitle'),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      LiquidPrimaryButton(
                        label: l10n.text('requestChange'),
                        icon: CupertinoIcons.calendar_badge_plus,
                        onPressed: () => _showRescheduleDialog(
                          context,
                          ref,
                          l10n: l10n,
                          profile: profile,
                          groups: allGroups,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (myRequests.isEmpty)
                    LiquidGlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(20),
                      child: Text(l10n.text('noRequests')),
                    )
                  else
                    for (final req in myRequests) ...[
                      LiquidGlassContainer(
                        borderRadius: 20,
                        blurSigma: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${req.groupName} • ${DateFormat('EEE, MMM d').format(req.requestedDate)} (${req.preferredSlot})',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                StatusBadge(
                                  label: switch (req.status) {
                                    RequestStatus.pending =>
                                      l10n.text('statusPending'),
                                    RequestStatus.approved =>
                                      l10n.text('statusApproved'),
                                    RequestStatus.declined =>
                                      l10n.text('statusDeclined'),
                                  },
                                  color: switch (req.status) {
                                    RequestStatus.pending =>
                                      AppColors.warningAmber,
                                    RequestStatus.approved =>
                                      AppColors.liveEmerald,
                                    RequestStatus.declined =>
                                      AppColors.dangerRose,
                                  },
                                  compact: true,
                                ),
                              ],
                            ),
                            if (req.reason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                req.reason,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (req.staffNote.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                l10n.text(
                                  'centerReply',
                                  {'text': req.staffNote},
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.englishAccent(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSubmitHomeworkDialog(
    BuildContext context,
    WidgetRef ref, {
    required StudentPortalL10n l10n,
    required HomeworkAssignment homework,
    required HomeworkSubmission? existing,
    required StudentPortalProfile profile,
  }) async {
    final answerCtrl = TextEditingController(text: existing?.answerOrLink ?? '');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.text('submitDialogTitle', {'title': homework.title})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.text('submitDialogDesc')),
            const SizedBox(height: 12),
            TextField(
              controller: answerCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.text('answerOrLinkLabel'),
                hintText: l10n.text('answerOrLinkHint'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.text('submitToTeacher')),
          ),
        ],
      ),
    );
    final text = answerCtrl.text.trim();
    answerCtrl.dispose();
    if (submitted != true || text.isEmpty) return;

    await ref.read(dataRepositoryProvider).submitHomeworkResponse(
          homeworkId: homework.id,
          submission: HomeworkSubmission(
            homeworkId: homework.id,
            studentUid: profile.uid,
            studentName: profile.fullName,
            studentEmail: profile.email,
            answerOrLink: text,
            submittedAt: DateTime.now(),
            teacherFeedback: existing?.teacherFeedback ?? '',
            reviewed: false,
          ),
        );
  }

  Future<void> _showRescheduleDialog(
    BuildContext context,
    WidgetRef ref, {
    required StudentPortalL10n l10n,
    required StudentPortalProfile profile,
    required List<StudyGroup> groups,
  }) async {
    final joinedGroups = groups
        .where((g) => profile.selectedGroupIds.contains(g.id))
        .toList();
    final candidateGroups = joinedGroups.isNotEmpty ? joinedGroups : groups;
    if (candidateGroups.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.text('selectGroupFirst'))),
      );
      return;
    }

    var selectedGroup = candidateGroups.first;
    var requestedDate = DateTime.now().add(const Duration(days: 1));
    final slotCtrl = TextEditingController(text: '16:00');
    final reasonCtrl = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: Text(l10n.text('requestDialogTitle')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<StudyGroup>(
                  initialValue: selectedGroup,
                  decoration: InputDecoration(
                    labelText: l10n.text('studyGroupLabel'),
                  ),
                  items: [
                    for (final g in candidateGroups)
                      DropdownMenuItem(value: g, child: Text(g.name)),
                  ],
                  onChanged: (g) {
                    if (g != null) setState(() => selectedGroup = g);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: dialogCtx,
                      initialDate: requestedDate,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 90)),
                    );
                    if (picked != null && dialogCtx.mounted) {
                      setState(() => requestedDate = picked);
                    }
                  },
                  icon: const Icon(CupertinoIcons.calendar, size: 16),
                  label: Text(
                    l10n.text(
                      'preferredDate',
                      {'date': DateFormat('EEE, MMM d').format(requestedDate)},
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slotCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.text('preferredSlotLabel'),
                    hintText: l10n.text('preferredSlotHint'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.text('reasonLabel'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(l10n.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(l10n.text('sendRequest')),
            ),
          ],
        ),
      ),
    );
    final slot = slotCtrl.text.trim();
    final reason = reasonCtrl.text.trim();
    slotCtrl.dispose();
    reasonCtrl.dispose();
    if (sent != true || slot.isEmpty) return;

    await ref.read(dataRepositoryProvider).submitRescheduleRequest(
          RescheduleRequest(
            id: const Uuid().v4(),
            studentUid: profile.uid,
            studentName: profile.fullName,
            studentEmail: profile.email,
            groupId: selectedGroup.id,
            groupName: selectedGroup.name,
            requestedDate: requestedDate,
            preferredSlot: slot,
            reason: reason,
            createdAt: DateTime.now(),
          ),
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.text('requestSent'))),
    );
  }
}

class _StudentGroupSelectCard extends StatelessWidget {
  const _StudentGroupSelectCard({
    required this.group,
    required this.l10n,
    required this.isJoined,
    required this.teacherName,
    required this.roomName,
    required this.onToggle,
  });

  final StudyGroup group;
  final StudentPortalL10n l10n;
  final bool isJoined;
  final String teacherName;
  final String roomName;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = group.language.accentColor(context);

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 18,
      elevation: isJoined ? 0.9 : 0.45,
      tintColor: isJoined ? AppColors.liveEmerald : accent,
      tintStrength: isJoined ? 0.11 : 0.05,
      isSelected: isJoined,
      padding: const EdgeInsets.all(16),
      onTap: onToggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassInfoTag(
                label: l10n.languageName(group.language.name),
                color: accent,
              ),
              const SizedBox(width: 8),
              GlassInfoTag(label: group.level),
              const Spacer(),
              LiquidGlassPillButton(
                label: isJoined ? l10n.text('joined') : l10n.text('joinGroup'),
                selected: isJoined,
                accentColor: isJoined ? AppColors.liveEmerald : accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                onTap: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            group.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.formatSchedule(group)} • ${l10n.text('room')} $roomName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${l10n.text('teacher')}: $teacherName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StudentProgressCard extends StatelessWidget {
  const _StudentProgressCard({
    required this.student,
    required this.l10n,
  });

  final Student student;
  final StudentPortalL10n l10n;

  @override
  Widget build(BuildContext context) {
    final accent = student.targetLanguage.accentColor(context);
    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 20,
      tintColor: student.readyForNextLevel ? AppColors.liveEmerald : accent,
      tintStrength: 0.08,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LanguageBadge(language: student.targetLanguage, compact: true),
              GlassInfoTag(label: student.proficiencyLevel),
              StatusBadge(
                label: l10n.text(
                  'creditsLeft',
                  {'n': '${student.remainingCredits}'},
                ),
                color: student.remainingCredits <= 2
                    ? AppColors.warningAmber
                    : AppColors.liveEmerald,
                compact: true,
              ),
              if (student.readyForNextLevel)
                StatusBadge(
                  label: l10n.text('readyForNextLevel'),
                  color: AppColors.liveEmerald,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.text(
                    'masteryProgress',
                    {'level': student.proficiencyLevel},
                  ),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${student.levelProgressPercent}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (student.levelProgressPercent.clamp(0, 100)) / 100.0,
              minHeight: 8,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(
                student.readyForNextLevel ? AppColors.liveEmerald : accent,
              ),
            ),
          ),
          if (student.completedTopics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in student.completedTopics)
                  GlassInfoTag(
                    label: '✓ $t',
                    color: AppColors.liveEmerald,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentHomeworkCard extends StatelessWidget {
  const _StudentHomeworkCard({
    required this.homework,
    required this.l10n,
    required this.group,
    required this.teacherName,
    required this.isDone,
    required this.submission,
    required this.onToggleDone,
    required this.onSubmitWork,
  });

  final HomeworkAssignment homework;
  final StudentPortalL10n l10n;
  final StudyGroup? group;
  final String teacherName;
  final bool isDone;
  final HomeworkSubmission? submission;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onSubmitWork;

  @override
  Widget build(BuildContext context) {
    final accent = group?.language.accentColor(context) ??
        AppColors.englishAccent(context);

    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 18,
      elevation: 0.6,
      tintColor: isDone ? AppColors.liveEmerald : accent,
      tintStrength: isDone ? 0.09 : 0.05,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isDone,
            onChanged: (v) => onToggleDone(v ?? false),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (group != null) GlassInfoTag(label: group!.name),
                    StatusBadge(
                      label: l10n.text(
                        'due',
                        {'date': DateFormat('MMM d').format(homework.dueDate)},
                      ),
                      color: isDone ? AppColors.liveEmerald : accent,
                      compact: true,
                    ),
                    if (isDone)
                      StatusBadge(
                        label: l10n.text('completed'),
                        color: AppColors.liveEmerald,
                        compact: true,
                      ),
                    if (submission != null)
                      StatusBadge(
                        label: submission!.reviewed
                            ? l10n.text('teacherReviewed')
                            : l10n.text('submitted'),
                        color: submission!.reviewed
                            ? AppColors.liveEmerald
                            : AppColors.englishAccent(context),
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  homework.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  homework.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.text('assignedBy', {'name': teacherName}),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (submission != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.72),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.text(
                            'yourSubmission',
                            {'text': submission!.answerOrLink},
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (submission!.teacherFeedback.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.text(
                              'teacherFeedback',
                              {'text': submission!.teacherFeedback},
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.liveEmerald,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onSubmitWork,
                  icon: const Icon(CupertinoIcons.paperplane, size: 14),
                  label: Text(
                    submission == null
                        ? l10n.text('submitAnswer')
                        : l10n.text('editSubmission'),
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
