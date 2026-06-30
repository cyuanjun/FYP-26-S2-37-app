import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

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

  /// MET (metabolic equivalent) per catalog slug — population averages from
  /// the Compendium of Physical Activities; unknown/custom types fall back to
  /// a moderate 4.0.
  static const mets = <String, double>{
    'running': 9.8,
    'cycling': 7.5,
    'swimming': 8.0,
    'walking': 3.5,
    'hiit': 10.0,
    'rowing': 7.0,
    'hiking': 6.0,
    'strength': 5.0,
    'yoga': 2.5,
    'pilates': 3.0,
  };

  double get met => mets[slug] ?? 4.0;

  /// Population-average fallback weight (kg) used when the fitness profile has
  /// no weight set, keyed on sex (≈ adult averages); 70 kg when sex is unknown.
  static double defaultWeightKg(Sex? sex) => switch (sex) {
        Sex.male => 70,
        Sex.female => 55,
        _ => 70, // other / not specified
      };

  /// Estimated kcal = MET × weight(kg) × hours (US16 basic effect estimate).
  /// [weightKg] falls back to a sex-based population default ([defaultWeightKg])
  /// when the fitness profile has no weight set.
  int estimateCalories({required int durationSeconds, double? weightKg, Sex? sex}) =>
      (met * (weightKg ?? defaultWeightKg(sex)) * (durationSeconds / 3600)).round();
}
