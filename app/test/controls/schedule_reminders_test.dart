import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/controls/schedule_reminders.dart';
import 'package:wise_workout/entities/planned_workout.dart';
import 'package:wise_workout/entities/workout_session.dart';

// (#) Tests planReminders, the rule-based reminder scheduler (US19-21).

// Wed 8 Jul 2026, 07:00 local.
final _now = DateTime(2026, 7, 8, 7);

// (#) Makes a planned workout on the given day of week.
PlannedWorkout _pw(int day, {String? name}) => PlannedWorkout(
      id: 'pw$day',
      fitnessPlanId: 'plan1',
      workoutTypeId: 'run',
      weekNumber: 1,
      dayOfWeek: day,
      durationMinutes: 40,
      name: name ?? 'Workout $day',
    );

// (#) Makes a one-hour workout session starting at the given hour.
WorkoutSession _session(DateTime start, {int hour = 18}) => WorkoutSession(
      id: 's${start.day}-$hour',
      userId: 'u1',
      workoutTypeId: 'run',
      startedAt: DateTime(start.year, start.month, start.day, hour),
      endedAt: DateTime(start.year, start.month, start.day, hour + 1),
    );

const _allOn = {
  'daily_reminder': true,
  'missed_workout': true,
  'inactivity_reminder': true,
  'rest_alert': true,
};

