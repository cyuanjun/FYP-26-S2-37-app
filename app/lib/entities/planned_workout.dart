import 'package:freezed_annotation/freezed_annotation.dart';

part 'planned_workout.freezed.dart';
part 'planned_workout.g.dart';

// (#) One workout slotted into a plan's weekly schedule. It knows its week, its
// (#) day, how long it should run and which workout type it is.
@freezed
abstract class PlannedWorkout with _$PlannedWorkout {
  const PlannedWorkout._();

  const factory PlannedWorkout({
    required String id,
    required String fitnessPlanId, // (#) the plan this workout belongs to
    required String workoutTypeId, // (#) which discipline it is, like running or yoga
    required int weekNumber, // (#) which week of the plan it sits in
    required int dayOfWeek, // (#) day of the week, 1 is Monday through 7 is Sunday
    required int durationMinutes, // (#) how many minutes the workout is planned for
    String? name,
    String? descriptor,
    @Default(0) int orderIndex, // (#) sort order when a day holds more than one workout
  }) = _PlannedWorkout;

  // (#) Rebuilds a PlannedWorkout from its stored JSON.
  factory PlannedWorkout.fromJson(Map<String, dynamic> json) =>
      _$PlannedWorkoutFromJson(json);

  // (#) Lookup table turning dayOfWeek 1..7 into a short label, index 0 unused.
  static const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // (#) The short day label for this workout, so the UI can print Mon, Tue and so on.
  String get dayName => dayNames[dayOfWeek];
}
