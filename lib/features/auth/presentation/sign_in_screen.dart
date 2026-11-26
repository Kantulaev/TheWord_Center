import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/data/center_info.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_background.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

/// Closed staff-only Sign-In screen using Google authentication + Firestore whitelist.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _submitting = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle({required bool requireStaff}) async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(requireStaff: requireStaff);
    } on AuthFailureException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Google sign-in failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final animateBg = ref.watch(enableAmbientAnimationsProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return LiquidAuroraBackground(
      animate: animateBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                right: 16,
                child: LiquidGlassPillButton(
                  label: isDark ? 'Dark' : 'Light',
                  icon: isDark
                      ? CupertinoIcons.moon_stars_fill
                      : CupertinoIcons.sun_max_fill,
                  onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: LiquidGlassContainer(
                      borderRadius: 28,
                      blurSigma: 28,
                      elevation: 1.4,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
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
                                      color: AppColors.englishSapphire
                                          .withValues(alpha: 0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'W',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'The Word',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    Text(
                                      'Mandarin & English Center',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: StatusBadge(
                              label: 'Authorized Staff Only',
                              color: AppColors.englishSapphire,
                              icon: CupertinoIcons.lock_shield_fill,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome to The Word',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in with Google. Staff accounts open the center workspace; students open the self-service Student Portal.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerRose
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.dangerRose
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons
                                        .exclamationmark_triangle_fill,
                                    color: AppColors.dangerRose,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                AppColors.textPrimary(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          LiquidPrimaryButton(
                            label: _submitting
                                ? 'Signing In...'
                                : 'Sign in with Google',
                            icon: CupertinoIcons.globe,
                            onPressed: _submitting
                                ? null
                                : () => _signInWithGoogle(requireStaff: false),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _submitting
                                ? null
                                : () => _signInWithGoogle(requireStaff: true),
                            icon: const Icon(
                              CupertinoIcons.lock_shield,
                              size: 17,
                            ),
                            label: const Text('Staff Sign In Only'),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Students can register freely with any Google account to join HSK groups & view homework.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.englishSapphire
                                  .withValues(alpha: 0.06),
                              border: Border.all(
                                color: AppColors.englishSapphire
                                    .withValues(alpha: 0.16),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  CenterInfo.address,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CenterInfo.compactHoursSummary,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${CenterInfo.primaryPhone} • ${CenterInfo.secondaryPhone}',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
