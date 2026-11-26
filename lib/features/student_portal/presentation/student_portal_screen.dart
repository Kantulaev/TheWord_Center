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
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

/// Self-service Student Portal accessible via open Google Sign-In.
/// Students can pick their HSK / English study groups, view steady schedules,
/// see their 12-lesson balance (if linked), and mark homework complete.
class StudentPortalScreen extends ConsumerWidget {
  const StudentPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profileAsync = ref.watch(studentPortalProfileProvider);
    // Security & Quota Optimization: students subscribe ONLY to scoped public collections
    // (Sharing groups, teacher salaries/phones, raw lessons, and classmate lists are never read).
    final groupsAsync = ref.watch(publicGroupsStreamProvider);
    final homeworksAsync = ref.watch(studentHomeworksProvider);
    final mySubsList = ref.watch(myHomeworkSubmissionsProvider).value ?? const [];
    final teachers = ref.watch(publicTeachersMapProvider);
    final classrooms = ref.watch(classroomsMapProvider);
    final matchedStudent = ref.watch(myStudentRecordProvider).value;
    final myRequests = ref.watch(myRescheduleRequestsProvider).value ?? const [];
    final animateBg = ref.watch(enableAmbientAnimationsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'The Word • Student Portal',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${profile.fullName} (${profile.email})',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Toggle Theme',
                              onPressed: () =>
                                  ref.read(themeModeProvider.notifier).toggle(),
                              icon: Icon(
                                isDark
                                    ? CupertinoIcons.moon_stars_fill
                                    : CupertinoIcons.sun_max_fill,
                              ),
                            ),
                            const SizedBox(width: 6),
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
                              label: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (matchedStudent != null) ...[
                    _StudentProgressCard(student: matchedStudent),
                    const SizedBox(height: 16),
                  ],

