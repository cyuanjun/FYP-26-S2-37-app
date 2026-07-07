import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/controls/workout_history.dart';
import 'package:wise_workout/entities/workout_session.dart';
import 'package:wise_workout/entities/workout_type.dart';

const _types = {
  'wt-run': WorkoutType(id: 'wt-run', name: 'Running', slug: 'running'),
  'wt-yoga': WorkoutType(id: 'wt-yoga', name: 'Yoga', slug: 'yoga'),
};

WorkoutSession _session(String id, String typeId, {String? customName}) =>
    WorkoutSession(
      id: id,
      userId: 'u1',
      workoutTypeId: typeId,
      startedAt: DateTime(2026, 7, 1, 8),
      endedAt: DateTime(2026, 7, 1, 9),
      customName: customName,
    );

void main() {
  final sessions = [
    _session('s1', 'wt-run', customName: 'Morning tempo'),
    _session('s2', 'wt-run'),
    _session('s3', 'wt-yoga', customName: 'Evening wind-down'),
  ];

  group('filterSessionsByQuery (#12 Premium search)', () {
    test('blank query returns the list untouched', () {
      expect(filterSessionsByQuery(sessions, _types, '   '), sessions);
    });

    test('matches the resolved workout-type name, case-insensitive', () {
      final hits = filterSessionsByQuery(sessions, _types, 'RUN');
      expect(hits.map((s) => s.id), ['s1', 's2']);
    });

    test('matches the custom session name', () {
      final hits = filterSessionsByQuery(sessions, _types, 'wind-down');
      expect(hits.map((s) => s.id), ['s3']);
    });

    test('no matches yields an empty list (negative)', () {
      expect(filterSessionsByQuery(sessions, _types, 'swim'), isEmpty);
    });
  });
}
