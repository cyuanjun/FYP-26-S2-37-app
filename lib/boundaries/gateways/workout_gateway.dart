import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/workout_session.dart';
import '../../entities/workout_type.dart';

/// BOUNDARY (gateway) — `workout_types` + `workout_sessions` CRUD and the
/// `end_workout_session` RPC. Controls call this; the UI never queries Supabase.
class WorkoutGateway {
  WorkoutGateway(this._client);

  final SupabaseClient _client;

  Future<List<WorkoutType>> listWorkoutTypes() async {
    final rows = await _client.from('workout_types').select().order('name');
    return rows.map(WorkoutType.fromJson).toList();
  }

  /// Inserts a fresh free-form session (StartWorkoutSession use case).
  Future<WorkoutSession> startSession({
    required String userId,
    required String workoutTypeId,
  }) async {
    final row = await _client.from('workout_sessions').insert({
      'user_id': userId,
      'workout_type_id': workoutTypeId,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();
    return WorkoutSession.fromJson(row);
  }

  /// Finalizes the session atomically (EndWorkoutSession use case) — returns the
  /// RPC result: { xp_gained, total_xp, new_level, leveled_up, current_streak }.
  Future<Map<String, dynamic>> endSession({
    required String sessionId,
    required Map<String, dynamic> metrics,
  }) async {
    final res = await _client.rpc('end_workout_session', params: {
      'p_session_id': sessionId,
      'p_metrics': metrics,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Captures the post-session inputs from the summary screen.
  Future<void> updateSummary({
    required String sessionId,
    String? customName,
    FeelRating? feelRating,
    String? notes,
  }) async {
    final patch = <String, dynamic>{};
    if (customName != null && customName.trim().isNotEmpty) patch['custom_name'] = customName.trim();
    if (feelRating != null) patch['feel_rating'] = feelRating.name;
    if (notes != null && notes.trim().isNotEmpty) patch['notes'] = notes.trim();
    if (patch.isEmpty) return;
    await _client.from('workout_sessions').update(patch).eq('id', sessionId);
  }
}

final workoutGatewayProvider =
    Provider<WorkoutGateway>((ref) => WorkoutGateway(Supabase.instance.client));

/// The seeded workout-type catalog (Train screen picker).
final workoutTypesProvider = FutureProvider<List<WorkoutType>>(
  (ref) => ref.watch(workoutGatewayProvider).listWorkoutTypes(),
);