                  // Official Center Contacts & Operating Hours
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
                              '${CenterInfo.address} (${CenterInfo.landmarks})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              CenterInfo.compactHoursSummary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            GlassInfoTag(
                              icon: CupertinoIcons.phone_fill,
                              label: CenterInfo.primaryPhone,
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => ReminderHelper.openWhatsApp(
                                context,
                                phone: CenterInfo.whatsappPhone,
                                message:
                                    'Hello The Word Center! I am ${profile.fullName} (${profile.email}).',
                              ),
                              icon: const Icon(
                                CupertinoIcons.chat_bubble_fill,
                                size: 14,
                              ),
                              label: const Text('Message Center'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 1: Choose Your HSK / English Group
                  Text(
                    '1. Choose Your HSK / English Group',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your group(s) below to see your steady class schedule and receive homework assignments.',
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
                      child: const Text(
                        'No study groups are available yet. Ask your teacher to create an HSK or English group.',
                      ),
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
                                  isJoined: selectedIds.contains(g.id),
                                  teacherName:
                                      teachers[g.teacherId]?.fullName ??
                                          'Teacher',
                                  roomName:
                                      classrooms[g.classroomId]?.name ?? 'Room',
                                  studentEmail: profile.email,
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
                    '2. My Homework (${myHomeworks.length})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assignments sent by your teachers appear here automatically.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),

                  if (selectedIds.isEmpty)
                    LiquidGlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Join at least one HSK or English group above to see its homework.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else if (myHomeworks.isEmpty)
                    LiquidGlassContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No homework assigned for your selected groups yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (final hw in myHomeworks) ...[
                          _StudentHomeworkCard(
                            homework: hw,
                            group: allGroups.cast<StudyGroup?>().firstWhere(
                                  (g) => g?.id == hw.groupId,
                                  orElse: () => null,
                                ),
                            teacherName:
                                teachers[hw.teacherId]?.fullName ?? 'Teacher',
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
                              homework: hw,
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
                              '3. Reschedule Requests (${myRequests.length})',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Need to move an upcoming class? Request a preferred date & time and track teacher approval.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      LiquidPrimaryButton(
                        label: 'Request Change',
                        icon: CupertinoIcons.calendar_badge_plus,
                        onPressed: () => _showRescheduleDialog(
                          context,
                          ref,
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
                      child: const Text(
                        'No reschedule requests submitted yet.',
                      ),
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
                                  label: req.status.label,
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
                                'Center reply: ${req.staffNote}',
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
    required HomeworkAssignment homework,
    required StudentPortalProfile profile,
  }) async {
    final existing = homework.submissionFor(profile.uid);
    final answerCtrl = TextEditingController(text: existing?.answerOrLink ?? '');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Submit: ${homework.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your written answer, Google Doc / Google Drive link, or voice recording link for your teacher:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: answerCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Answer or Link *',
                hintText: 'Type your answer or paste https://...',
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
            child: const Text('Submit to Teacher'),
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
        const SnackBar(
          content: Text('Please select a study group first.'),
        ),
      );
      return;
    }

    var selectedGroup = candidateGroups.first;
    var requestedDate = DateTime.now().add(const Duration(days: 1));
    final slotCtrl = TextEditingController(text: '6:00 PM');
    final reasonCtrl = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setState) => AlertDialog(
          title: const Text('Request Class Reschedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<StudyGroup>(
                  initialValue: selectedGroup,
                  decoration: const InputDecoration(labelText: 'Study Group'),
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
                    'Preferred Date: ${DateFormat('EEE, MMM d').format(requestedDate)}',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: slotCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Time Slot *',
                    hintText: 'e.g., Thursday 6:00 PM',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Send Request'),
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
      const SnackBar(
        content: Text('Reschedule request sent to teachers!'),
      ),
    );
  }
}

class _StudentGroupSelectCard extends StatelessWidget {
  const _StudentGroupSelectCard({
    required this.group,
    required this.isJoined,
    required this.teacherName,
    required this.roomName,
    required this.studentEmail,
    required this.onToggle,
  });

  final StudyGroup group;
  final bool isJoined;
  final String teacherName;
  final String roomName;
  final String studentEmail;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final accent = group.language.accentColor(context);
    final normalized = studentEmail.trim().toLowerCase();
    final matchedPayment = group.members.cast<GroupMemberPayment?>().firstWhere(
          (m) => m?.email.trim().toLowerCase() == normalized && normalized.isNotEmpty,
          orElse: () => null,
        );

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
              LanguageBadge(language: group.language, compact: true),
              const SizedBox(width: 8),
              GlassInfoTag(label: group.level),
              const Spacer(),
              LiquidGlassPillButton(
                label: isJoined ? 'Joined ✓' : 'Join Group',
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
            '${group.scheduleSummary} • Room $roomName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Teacher: $teacherName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (matchedPayment != null) ...[
            const SizedBox(height: 8),
            StatusBadge(
              label:
                  '${matchedPayment.lessonsRemaining}/${matchedPayment.totalPaidLessons} lessons left • ${matchedPayment.hasPaid ? 'Paid' : 'Unpaid'}',
              color: matchedPayment.hasPaid
                  ? AppColors.liveEmerald
                  : AppColors.warningAmber,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentProgressCard extends StatelessWidget {
  const _StudentProgressCard({required this.student});

  final Student student;

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
                label: '${student.remainingCredits} credits left',
                color: student.remainingCredits <= 2
                    ? AppColors.warningAmber
                    : AppColors.liveEmerald,
                compact: true,
              ),
              if (student.readyForNextLevel)
                const StatusBadge(
                  label: 'Ready for Next Level!',
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
                  'My ${student.proficiencyLevel} Mastery Progress',
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
    required this.group,
    required this.teacherName,
    required this.isDone,
    required this.submission,
    required this.onToggleDone,
    required this.onSubmitWork,
  });

  final HomeworkAssignment homework;
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
                      label:
                          'Due ${DateFormat('MMM d').format(homework.dueDate)}',
                      color: isDone ? AppColors.liveEmerald : accent,
                      compact: true,
                    ),
                    if (isDone)
                      const StatusBadge(
                        label: 'Completed',
                        color: AppColors.liveEmerald,
                        compact: true,
                      ),
                    if (submission != null)
                      StatusBadge(
                        label: submission!.reviewed
                            ? 'Teacher Reviewed'
                            : 'Submitted',
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
                  'Assigned by $teacherName',
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
                          'Your Submission: ${submission!.answerOrLink}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (submission!.teacherFeedback.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Teacher Feedback: ${submission!.teacherFeedback}',
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
                        ? 'Submit Answer / Link'
                        : 'Edit Submission',
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
