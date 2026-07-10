import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import 'authenticate.dart';

// (#) The default on/off for every notification type. Keys are saved in the
// (#) profile's notification_prefs jsonb; workout/summary/social default on and
// (#) marketing defaults off.
const notificationDefaults = <String, bool>{
  'daily_reminder': true,
  'missed_workout': true,
  'inactivity_reminder': true,
  'rest_alert': true, // Premium-only at schedule time (US21)
  'weekly_summary': true,
  'friend_activity': true,
  'likes_comments': true,
  'challenge_invites': true,
  'product_tips': false,
  'app_updates': false,
  'promotions': false,
};

// (#) Handles the notification toggles. Each flip updates local state right away
// (#) (so it renders instantly) and writes the whole prefs map through the gateway,
// (#) rolling the flip back if the save fails.
class ManageNotificationPrefs extends AsyncNotifier<Map<String, bool>> {
  // (#) Loads the current prefs: starts from the defaults, overlaying any stored
  // (#) values from the profile.
  @override
  Future<Map<String, bool>> build() async {
    final profile = await ref.watch(currentProfileProvider.future);
    final stored = profile?.notificationPrefs ?? const <String, dynamic>{};
    return {
      for (final e in notificationDefaults.entries)
        e.key: stored[e.key] is bool ? stored[e.key] as bool : e.value,
    };
  }

  // (#) Turns one notification type on or off: flips local state first, then saves
  // (#) the whole map; restores the old state and rethrows if the save fails.
  Future<void> setEnabled(String typeKey, bool enabled) async {
    final userId = ref.read(currentUserIdProvider);
    final current = state.value;
    if (userId == null || current == null) return;
    SeqLog.msg('notification-prefs', 'NotificationsScreen', 'ManageNotificationPrefs',
        'setEnabled($typeKey, $enabled)');
    final next = {...current, typeKey: enabled};
    state = AsyncData(next); // optimistic — flips render instantly
    try {
      SeqLog.msg('notification-prefs', 'ManageNotificationPrefs', 'ProfileGateway',
          'updateNotificationPrefs');
      await ref.read(profileGatewayProvider).updateNotificationPrefs(userId, next);
    } catch (_) {
      state = AsyncData(current); // roll back on failure
      rethrow;
    }
  }
}

// (#) Hands the notifications screen the control and the current prefs map.
final notificationPrefsProvider =
    AsyncNotifierProvider<ManageNotificationPrefs, Map<String, bool>>(
        ManageNotificationPrefs.new);
