import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/update_account_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/enums.dart';
import 'profile_widgets.dart';

/// BOUNDARY (#13.3 Account Settings). Account-level data only — fitness data
/// lives on #13.1 by design. Inline commits (no save button).
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what arrives in a later sprint.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final sending = ref.watch(updateAccountSettingsProvider).isLoading;
    final units = profile?.preferredUnits ?? PreferredUnits.metric;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('ACCOUNT SETTINGS',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SectionLabel(label: 'Personal Info'),
          SettingRow(
            label: 'Full Name',
            value: profile?.displayName ?? '—',
            onTap: () => _soon(context, 'Editing name'),
          ),
          const Divider(color: AppColors.faint, height: 1),
          SettingRow(
            label: 'Username',
            value: profile?.username != null ? '@${profile!.username}' : '—',
            onTap: () => _soon(context, 'Editing username'),
          ),
          const Divider(color: AppColors.faint, height: 1),
          SettingRow(
            label: 'Email',
            value: profile?.email ?? '—',
            onTap: () => _soon(context, 'Editing email'),
          ),
          const SizedBox(height: 24),

          const SectionLabel(label: 'Preferences'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                    child: Text('Preferred Measurement Unit', style: AppTypography.headline)),
                _Segmented(
                  options: const ['METRIC', 'IMPERIAL'],
                  selectedIndex: units == PreferredUnits.metric ? 0 : 1,
                  onChanged: (i) => ref
                      .read(updateAccountSettingsProvider.notifier)
                      .setPreferredUnits(
                          i == 0 ? PreferredUnits.metric : PreferredUnits.imperial),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionLabel(label: 'Security'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: sending || profile == null
                ? null
                : () async {
                    final ok = await ref
                        .read(updateAccountSettingsProvider.notifier)
                        .sendChangePasswordEmail(profile.email);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'Password-reset link sent to ${profile.email}.'
                            : 'Could not send reset link. Try again later.')));
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('CHANGE PASSWORD',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented(
      {required this.options, required this.selectedIndex, required this.onChanged});

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.faint),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: i == selectedIndex ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(options[i],
                    style: AppTypography.caption2.copyWith(
                        color: i == selectedIndex ? AppColors.bg : AppColors.muted,
                        fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
