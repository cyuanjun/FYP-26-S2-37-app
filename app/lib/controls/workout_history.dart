import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_gateway.dart';
import '../core/format.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import '../entities/workout_session.dart';
import 'authenticate.dart';

/// Read-side: the current user's ended sessions (View Workout History activity).
/// Free tier is capped at the current calendar month **at the query level**
/// (#12 spec) so the list, analytics, and deltas all work off the same window;
/// Premium (and other roles) see lifetime. Invalidated by EndWorkoutSession /
/// DeleteWorkoutSession / SaveWorkoutDetails.
final historyProvider = FutureProvider<List<WorkoutSession>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const <WorkoutSession>[];
  final profile = await ref.watch(currentProfileProvider.future);
  final capped = profile?.role == UserRole.free;
  final from = capped ? startOfMonth(DateTime.now()) : null;
  SeqLog.msg('view-history', 'ViewWorkoutHistory', 'WorkoutGateway',
      'listEndedSessions(from: ${from?.toIso8601String() ?? 'lifetime'})');
  return ref.watch(workoutGatewayProvider).listEndedSessions(userId, from: from);
});

/// True when the Free monthly cap is hiding earlier workouts — i.e. the user
/// has ended sessions from before this month that the capped [historyProvider]
/// window excludes. Always false for uncapped roles (Premium sees lifetime, so
/// an empty list genuinely means "no workouts yet").
final earlierHistoryHiddenProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.role != UserRole.free) return false;
  return ref
      .watch(workoutGatewayProvider)
      .hasEndedSessionsBefore(userId, startOfMonth(DateTime.now()));
});

/// CONTROL — Delete Completed Workout (cascades exercise logs via FK).
class DeleteWorkoutSession {
  DeleteWorkoutSession(this._ref);

  final Ref _ref;

  Future<void> call(String sessionId) async {
    SeqLog.msg('delete-workout', 'HistoryDetailScreen', 'DeleteWorkoutSession', 'delete($sessionId)');
    await _ref.read(workoutGatewayProvider).deleteSession(sessionId);
    _ref.invalidate(historyProvider);
  }
}

final deleteWorkoutSessionProvider = Provider<DeleteWorkoutSession>(DeleteWorkoutSession.new);
