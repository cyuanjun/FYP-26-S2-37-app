import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/seq_log.dart';

/// BOUNDARY (gateway) — wraps `flutter_local_notifications`. Controls hand it
/// absolute fire instants; it never decides *when* to remind (that rule logic
/// lives in ScheduleReminders). Local notifications only — FCM/push is a
/// later sprint.
class NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Workout, inactivity, and rest reminders',
      importance: Importance.defaultImportance,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
    ),
  );

  Future<void> _ensureInit() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    // The plugin schedules off the TZDateTime's wall-clock components, so
    // tz.local must be the device's real IANA zone (UTC instants misfire).
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      // Keep the tz default (UTC) if the platform lookup fails.
      SeqLog.msg('schedule-reminders', 'NotificationGateway', 'tz',
          'zone lookup failed: $e');
    }
    SeqLog.msg('schedule-reminders', 'NotificationGateway', 'tz',
        'local=${tz.local.name}');
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permission is requested explicitly via requestPermission().
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// One-time OS permission prompt; returns whether notifications are allowed.
  Future<bool> requestPermission() async {
    await _ensureInit();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
      SeqLog.msg(
          'schedule-reminders', 'NotificationGateway', 'OS', 'granted=$granted');
      return granted;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// One-shot notification at an absolute local instant, expressed in the
  /// device's zone (see _ensureInit). Inexact Android mode avoids the
  /// exact-alarm permission.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await _ensureInit();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await _ensureInit();
    await _plugin.cancelAll();
  }

  /// How many notifications the OS currently holds for us (verification aid).
  Future<int> pendingCount() async {
    await _ensureInit();
    return (await _plugin.pendingNotificationRequests()).length;
  }
}

final notificationGatewayProvider =
    Provider<NotificationGateway>((ref) => NotificationGateway());
