import 'package:freezed_annotation/freezed_annotation.dart';

part 'planned_workout.freezed.dart';
part 'planned_workout.g.dart';

/// ENTITY — one scheduled workout inside a FitnessPlan's weekly template
/// (dayOfWeek 1=Mon … 7=Sun).
@freezed
abstract class PlannedWorkout with _$PlannedWorkout {
  const PlannedWorkout._();

  const factory PlannedWorkout({
    required String id,
    required String fitnessPlanId,
    required String workoutTypeId,
    required int weekNumber,
    required int dayOfWeek,
    required int durationMinutes,
    String? name,
    String? descriptor,
    @Default(0) int orderIndex,
  }) = _PlannedWorkout;

  factory PlannedWorkout.fromJson(Map<String, dynamic> json) =>
      _$PlannedWorkoutFromJson(json);

  static const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get dayName => dayNames[dayOfWeek];
}
