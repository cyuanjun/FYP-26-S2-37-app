import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/fitness_plan.dart';
import '../../entities/planned_workout.dart';

/// BOUNDARY (gateway) — `fitness_plans` + `planned_workouts`. Controls call
/// this; the UI never queries Supabase directly.
class PlanGateway {
  PlanGateway(this._client);

  final SupabaseClient _client;

  /// The user's active plan, or null when none.
  Future<FitnessPlan?> fetchActivePlan(String userId) async {
    final row = await _client
        .from('fitness_plans')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
    return row == null ? null : FitnessPlan.fromJson(row);
  }

  Future<FitnessPlan?> fetchPlan(String planId) async {
    final row = await _client
        .from('fitness_plans')
        .select()
        .eq('id', planId)
        .maybeSingle();
    return row == null ? null : FitnessPlan.fromJson(row);
  }

  Future<List<FitnessPlan>> listPlans(String userId) async {
    final rows = await _client
        .from('fitness_plans')
        .select()
        .eq('user_id', userId)
        .order('is_active', ascending: false)
        .order('started_at', ascending: false);
    return rows.map(FitnessPlan.fromJson).toList();
  }

  Future<List<PlannedWorkout>> listPlannedWorkouts(String planId) async {
    final rows = await _client
        .from('planned_workouts')
        .select()
        .eq('fitness_plan_id', planId)
        .order('week_number', ascending: true)
        .order('day_of_week', ascending: true)
        .order('order_index', ascending: true);
    return rows.map(PlannedWorkout.fromJson).toList();
  }

  /// Inserts a plan + its weekly template. Deactivates any prior active plan
  /// first (unique partial index allows one active plan per user).
  Future<FitnessPlan> insertPlan({
    required String userId,
    required String fitnessGoalId,
    required Map<String, dynamic> plan,
    required List<Map<String, dynamic>> workouts,
  }) async {
    await _client
        .from('fitness_plans')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    final row = await _client.from('fitness_plans').insert({
      'user_id': userId,
      'fitness_goal_id': fitnessGoalId,
      'started_at': DateTime.now().toUtc().toIso8601String(),
      ...plan,
    }).select().single();
    final created = FitnessPlan.fromJson(row);

    if (workouts.isNotEmpty) {
      await _client.from('planned_workouts').insert([
        for (final w in workouts) {'fitness_plan_id': created.id, ...w},
      ]);
    }
    return created;
  }

  Future<void> setActivePlan({
    required String userId,
    required String planId,
  }) async {
    await _client
        .from('fitness_plans')
        .update({'is_active': false})
        .eq('user_id', userId)
        .eq('is_active', true);

    await _client.from('fitness_plans').update({
      'is_active': true,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', planId).eq('user_id', userId);
  }
}

final planGatewayProvider =
    Provider<PlanGateway>((ref) => PlanGateway(Supabase.instance.client));
