import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/workout_session.dart';
import 'package:wise_workout/entities/workout_type.dart';

import '../helpers/fakes.dart';

// (#) Tests the workout entities: cardio classification, ended state, JSON decoding, calorie estimation.
void main() {
  // (#) Group covering which workout types count as cardio.
  group('WorkoutType.isCardio', () {
    // (#) (+) Check if the known cardio slugs are classed as cardio.
    test('cardio slugs are cardio', () {
      for (final slug in ['running', 'cycling', 'swimming', 'hiit', 'rowing', 'walking', 'hiking']) {
        expect(WorkoutType(id: 'x', name: slug, slug: slug).isCardio, isTrue, reason: slug);
      }
    });
    // (#) (-) Check if strength/yoga/pilates slugs are not cardio.
    test('non-cardio slugs are not cardio', () {
      for (final slug in ['strength', 'yoga', 'pilates']) {
        expect(WorkoutType(id: 'x', name: slug, slug: slug).isCardio, isFalse, reason: slug);
      }
    });
    // (#) (-) Check if an unknown slug defaults to not cardio.
    test('unknown slug is not cardio (negative)', () {
      expect(const WorkoutType(id: 'x', name: 'Surfing', slug: 'surfing').isCardio, isFalse);
    });
  });

  // (#) Group covering the session ended flag.
  group('WorkoutSession.isEnded', () {
    final started = DateTime(2026, 6, 10, 10);
    // (#) (-) Check if a session with no end time reads as not ended.
    test('false while in progress', () {
      expect(WorkoutSession(id: 's', userId: 'u', workoutTypeId: 't', startedAt: started).isEnded, isFalse);
    });
    // (#) (+) Check if a session with an end time reads as ended.
    test('true once ended', () {
      final s = WorkoutSession(
          id: 's', userId: 'u', workoutTypeId: 't', startedAt: started, endedAt: started.add(const Duration(minutes: 5)));
      expect(s.isEnded, isTrue);
    });
  });

  // (#) Group covering JSON decoding of a session row.
  group('WorkoutSession.fromJson', () {
    // (#) (+) Check if fromJson maps snake_case fields and keeps nullable metrics null.
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

  // (#) Group covering the MET-based calorie estimate.
  group('WorkoutType.estimateCalories (MET × kg × hours)', () {
    // (#) (+) Check if a 30-min run at 70 kg estimates about 343 kcal.
    test('30-min run at 70 kg ≈ 343 kcal (positive)', () {
      expect(runningType.estimateCalories(durationSeconds: 1800, weightKg: 70), 343);
    });

    // (#) (-) Check if null weight with unknown sex falls back to the 70 kg default.
    test('null weight + unknown sex falls back to the 70 kg default', () {
      expect(runningType.estimateCalories(durationSeconds: 1800),
          runningType.estimateCalories(durationSeconds: 1800, weightKg: 70));
    });

    // (#) (+) Check if null weight uses a sex-based default, with male heavier than female.
    test('null weight uses a sex-based default (male heavier than female)', () {
      final male = runningType.estimateCalories(durationSeconds: 1800, sex: Sex.male);
      final female = runningType.estimateCalories(durationSeconds: 1800, sex: Sex.female);
      expect(male, runningType.estimateCalories(durationSeconds: 1800, weightKg: 70));
      expect(female, runningType.estimateCalories(durationSeconds: 1800, weightKg: 55));
      expect(male, greaterThan(female));
    });

    // (#) (+) Check if the default weight is male 70, female 55, other/null 70.
    test('defaultWeightKg: male 70, female 55, other/null 70', () {
      expect(WorkoutType.defaultWeightKg(Sex.male), 70);
      expect(WorkoutType.defaultWeightKg(Sex.female), 55);
      expect(WorkoutType.defaultWeightKg(Sex.other), 70);
      expect(WorkoutType.defaultWeightKg(null), 70);
    });

    // (#) (+) Check if an explicit weight overrides the sex-based default.
    test('explicit weight overrides the sex-based default', () {
      expect(runningType.estimateCalories(durationSeconds: 1800, weightKg: 70, sex: Sex.male),
          runningType.estimateCalories(durationSeconds: 1800, weightKg: 70));
    });

    // (#) (+) Check if a lower-MET discipline burns fewer calories for the same session.
    test('lower-MET discipline burns less for the same session', () {
      final run = runningType.estimateCalories(durationSeconds: 1800, weightKg: 70);
      final yoga = yogaType.estimateCalories(durationSeconds: 1800, weightKg: 70);
      expect(yoga, lessThan(run));
    });

    // (#) (-) Check if a zero-duration session estimates 0 kcal.
    test('zero duration → 0 kcal (negative)', () {
      expect(runningType.estimateCalories(durationSeconds: 0, weightKg: 70), 0);
    });

    // (#) (-) Check if an unknown slug falls back to the moderate 4.0 MET.
    test('unknown slug falls back to moderate 4.0 MET', () {
      const custom = WorkoutType(id: 'x', name: 'Aerial silks', slug: 'aerial-silks');
      expect(custom.met, 4.0);
      expect(custom.estimateCalories(durationSeconds: 3600, weightKg: 70), 280);
    });
  });
}
