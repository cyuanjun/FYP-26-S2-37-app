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
    final rows = await _client.from('workout_types').select().order('name', ascending: true);
    return rows.map(WorkoutType.fromJson).toList();
  }

  /// User-added catalog entry ("+ Add your own" in pickers). Slug derived from
  /// the name; unknown slugs fall back to a moderate MET for calories.
  Future<WorkoutType> addCustomWorkoutType({
    required String userId,
    required String name,
  }) async {
    final slug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final row = await _client.from('workout_types').insert({
      'name': name.trim(),
      'slug': slug,
      'is_custom': true,
      'created_by_user_id': userId,
    }).select().single();
    return WorkoutType.fromJson(row);
  }

  /// Inserts a fresh free-form session (StartWorkoutSession use case).
  /// [connectedDeviceId] records the capture source (phone-sensors row for
  /// in-app GPS capture, a wearable row when one is active; null = manual).
  Future<WorkoutSession> startSession({
    required String userId,
    required String workoutTypeId,
    String? connectedDeviceId,
  }) async {
    final row = await _client.from('workout_sessions').insert({
      'user_id': userId,
      'workout_type_id': workoutTypeId,
      'connected_device_id': ?connectedDeviceId,
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

  /// Ended sessions for a user, newest first (History list). [from] bounds
  /// the window at the query level — the Free monthly cap passes the start of
  /// the current calendar month; Premium passes nothing (lifetime).
  Future<List<WorkoutSession>> listEndedSessions(String userId, {DateTime? from}) async {
    var query = _client
        .from('workout_sessions')
        .select()
        .eq('user_id', userId)
        .not('ended_at', 'is', null);
    if (from != null) {
      query = query.gte('started_at', from.toUtc().toIso8601String());
    }
    final rows = await query.order('started_at', ascending: false);
    return rows.map(WorkoutSession.fromJson).toList();
  }

  /// Whether the user has any ended session that started before [before].
  /// Lets History tell "no workouts ever" apart from "earlier workouts exist
  /// but are hidden by the Free monthly cap". Limited to 1 row (existence only).
  Future<bool> hasEndedSessionsBefore(String userId, DateTime before) async {
    final rows = await _client
        .from('workout_sessions')
        .select('id')
        .eq('user_id', userId)
        .not('ended_at', 'is', null)
        .lt('started_at', before.toUtc().toIso8601String())
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('workout_sessions').delete().eq('id', sessionId);
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
