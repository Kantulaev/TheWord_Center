import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../features/student_portal/l10n/student_portal_strings.dart';
import 'confirm_delete_dialog.dart';
import 'liquid_glass_container.dart';

Future<void> showAppearanceSettingsModal(
  BuildContext context, {
  bool showLanguagePicker = true,
}) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 500,
    builder: (_) =>
        AppearanceSettingsDialog(showLanguagePicker: showLanguagePicker),
  );
}

class AppearanceSettingsDialog extends ConsumerWidget {
  const AppearanceSettingsDialog({
    super.key,
    this.showLanguagePicker = true,
  });

  final bool showLanguagePicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final locale = ref.watch(portalLocaleProvider);
    final l10n = StudentPortalL10n(locale);
    final isDark = themeMode == ThemeMode.dark;

    const scaleLabels = [
      (scale: 1.0, label: '100% Standard'),
      (scale: 1.15, label: '115% Large'),
      (scale: 1.30, label: '130% Extra Large'),
      (scale: 1.45, label: '145% Max'),
    ];

    return LiquidGlassContainer(
      borderRadius: 28,
      blurSigma: 28,
      elevation: 1.4,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: AppColors.englishAccent(context).withValues(alpha: 0.14),
                ),
                child: Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: AppColors.englishAccent(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.text('settings'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.text('close'),
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
                  Text(
                    l10n.text('themeLabel'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      LiquidGlassPillButton(
                        label: '${l10n.text('darkMode')} (Default)',
                        icon: CupertinoIcons.moon_stars_fill,
                        selected: isDark,
                        accentColor: AppColors.chineseCoralGold,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setMode(ThemeMode.dark),
                      ),
                      LiquidGlassPillButton(
                        label: l10n.text('lightMode'),
                        icon: CupertinoIcons.sun_max_fill,
                        selected: !isDark,
                        accentColor: AppColors.englishSapphire,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setMode(ThemeMode.light),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.text('fontSizeLabel'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Text(
                        '${(fontScale * 100).round()}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.englishAccent(context),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opt in scaleLabels)
                        LiquidGlassPillButton(
                          label: opt.label,
                          selected: (fontScale - opt.scale).abs() < 0.03,
                          accentColor: AppColors.englishAccent(context),
                          onTap: () => ref
                              .read(fontScaleProvider.notifier)
                              .setScale(opt.scale),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.englishAccent(context)
                          .withValues(alpha: 0.08),
                    ),
                    child: Text(
                      'Aa • The Word Bishkek • Пример текста • 汉字阅读',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  if (showLanguagePicker) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.text('languageLabel'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final loc in PortalLocale.values)
                          LiquidGlassPillButton(
                            label: loc.nativeName,
                            selected: locale == loc,
                            accentColor: AppColors.liveEmerald,
                            onTap: () => ref
                                .read(portalLocaleProvider.notifier)
                                .setLocale(loc),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: LiquidPrimaryButton(
              label: l10n.text('close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
