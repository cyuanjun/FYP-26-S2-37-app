import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/fitness_goal.dart';
import '../entities/validators.dart';
import 'view_profile.dart';

/// CONTROL — Set Fitness Goal (#13.2 Save Goal). Upsert-by-convention: patches
/// the active goal (achievedAt == null) or inserts a fresh one. The screen
/// never needs to know whether it's editing or creating.
class SetFitnessGoal extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

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

// Explicit enum→column adapters (kept deliberately, simplify M4): the
// json_serializable enum maps are library-private to the entities' .g.dart
// files, so a control building a raw values map spells the mapping out.
extension PrimaryGoalDb on PrimaryGoal {
  String get toDb => switch (this) {
        PrimaryGoal.loseWeight => 'lose_weight',
        PrimaryGoal.buildMuscle => 'build_muscle',
        PrimaryGoal.improveEndurance => 'improve_endurance',
        PrimaryGoal.maintainFitness => 'maintain_fitness',
      };
}

extension TargetUnitDb on TargetUnit {
  String get toDb => switch (this) {
        TargetUnit.stepsPerDay => 'steps_per_day',
        _ => name,
      };
}

final setFitnessGoalProvider =
    AsyncNotifierProvider<SetFitnessGoal, void>(SetFitnessGoal.new);
