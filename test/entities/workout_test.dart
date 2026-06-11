import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/workout_session.dart';
import 'package:wise_workout/entities/workout_type.dart';

import '../helpers/fakes.dart';

void main() {
  group('WorkoutType.isCardio', () {
    test('cardio slugs are cardio', () {
      for (final slug in ['running', 'cycling', 'swimming', 'hiit', 'rowing', 'walking', 'hiking']) {
        expect(WorkoutType(id: 'x', name: slug, slug: slug).isCardio, isTrue, reason: slug);
      }
    });
    test('non-cardio slugs are not cardio', () {
      for (final slug in ['strength', 'yoga', 'pilates']) {
        expect(WorkoutType(id: 'x', name: slug, slug: slug).isCardio, isFalse, reason: slug);
      }
    });
    test('unknown slug is not cardio (negative)', () {
      expect(const WorkoutType(id: 'x', name: 'Surfing', slug: 'surfing').isCardio, isFalse);
    });
  });

  group('WorkoutSession.isEnded', () {
    final started = DateTime(2026, 6, 10, 10);
    test('false while in progress', () {
      expect(WorkoutSession(id: 's', userId: 'u', workoutTypeId: 't', startedAt: started).isEnded, isFalse);
    });
    test('true once ended', () {
      final s = WorkoutSession(
          id: 's', userId: 'u', workoutTypeId: 't', startedAt: started, endedAt: started.add(const Duration(minutes: 5)));
      expect(s.isEnded, isTrue);
    });
  });

  group('WorkoutSession.fromJson', () {
    test('maps snake_case + nullable metrics', () {
      final s = WorkoutSession.fromJson({
        'id': 's1',
        'user_id': 'u1',
        'workout_type_id': 't1',
        'started_at': '2026-06-10T10:00:00Z',
        'ended_at': '2026-06-10T10:30:00Z',
        'duration_seconds': 1800,
        'distance_meters': 5000,
        'feel_rating': 'great',
        'calories_burned': null,
      });
      expect(s.isEnded, isTrue);
      expect(s.durationSeconds, 1800);
      expect(s.distanceMeters, 5000);
      expect(s.feelRating, FeelRating.great);
      expect(s.caloriesBurned, isNull);
    });
  });

  group('WorkoutType.estimateCalories (MET × kg × hours)', () {
    test('30-min run at 70 kg ≈ 343 kcal (positive)', () {
      expect(runningType.estimateCalories(durationSeconds: 1800, weightKg: 70), 343);
    });

    test('null weight falls back to the 70 kg default', () {
      expect(runningType.estimateCalories(durationSeconds: 1800),
          runningType.estimateCalories(durationSeconds: 1800, weightKg: 70));
    });

    test('lower-MET discipline burns less for the same session', () {
      final run = runningType.estimateCalories(durationSeconds: 1800, weightKg: 70);
      final yoga = yogaType.estimateCalories(durationSeconds: 1800, weightKg: 70);
      expect(yoga, lessThan(run));
    });

    test('zero duration → 0 kcal (negative)', () {
      expect(runningType.estimateCalories(durationSeconds: 0, weightKg: 70), 0);
    });

    test('unknown slug falls back to moderate 4.0 MET', () {
      const custom = WorkoutType(id: 'x', name: 'Aerial silks', slug: 'aerial-silks');
      expect(custom.met, 4.0);
      expect(custom.estimateCalories(durationSeconds: 3600, weightKg: 70), 280);
    });
  });
}
