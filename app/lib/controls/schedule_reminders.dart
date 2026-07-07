import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/notification_gateway.dart';
import '../core/seq_log.dart';
import '../entities/planned_workout.dart';
import '../entities/workout_session.dart';
import 'authenticate.dart';
import 'generate_plan.dart';
import 'manage_notification_prefs.dart';
import 'workout_history.dart';

/// CONTROL — Schedule Reminders (US19–US21). RULE-BASED by design (SRS §3.9:
/// reminders/inactivity/rest alerts are not AI). A sync recomputes the next
/// 7 days of one-shot local notifications from the user's prefs, plan, and
/// recent history, then replaces whatever the OS was holding.
///
/// Rules:
/// - `daily_reminder` (US19): a nudge on each plan day at the reminder hour —
///   Free at 08:00; Premium adapts to the user's median session start hour.
///   If today's hour already passed with no session yet, a late nudge fires
///   in a couple of minutes (evening cutoff 21:00).
/// - `missed_workout` (US19): if yesterday was a plan day with no session,
///   one catch-up nudge tomorrow-morning-at-09:00.
/// - `inactivity_reminder` (US20): one alert 3 days after the last session
///   (at 10:00), or 3 days from now when there's no history yet.
/// - `rest_alert` (US21, Premium): if the last 3 days hold 3+ sessions, a
///   recovery suggestion at 08:00 tomorrow.

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.fireAt,
  });

  final int id;
  final String kind;
  final String title;
  final String body;
  final DateTime fireAt;
}

/// Days without a session before the inactivity alert fires (US20).
const inactivityThresholdDays = 3;

/// Sessions within [restWindowDays] that trigger the rest alert (US21).
const restAlertSessionCount = 3;
const restWindowDays = 3;

/// The pure rule engine — deterministic given `now`, so fully testable.
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

/// What the last sync scheduled — #13.4 renders this as its UPCOMING list.
class ScheduledReminders extends Notifier<List<PlannedReminder>> {
  @override
  List<PlannedReminder> build() => const [];

  void set(List<PlannedReminder> value) => state = value;
}

final scheduledRemindersProvider =
    NotifierProvider<ScheduledReminders, List<PlannedReminder>>(
        ScheduledReminders.new);

class SyncReminders {
  SyncReminders(this._ref);

  final Ref _ref;

  /// Recomputes and replaces all scheduled local notifications. Safe to call
  /// often — same inputs produce the same schedule (stable ids overwrite).
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
}

final syncRemindersProvider = Provider<SyncReminders>(SyncReminders.new);
