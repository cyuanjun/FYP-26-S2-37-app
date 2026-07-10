import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/fitness_goal.dart';
import '../entities/validators.dart';
import 'view_profile.dart';

// (#) The set-goal use case. It checks the input (1 to 7 days a week, positive
// (#) target where needed) then saves through the gateway, which patches the
// (#) active goal or inserts a new one. The screen just calls save() and never
// (#) sees the DB or knows whether it's creating or editing.
class SetFitnessGoal extends AsyncNotifier<void> {
  // (#) Nothing to load up front; idle until save() is called.
  @override
  Future<void> build() async {}

  // (#) Validates the inputs, maps enums to columns and upserts the goal; returns
  // (#) true on success, false when validation fails or the save errors.
  Future<bool> save({
    required String userId,
    required PrimaryGoal primaryGoal,
    double? targetValue,
    double? startingValue,
    int? timelineWeeks,
    required int weeklyCommitmentDays,
  }) async {
    SeqLog.msg('set-fitness-goal', 'FitnessGoalsScreen', 'SetFitnessGoal',
        'save(${primaryGoal.name})');
    if (weeklyCommitmentDays < 1 || weeklyCommitmentDays > 7) {
      state = AsyncError(ArgumentError('weeklyCommitmentDays must be 1–7'), StackTrace.current);
      return false;
    }
    final hasTarget = FitnessGoal.hasTargetFor(primaryGoal);
    // A goal that races a target must carry a positive one.
    if (hasTarget && !Validators.validPositiveTarget(targetValue)) {
      state = AsyncError(
          ArgumentError('Target value must be greater than 0'), StackTrace.current);
      return false;
    }
    final unit = FitnessGoal.unitFor(primaryGoal);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      SeqLog.msg('set-fitness-goal', 'SetFitnessGoal', 'FitnessGateway', 'upsertActiveGoal');
      await ref.read(fitnessGatewayProvider).upsertActiveGoal(userId: userId, values: {
        'primary_goal': primaryGoal.toDb,
        'target_value': hasTarget ? targetValue : null,
        'target_unit': hasTarget ? unit?.toDb : null,
        'starting_value': hasTarget ? startingValue : null,
        'timeline_weeks': hasTarget ? timelineWeeks : null,
        'weekly_commitment_days': weeklyCommitmentDays,
      });
      ref.invalidate(activeGoalProvider);
    });
    return !state.hasError;
  }
}

// (#) Spells out how a PrimaryGoal maps to its DB string. Kept on purpose: the
// (#) generated enum maps are private to the entity .g.dart files, so a control
// (#) building a raw values map needs its own mapping.
extension PrimaryGoalDb on PrimaryGoal {
  // (#) The snake_case column value for this goal.
  String get toDb => switch (this) {
        PrimaryGoal.loseWeight => 'lose_weight',
        PrimaryGoal.buildMuscle => 'build_muscle',
        PrimaryGoal.improveEndurance => 'improve_endurance',
        PrimaryGoal.maintainFitness => 'maintain_fitness',
      };
}

// (#) Same enum-to-column mapping for the target unit.
extension TargetUnitDb on TargetUnit {
  // (#) The snake_case column value for this unit.
  String get toDb => switch (this) {
        TargetUnit.stepsPerDay => 'steps_per_day',
        _ => name,
      };
}

// (#) Hands the fitness-goals screen the SetFitnessGoal control.
final setFitnessGoalProvider =
    AsyncNotifierProvider<SetFitnessGoal, void>(SetFitnessGoal.new);
