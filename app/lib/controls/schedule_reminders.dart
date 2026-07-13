import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/notification_gateway.dart';
import '../core/seq_log.dart';
import '../entities/planned_workout.dart';
import '../entities/workout_session.dart';
import 'authenticate.dart';
import 'generate_plan.dart';
import 'manage_notification_prefs.dart';
import 'workout_history.dart';

// (#) The Schedule Reminders feature (US19 to US21). These are rule-based, not AI:
// (#) a sync works out the next 7 days of local notifications from the user's prefs,
// (#) plan, and recent history, then swaps out whatever the phone had queued.
// (#) Four rules exist: daily plan-day nudge (Premium adapts the hour), missed-workout
// (#) catch-up, 3-day inactivity alert, and a Premium rest alert when training a lot.

// (#) One reminder the engine decided to schedule: its id, kind, text, and fire time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.fireAt,
  });

  final int id; // (#) stable id so a re-sync overwrites the same slot instead of piling up
  final String kind; // (#) which rule made it (daily_reminder, missed_workout, etc.)
  final String title; // (#) notification headline
  final String body; // (#) notification message
  final DateTime fireAt; // (#) when it should pop
}

// (#) How many days without a workout before the inactivity alert fires (US20).
const inactivityThresholdDays = 3;

// (#) The rest alert (US21) triggers when this many sessions land inside the window.
const restAlertSessionCount = 3;
const restWindowDays = 3; // (#) size of the recent-training window checked for the rest alert

// (#) The pure rule engine. Given now plus the inputs it always returns the same
// (#) list, no side effects, which makes it easy to unit test.
List<PlannedReminder> planReminders({
  required Map<String, bool> prefs,
  required bool isPremium,
  required List<PlannedWorkout> plannedWorkouts,
  required List<WorkoutSession> sessions,
  required DateTime now,
}) {
  final out = <PlannedReminder>[];
  final today = DateTime(now.year, now.month, now.day);
  final ended = sessions.where((s) => s.isEnded).toList();

  bool sessionOn(DateTime day) => ended.any((s) {
        final local = s.startedAt.toLocal();
        return DateTime(local.year, local.month, local.day) == day;
      });

  // Plan days as a weekly pattern (1=Mon … 7=Sun), union across weeks.
  final byDay = <int, PlannedWorkout>{};
  for (final w in plannedWorkouts) {
    byDay.putIfAbsent(w.dayOfWeek, () => w);
  }

  // Premium adaptive hour: the median local start hour of recent sessions.
  var reminderHour = 8;
  if (isPremium && ended.isNotEmpty) {
    final hours = ended.map((s) => s.startedAt.toLocal().hour).toList()
      ..sort();
    reminderHour = hours[hours.length ~/ 2];
  }

  if (prefs['daily_reminder'] ?? false) {
    for (var i = 0; i < 7; i++) {
      final day = today.add(Duration(days: i));
      final workout = byDay[day.weekday];
      if (workout == null) continue;
      final name = workout.name ?? 'your planned workout';
      var fireAt =
          DateTime(day.year, day.month, day.day, reminderHour);
      if (i == 0) {
        if (sessionOn(today)) continue; // already trained today
        if (!fireAt.isAfter(now)) {
          if (now.hour >= 21) continue; // too late for a nudge
          fireAt = now.add(const Duration(minutes: 2));
        }
      }
      out.add(PlannedReminder(
        id: 100 + i,
        kind: 'daily_reminder',
        title: 'Workout day 💪',
        body: '$name is on your plan today — ${workout.durationMinutes} min.',
        fireAt: fireAt,
      ));
    }
  }

  if (prefs['missed_workout'] ?? false) {
    final yesterday = today.subtract(const Duration(days: 1));
    final missed = byDay[yesterday.weekday];
    if (missed != null && !sessionOn(yesterday)) {
      out.add(PlannedReminder(
        id: 120,
        kind: 'missed_workout',
        title: 'Missed workout',
        body:
            "Yesterday's ${missed.name ?? 'workout'} slipped by — squeeze it in today?",
        fireAt: DateTime(today.year, today.month, today.day, 9)
                .isAfter(now)
            ? DateTime(today.year, today.month, today.day, 9)
            : now.add(const Duration(minutes: 3)),
      ));
    }
  }

  if (prefs['inactivity_reminder'] ?? false) {
    final last = ended.isEmpty
        ? null
        : ended
            .map((s) => s.startedAt.toLocal())
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final base = last ?? now;
    var fireAt = DateTime(base.year, base.month, base.day, 10)
        .add(const Duration(days: inactivityThresholdDays));
    if (!fireAt.isAfter(now)) {
      fireAt = now.add(const Duration(minutes: 2)); // already overdue
    }
    out.add(PlannedReminder(
      id: 130,
      kind: 'inactivity_reminder',
      title: 'Still with us? 🏃',
      body:
          "It's been $inactivityThresholdDays days since your last workout — even a short walk counts.",
      fireAt: fireAt,
    ));
  }

  if (isPremium && (prefs['rest_alert'] ?? false)) {
    final windowStart = today.subtract(const Duration(days: restWindowDays - 1));
    final recent = ended.where((s) {
      final local = s.startedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      return !day.isBefore(windowStart);
    }).length;
    if (recent >= restAlertSessionCount) {
      final tomorrow = today.add(const Duration(days: 1));
      out.add(PlannedReminder(
        id: 140,
        kind: 'rest_alert',
        title: 'Recovery matters 😴',
        body:
            '$recent sessions in $restWindowDays days — consider making tomorrow a rest day.',
        fireAt: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8),
      ));
    }
  }

  out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return out;
}

