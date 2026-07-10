import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'fitness_goal.freezed.dart';
part 'fitness_goal.g.dart';

// (#) What the user is training towards. Records the primary goal, a target and
// (#) a timeline. Only one goal is active at a time; older ones keep the date
// (#) they were achieved.
@freezed
abstract class FitnessGoal with _$FitnessGoal {
  const FitnessGoal._();

  const factory FitnessGoal({
    required String id,
    required String userId,
    required PrimaryGoal primaryGoal, // (#) lose weight, build muscle, etc.
    double? targetValue, // (#) the number to hit, null for maintain
    TargetUnit? targetUnit, // (#) unit that number is in
    double? startingValue, // (#) where they began, for progress bars
    int? timelineWeeks, // (#) how long they gave themselves
    int? weeklyCommitmentDays, // (#) how many days a week they'll train
    DateTime? createdAt,
    DateTime? achievedAt, // (#) set once reached, null while still active
  }) = _FitnessGoal;

  factory FitnessGoal.fromJson(Map<String, dynamic> json) => _$FitnessGoalFromJson(json);

  // (#) true while this is the current goal (not yet achieved)
  bool get isActive => achievedAt == null;

  // (#) whether this goal has a numeric target (maintain-fitness doesn't)
  bool get hasTarget => hasTargetFor(primaryGoal);

  // (#) same rule as a static, everything except maintain-fitness takes a target
  static bool hasTargetFor(PrimaryGoal goal) =>
      goal != PrimaryGoal.maintainFitness;

  // (#) app's mapping of which unit each goal's target uses (the DB doesn't enforce this)
  static TargetUnit? unitFor(PrimaryGoal goal) => switch (goal) {
        PrimaryGoal.loseWeight || PrimaryGoal.buildMuscle => TargetUnit.kg,
        PrimaryGoal.improveEndurance => TargetUnit.minutes,
        PrimaryGoal.maintainFitness => null,
      };

  // (#) sensible starting target when the user switches goal, so stale numbers don't linger
  static double? defaultTargetFor(PrimaryGoal goal, {double? currentWeightKg}) =>
      switch (goal) {
        PrimaryGoal.loseWeight => (currentWeightKg ?? 62) - 5,
        PrimaryGoal.buildMuscle => (currentWeightKg ?? 62) + 4,
        PrimaryGoal.improveEndurance => 60,
        PrimaryGoal.maintainFitness => null,
      };

  // (#) how much the +/- stepper moves per unit (1 kg or 5 minutes)
  static double stepFor(TargetUnit unit) =>
      unit == TargetUnit.minutes ? 5 : 1;

  // (#) the timeline lengths the picker offers, in weeks
  static const timelineOptions = [4, 8, 12, 16, 24];
}
