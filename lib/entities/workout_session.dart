import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'workout_session.freezed.dart';
part 'workout_session.g.dart';

/// ENTITY — a recorded session (what the user actually did). Tied to a PlannedWorkout
/// when executing a plan, or free-form. `notes` is always private (enforced by RLS).
@freezed
abstract class WorkoutSession with _$WorkoutSession {
  const WorkoutSession._();

  const factory WorkoutSession({
    required String id,
    required String userId,
    required String workoutTypeId,
    String? plannedWorkoutId,
    String? connectedDeviceId,
    required DateTime startedAt,
    DateTime? endedAt,
    @Default(0) int durationSeconds,
    int? caloriesBurned,
    int? avgHeartRate,
    int? maxHeartRate,
    int? distanceMeters,
    FeelRating? feelRating,
    String? notes,
    String? customName,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);

  bool get isEnded => endedAt != null;
}