void main() {
  // (#) Daily plan-day nudges.
  group('daily_reminder (US19)', () {
    // (#) (+) Check if one nudge is scheduled per plan day, defaulting to 08:00 for Free.
    test('one nudge per plan day in the next week, Free at 08:00', () {
      // Wednesdays (3) and Fridays (5) are plan days.
      final plan = planReminders(
        prefs: const {'daily_reminder': true},
        isPremium: false,
        plannedWorkouts: [_pw(3), _pw(5)],
        sessions: const [],
        now: _now,
      );
      final daily = plan.where((r) => r.kind == 'daily_reminder').toList();
      expect(daily, hasLength(2)); // today (Wed) + Friday
      expect(daily.first.fireAt, DateTime(2026, 7, 8, 8)); // 08:00 default
      expect(daily.last.fireAt, DateTime(2026, 7, 10, 8));
    });

    // (#) (+) Check if Premium moves the nudge to the median of past session start hours.
    test('Premium adapts the hour to the median session start (adaptive)',
        () {
      final sessions = [
        _session(DateTime(2026, 7, 1), hour: 6),
        _session(DateTime(2026, 7, 2), hour: 19),
        _session(DateTime(2026, 7, 3), hour: 19),
      ];
      final plan = planReminders(
        prefs: const {'daily_reminder': true},
        isPremium: true,
        plannedWorkouts: [_pw(5)],
        sessions: sessions,
        now: _now,
      );
      expect(plan.single.fireAt.hour, 19); // median of 6, 19, 19
    });

    // (#) (-) Check if no nudge is scheduled for today once a session is already logged.
    test('no nudge today when a session is already logged (negative)', () {
      final plan = planReminders(
        prefs: const {'daily_reminder': true},
        isPremium: false,
        plannedWorkouts: [_pw(3)], // today is Wed=3
        sessions: [_session(DateTime(2026, 7, 8), hour: 6)],
        now: _now,
      );
      expect(plan.where((r) => r.kind == 'daily_reminder'), isEmpty);
    });

    // (#) (+) Check if a plan-day whose hour already passed still fires as a near-term late nudge.
    test('passed hour becomes a near-term late nudge', () {
      final plan = planReminders(
        prefs: const {'daily_reminder': true},
        isPremium: false,
        plannedWorkouts: [_pw(3)],
        sessions: const [],
        now: DateTime(2026, 7, 8, 12), // past 08:00, before 21:00
      );
      final nudge =
          plan.singleWhere((r) => r.kind == 'daily_reminder');
      expect(nudge.fireAt, DateTime(2026, 7, 8, 12, 2));
    });
  });

  // (#) Alerts for a missed plan day.
  group('missed_workout (US19)', () {
    // (#) (+) Check if a missed-workout alert fires when yesterday was a plan day with no session.
    test('fires when yesterday was a plan day with no session', () {
      final plan = planReminders(
        prefs: const {'missed_workout': true},
        isPremium: false,
        plannedWorkouts: [_pw(2, name: 'Tempo Run')], // Tue = yesterday
        sessions: const [],
        now: _now,
      );
      final missed = plan.singleWhere((r) => r.kind == 'missed_workout');
      expect(missed.body, contains('Tempo Run'));
      expect(missed.fireAt, DateTime(2026, 7, 8, 9));
    });

    // (#) (-) Check if no missed-workout alert fires when yesterday was actually trained.
    test('silent when yesterday was trained (negative)', () {
      final plan = planReminders(
        prefs: const {'missed_workout': true},
        isPremium: false,
        plannedWorkouts: [_pw(2)],
        sessions: [_session(DateTime(2026, 7, 7))],
        now: _now,
      );
      expect(plan.where((r) => r.kind == 'missed_workout'), isEmpty);
    });
  });

  // (#) Nudges after a stretch of inactivity.
  group('inactivity_reminder (US20)', () {
    // (#) (+) Check if the inactivity nudge fires 3 days after the last session at 10:00.
    test('fires 3 days after the last session at 10:00', () {
      final plan = planReminders(
        prefs: const {'inactivity_reminder': true},
        isPremium: false,
        plannedWorkouts: const [],
        sessions: [_session(DateTime(2026, 7, 6))],
        now: _now,
      );
      expect(plan.single.fireAt, DateTime(2026, 7, 9, 10));
    });

    // (#) (+) Check if an already-overdue inactivity alert is bumped to a near-term fire time.
    test('an overdue alert moves to a near-term fire', () {
      final plan = planReminders(
        prefs: const {'inactivity_reminder': true},
        isPremium: false,
        plannedWorkouts: const [],
        sessions: [_session(DateTime(2026, 7, 1))], // 7 days quiet
        now: _now,
      );
      expect(plan.single.fireAt, _now.add(const Duration(minutes: 2)));
    });
  });

  // (#) Premium-only recovery alerts after a heavy block.
  group('rest_alert (US21, Premium)', () {
    final heavyBlock = [
      _session(DateTime(2026, 7, 6)),
      _session(DateTime(2026, 7, 7)),
      _session(DateTime(2026, 7, 8), hour: 6),
    ];

    // (#) (+) Check if 3 sessions across 3 days triggers a recovery alert tomorrow at 08:00.
    test('3 sessions in 3 days → recovery alert tomorrow 08:00', () {
      final plan = planReminders(
        prefs: _allOn,
        isPremium: true,
        plannedWorkouts: const [],
        sessions: heavyBlock,
        now: _now,
      );
      final rest = plan.singleWhere((r) => r.kind == 'rest_alert');
      expect(rest.fireAt, DateTime(2026, 7, 9, 8));
    });

    // (#) (-) Check if a Free account never gets a rest alert even with the pref toggled on.
    test('Free never gets a rest alert even when toggled on (negative)', () {
      final plan = planReminders(
        prefs: _allOn,
        isPremium: false,
        plannedWorkouts: const [],
        sessions: heavyBlock,
        now: _now,
      );
      expect(plan.where((r) => r.kind == 'rest_alert'), isEmpty);
    });
  });

  // (#) (-) Check if empty/disabled prefs schedule no reminders at all.
  test('disabled prefs schedule nothing (negative)', () {
    final plan = planReminders(
      prefs: const {},
      isPremium: true,
      plannedWorkouts: [_pw(3)],
      sessions: [_session(DateTime(2026, 7, 1))],
      now: _now,
    );
    expect(plan, isEmpty);
  });
}
