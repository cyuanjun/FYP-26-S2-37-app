import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/controls/schedule_reminders.dart';
import 'package:wise_workout/entities/planned_workout.dart';
import 'package:wise_workout/entities/workout_session.dart';

// Wed 8 Jul 2026, 07:00 local.
final _now = DateTime(2026, 7, 8, 7);

PlannedWorkout _pw(int day, {String? name}) => PlannedWorkout(
      id: 'pw$day',
      fitnessPlanId: 'plan1',
      workoutTypeId: 'run',
      weekNumber: 1,
      dayOfWeek: day,
      durationMinutes: 40,
      name: name ?? 'Workout $day',
    );

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
  group('daily_reminder (US19)', () {
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

  group('missed_workout (US19)', () {
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

  group('inactivity_reminder (US20)', () {
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

  group('rest_alert (US21, Premium)', () {
    final heavyBlock = [
      _session(DateTime(2026, 7, 6)),
      _session(DateTime(2026, 7, 7)),
      _session(DateTime(2026, 7, 8), hour: 6),
    ];

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
