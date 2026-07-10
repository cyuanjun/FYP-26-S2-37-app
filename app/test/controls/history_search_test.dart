import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/controls/workout_history.dart';
import 'package:wise_workout/entities/workout_session.dart';
import 'package:wise_workout/entities/workout_type.dart';

// (#) Tests the Premium history search filter: matching sessions by workout-type
// (#) name or custom name, case-insensitively.

// (#) Lookup of workout types by id, used to resolve type names during filtering.
const _types = {
  'wt-run': WorkoutType(id: 'wt-run', name: 'Running', slug: 'running'),
  'wt-yoga': WorkoutType(id: 'wt-yoga', name: 'Yoga', slug: 'yoga'),
};

// (#) Builds a sample WorkoutSession for the tests.
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

  // (#) The pure filter function behind Premium history search.
  group('filterSessionsByQuery (#12 Premium search)', () {
    // (#) (-) Check if a blank query returns the full list unchanged.
    test('blank query returns the list untouched', () {
      expect(filterSessionsByQuery(sessions, _types, '   '), sessions);
    });

    // (#) (+) Check if it matches the resolved workout-type name, ignoring case.
    test('matches the resolved workout-type name, case-insensitive', () {
      final hits = filterSessionsByQuery(sessions, _types, 'RUN');
      expect(hits.map((s) => s.id), ['s1', 's2']);
    });

    // (#) (+) Check if it matches on the custom session name.
    test('matches the custom session name', () {
      final hits = filterSessionsByQuery(sessions, _types, 'wind-down');
      expect(hits.map((s) => s.id), ['s3']);
    });

    // (#) (-) Check if a query with no matches yields an empty list.
    test('no matches yields an empty list (negative)', () {
      expect(filterSessionsByQuery(sessions, _types, 'swim'), isEmpty);
    });
  });
}
