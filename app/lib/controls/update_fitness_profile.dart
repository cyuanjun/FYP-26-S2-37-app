import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/health_tag.dart';
import '../entities/workout_type.dart';
import 'view_profile.dart';
import '../core/strings.dart';

/// CONTROL — Update Fitness Profile (#13.1 Save Profile). Batches every edited
/// field + chip selection into one update; the screen edits locally and commits
/// once.
class UpdateFitnessProfile extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save(String userId, Map<String, dynamic> patch) async {
    SeqLog.msg('update-fitness-profile', 'FitnessProfileScreen', 'UpdateFitnessProfile',
        'save(${patch.keys.join(',')})');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      SeqLog.msg('update-fitness-profile', 'UpdateFitnessProfile', 'FitnessGateway',
          'updateFitnessProfile');
      await ref.read(fitnessGatewayProvider).updateFitnessProfile(userId, patch);
      ref.invalidate(fitnessProfileProvider);
    });
    return !state.hasError;
  }

  /// "+ Add your own" workout type — inserts the custom type and refreshes
  /// the catalog (#13.1 / onboarding preferred-workouts pickers).
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

  /// "+ Add X" in a picker — inserts the custom tag and refreshes the catalog.
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

final updateFitnessProfileProvider =
    AsyncNotifierProvider<UpdateFitnessProfile, void>(UpdateFitnessProfile.new);
