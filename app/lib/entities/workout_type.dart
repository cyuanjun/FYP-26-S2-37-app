import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'workout_type.freezed.dart';
part 'workout_type.g.dart';

// (#) The set of slugs counted as cardio, which earn distance-based XP and show pace.
const cardioSlugs = {'running', 'cycling', 'swimming', 'walking', 'hiit', 'rowing', 'hiking'};

// (#) A kind of workout, like running or yoga. It is a catalog entry that also
// (#) carries the MET value and the calorie maths for that discipline.
@freezed
abstract class WorkoutType with _$WorkoutType {
  const WorkoutType._();

  const factory WorkoutType({
    required String id,
    required String name,
    required String slug, // (#) machine key like "running", also used to look up MET
    @Default(false) bool isCustom, // (#) true when a user added it, not from the seeded catalog
  }) = _WorkoutType;

  // (#) Rebuilds a WorkoutType from its stored JSON.
  factory WorkoutType.fromJson(Map<String, dynamic> json) => _$WorkoutTypeFromJson(json);

  // (#) True when this discipline is a cardio one, based on its slug.
  bool get isCardio => cardioSlugs.contains(slug);

  // (#) MET, the metabolic equivalent, per discipline, from published population
  // (#) averages. Anything not listed here falls back to a moderate 4.0.
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

  // (#) This discipline's MET value, falling back to a moderate 4.0 if unlisted.
  double get met => mets[slug] ?? 4.0;

  // (#) A stand-in body weight in kg for when the profile has none, picked by
  // (#) sex from rough adult averages, and 70 kg when sex is unknown.
  static double defaultWeightKg(Sex? sex) => switch (sex) {
        Sex.male => 70,
        Sex.female => 55,
        _ => 70, // other / not specified
      };

  // (#) Rough calories burned = MET times weight in kg times hours. If no weight
  // (#) is known it borrows the sex-based default above.
  int estimateCalories({required int durationSeconds, double? weightKg, Sex? sex}) =>
      (met * (weightKg ?? defaultWeightKg(sex)) * (durationSeconds / 3600)).round();
}
