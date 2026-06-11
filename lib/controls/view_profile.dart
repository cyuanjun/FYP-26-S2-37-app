import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../core/seq_log.dart';
import '../entities/fitness_goal.dart';
import '../entities/fitness_profile.dart';
import '../entities/health_tag.dart';
import 'authenticate.dart';
import 'workout_history.dart';

/// Read-side of the Profile hub (#13) and its sub-screens — the ViewProfile
/// use case. Write controls invalidate these providers after committing.

/// The signed-in user's athlete specialization row (XP / streak / metrics).
final fitnessProfileProvider = FutureProvider<FitnessProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  SeqLog.msg('view-profile', 'ViewProfile', 'FitnessGateway', 'fetchFitnessProfile');
  return ref.watch(fitnessGatewayProvider).fetchFitnessProfile(userId);
});

/// The active fitness goal (achievedAt == null), or null when none set.
final activeGoalProvider = FutureProvider<FitnessGoal?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  return ref.watch(fitnessGatewayProvider).fetchActiveGoal(userId);
});

/// The diet/allergy/injury catalog (#13.1 pickers).
final healthTagsProvider = FutureProvider<List<HealthTag>>(
  (ref) => ref.watch(fitnessGatewayProvider).listHealthTags(),
);

/// Headline stats for the Profile identity block. Lifetime, uncapped —
/// Profile is identity, not a History-window snapshot.
class ProfileStats {
  const ProfileStats({required this.workouts, required this.activeDays});

  final int workouts;
  final int activeDays;
}

final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  return ref.watch(historyProvider).whenData((sessions) {
    final days = <String>{};
    for (final s in sessions) {
      final d = s.endedAt ?? s.startedAt;
      days.add('${d.year}-${d.month}-${d.day}');
    }
    return ProfileStats(workouts: sessions.length, activeDays: days.length);
  });
});
