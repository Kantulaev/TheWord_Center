import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/data/app_changelog.dart';
import '../../core/models/operations_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_background.dart';
import '../../features/auth/presentation/staff_access_dialog.dart';
import '../../features/classrooms/presentation/classroom_detail_panel.dart';
import '../../features/classrooms/presentation/classrooms_screen.dart';
import '../../features/community/presentation/events_screen.dart';
import '../../features/community/presentation/notifications_sheet.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/groups/presentation/group_detail_panel.dart';
import '../../features/groups/presentation/groups_screen.dart';
import '../../features/operations/presentation/leads_requests_screen.dart';
import '../../features/operations/presentation/updates_activity_screen.dart';
import '../../features/schedule/presentation/lesson_detail_panel.dart';
import '../../features/schedule/presentation/lesson_form_dialog.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/students/presentation/student_detail_panel.dart';
import '../../features/students/presentation/students_screen.dart';
import '../../features/teachers/presentation/teacher_detail_panel.dart';
import '../../features/teachers/presentation/teachers_screen.dart';
import 'appearance_settings_dialog.dart';
import 'language_badge.dart';
import 'liquid_glass_container.dart';

/// Top-level adaptive Liquid Glass shell adapting seamlessly across:
/// - Mobile (< 600px): Floating translucent bottom nav bar + compact top bar
/// - Tablet (600px - 1024px): Collapsible translucent NavigationRail + split master-detail
/// - Desktop (> 1024px): Persistent glass sidebar + workspace + slide-over inspector
class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({super.key});

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  bool _railExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(dataRepositoryProvider).seedInitialCenterDataIfNeeded(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(navigationTabProvider);
    final inspector = ref.watch(inspectorSelectionProvider);
    final animateBg = ref.watch(enableAmbientAnimationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final repo = ref.watch(dataRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);
    final authUser = ref.watch(authStateProvider).value;
    final staffEmail = authRepo.isSignInRequired ? authUser?.email : null;
    Future<void> handleSignOut() => ref.read(authRepositoryProvider).signOut();

    final lessonsCount =
        ref.watch(lessonsStreamProvider).value?.length ?? 0;
    final groupsCount =
        ref.watch(groupsStreamProvider).value?.length ?? 0;
    final teachersCount =
        ref.watch(teachersStreamProvider).value?.length ?? 0;
    final classroomsCount =
        ref.watch(classroomsStreamProvider).value?.length ?? 0;
    final studentsCount =
        ref.watch(studentsStreamProvider).value?.length ?? 0;
    final paymentsCount =
        ref.watch(paymentsStreamProvider).value?.length ?? 0;
    final leadsCount =
        (ref.watch(trialLeadsStreamProvider).value?.length ?? 0) +
            (ref
                    .watch(rescheduleRequestsStreamProvider)
                    .value
                    ?.where((r) => r.status == RequestStatus.pending)
                    .length ??
                0);
    final eventsCount =
        ref.watch(eventsStreamProvider).value?.length ?? 0;
    final updatesCount =
        ref.watch(activityLogsStreamProvider).value?.length ??
            kAppChangelog.length;

    final bodyPage = switch (activeTab) {
      AppTab.schedule => const ScheduleScreen(),
      AppTab.groups => const GroupsScreen(),
      AppTab.teachers => const TeachersScreen(),
      AppTab.classrooms => const ClassroomsScreen(),
      AppTab.students => const StudentsScreen(),
      AppTab.finance => const FinanceScreen(),
      AppTab.leads => const LeadsRequestsScreen(),
      AppTab.events => const EventsScreen(),
      AppTab.updates => const UpdatesActivityScreen(),
    };

    return LiquidAuroraBackground(
      animate: animateBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width <= 1024;
          final isDesktop = width > 1024;

          if (isMobile) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBody: true,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _MobileTopBar(
                      isCloudSync: repo.isCloudSync,
                      themeMode: themeMode,
                      onToggleTheme: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                      onShowSyncInfo: () => _showSyncStatusDialog(context),
                      onOpenStaffAccess: () => showStaffAccessModal(context),
                      onOpenUpdates: () {
                        ref
                            .read(navigationTabProvider.notifier)
                            .select(AppTab.updates);
                        ref.read(inspectorSelectionProvider.notifier).close();
                      },
                      onSignOut:
                          authRepo.isSignInRequired ? handleSignOut : null,
                    ),
                    Expanded(child: bodyPage),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _MobileFloatingNavBar(
                    activeTab: activeTab,
                    onSelect: (tab) {
                      ref.read(navigationTabProvider.notifier).select(tab);
                      ref.read(inspectorSelectionProvider.notifier).close();
                    },
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    if (isDesktop)
                      _DesktopGlassSidebar(
                        activeTab: activeTab,
                        counts: {
                          AppTab.schedule: lessonsCount,
                          AppTab.groups: groupsCount,
                          AppTab.teachers: teachersCount,
                          AppTab.classrooms: classroomsCount,
                          AppTab.students: studentsCount,
                          AppTab.finance: paymentsCount,
                          AppTab.leads: leadsCount,
                          AppTab.events: eventsCount,
                          AppTab.updates: updatesCount,
                        },
                        isCloudSync: repo.isCloudSync,
                        modeLabel: repo.modeLabel,
                        staffEmail: staffEmail,
                        themeMode: themeMode,
                        onSelectTab: (tab) {
                          ref.read(navigationTabProvider.notifier).select(tab);
                        },
                        onNewLesson: () => showLessonFormModal(context),
                        onToggleTheme: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        onShowSyncInfo: () => _showSyncStatusDialog(context),
                        onOpenStaffAccess: () => showStaffAccessModal(context),
                        onSignOut:
                            authRepo.isSignInRequired ? handleSignOut : null,
                      )
                    else if (isTablet)
                      _TabletGlassRail(
                        activeTab: activeTab,
                        expanded: _railExpanded,
                        isCloudSync: repo.isCloudSync,
                        themeMode: themeMode,
                        onToggleExpand: () =>
                            setState(() => _railExpanded = !_railExpanded),
                        onSelectTab: (tab) {
                          ref.read(navigationTabProvider.notifier).select(tab);
                        },
                        onToggleTheme: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        onShowSyncInfo: () => _showSyncStatusDialog(context),
                        onOpenStaffAccess: () => showStaffAccessModal(context),
                        onSignOut:
                            authRepo.isSignInRequired ? handleSignOut : null,
                      ),
                    const SizedBox(width: 14),
                    Expanded(child: bodyPage),
                    if (inspector != null) ...[
                      const SizedBox(width: 14),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        width: isDesktop ? 380 : 330,
                        child: LiquidGlassContainer(
                          borderRadius: 28,
                          blurSigma: 26,
                          elevation: 1.0,
                          height: double.infinity,
                          child: _buildInspectorContent(inspector),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInspectorContent(InspectorTarget selection) {
    void close() => ref.read(inspectorSelectionProvider.notifier).close();
    return switch (selection.kind) {
      InspectorKind.lesson => LessonDetailPanel(
          key: ValueKey('lesson_${selection.id}'),
          lessonId: selection.id,
          onClose: close,
        ),
      InspectorKind.group => GroupDetailPanel(
          key: ValueKey('group_${selection.id}'),
          groupId: selection.id,
          onClose: close,
        ),
      InspectorKind.teacher => TeacherDetailPanel(
          key: ValueKey('teacher_${selection.id}'),
          teacherId: selection.id,
          onClose: close,
        ),
      InspectorKind.classroom => ClassroomDetailPanel(
          key: ValueKey('classroom_${selection.id}'),
          classroomId: selection.id,
          onClose: close,
        ),
      InspectorKind.student => StudentDetailPanel(
          key: ValueKey('student_${selection.id}'),
          studentId: selection.id,
          onClose: close,
        ),
    };
  }

  void _showSyncStatusDialog(BuildContext context) {
    final repo = ref.read(dataRepositoryProvider);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: LiquidGlassContainer(
            borderRadius: 28,
            blurSigma: 28,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: repo.modeLabel,
                      color: repo.isCloudSync
                          ? AppColors.liveEmerald
                          : AppColors.englishAccent(dialogContext),
                      glow: true,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  repo.isCloudSync
                      ? 'Firebase Cloud Firestore Active'
                      : 'Running in Instant Demo Mode',
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  repo.isCloudSync
                      ? 'All schedule updates, teachers, classrooms, and student credits sync live via Cloud Firestore with local cache persistence & role isolation.'
                      : 'Running with reactive in-memory demo data.',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Got It'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 11 : 14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.chineseCrimson,
                AppColors.englishSapphire,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.englishSapphire.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'W',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 17 : 20,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The Word',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.titleLarge)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (!compact)
                Text(
                  'Mandarin & English Center',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopGlassSidebar extends StatelessWidget {
  const _DesktopGlassSidebar({
    required this.activeTab,
    required this.counts,
    required this.isCloudSync,
    required this.modeLabel,
    this.staffEmail,
    required this.themeMode,
    required this.onSelectTab,
    required this.onNewLesson,
    required this.onToggleTheme,
    required this.onShowSyncInfo,
    required this.onOpenStaffAccess,
    this.onSignOut,
  });

  final AppTab activeTab;
  final Map<AppTab, int> counts;
  final bool isCloudSync;
  final String modeLabel;
  final String? staffEmail;
  final ThemeMode themeMode;
  final ValueChanged<AppTab> onSelectTab;
  final VoidCallback onNewLesson;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSyncInfo;
  final VoidCallback onOpenStaffAccess;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;

    return LiquidGlassContainer(
      width: 256,
      height: double.infinity,
      borderRadius: 28,
      blurSigma: 24,
      elevation: 0.9,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: const [
                Expanded(child: _BrandMark()),
                SizedBox(width: 4),
                NotificationBellButton(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelectTab(AppTab.updates),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: AppColors.liveEmerald.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.liveEmerald.withValues(alpha: 0.28),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    size: 13,
                    color: AppColors.liveEmerald,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'v$kCurrentAppVersion • Updates',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.liveEmerald,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          LiquidPrimaryButton(
            label: 'Schedule Lesson',
            icon: CupertinoIcons.plus,
            onPressed: onNewLesson,
          ),
          const SizedBox(height: 12),
          Text(
            'WORKSPACE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted(context),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final tab in AppTab.values) ...[
                    _SidebarNavItem(
                      tab: tab,
                      count: counts[tab] ?? 0,
                      selected: activeTab == tab,
                      onTap: () => onSelectTab(tab),
                    ),
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          LiquidGlassContainer(
            borderRadius: 18,
            blurSigma: 12,
            elevation: 0.25,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: onToggleTheme,
            child: Row(
              children: [
                Icon(
                  isDark ? CupertinoIcons.moon_stars_fill : CupertinoIcons.sun_max_fill,
                  size: 18,
                  color: isDark
                      ? AppColors.chineseCoralGold
                      : AppColors.englishSapphire,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDark ? 'Obsidian Dark' : 'Pearl Light',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Switch',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LiquidGlassContainer(
            borderRadius: 18,
            blurSigma: 12,
            elevation: 0.25,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: () => showAppearanceSettingsModal(
              context,
              showLanguagePicker: false,
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.textformat_size,
                  size: 18,
                  color: AppColors.englishAccent(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Display & Font',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Size',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LiquidGlassContainer(
            borderRadius: 18,
            blurSigma: 12,
            elevation: 0.25,
            tintColor: isCloudSync
                ? AppColors.liveEmerald
                : AppColors.englishAccent(context),
            tintStrength: 0.08,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: onShowSyncInfo,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCloudSync
                        ? AppColors.liveEmerald
                        : AppColors.englishAccent(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    modeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Icon(
                  CupertinoIcons.info_circle,
                  size: 16,
                  color: AppColors.textMuted(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LiquidGlassContainer(
            borderRadius: 18,
            blurSigma: 12,
            elevation: 0.25,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            onTap: onOpenStaffAccess,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.person_badge_plus,
                  size: 17,
                  color: AppColors.englishAccent(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Staff Access',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Invite',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted(context),
                      ),
                ),
              ],
            ),
          ),
          if (onSignOut != null) ...[
            const SizedBox(height: 8),
            LiquidGlassContainer(
              borderRadius: 18,
              blurSigma: 12,
              elevation: 0.25,
              tintColor: AppColors.dangerRose,
              tintStrength: 0.05,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onTap: onSignOut,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.square_arrow_right,
                    size: 17,
                    color: AppColors.dangerRose,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign Out',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.dangerRose,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (staffEmail != null && staffEmail!.isNotEmpty)
                          Text(
                            staffEmail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10.5),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.tab,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.englishAccent(context);
    return LiquidGlassContainer(
      borderRadius: 18,
      blurSigma: 14,
      elevation: selected ? 0.65 : 0.0,
      tintColor: selected ? accent : null,
      tintStrength: selected ? 0.14 : 0.0,
      isSelected: selected,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            _iconForTab(tab, selected),
            size: 19,
            color: selected ? accent : AppColors.textSecondary(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tab.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? accent : AppColors.textPrimary(context),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: (selected ? accent : AppColors.textMuted(context))
                  .withValues(alpha: 0.14),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? accent : AppColors.textMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletGlassRail extends StatelessWidget {
  const _TabletGlassRail({
    required this.activeTab,
    required this.expanded,
    required this.isCloudSync,
    required this.themeMode,
    required this.onToggleExpand,
    required this.onSelectTab,
    required this.onToggleTheme,
    required this.onShowSyncInfo,
    required this.onOpenStaffAccess,
    this.onSignOut,
  });

  final AppTab activeTab;
  final bool expanded;
  final bool isCloudSync;
  final ThemeMode themeMode;
  final VoidCallback onToggleExpand;
  final ValueChanged<AppTab> onSelectTab;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSyncInfo;
  final VoidCallback onOpenStaffAccess;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;
    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 24,
      elevation: 0.85,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, railConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: railConstraints.maxHeight),
              child: IntrinsicHeight(
                child: NavigationRail(
                  backgroundColor: Colors.transparent,
                  extended: expanded,
                  selectedIndex: activeTab.index,
                  onDestinationSelected: (i) => onSelectTab(AppTab.values[i]),
                  leading: Column(
                    children: [
                      IconButton(
                        tooltip: expanded ? 'Collapse Rail' : 'Expand Rail',
                        onPressed: onToggleExpand,
                        icon: Icon(
                          expanded
                              ? CupertinoIcons.sidebar_left
                              : CupertinoIcons.chevron_right_2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const NotificationBellButton(),
                      const SizedBox(height: 6),
                    ],
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Display & Font Size',
                            onPressed: () => showAppearanceSettingsModal(
                              context,
                              showLanguagePicker: false,
                            ),
                            icon: const Icon(CupertinoIcons.textformat_size),
                          ),
                          IconButton(
                            tooltip: 'Toggle Light/Dark Mode',
                            onPressed: onToggleTheme,
                            icon: Icon(
                              isDark
                                  ? CupertinoIcons.moon_stars_fill
                                  : CupertinoIcons.sun_max_fill,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sync Status',
                            onPressed: onShowSyncInfo,
                            icon: Icon(
                              CupertinoIcons.cloud_fill,
                              color: isCloudSync
                                  ? AppColors.liveEmerald
                                  : AppColors.englishAccent(context),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Staff Access & Invites',
                            onPressed: onOpenStaffAccess,
                            icon: const Icon(CupertinoIcons.person_badge_plus),
                          ),
                          if (onSignOut != null)
                            IconButton(
                              tooltip: 'Sign Out',
                              onPressed: onSignOut,
                              icon: const Icon(
                                CupertinoIcons.square_arrow_right,
                                color: AppColors.dangerRose,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  destinations: [
                    for (final tab in AppTab.values)
                      NavigationRailDestination(
                        icon: Icon(_iconForTab(tab, false)),
                        selectedIcon: Icon(_iconForTab(tab, true)),
                        label: Text(tab.label),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.isCloudSync,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onShowSyncInfo,
    required this.onOpenStaffAccess,
    required this.onOpenUpdates,
    this.onSignOut,
  });

  final bool isCloudSync;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSyncInfo;
  final VoidCallback onOpenStaffAccess;
  final VoidCallback onOpenUpdates;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: LiquidGlassContainer(
        borderRadius: 22,
        blurSigma: 12,
        enableBlur: true,
        elevation: 0.65,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const Expanded(child: _BrandMark(compact: true)),
            LiquidGlassPillButton(
              label: isCloudSync ? 'Cloud' : 'Demo',
              accentColor: isCloudSync
                  ? AppColors.liveEmerald
                  : AppColors.englishAccent(context),
              selected: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              onTap: onShowSyncInfo,
            ),
            const SizedBox(width: 4),
            const NotificationBellButton(compact: true),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Staff Access',
              onPressed: onOpenStaffAccess,
              icon: const Icon(
                CupertinoIcons.person_badge_plus,
                size: 18,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Toggle Theme',
              onPressed: onToggleTheme,
              icon: Icon(
                isDark
                    ? CupertinoIcons.moon_stars_fill
                    : CupertinoIcons.sun_max_fill,
                size: 18,
              ),
            ),
            if (onSignOut != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Sign Out',
                onPressed: onSignOut,
                icon: const Icon(
                  CupertinoIcons.square_arrow_right,
                  color: AppColors.dangerRose,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileFloatingNavBar extends StatelessWidget {
  const _MobileFloatingNavBar({
    required this.activeTab,
    required this.onSelect,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onSelect;

  static const _primaryTabs = [
    AppTab.schedule,
    AppTab.groups,
    AppTab.finance,
    AppTab.students,
  ];

  static const _moreTabs = [
    AppTab.teachers,
    AppTab.classrooms,
    AppTab.leads,
    AppTab.events,
    AppTab.updates,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.englishAccent(context);
    final isMoreSelected = _moreTabs.contains(activeTab);

    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 12,
      enableBlur: true,
      elevation: 1.1,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final tab in _primaryTabs)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelect(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: activeTab == tab
                        ? accent.withValues(alpha: 0.14)
                        : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForTab(tab, activeTab == tab),
                        size: 20,
                        color: activeTab == tab
                            ? accent
                            : AppColors.textSecondary(context),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: activeTab == tab
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: activeTab == tab
                              ? accent
                              : AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openMoreSheet(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isMoreSelected
                      ? accent.withValues(alpha: 0.14)
                      : Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMoreSelected
                          ? CupertinoIcons.square_grid_2x2_fill
                          : CupertinoIcons.square_grid_2x2,
                      size: 20,
                      color: isMoreSelected
                          ? accent
                          : AppColors.textSecondary(context),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'More',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isMoreSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isMoreSelected
                            ? accent
                            : AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(16),
        child: LiquidGlassContainer(
          borderRadius: 28,
          blurSigma: 28,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More Sections',
                style: Theme.of(sheetCtx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final tab in _moreTabs) ...[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(_iconForTab(tab, activeTab == tab)),
                  title: Text(tab.label),
                  trailing: tab == AppTab.updates
                      ? const StatusBadge(
                          label: 'v$kCurrentAppVersion',
                          color: AppColors.liveEmerald,
                          compact: true,
                        )
                      : null,
                  selected: activeTab == tab,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    onSelect(tab);
                  },
                ),
              ],
              const Divider(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: const Icon(CupertinoIcons.textformat_size),
                title: const Text('Display & Font Size'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  showAppearanceSettingsModal(
                    context,
                    showLanguagePicker: false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForTab(AppTab tab, bool selected) {
  return switch (tab) {
    AppTab.schedule =>
      selected ? CupertinoIcons.calendar_today : CupertinoIcons.calendar,
    AppTab.groups =>
      selected ? CupertinoIcons.person_3_fill : CupertinoIcons.person_3,
    AppTab.teachers =>
      selected ? CupertinoIcons.person_2_fill : CupertinoIcons.person_2,
    AppTab.classrooms =>
      selected ? CupertinoIcons.building_2_fill : CupertinoIcons.building_2_fill,
    AppTab.students =>
      selected ? CupertinoIcons.book_fill : CupertinoIcons.book,
    AppTab.finance => selected
        ? CupertinoIcons.money_dollar_circle_fill
        : CupertinoIcons.money_dollar_circle,
    AppTab.leads =>
      selected ? CupertinoIcons.sparkles : CupertinoIcons.sparkles,
    AppTab.events =>
      selected ? Icons.celebration_rounded : Icons.celebration_outlined,
    AppTab.updates =>
      selected ? CupertinoIcons.rocket_fill : CupertinoIcons.rocket,
  };
}
