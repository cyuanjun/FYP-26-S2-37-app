import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_gateway.dart';
import '../core/format.dart';
import '../core/seq_log.dart';
import '../entities/workout_session.dart';
import '../entities/workout_type.dart';
import 'authenticate.dart';

// (#) Read provider behind View Workout History: the user's finished sessions. Free
// (#) users are limited to the current month right in the query (so the list, analytics,
// (#) and deltas all share one window); Premium and other roles get everything. Write
// (#) controls like EndWorkoutSession and DeleteWorkoutSession invalidate it.
final historyProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const <WorkoutSession>[];
  final profile = await ref.watch(currentProfileProvider.future);
  final capped = profile?.isFree ?? false;
  final from = capped ? startOfMonth(DateTime.now()) : null;
  SeqLog.msg('view-history', 'ViewWorkoutHistory', 'WorkoutGateway',
      'listEndedSessions(from: ${from?.toIso8601String() ?? 'lifetime'})');
  return ref.watch(workoutGatewayProvider).listEndedSessions(userId, from: from);
});

// (#) True when the Free monthly cap is actually hiding older workouts, so the UI can
// (#) show an upgrade nudge. It asks the gateway whether any ended session exists before
// (#) this month. Always false for uncapped roles, where an empty list really means none.
final earlierHistoryHiddenProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  final profile = await ref.watch(currentProfileProvider.future);
  if (!(profile?.isFree ?? false)) return false;
  return ref
      .watch(workoutGatewayProvider)
      .hasEndedSessionsBefore(userId, startOfMonth(DateTime.now()));
});

// (#) The Delete Completed Workout use case. Removes one finished session; its exercise
// (#) logs get cleaned up automatically by the foreign-key cascade.
class DeleteWorkoutSession {
  DeleteWorkoutSession(this._ref);

  final Ref _ref;

  // (#) Deletes the session via the workout gateway, then invalidates history.
  Future<void> call(String sessionId) async {
    SeqLog.msg('delete-workout', 'HistoryDetailScreen', 'DeleteWorkoutSession', 'delete($sessionId)');
    await _ref.read(workoutGatewayProvider).deleteSession(sessionId);
    _ref.invalidate(historyProvider);
  }
}

// (#) Provider the history detail screen uses to delete a workout.
final deleteWorkoutSessionProvider = Provider<DeleteWorkoutSession>(DeleteWorkoutSession.new);

// (#) Pure helper for History search (#12, Premium). Filters sessions by a case-
// (#) insensitive substring match against the custom name plus the workout-type name;
// (#) a blank query just returns the list as-is.
List<WorkoutSession> filterSessionsByQuery(
  List<WorkoutSession> sessions,
  Map<String, WorkoutType> typeById,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return sessions;
  return sessions.where((s) {
    final haystack =
        '${s.customName ?? ''} ${typeById[s.workoutTypeId]?.name ?? ''}'
            .toLowerCase();
    return haystack.contains(q);
  }).toList();
}
