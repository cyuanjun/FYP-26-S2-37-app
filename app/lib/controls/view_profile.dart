import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/fitness_gateway.dart';
import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/fitness_goal.dart';
import '../entities/fitness_profile.dart';
import '../entities/health_tag.dart';
import '../entities/workout_session.dart';
import 'authenticate.dart';

// (#) The read side of the Profile hub (#13) and its sub-screens: the ViewProfile use
// (#) case. These are all read providers; the write controls elsewhere invalidate them
// (#) after they commit so the profile screens refresh.

// (#) Loads the signed-in user's fitness profile row, the one holding XP, streak, and
// (#) body metrics. Null when logged out.
final fitnessProfileProvider = FutureProvider<FitnessProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  SeqLog.msg('view-profile', 'ViewProfile', 'FitnessGateway', 'fetchFitnessProfile');
  return ref.watch(fitnessGatewayProvider).fetchFitnessProfile(userId);
});

// (#) Loads the user's current in-progress fitness goal (one that isn't achieved yet),
// (#) or null when they haven't set one.
final activeGoalProvider = FutureProvider<FitnessGoal?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  return ref.watch(fitnessGatewayProvider).fetchActiveGoal(userId);
});

// (#) Loads the full diet/allergy/injury tag catalog that the #13.1 pickers offer.
final healthTagsProvider = FutureProvider<List<HealthTag>>(
  (ref) => ref.watch(fitnessGatewayProvider).listHealthTags(),
);

// (#) Small data holder for the headline numbers on the Profile identity block. Kept
// (#) separate from the History window on purpose: Profile shows lifetime totals and so
// (#) ignores the Free monthly cap, using its own query below.
class ProfileStats {
  const ProfileStats({required this.workouts, required this.activeDays});

  final int workouts; // (#) total completed workouts ever
  final int activeDays; // (#) count of distinct calendar days trained
}

// (#) Loads every ended session for the user (lifetime, no cap) to feed the stats.
final lifetimeSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <WorkoutSession>[]);
  return ref.watch(workoutGatewayProvider).listEndedSessions(userId);
});

// (#) Derives the ProfileStats (workout count and unique active days) from the lifetime
// (#) sessions, keeping the loading/error wrapper.
final profileStatsProvider = Provider<AsyncValue<ProfileStats>>((ref) {
  return ref.watch(lifetimeSessionsProvider).whenData((sessions) {
    final days = <String>{};
    for (final s in sessions) {
      final d = s.endedAt ?? s.startedAt;
      days.add('${d.year}-${d.month}-${d.day}');
    }
    return ProfileStats(workouts: sessions.length, activeDays: days.length);
  });
});
