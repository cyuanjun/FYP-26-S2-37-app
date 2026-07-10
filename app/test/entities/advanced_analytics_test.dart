import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/advanced_analytics.dart';
import 'package:wise_workout/entities/workout_session.dart';

// Wed 8 Jul 2026 noon.
final _now = DateTime(2026, 7, 8, 12);

// (#) Builds a fake workout session for feeding the analytics maths.
WorkoutSession _session(DateTime start,
        {int minutes = 60, int? avgHr, int? distanceMeters, int? calories}) =>
    WorkoutSession(
      id: 's${start.millisecondsSinceEpoch}-$minutes-${avgHr ?? 0}',
      userId: 'u1',
      workoutTypeId: 'run',
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      durationSeconds: minutes * 60,
      avgHeartRate: avgHr,
      distanceMeters: distanceMeters,
      caloriesBurned: calories,
    );

// (#) Tests the advanced analytics maths: session load, ACWR, weekly buckets, HR zones, personal bests.
void main() {
  // (#) Group covering the per-session training load score.
  group('sessionLoad', () {
    // (#) (+) Check if an hour of moderate effort with no HR scores a flat 5.
    test('an hour at moderate effort (no HR) scores 5', () {
      expect(sessionLoad(_session(_now, minutes: 60)), 5.0);
    });

    // (#) (+) Check if a higher heart rate raises the load score via Karvonen.
    test('higher HR intensity raises the score (Karvonen)', () {
      // rest 60, max 190 (age 30): hr=190 → HRR 1.0 → intensity 1.5.
      final hard = sessionLoad(_session(_now, minutes: 60, avgHr: 190));
      expect(hard, 7.5);
    });

    // (#) (-) Check if the score is clamped at the 1 floor and 10 ceiling.
    test('clamped to 1–10', () {
      expect(sessionLoad(_session(_now, minutes: 5)), 1.0); // floor
      expect(sessionLoad(_session(_now, minutes: 600, avgHr: 190)), 10.0);
    });
  });

  // (#) Group covering the acute-to-chronic workload ratio.
  group('computeAcwr', () {
    // (#) (-) Check if too little history reports the not-enough state.
    test('thin history yields the not-enough state (negative)', () {
      final acwr = computeAcwr([_session(_now.subtract(const Duration(days: 1)), minutes: 20)],
          now: _now);
      expect(acwr.hasEnoughHistory, isFalse);
    });

    // (#) (+) Check if steady daily training gives a ratio of 1.0 in the sustainable band.
    test('steady training lands in the sustainable band', () {
      // One 60-min moderate session per day for 28 days: acute 7×5=35,
      // chronic (28×5)/4=35 → ratio 1.0.
      final sessions = [
        for (var i = 0; i < 28; i++)
          _session(_now.subtract(Duration(days: i, hours: 1))),
      ];
      final acwr = computeAcwr(sessions, now: _now);
      expect(acwr.ratio, closeTo(1.0, 0.01));
      expect(acwr.band, AcwrBand.sustainable);
    });

    // (#) (+) Check if a sudden training spike is classed as overreaching.
    test('an acute spike lands in overreaching', () {
      // Weeks 2–4: one light session/week; week 1: daily long sessions.
      final sessions = [
        for (var i = 0; i < 7; i++)
          _session(_now.subtract(Duration(days: i, hours: 1)), minutes: 90),
        _session(_now.subtract(const Duration(days: 10)), minutes: 30),
        _session(_now.subtract(const Duration(days: 17)), minutes: 30),
        _session(_now.subtract(const Duration(days: 24)), minutes: 30),
      ];
      final acwr = computeAcwr(sessions, now: _now);
      expect(acwr.band, AcwrBand.overreaching);
    });
  });

  // (#) Group covering the per-week aggregation buckets.
  group('weeklyBuckets', () {
    // (#) (-) Check if weeks with no sessions are zero-filled so the chart has no gaps.
    test('zero-fills empty weeks so the chart is honest', () {
      final sessions = [
        _session(DateTime(2026, 7, 6, 8)), // this week (Mon)
        _session(DateTime(2026, 6, 15, 8)), // three weeks earlier
      ];
      final buckets = weeklyBuckets(sessions, now: _now, weeks: 4);
      expect(buckets, hasLength(4));
      expect(buckets.map((b) => b.sessions), [1, 0, 0, 1]);
      expect(buckets.first.weekStart, DateTime(2026, 6, 15));
    });

    // (#) (+) Check if minutes, calories, and average HR are summed per week.
    test('aggregates minutes, calories, and avg HR per week', () {
      final sessions = [
        _session(DateTime(2026, 7, 6, 8),
            minutes: 30, avgHr: 120, calories: 200),
        _session(DateTime(2026, 7, 7, 8),
            minutes: 60, avgHr: 140, calories: 400),
      ];
      final wk = weeklyBuckets(sessions, now: _now, weeks: 1).single;
      expect(wk.activeMinutes, 90);
      expect(wk.calories, 600);
      expect(wk.avgHr, 130);
    });
  });

  // (#) (+) Check if a load jump over 50% week-over-week is flagged as a spike.
  test('hasAcuteSpike flags a >50% week-over-week load jump', () {
    final calm = weeklyBuckets(
        [
          _session(DateTime(2026, 6, 29, 8)),
          _session(DateTime(2026, 7, 6, 8)),
        ],
        now: _now,
        weeks: 2);
    expect(hasAcuteSpike(calm), isFalse);

    final spiked = weeklyBuckets(
        [
          _session(DateTime(2026, 6, 29, 8), minutes: 30),
          _session(DateTime(2026, 7, 6, 8), minutes: 60),
          _session(DateTime(2026, 7, 7, 8), minutes: 60),
        ],
        now: _now,
        weeks: 2);
    expect(hasAcuteSpike(spiked), isTrue);
  });

  // (#) Group covering the heart-rate zone distribution.
  group('computeHrZones', () {
    // (#) (+) Check if sessions are bucketed into HR zones and sub-Z1 time is excluded.
    test('buckets whole sessions by avg HR and excludes sub-Z1 time', () {
      // rest 60 / max 190: HRR 0.5+0.1z boundaries → 125 ≈ Z1, 151 ≈ Z3.
      final zones = computeHrZones([
        _session(_now, minutes: 30, avgHr: 126), // ~50.8% HRR → Z1
        _session(_now, minutes: 30, avgHr: 152), // ~70.8% HRR → Z3
        _session(_now, minutes: 60, avgHr: 100), // ~30% HRR → excluded
      ]);
      expect(zones[0], closeTo(0.5, 0.01));
      expect(zones[2], closeTo(0.5, 0.01));
      expect(zones[1] + zones[3] + zones[4], 0);
    });

    // (#) (-) Check if sessions with no HR data give all-zero zone shares.
    test('no HR data at all yields all-zero shares (negative)', () {
      expect(computeHrZones([_session(_now, minutes: 30)]),
          everyElement(0));
    });
  });

  // (#) Group covering the personal-best records.
  group('computePersonalBests', () {
    // (#) (+) Check if longest distance, fastest pace, longest session, and day streak are found.
    test('finds distance, pace, duration, and day-streak bests', () {
      final bests = computePersonalBests([
        _session(DateTime(2026, 7, 1, 8),
            minutes: 60, distanceMeters: 12000), // longest distance
        _session(DateTime(2026, 7, 2, 8),
            minutes: 20, distanceMeters: 4000), // fastest pace (5:00/km)
        _session(DateTime(2026, 7, 3, 8), minutes: 95), // longest session
      ]);
      expect(bests.longestDistance!.value, '12.00 km');
      expect(bests.fastestPace!.value, '5:00 /km');
      expect(bests.longestSession!.value, '95 min');
      expect(bests.longestStreakDays, 3); // 1–3 Jul consecutive
    });

    // (#) (-) Check if an empty history gives null bests and a zero streak.
    test('empty history yields dashes-and-zero (negative)', () {
      final bests = computePersonalBests(const []);
      expect(bests.longestDistance, isNull);
      expect(bests.fastestPace, isNull);
      expect(bests.longestStreakDays, 0);
    });
  });
}
