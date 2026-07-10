import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'workout_history.dart';

// (#) Saves the extras typed on the workout summary screen. It sends the custom
// (#) name, feel rating and notes to the workout gateway, then refreshes history.
class SaveWorkoutDetails {
  SaveWorkoutDetails(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Writes the name/feel/notes for the given session.
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

// (#) Hands the summary screen the SaveWorkoutDetails control.
final saveWorkoutDetailsProvider = Provider<SaveWorkoutDetails>(SaveWorkoutDetails.new);
