import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/app_changelog.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

class UpdatesActivityScreen extends ConsumerStatefulWidget {
  const UpdatesActivityScreen({super.key});

  @override
  ConsumerState<UpdatesActivityScreen> createState() =>
      _UpdatesActivityScreenState();
}

class _UpdatesActivityScreenState extends ConsumerState<UpdatesActivityScreen> {
  String _categoryFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(activityLogsStreamProvider).value ?? const [];
    final categories = <String>{
      'All',
      for (final log in logs) log.category,
    }.toList();

    final filteredLogs = _categoryFilter == 'All'
        ? logs
        : logs.where((l) => l.category == _categoryFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // Header banner
        LiquidGlassContainer(
          borderRadius: 26,
          blurSigma: 22,
          tintColor: AppColors.englishAccent(context),
          tintStrength: 0.08,
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.liveEmerald.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'VERSION $kCurrentAppVersion LIVE',
                          style: const TextStyle(
                            color: AppColors.liveEmerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'App Updates & Center Activity Log',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Release notes for teachers explaining every new tool added to The Word, paired with a real-time center audit feed.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
              if (isNarrow) return titleBlock;
              return Row(
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.englishAccent(context)
                          .withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      size: 30,
                      color: AppColors.englishAccent(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 22),

        // What's New Release Notes for Teachers
        Row(
          children: [
            Icon(
              CupertinoIcons.rocket_fill,
              size: 19,
              color: AppColors.sharingAccent(context),
            ),
            const SizedBox(width: 8),
            Text(
              'What\'s New in The Word',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < kAppChangelog.length; i++) ...[
          _ReleaseNoteCard(
            release: kAppChangelog[i],
            isLatest: i == 0,
          ),
          const SizedBox(height: 14),
        ],

        const SizedBox(height: 10),

        // Live Staff Activity Audit Log
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
                    CupertinoIcons.list_bullet_indent,
                    color: AppColors.englishAccent(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live Staff Activity Log (${filteredLogs.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Automatic trail of attendance marks, recorded tuition payments, converted trial leads, homework reviews, and schedule updates.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final cat in categories) ...[
                      LiquidGlassPillButton(
                        label: cat,
                        selected: _categoryFilter == cat,
                        onTap: () => setState(() => _categoryFilter = cat),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filteredLogs.isEmpty)
                Text(
                  'No staff activity logged yet. Actions across Attendance, Payments, Leads, Homework, and Schedule appear here automatically.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (final entry in filteredLogs.take(50)) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white.withValues(alpha: 0.68),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusBadge(
                          label: entry.category,
                          color: _categoryColor(context, entry.category),
                          compact: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.summary,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${entry.actorEmail} • ${DateFormat('MMM d, h:mm a').format(entry.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Color _categoryColor(BuildContext context, String category) =>
      switch (category.toLowerCase()) {
        'attendance' => AppColors.liveEmerald,
        'payment' => AppColors.liveEmerald,
        'lead' => AppColors.sharingAccent(context),
        'homework' => AppColors.chineseAccent(context),
        'schedule' => AppColors.englishAccent(context),
        _ => AppColors.completedSlate,
      };
}

class _ReleaseNoteCard extends StatelessWidget {
  const _ReleaseNoteCard({
    required this.release,
    required this.isLatest,
  });

  final AppReleaseNote release;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 24,
      blurSigma: 20,
      tintColor: isLatest ? AppColors.liveEmerald : null,
      tintStrength: isLatest ? 0.05 : 0.0,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: (isLatest
                          ? AppColors.liveEmerald
                          : AppColors.englishAccent(context))
                      .withValues(alpha: 0.14),
                ),
                child: Text(
                  'v${release.version}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isLatest
                        ? AppColors.liveEmerald
                        : AppColors.englishAccent(context),
                  ),
                ),
              ),
              if (isLatest)
                const StatusBadge(
                  label: 'Latest',
                  color: AppColors.liveEmerald,
                  compact: true,
                ),
              Text(
                release.dateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            release.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            release.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final item in release.highlights) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChangeTypeChip(type: item.type),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.text,
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _ChangeTypeChip extends StatelessWidget {
  const _ChangeTypeChip({required this.type});

  final ReleaseChangeType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      ReleaseChangeType.newFeature => ('NEW', AppColors.liveEmerald),
      ReleaseChangeType.improved => ('IMPROVED', AppColors.englishAccent(context)),
      ReleaseChangeType.fixed => ('FIXED', AppColors.warningAmber),
    };

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
