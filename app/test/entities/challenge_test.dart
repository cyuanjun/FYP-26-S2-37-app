import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/challenge.dart';
import 'package:wise_workout/entities/challenge_summary.dart';
import 'package:wise_workout/entities/enums.dart';

Challenge _challenge({
  ChallengeMetricKind kind = ChallengeMetricKind.accumulator,
  ChallengeMetric metric = ChallengeMetric.totalSessions,
  int? target = 20,
  DateTime? start,
  DateTime? end,
}) {
  return Challenge(
    id: 'c1',
    name: 'Test',
    shortName: 'TEST',
    icon: '⚡',
    metricKind: kind,
    metric: metric,
    targetValue: target,
    startedAt: start ?? DateTime(2026, 7, 1),
    endedAt: end ?? DateTime(2026, 7, 30),
  );
}

void main() {
  group('Challenge window rules', () {
    final c = _challenge(start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 30));

    test('isActive inside the window, isPast at/after endedAt (boundaries)', () {
      expect(c.isActive(DateTime(2026, 6, 30)), isFalse); // before start
      expect(c.isActive(DateTime(2026, 7, 1)), isTrue); // inclusive start
      expect(c.isActive(DateTime(2026, 7, 15)), isTrue);
      expect(c.isActive(DateTime(2026, 7, 30)), isFalse); // exclusive end
      expect(c.isPast(DateTime(2026, 7, 30)), isTrue);
      expect(c.isPast(DateTime(2026, 7, 29)), isFalse);
    });

    test('dayXofY clamps before start and after end', () {
      expect(c.dayXofY(DateTime(2026, 6, 20)), (1, 30));
      expect(c.dayXofY(DateTime(2026, 7, 1)), (1, 30));
      expect(c.dayXofY(DateTime(2026, 7, 15)), (15, 30));
      expect(c.dayXofY(DateTime(2026, 8, 9)), (30, 30));
    });
  });

  group('Challenge metric rules', () {
    test('metricsFor partitions the 7 metrics 4/3 with no overlap', () {
      final acc = Challenge.metricsFor(ChallengeMetricKind.accumulator);
      final best = Challenge.metricsFor(ChallengeMetricKind.bestOf);
      expect(acc, hasLength(4));
      expect(best, hasLength(3));
      expect({...acc, ...best}, hasLength(7));
    });

    test('lowerWins only for fastestTime', () {
      expect(_challenge(metric: ChallengeMetric.fastestTime).lowerWins, isTrue);
      expect(
          _challenge(metric: ChallengeMetric.totalDistance).lowerWins, isFalse);
    });

    test('formatValue renders per metric (m→km, s→mm:ss, counts)', () {
      expect(
          _challenge(metric: ChallengeMetric.totalDistance).formatValue(18400),
          '18.40 km');
      expect(_challenge(metric: ChallengeMetric.fastestTime).formatValue(1920),
          '32:00');
      expect(_challenge(metric: ChallengeMetric.totalSessions).formatValue(5),
          '5');
      expect(_challenge(metric: ChallengeMetric.activeDays).formatValue(7),
          '7 days');
      expect(_challenge(metric: ChallengeMetric.mostCalories).formatValue(420),
          '420 kcal');
    });
  });

  group('ChallengeSummary.progressToTarget', () {
    test('clamps to 0..1 and handles missing target (negative)', () {
      final s = ChallengeSummary(challenge: _challenge(target: 20), myValue: 5);
      expect(s.progressToTarget(), 0.25);
      expect(
          ChallengeSummary(challenge: _challenge(target: 20), myValue: 50)
              .progressToTarget(),
          1.0);
      expect(
          ChallengeSummary(challenge: _challenge(target: null), myValue: 5)
              .progressToTarget(),
          0.0);
    });
  });
}
