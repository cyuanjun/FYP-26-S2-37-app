import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'workout_session.freezed.dart';
part 'workout_session.g.dart';

// (#) A workout the user actually did: when, how long, calories, heart rate,
// (#) distance and how it felt. Notes stay private. It can hang off a planned
// (#) workout or stand entirely on its own.
@freezed
abstract class WorkoutSession with _$WorkoutSession {
  const WorkoutSession._();

  const factory WorkoutSession({
    required String id,
    required String userId, // (#) whose workout this is
    required String workoutTypeId, // (#) the discipline, like running or yoga
    String? plannedWorkoutId, // (#) the plan slot it fulfils, null for a free-form workout
    String? connectedDeviceId, // (#) which device recorded it, null means manual entry
    required DateTime startedAt,
    DateTime? endedAt, // (#) when it finished, null while still in progress
    @Default(0) int durationSeconds, // (#) total length in seconds
    int? caloriesBurned,
    int? avgHeartRate, // (#) average bpm, null if no heart rate was captured
    int? maxHeartRate,
    int? distanceMeters, // (#) distance covered, mainly for cardio
    FeelRating? feelRating, // (#) the user's own rating of how the session felt
    String? notes, // (#) private notes, never shown to anyone else, locked down by RLS
    String? customName,
  }) = _WorkoutSession;

  // (#) Rebuilds a WorkoutSession from its stored JSON.
  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);

  // (#) True once the session has an end time, meaning it is finished.
  bool get isEnded => endedAt != null;
}
