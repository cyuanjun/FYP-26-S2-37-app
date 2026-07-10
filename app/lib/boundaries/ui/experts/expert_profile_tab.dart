import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/authenticate.dart';
import '../../../controls/browse_experts.dart';
import '../../../core/theme/app_buttons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import '../common/stat_tile.dart';
import '../common/status_badge.dart';
import '../profile/account_settings_screen.dart';
import '../profile/profile_widgets.dart';
import '../profile/submit_feedback_screen.dart';
import 'professional_info_screen.dart';

// (#) The expert's own profile tab. Shows what clients see plus account actions. Editing pro info,
// (#) settings and log out each open a screen or call a control.
class ExpertProfileTab extends ConsumerWidget {
  const ExpertProfileTab({super.key});

  // (#) Reads the expert's own summary and lays out avatar, stats, about, credentials, menu rows and log out.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserIdProvider);
    final summary =
        me == null ? null : ref.watch(expertSummaryProvider(me)).value;
    final identity = summary?.identity;
    final profile = summary?.profile;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('PROFILE', style: AppTypography.title1),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Column(
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
                child: Text(identity?.initials ?? '?',
                    style: const TextStyle(
                        color: AppColors.bg,
                        fontWeight: FontWeight.w800,
                        fontSize: 34)),
              ),
              const SizedBox(height: 10),
              Text(identity?.displayName ?? 'Expert',
                  style: AppTypography.title2),
              const SizedBox(height: 4),
              Text(
                  '${profile?.title ?? ''} · '
                  '${profile?.yearsCoaching ?? 0} yrs coaching',
                  style: AppTypography.caption2),
              const SizedBox(height: 8),
              if (profile?.isVerified ?? false)
                const StatusBadge('✓ VERIFIED EXPERT',
                    bg: AppColors.successBright, fg: AppColors.ink)
              else
                const StatusBadge('VERIFICATION PENDING',
                    borderColor: AppColors.faint),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                StatTile('RATING', '★ ${profile?.ratingAvg ?? '—'}',
                    valueFirst: true),
                StatTile('REVIEWS', '${profile?.reviewCount ?? '—'}',
                    valueFirst: true),
                StatTile('CLIENTS', '${profile?.clientCount ?? '—'}',
                    valueFirst: true),
                StatTile('EARNED', profile?.earnedLabel ?? '—',
                    valueFirst: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if ((profile?.about ?? '').isNotEmpty) ...[
            Text('ABOUT', style: AppTypography.caption2),
            const SizedBox(height: 8),
            Text(profile!.about,
                style: AppTypography.body.copyWith(height: 1.4)),
            const SizedBox(height: 20),
          ],
          if ((profile?.credentials ?? []).isNotEmpty) ...[
            Text('CREDENTIALS', style: AppTypography.caption2),
            const SizedBox(height: 8),
            for (final c in profile!.credentials)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: AppTypography.footnote)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
          ],
          if ((profile?.specialties ?? []).isNotEmpty) ...[
            Text('SPECIALTIES', style: AppTypography.caption2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in profile!.specialties)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.faint),
                    ),
                    child: Text(s[0].toUpperCase() + s.substring(1),
                        style: AppTypography.caption2),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (profile != null) ...[
            MenuRow(
                emoji: '🧾',
                label: 'Manage Professional Info',
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            ProfessionalInfoScreen(profile: profile)))),
            const Divider(color: AppColors.faint, height: 1),
          ],
          MenuRow(
              emoji: '⚙️',
              label: 'Account Settings',
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen()))),
          const Divider(color: AppColors.faint, height: 1),
          MenuRow(
              emoji: '💬',
              label: 'Submit Feedback',
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => const SubmitFeedbackScreen()))),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authenticateProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            style: AppButtonStyles.outlinedDanger(height: 52, radius: 16),
            child: const Text('LOG OUT',
                style:
                    TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }
}
