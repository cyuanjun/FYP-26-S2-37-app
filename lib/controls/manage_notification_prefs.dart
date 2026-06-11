import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/profile_gateway.dart';
import '../core/seq_log.dart';
import 'authenticate.dart';

/// The notification-type catalog (#13.4). Keys are stored in
/// profiles.notification_prefs (jsonb: key -> bool); labels are UI strings.
/// Defaults: workout/summary/social on, marketing off.
const notificationDefaults = <String, bool>{
  'daily_reminder': true,
  'missed_workout': true,
  'inactivity_reminder': true,
  'weekly_summary': true,
  'friend_activity': true,
  'likes_comments': true,
  'challenge_invites': true,
  'product_tips': false,
  'app_updates': false,
  'promotions': false,
};

/// CONTROL — Manage Notification Preferences (#13.4). Each toggle flip commits
/// immediately (optimistic local state, whole-map jsonb write).
class ManageNotificationPrefs extends AsyncNotifier<Map<String, bool>> {
  @override
  Future<Map<String, bool>> build() async {
    final profile = await ref.watch(currentProfileProvider.future);
    final stored = profile?.notificationPrefs ?? const <String, dynamic>{};
    return {
      for (final e in notificationDefaults.entries)
        e.key: stored[e.key] is bool ? stored[e.key] as bool : e.value,
    };
  }

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

final notificationPrefsProvider =
    AsyncNotifierProvider<ManageNotificationPrefs, Map<String, bool>>(
        ManageNotificationPrefs.new);
