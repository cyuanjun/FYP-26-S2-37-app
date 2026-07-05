import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'fitness_goal.freezed.dart';
part 'fitness_goal.g.dart';

/// ENTITY — what the athlete is trying to achieve. One active goal per user
/// (achievedAt == null); history rows keep their achievedAt timestamps.
@freezed
abstract class FitnessGoal with _$FitnessGoal {
  const FitnessGoal._();

  const factory FitnessGoal({
    required String id,
    required String userId,
    required PrimaryGoal primaryGoal,
    double? targetValue,
    TargetUnit? targetUnit,
    double? startingValue,
    int? timelineWeeks,
    int? weeklyCommitmentDays,
    DateTime? createdAt,
    DateTime? achievedAt,
  }) = _FitnessGoal;

  factory FitnessGoal.fromJson(Map<String, dynamic> json) => _$FitnessGoalFromJson(json);

  bool get isActive => achievedAt == null;

  /// maintain_fitness is an ongoing routine: no target, no timeline.
  bool get hasTarget => hasTargetFor(primaryGoal);

  static bool hasTargetFor(PrimaryGoal goal) =>
      goal != PrimaryGoal.maintainFitness;

  /// The unit each goal's target is expressed in (app-owned mapping; the DB
  /// doesn't enforce the goal↔unit link).
  static TargetUnit? unitFor(PrimaryGoal goal) => switch (goal) {
        PrimaryGoal.loseWeight || PrimaryGoal.buildMuscle => TargetUnit.kg,
        PrimaryGoal.improveEndurance => TargetUnit.minutes,
        PrimaryGoal.maintainFitness => null,
      };

  /// Default target when switching to [goal] (stale cross-unit values mislead).
  static double? defaultTargetFor(PrimaryGoal goal, {double? currentWeightKg}) =>
      switch (goal) {
        PrimaryGoal.loseWeight => (currentWeightKg ?? 62) - 5,
        PrimaryGoal.buildMuscle => (currentWeightKg ?? 62) + 4,
        PrimaryGoal.improveEndurance => 60,
        PrimaryGoal.maintainFitness => null,
      };

  /// Stepper increment per unit (±1 kg, ±5 minutes).
  static double stepFor(TargetUnit unit) =>
      unit == TargetUnit.minutes ? 5 : 1;

  static const timelineOptions = [4, 8, 12, 16, 24];
}
