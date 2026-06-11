import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/health_tag.dart';
import 'view_profile.dart';

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

  /// "+ Add X" in a picker — inserts the custom tag and refreshes the catalog.
  Future<HealthTag?> addCustomTag({
    required String userId,
    required HealthTagKind kind,
    required String name,
  }) async {
    if (name.trim().isEmpty) return null;
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
