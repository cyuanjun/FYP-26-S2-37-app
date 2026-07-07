import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/workout_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/enums.dart';
import '../entities/workout_type.dart';
import 'authenticate.dart';
import 'view_profile.dart';
import 'workout_history.dart';

/// CONTROL — Log Manual Workout (US13). A manual entry is a normal session
/// with no source device (connected_device_id = null): insert → finalize via
/// the same `end_workout_session` RPC (which honours the backdated
/// `started_at` and computes XP/streak/level-up server-side) → optional
/// feel/notes via the summary path. Calories use the same MET estimate as
/// live capture.
class LogManualWorkout {
  LogManualWorkout(this._ref);

  final Ref _ref;

  /// Returns the RPC result ({xp_gained, leveled_up, ...}) for the snackbar.
  Future<Map<String, dynamic>> call({
    required WorkoutType type,
    required DateTime startedAt,
    required Duration duration,
    int? distanceMeters,
    FeelRating? feelRating,
    String? notes,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) throw StateError('Not signed in');

    SeqLog.msg('log-manual-workout', 'ManualEntryScreen', 'LogManualWorkout',
        'log(${type.slug}, ${duration.inMinutes}m)');

    final fitness = await _ref.read(fitnessProfileProvider.future);
    final calories = type.estimateCalories(
      durationSeconds: duration.inSeconds,
      weightKg: fitness?.weightKg,
      sex: fitness?.sex,
    );

    final gateway = _ref.read(workoutGatewayProvider);
    SeqLog.msg('log-manual-workout', 'LogManualWorkout', 'WorkoutGateway',
        'startSession(manual — no device)');
    final session = await gateway.startSession(
        userId: userId, workoutTypeId: type.id, connectedDeviceId: null);

    SeqLog.msg('log-manual-workout', 'LogManualWorkout', 'WorkoutGateway',
        'endSession(rpc, backdated)');
    final result = await gateway.endSession(sessionId: session.id, metrics: {
      'started_at': startedAt.toUtc().toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'calories_burned': calories,
      if (type.isCardio && distanceMeters != null)
        'distance_meters': distanceMeters,
    });

    if (feelRating != null || notes.isNotBlank) {
      await gateway.updateSummary(
          sessionId: session.id, feelRating: feelRating, notes: notes);
    }

    _ref.invalidate(historyProvider);
    _ref.invalidate(fitnessProfileProvider); // XP / streak moved
    return result;
  }
}

final logManualWorkoutProvider =
    Provider<LogManualWorkout>(LogManualWorkout.new);
