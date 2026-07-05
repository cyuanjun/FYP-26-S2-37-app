import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'fitness_profile.freezed.dart';
part 'fitness_profile.g.dart';

/// ENTITY — 1:1 athlete specialization of the user (shared key on profiles.id).
/// Owns the XP/level/streak rules: level = floor(XP/200)+1.
@freezed
abstract class FitnessProfile with _$FitnessProfile {
  const FitnessProfile._();

  const factory FitnessProfile({
    required String id,
    DateTime? dateOfBirth,
    Sex? sex,
    int? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    TrainingExperience? trainingExperience,
    int? restingHeartRate,
    @Default(<String>[]) List<String> healthTagIds,
    @Default(<String>[]) List<String> preferredWorkoutTypeIds,
    @Default(0) int totalXp,
    @Default(0) int currentStreak,
  }) = _FitnessProfile;

  factory FitnessProfile.fromJson(Map<String, dynamic> json) =>
      _$FitnessProfileFromJson(json);

  static const xpPerLevel = 200;

  int get level => totalXp ~/ xpPerLevel + 1;

  /// XP accumulated inside the current level (fills the profile XP bar /200).
  int get xpIntoLevel => totalXp % xpPerLevel;

  /// Age in whole years at [now], or null when DOB is unset.
  int? ageAt(DateTime now) =>
      dateOfBirth == null ? null : ageFrom(dateOfBirth!, now);

  /// Age rule for a bare DOB (screens with a draft DOB share the same math).
  static int ageFrom(DateTime dob, DateTime now) {
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }
}
