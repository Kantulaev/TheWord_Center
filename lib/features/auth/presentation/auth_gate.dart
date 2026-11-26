import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/glass_background.dart';
import '../../../shared/widgets/adaptive_shell.dart';
import '../../../shared/widgets/liquid_glass_container.dart';
import '../../student_portal/presentation/student_portal_screen.dart';
import 'sign_in_screen.dart';

/// Routes signed-in staff to [AdaptiveShell] and signed-in students to [StudentPortalScreen].
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    if (!authRepo.isSignInRequired) {
      return const AdaptiveShell();
    }

    final authAsync = ref.watch(authStateProvider);
    final animateBg = ref.watch(enableAmbientAnimationsProvider);

    return authAsync.when(
      loading: () => LiquidAuroraBackground(
        animate: animateBg,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: LiquidGlassContainer(
              borderRadius: 24,
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ),
      error: (_, _) => const SignInScreen(),
      data: (user) {
        if (user == null) {
          return const SignInScreen();
        }
        if (user.isStudent) {
          return const StudentPortalScreen();
        }
        return const AdaptiveShell();
      },
    );
  }
}
