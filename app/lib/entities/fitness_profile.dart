import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'fitness_profile.freezed.dart';
part 'fitness_profile.g.dart';

// (#) The athlete side of a user's account: body stats plus their XP, level and
// (#) streak. Sits 1:1 with the user row and owns the rule that level is XP
// (#) divided by 200.
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
    int? restingHeartRate, // (#) feeds the HR-zone and load maths
    @Default(<String>[]) List<String> healthTagIds, // (#) diet/allergy/injury flags
    @Default(<String>[]) List<String> preferredWorkoutTypeIds, // (#) types they like, for plan building
    @Default(0) int totalXp, // (#) lifetime XP, drives level and the XP bar
    @Default(0) int currentStreak, // (#) current run of consecutive active days
  }) = _FitnessProfile;

  factory FitnessProfile.fromJson(Map<String, dynamic> json) =>
      _$FitnessProfileFromJson(json);

  // (#) how much XP each level costs
  static const xpPerLevel = 200;

  // (#) current level, every 200 XP is one level starting at 1
  int get level => totalXp ~/ xpPerLevel + 1;

  // (#) XP earned inside the current level, fills the /200 progress bar
  int get xpIntoLevel => totalXp % xpPerLevel;

  // (#) age in whole years at the given time, null when no DOB is set
  int? ageAt(DateTime now) =>
      dateOfBirth == null ? null : ageFrom(dateOfBirth!, now);

  // (#) shared age calc so screens with a draft DOB use the same math
  static int ageFrom(DateTime dob, DateTime now) {
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }
}
