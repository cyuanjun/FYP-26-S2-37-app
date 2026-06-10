import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/workout_session.dart';
import 'authenticate.dart';

/// Read-side: the current user's ended sessions (View Workout History activity).
/// Invalidated by EndWorkoutSession / DeleteWorkoutSession / SaveWorkoutDetails.
final historyProvider = FutureProvider<List<WorkoutSession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <WorkoutSession>[]);
  return ref.watch(workoutGatewayProvider).listEndedSessions(userId);
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
