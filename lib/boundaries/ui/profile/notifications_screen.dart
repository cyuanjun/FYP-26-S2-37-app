import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_notification_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'profile_widgets.dart';

/// Display catalog for #13.4 — UI strings only; keys live in
/// profiles.notification_prefs (see manage_notification_prefs.dart).
const _sections = <(String, List<(String, String, String)>)>[
  (
    'Workout Reminders',
    [
      ('daily_reminder', 'Daily reminder', 'Nudge me at my preferred time'),
      ('missed_workout', 'Missed workout', 'When a planned workout slips by'),
      ('inactivity_reminder', 'Inactivity reminder', 'After a few quiet days'),
    ]
  ),
  (
    'Summaries',
    [
      ('weekly_summary', 'Weekly summary', 'Your week in numbers, every Monday'),
    ]
  ),
  (
    'Social',
    [
      ('friend_activity', 'Friend activity', 'When friends finish workouts'),
      ('likes_comments', 'Likes & comments', 'Reactions to your posts'),
      ('challenge_invites', 'Challenge invites', 'When someone invites you'),
    ]
  ),
  (
    'Marketing & Updates',
    [
      ('product_tips', 'Product tips', 'Get more out of Wise Workout'),
      ('app_updates', 'App updates', "What's new in each release"),
      ('promotions', 'Promotions', 'Offers and discounts'),
    ]
  ),
];

/// BOUNDARY (#13.4 Notifications). Per-type toggles; every flip commits
/// immediately — no save button.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text('NOTIFICATIONS',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.ink)),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Could not load preferences.', style: AppTypography.subheadline)),
        data: (prefs) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final (sectionLabel, rows) in _sections) ...[
              SectionLabel(label: sectionLabel),
              for (final (key, label, description) in rows) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: AppTypography.headline),
                            const SizedBox(height: 2),
                            Text(description, style: AppTypography.subheadline),
                          ],
                        ),
                      ),
                      Switch(
                        value: prefs[key] ?? false,
                        activeThumbColor: AppColors.bg,
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: AppColors.surface2,
                        onChanged: (on) => ref
                            .read(notificationPrefsProvider.notifier)
                            .setEnabled(key, on),
                      ),
                    ],
                  ),
                ),
                if (rows.last.$1 != key)
                  const Divider(color: AppColors.faint, height: 1),
              ],
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
