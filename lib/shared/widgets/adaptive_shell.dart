import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_background.dart';
import '../../features/classrooms/presentation/classroom_detail_panel.dart';
import '../../features/classrooms/presentation/classrooms_screen.dart';
import '../../features/schedule/presentation/lesson_detail_panel.dart';
import '../../features/schedule/presentation/lesson_form_dialog.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/students/presentation/student_detail_panel.dart';
import '../../features/students/presentation/students_screen.dart';
import '../../features/teachers/presentation/teacher_detail_panel.dart';
import '../../features/teachers/presentation/teachers_screen.dart';
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
  Widget build(BuildContext context) {
    final activeTab = ref.watch(navigationTabProvider);
    final inspector = ref.watch(inspectorSelectionProvider);
    final animateBg = ref.watch(enableAmbientAnimationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final repo = ref.watch(dataRepositoryProvider);

    final lessonsCount =
        ref.watch(lessonsStreamProvider).value?.length ?? 0;
    final teachersCount =
        ref.watch(teachersStreamProvider).value?.length ?? 0;
    final classroomsCount =
        ref.watch(classroomsStreamProvider).value?.length ?? 0;
    final studentsCount =
        ref.watch(studentsStreamProvider).value?.length ?? 0;

    final bodyPage = switch (activeTab) {
      AppTab.schedule => const ScheduleScreen(),
      AppTab.teachers => const TeachersScreen(),
      AppTab.classrooms => const ClassroomsScreen(),
      AppTab.students => const StudentsScreen(),
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
                          AppTab.teachers: teachersCount,
                          AppTab.classrooms: classroomsCount,
                          AppTab.students: studentsCount,
                        },
                        isCloudSync: repo.isCloudSync,
                        modeLabel: repo.modeLabel,
                        themeMode: themeMode,
                        onSelectTab: (tab) {
                          ref.read(navigationTabProvider.notifier).select(tab);
                        },
                        onNewLesson: () => showLessonFormModal(context),
                        onToggleTheme: () =>
                            ref.read(themeModeProvider.notifier).toggle(),
                        onShowSyncInfo: () => _showSyncStatusDialog(context),
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
                      ? 'All schedule updates, teachers, classrooms, and student credits sync live across every connected browser and device via Firestore.'
                      : 'Firebase keys are not configured yet, so The Word automatically booted with reactive in-memory streams pre-loaded with sample Chinese & English center data.\n\nTo enable multi-device cloud sync on the free Firebase Spark plan, run `flutterfire configure` to generate `lib/firebase_options.dart` and restart the app.',
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
    required this.themeMode,
    required this.onSelectTab,
    required this.onNewLesson,
    required this.onToggleTheme,
    required this.onShowSyncInfo,
  });

  final AppTab activeTab;
  final Map<AppTab, int> counts;
  final bool isCloudSync;
  final String modeLabel;
  final ThemeMode themeMode;
  final ValueChanged<AppTab> onSelectTab;
  final VoidCallback onNewLesson;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSyncInfo;

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _BrandMark(),
          ),
          const SizedBox(height: 18),
          LiquidPrimaryButton(
            label: 'Schedule Lesson',
            icon: CupertinoIcons.plus,
            onPressed: onNewLesson,
          ),
          const SizedBox(height: 18),
          Text(
            'WORKSPACE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted(context),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (final tab in AppTab.values) ...[
            _SidebarNavItem(
              tab: tab,
              count: counts[tab] ?? 0,
              selected: activeTab == tab,
              onTap: () => onSelectTab(tab),
            ),
            const SizedBox(height: 6),
          ],
          const Spacer(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
  });

  final AppTab activeTab;
  final bool expanded;
  final bool isCloudSync;
  final ThemeMode themeMode;
  final VoidCallback onToggleExpand;
  final ValueChanged<AppTab> onSelectTab;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSyncInfo;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;
    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 24,
      elevation: 0.85,
      padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.isCloudSync,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onShowSyncInfo,
  });

  final bool isCloudSync;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onShowSyncInfo;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: LiquidGlassContainer(
        borderRadius: 22,
        blurSigma: 20,
        elevation: 0.65,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            const _BrandMark(compact: true),
            const Spacer(),
            LiquidGlassPillButton(
              label: isCloudSync ? 'Cloud' : 'Demo',
              accentColor: isCloudSync
                  ? AppColors.liveEmerald
                  : AppColors.englishAccent(context),
              selected: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onTap: onShowSyncInfo,
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Toggle Theme',
              onPressed: onToggleTheme,
              icon: Icon(
                isDark
                    ? CupertinoIcons.moon_stars_fill
                    : CupertinoIcons.sun_max_fill,
                size: 20,
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

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.englishAccent(context);
    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 26,
      elevation: 1.2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final tab in AppTab.values)
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
                          fontSize: 11,
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
        ],
      ),
    );
  }
}

IconData _iconForTab(AppTab tab, bool selected) {
  return switch (tab) {
    AppTab.schedule =>
      selected ? CupertinoIcons.calendar_today : CupertinoIcons.calendar,
    AppTab.teachers =>
      selected ? CupertinoIcons.person_2_fill : CupertinoIcons.person_2,
    AppTab.classrooms =>
      selected ? CupertinoIcons.building_2_fill : CupertinoIcons.building_2_fill,
    AppTab.students => selected
        ? CupertinoIcons.book_fill
        : CupertinoIcons.book,
  };
}
