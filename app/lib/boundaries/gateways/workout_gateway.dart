import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/workout_session.dart';
import '../../entities/workout_type.dart';
import '../../core/strings.dart';

// (#) Handles the workout_types and workout_sessions tables plus the end-session
// (#) RPC. Controls use it to start, finish, list, and tidy up a user's workouts.
class WorkoutGateway {
  // (#) Keeps the Supabase client used for all workout queries.
  WorkoutGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for table and RPC calls

  // (#) Loads the workout-type catalog, A to Z, for the Train screen picker.
  Future<List<WorkoutType>> listWorkoutTypes() async {
    final rows = await _client.from('workout_types').select().order('name', ascending: true);
    return rows.map(WorkoutType.fromJson).toList();
  }

  // (#) Adds a user's own workout type when they use "+ Add your own". Builds a
  // (#) slug from the name for the calorie lookup later.
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

  // (#) Starts a new workout session row and returns it. connectedDeviceId notes
  // (#) what captured it: the phone, a wearable, or null for a manual entry.
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

  // (#) Finishes a session in one server call and returns the XP, level, and
  // (#) streak results the RPC hands back.
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

  // (#) Loads a user's finished sessions, newest first, for History. from limits
  // (#) the window: Free users pass this month's start, Premium passes nothing.
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

  // (#) Tells whether any finished session exists before a given date, so History
  // (#) can tell "no workouts ever" apart from "older ones hidden by the Free cap".
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

  // (#) Deletes a session by id.
  Future<void> deleteSession(String sessionId) async {
    await _client.from('workout_sessions').delete().eq('id', sessionId);
  }

  // (#) Saves the extras the user adds on the summary screen: a name, a feel
  // (#) rating, and notes. Skips the write if nothing was filled in.
  Future<void> updateSummary({
    required String sessionId,
    String? customName,
    FeelRating? feelRating,
    String? notes,
  }) async {
    final patch = <String, dynamic>{};
    if (customName.isNotBlank) patch['custom_name'] = customName!.trim();
    if (feelRating != null) patch['feel_rating'] = feelRating.name;
    if (notes.isNotBlank) patch['notes'] = notes!.trim();
    if (patch.isEmpty) return;
    await _client.from('workout_sessions').update(patch).eq('id', sessionId);
  }
}

// (#) Riverpod provider handing out the workout gateway on the live client.
final workoutGatewayProvider =
    Provider<WorkoutGateway>((ref) => WorkoutGateway(Supabase.instance.client));

// (#) Provider that loads the workout-type catalog once for the Train picker.
final workoutTypesProvider = FutureProvider<List<WorkoutType>>(
  (ref) => ref.watch(workoutGatewayProvider).listWorkoutTypes(),
);
