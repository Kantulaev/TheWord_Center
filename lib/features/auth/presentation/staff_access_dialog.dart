import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../shared/widgets/language_badge.dart';
import '../../../shared/widgets/liquid_glass_container.dart';

/// Opens the Staff Access & Invites modal so any authorized teacher can grant
/// or revoke Google sign-in access for colleagues.
Future<void> showStaffAccessModal(BuildContext context) {
  return showAdaptiveGlassModal<void>(
    context,
    maxWidth: 520,
    builder: (_) => const StaffAccessDialog(),
  );
}

class StaffAccessDialog extends ConsumerStatefulWidget {
  const StaffAccessDialog({super.key});

  @override
  ConsumerState<StaffAccessDialog> createState() => _StaffAccessDialogState();
}

class _StaffAccessDialogState extends ConsumerState<StaffAccessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      await ref.read(authRepositoryProvider).addAllowedEmail(email);
      _emailCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access granted to $email'),
          ),
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
    final allowedAsync = ref.watch(allowedEmailsProvider);
    final currentEmail =
        (ref.watch(authStateProvider).value?.email ?? '').trim().toLowerCase();

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
                  color: AppColors.englishSapphire.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  CupertinoIcons.person_badge_plus_fill,
                  color: AppColors.englishSapphire,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Access & Invites',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Add Google emails that are allowed to sign in.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CupertinoIcons.xmark_circle_fill),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Colleague Google Email',
                      hintText: 'teacher@gmail.com',
                      isDense: true,
                    ),
                    onFieldSubmitted: (_) {
                      if (!_submitting) _invite();
                    },
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty ||
                          !value.contains('@') ||
                          !value.contains('.')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                LiquidPrimaryButton(
                  label: _submitting ? 'Adding...' : 'Invite',
                  icon: CupertinoIcons.plus,
                  onPressed: _submitting ? null : _invite,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Authorized Staff Emails',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: allowedAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Text(
                'Unable to load authorized emails: $err',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              data: (emails) {
                if (emails.isEmpty) {
                  return Text(
                    'No staff emails added yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: emails.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = emails[index];
                    final isSelf = item.email == currentEmail;
                    return LiquidGlassContainer(
                      borderRadius: 16,
                      blurSigma: 10,
                      elevation: 0.25,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_shield_fill,
                            size: 18,
                            color: AppColors.liveEmerald,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.email,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (item.addedBy.isNotEmpty)
                                  Text(
                                    'Added by ${item.addedBy}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          if (isSelf)
                            const StatusBadge(
                              label: 'You',
                              color: AppColors.englishSapphire,
                              compact: true,
                            )
                          else
                            IconButton(
                              tooltip: 'Revoke access',
                              icon: const Icon(
                                CupertinoIcons.trash,
                                size: 17,
                                color: AppColors.dangerRose,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(authRepositoryProvider)
                                    .removeAllowedEmail(item.email);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
