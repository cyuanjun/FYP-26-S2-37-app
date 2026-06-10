import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/workout_session.dart';
import 'package:wise_workout/entities/workout_type.dart';

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
}
