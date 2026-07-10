import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/health_tag.dart';
import '../entities/validators.dart';
import '../entities/workout_type.dart';
import 'view_profile.dart';
import '../core/strings.dart';

// (#) The Update Fitness Profile use case (#13.1 Save Profile). The screen edits
// (#) everything locally then commits all the changed fields and chip picks in one
// (#) batch here, after range-checking the numeric ones.
class UpdateFitnessProfile extends AsyncNotifier<void> {
  // (#) Nothing to preload.
  @override
  Future<void> build() async {}

  // (#) Validates the patched numbers, then writes the whole patch via the fitness
  // (#) gateway and refreshes the profile. Returns false (with an error state) if any
  // (#) value is out of range.
  Future<bool> save(String userId, Map<String, dynamic> patch) async {
    SeqLog.msg('update-fitness-profile', 'FitnessProfileScreen', 'UpdateFitnessProfile',
        'save(${patch.keys.join(',')})');
    // Reject out-of-range numeric inputs before persisting — the Boundary also
    // validates for UX, but this is the enforced guard (defence in depth).
    final invalid = _invalidField(patch);
    if (invalid != null) {
      state = AsyncError(ArgumentError(invalid), StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      SeqLog.msg('update-fitness-profile', 'UpdateFitnessProfile', 'FitnessGateway',
          'updateFitnessProfile');
      await ref.read(fitnessGatewayProvider).updateFitnessProfile(userId, patch);
      ref.invalidate(fitnessProfileProvider);
    });
    return !state.hasError;
  }

  // (#) Helper that checks height, weight, and resting HR against their allowed ranges.
  // (#) Returns null when all present values are fine, otherwise the first error message.
  static String? _invalidField(Map<String, dynamic> patch) {
    if (patch.containsKey('height_cm') &&
        !Validators.validHeightCm(patch['height_cm'] as num?)) {
      return Validators.heightCmError(patch['height_cm'] as num?);
    }
    if (patch.containsKey('weight_kg') &&
        !Validators.validWeightKg(patch['weight_kg'] as num?)) {
      return Validators.weightKgError(patch['weight_kg'] as num?);
    }
    if (patch.containsKey('resting_heart_rate') &&
        !Validators.validRestingHr(patch['resting_heart_rate'] as num?)) {
      return 'Resting heart rate must be '
          '${Validators.minRestingHr}–${Validators.maxRestingHr} bpm';
    }
    return null;
  }

  // (#) Backs the "+ Add your own" option in the workout-type pickers. Inserts a custom
  // (#) type via the workout gateway, refreshes the catalog, and returns the new type.
  Future<WorkoutType?> addCustomWorkoutType({
    required String userId,
    required String name,
  }) async {
    if (name.isBlank) return null;
    SeqLog.msg('update-fitness-profile', 'UpdateFitnessProfile', 'WorkoutGateway',
        'addCustomWorkoutType($name)');
    final type = await ref
        .read(workoutGatewayProvider)
        .addCustomWorkoutType(userId: userId, name: name);
    ref.invalidate(workoutTypesProvider);
    return type;
  }

  // (#) Backs the "+ Add X" option in a diet/allergy/injury picker. Inserts a custom
  // (#) health tag via the fitness gateway, refreshes the catalog, and returns the tag.
  Future<HealthTag?> addCustomTag({
    required String userId,
    required HealthTagKind kind,
    required String name,
  }) async {
    if (name.isBlank) return null;
    SeqLog.msg('update-fitness-profile', 'UpdateFitnessProfile', 'FitnessGateway',
        'addCustomHealthTag(${kind.name}, $name)');
    final tag = await ref
        .read(fitnessGatewayProvider)
        .addCustomHealthTag(userId: userId, kind: kind, name: name);
    ref.invalidate(healthTagsProvider);
    return tag;
  }
}

// (#) Provider the fitness profile screen watches to save and add custom entries.
final updateFitnessProfileProvider =
    AsyncNotifierProvider<UpdateFitnessProfile, void>(UpdateFitnessProfile.new);
