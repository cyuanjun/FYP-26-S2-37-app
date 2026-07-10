import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controls/manage_notification_prefs.dart';
import '../../../controls/schedule_reminders.dart';
import '../../../core/format.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'profile_widgets.dart';

// (#) The list of notification toggles grouped into sections. Just the display
// text and keys, the actual saved values live in profiles.notification_prefs.
const _sections = <(String, List<(String, String, String)>)>[
  (
    'Workout Reminders',
    [
      ('daily_reminder', 'Daily reminder', 'Nudge me at my preferred time'),
      ('missed_workout', 'Missed workout', 'When a planned workout slips by'),
      ('inactivity_reminder', 'Inactivity reminder', 'After a few quiet days'),
      ('rest_alert', 'Rest alert', 'After heavy training blocks (Premium)'),
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

// (#) The toggle keys that, when flipped, need the reminder schedule redone.
const _schedulingKeys = {
  'daily_reminder',
  'missed_workout',
  'inactivity_reminder',
  'rest_alert',
};

// (#) Notification settings screen. One switch per notification type, each flip
// saves straight away, and flipping a reminder type re-runs the scheduling
// control. The Upcoming strip shows what was last scheduled.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  // (#) Builds the screen: the Upcoming strip on top, then a switch row for
  // every notification type grouped by section.
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
            _UpcomingStrip(),
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
                        onChanged: (on) async {
                          await ref
                              .read(notificationPrefsProvider.notifier)
                              .setEnabled(key, on);
                          if (_schedulingKeys.contains(key)) {
                            // Re-plan the local notifications to match.
                            await ref.read(syncRemindersProvider).call();
                          }
                        },
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

// (#) The Upcoming strip: lists the next few reminders the last sync scheduled,
// each with its relative day and time.
class _UpcomingStrip extends ConsumerWidget {
  // (#) Builds the strip, or nothing when there's nothing scheduled.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(scheduledRemindersProvider);
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Upcoming'),
          for (final r in upcoming.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(r.title, style: AppTypography.footnote)),
                  Text(
                      '${relativeDay(r.fireAt)} · '
                      '${r.fireAt.hour.toString().padLeft(2, '0')}:'
                      '${r.fireAt.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.caption2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
