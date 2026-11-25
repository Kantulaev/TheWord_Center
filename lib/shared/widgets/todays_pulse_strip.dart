import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import 'liquid_glass_container.dart';

/// Glass summary dashboard strip showing real-time center telemetry.
class TodaysPulseStrip extends ConsumerWidget {
  const TodaysPulseStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(todayPulseProvider);

    final cards = [
      _PulseCardData(
        label: 'Active Now',
        value: '${pulse.activeNowCount}',
        subtitle: pulse.activeNowCount == 1
            ? 'Lesson in progress'
            : 'Lessons in progress',
        accent: AppColors.liveEmerald,
        icon: CupertinoIcons.bolt_fill,
        liveDot: pulse.activeNowCount > 0,
        onTap: () {
          ref.read(navigationTabProvider.notifier).select(AppTab.schedule);
          ref.read(scheduleFilterProvider.notifier).jumpToToday();
        },
      ),
      _PulseCardData(
        label: "Today's Lessons",
        value: '${pulse.todayTotalCount}',
        subtitle: 'Scheduled for today',
        accent: AppColors.englishAccent(context),
        icon: CupertinoIcons.calendar_today,
        onTap: () {
          ref.read(navigationTabProvider.notifier).select(AppTab.schedule);
          ref.read(scheduleFilterProvider.notifier).jumpToToday();
        },
      ),
      _PulseCardData(
        label: 'Free Classrooms',
        value: '${pulse.freeClassroomsCount}/${pulse.totalClassroomsCount}',
        subtitle: 'Available right now',
        accent: AppColors.chineseCoralGold,
        icon: CupertinoIcons.building_2_fill,
        onTap: () {
          ref.read(navigationTabProvider.notifier).select(AppTab.classrooms);
        },
      ),
      _PulseCardData(
        label: 'Active Students',
        value: '${pulse.activeStudentsCount}',
        subtitle: 'Enrolled learners',
        accent: AppColors.chineseAccent(context),
        icon: CupertinoIcons.person_2_fill,
        onTap: () {
          ref.read(navigationTabProvider.notifier).select(AppTab.students);
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 760) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: _PulseMetricCard(data: cards[i])),
                if (i < cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        // 2x2 grid for mobile and compact tablets
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _PulseMetricCard(data: cards[0], compact: true)),
                const SizedBox(width: 10),
                Expanded(child: _PulseMetricCard(data: cards[1], compact: true)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _PulseMetricCard(data: cards[2], compact: true)),
                const SizedBox(width: 10),
                Expanded(child: _PulseMetricCard(data: cards[3], compact: true)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PulseCardData {
  const _PulseCardData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onTap,
    this.liveDot = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;
  final bool liveDot;
}

class _PulseMetricCard extends StatelessWidget {
  const _PulseMetricCard({
    required this.data,
    this.compact = false,
  });

  final _PulseCardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      borderRadius: 22,
      blurSigma: 18,
      elevation: 0.75,
      tintColor: data.accent,
      tintStrength: 0.06,
      onTap: data.onTap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 38 : 42,
            height: compact ? 38 : 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: data.accent.withValues(alpha: 0.14),
              border: Border.all(color: data.accent.withValues(alpha: 0.25)),
            ),
            child: Icon(data.icon, color: data.accent, size: compact ? 18 : 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        data.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textMuted(context),
                            ),
                      ),
                    ),
                    if (data.liveDot) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.accent,
                          boxShadow: [
                            BoxShadow(
                              color: data.accent.withValues(alpha: 0.8),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: (compact
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
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
