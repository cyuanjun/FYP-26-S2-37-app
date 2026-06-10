import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'workout_history.dart';

/// CONTROL — persists the summary-screen inputs (name / feel / notes) for a session.
class SaveWorkoutDetails {
  SaveWorkoutDetails(this._ref);

  final Ref _ref;

  Future<void> call({
    required String sessionId,
    String? customName,
    FeelRating? feelRating,
    String? notes,
  }) async {
    SeqLog.msg('save-workout', 'WorkoutSummaryScreen', 'SaveWorkoutDetails', 'update($sessionId)');
    await _ref.read(workoutGatewayProvider).updateSummary(
          sessionId: sessionId,
          customName: customName,
          feelRating: feelRating,
          notes: notes,
        );
    _ref.invalidate(historyProvider);
  }
}

final saveWorkoutDetailsProvider = Provider<SaveWorkoutDetails>(SaveWorkoutDetails.new);
