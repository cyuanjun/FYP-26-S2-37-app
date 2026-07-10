import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/seq_log.dart';

// (#) Wraps the phone's local-notifications plugin. Controls use it to ask for
// (#) permission and to put a reminder on the clock for a set time. It never
// (#) decides when to fire, the ScheduleReminders control does that.
class NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin(); // (#) the OS notification plugin
  bool _initialized = false; // (#) tracks whether first-time setup has run

  // (#) The look of our reminders on Android and iOS, reused for every one.
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

  // (#) Runs the plugin's one-time setup, including finding the device time zone
  // (#) so scheduled reminders fire at the right wall-clock moment.
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

  // (#) Asks the OS for notification permission and reports whether it was granted.
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

  // (#) Books one reminder to show at the given local time. Uses Android's
  // (#) inexact mode so it doesn't need the special exact-alarm permission.
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

  // (#) Wipes every scheduled reminder, used before re-scheduling from scratch.
  Future<void> cancelAll() async {
    await _ensureInit();
    await _plugin.cancelAll();
  }

  // (#) Counts how many reminders the OS is still holding, handy for testing.
  Future<int> pendingCount() async {
    await _ensureInit();
    return (await _plugin.pendingNotificationRequests()).length;
  }
}

// (#) Riverpod provider handing out a single notification gateway.
final notificationGatewayProvider =
    Provider<NotificationGateway>((ref) => NotificationGateway());
