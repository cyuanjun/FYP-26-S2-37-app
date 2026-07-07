import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/update_avatar.dart';
import '../../../controls/view_profile.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../entities/fitness_profile.dart';
import '../common/stat_tile.dart';
import '../common/premium_cta.dart';
import '../premium/subscription_management_screen.dart';
import '../premium/upgrade_screen.dart';
import 'account_settings_screen.dart';
import 'fitness_goals_screen.dart';
import 'fitness_profile_screen.dart';
import 'notifications_screen.dart';
import 'profile_widgets.dart';
import 'submit_feedback_screen.dart';

/// BOUNDARY (#13 Profile). The account hub — identity, level/XP, headline
/// stats, and entry points to all account-level sub-screens. Reached from the
/// top-right avatar on tab landings; deliberately not a bottom-nav tab.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Gallery pick → UpdateAvatar control (resize keeps uploads small).
  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    try {
      await ref.read(updateAvatarProvider).call(bytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final fitness = ref.watch(fitnessProfileProvider).value;
    final stats = ref.watch(profileStatsProvider).value;

    final initial =
        (profile?.firstName?.isNotEmpty ?? false) ? profile!.firstName![0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('PROFILE', style: AppTypography.title1),
        actions: [
          if (!(profile?.isPremium ?? false))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: PremiumCta('GO PREMIUM',
                  onTap: () => _push(context, const UpgradeScreen()),
                  icon: Icons.star,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  style: AppTypography.caption2.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // ---- Identity block ----
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    image: profile?.avatarUrl == null
                        ? null
                        : DecorationImage(
                            image: NetworkImage(profile!.avatarUrl!),
                            fit: BoxFit.cover),
                  ),
                  alignment: Alignment.center,
                  child: profile?.avatarUrl != null
                      ? null
                      : Text(initial,
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _pickAvatar(context, ref),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 3),
                      ),
                      child: const Icon(Icons.edit, size: 12, color: AppColors.bg),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(profile?.displayName.toUpperCase() ?? '',
                style: AppTypography.title2.copyWith(fontWeight: FontWeight.w900)),
          ),
          if (profile?.username != null)
            Center(child: Text('@${profile!.username}', style: AppTypography.subheadline)),
          const SizedBox(height: 16),

          // ---- Level + XP bar ----
          if (fitness != null) _LevelBar(fitness: fitness),
          const SizedBox(height: 20),

          // ---- Stats row ----
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: AppColors.faint)),
            ),
            child: Row(
              children: [
                _stat('${stats?.workouts ?? '—'}', 'WORKOUTS'),
                _divider(),
                _stat('${stats?.activeDays ?? '—'}', 'ACTIVE DAYS'),
                _divider(),
                _stat('${fitness?.currentStreak ?? 0}w', 'STREAK'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---- Menu ----
          MenuRow(
              emoji: '⚙️',
              label: 'Account Settings',
              onTap: () => _push(context, const AccountSettingsScreen())),
          const Divider(color: AppColors.faint, height: 1),
          MenuRow(
              emoji: '💪',
              label: 'Fitness Profile',
              onTap: () => _push(context, const FitnessProfileScreen())),
          const Divider(color: AppColors.faint, height: 1),
          MenuRow(
              emoji: '🎯',
              label: 'Fitness Goals',
              onTap: () => _push(context, const FitnessGoalsScreen())),
          const Divider(color: AppColors.faint, height: 1),
          MenuRow(
              emoji: '🔔',
              label: 'Notifications',
              onTap: () => _push(context, const NotificationsScreen())),
          if (profile?.isPremium ?? false) ...[
            const Divider(color: AppColors.faint, height: 1),
            MenuRow(
                emoji: '⭐',
                label: 'Manage Subscription',
                onTap: () =>
                    _push(context, const SubscriptionManagementScreen())),
          ],
          const Divider(color: AppColors.faint, height: 1),
          MenuRow(
              emoji: '💬',
              label: 'Submit Feedback',
              onTap: () => _push(context, const SubmitFeedbackScreen())),
          const SizedBox(height: 24),

          // ---- Log out (outlined danger: reversible-ish) ----
          OutlinedButton(
            onPressed: () async {
              await ref.read(authenticateProvider.notifier).signOut();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: AppButtonStyles.outlinedDanger(height: 52, radius: 16),
            child: const Text('LOG OUT',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => StatTile(label, value,
      valueFirst: true,
      valueStyle: AppTypography.title1.copyWith(fontWeight: FontWeight.w900),
      labelStyle: AppTypography.caption2.copyWith(letterSpacing: 1.2));

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.faint);
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.fitness});

  final FitnessProfile fitness;

  @override
  Widget build(BuildContext context) {
    final progress = fitness.xpIntoLevel / FitnessProfile.xpPerLevel;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LEVEL ${fitness.level}',
                style: AppTypography.caption2
                    .copyWith(color: AppColors.muted, fontWeight: FontWeight.w800)),
            Text('${fitness.xpIntoLevel} / ${FitnessProfile.xpPerLevel} XP',
                style: AppTypography.caption2),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.success),
          ),
        ),
      ],
    );
  }
}
