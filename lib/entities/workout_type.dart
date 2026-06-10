import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_type.freezed.dart';
part 'workout_type.g.dart';

/// Cardio disciplines earn distance-based XP and show pace/distance metrics.
const cardioSlugs = {'running', 'cycling', 'swimming', 'walking', 'hiit', 'rowing', 'hiking'};

/// ENTITY — catalog of selectable workout disciplines (seeded `workout_types`).
@freezed
abstract class WorkoutType with _$WorkoutType {
  const WorkoutType._();

  const factory WorkoutType({
    required String id,
    required String name,
    required String slug,
    @Default(false) bool isCustom,
  }) = _WorkoutType;

  factory WorkoutType.fromJson(Map<String, dynamic> json) => _$WorkoutTypeFromJson(json);

  bool get isCardio => cardioSlugs.contains(slug);
}