// (#) Holds whatever the last sync scheduled so the #13.4 screen can show it as
// (#) an UPCOMING list. Starts empty and gets set after each sync.
class ScheduledReminders extends Notifier<List<PlannedReminder>> {
  // (#) Starts with no reminders known.
  @override
  List<PlannedReminder> build() => const [];

  // (#) Replaces the stored list with the newest sync result.
  void set(List<PlannedReminder> value) => state = value;
}

// (#) Provider the UI watches to read the current UPCOMING reminder list.
final scheduledRemindersProvider =
    NotifierProvider<ScheduledReminders, List<PlannedReminder>>(
        ScheduledReminders.new);

// (#) The Sync Reminders use case. Reads the user's prefs, plan, and history, runs
// (#) the rule engine for the coming week, then tells the notification gateway to
// (#) cancel everything and re-schedule the fresh set.
class SyncReminders {
  SyncReminders(this._ref);

  final Ref _ref; // (#) handle to read the other providers and the gateway

  // (#) Recomputes and re-installs all local notifications. Cheap to call repeatedly
  // (#) since stable ids mean the same schedule just overwrites itself.
  Future<void> call() async {
    final profile = await _ref.read(currentProfileProvider.future);
    if (profile == null || profile.isExpert) return;
    final prefs = await _ref.read(notificationPrefsProvider.future);
    final workouts = await _ref.read(plannedWorkoutsProvider.future);
    final sessions = await _ref.read(historyProvider.future);

    final plan = planReminders(
      prefs: prefs,
      isPremium: profile.isPremium,
      plannedWorkouts: workouts,
      sessions: sessions,
      now: DateTime.now(),
    );

    SeqLog.msg('schedule-reminders', 'SyncReminders', 'NotificationGateway',
        'cancelAll + schedule ${plan.length}');
    final gateway = _ref.read(notificationGatewayProvider);
    await gateway.cancelAll();
    for (final r in plan) {
      await gateway.scheduleAt(
          id: r.id, title: r.title, body: r.body, when: r.fireAt);
    }
    SeqLog.msg('schedule-reminders', 'NotificationGateway', 'OS',
        'pending=${await gateway.pendingCount()}');
    _ref.read(scheduledRemindersProvider.notifier).set(plan);
  }

  // (#) Asks the OS for notification permission, through the gateway.
  Future<void> requestPermission() =>
      _ref.read(notificationGatewayProvider).requestPermission();
}

// (#) Provider the shell and #13.4 toggles use to trigger a re-sync.
final syncRemindersProvider = Provider<SyncReminders>(SyncReminders.new);
