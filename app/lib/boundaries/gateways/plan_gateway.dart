import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/fitness_plan.dart';
import '../../entities/planned_workout.dart';

// (#) Handles the fitness_plans and planned_workouts tables. Controls use it to
// (#) fetch a user's active plan, list past plans, and save a new one with its
// (#) weekly workouts.
class PlanGateway {
  // (#) Keeps the Supabase client used for all plan queries.
  PlanGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for table calls

  // (#) Loads the user's currently active plan, or null if none is active.
  Future<FitnessPlan?> fetchActivePlan(String userId) async {
    final row = await _client
        .from('fitness_plans')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
    return row == null ? null : FitnessPlan.fromJson(row);
  }

  // (#) Loads one plan by its id, or null if it does not exist.
  Future<FitnessPlan?> fetchPlan(String planId) async {
    final row = await _client
        .from('fitness_plans')
        .select()
        .eq('id', planId)
        .maybeSingle();
    return row == null ? null : FitnessPlan.fromJson(row);
  }

  // (#) Lists all of a user's plans, active one first then newest.
  Future<List<FitnessPlan>> listPlans(String userId) async {
    final rows = await _client
        .from('fitness_plans')
        .select()
        .eq('user_id', userId)
        .order('is_active', ascending: false)
        .order('started_at', ascending: false);
    return rows.map(FitnessPlan.fromJson).toList();
  }

  // (#) Loads a plan's weekly workouts in week, day, then slot order.
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

  // (#) Turns off whatever plan is currently active, since only one can be.
  Future<void> _deactivatePriorPlan(String userId) => _client
      .from('fitness_plans')
      .update({'is_active': false})
      .eq('user_id', userId)
      .eq('is_active', true);

  // (#) Saves a brand-new plan and its weekly workouts, clearing the old active
  // (#) plan first so the user only has one running at a time.
  Future<FitnessPlan> insertPlan({
    required String userId,
    required String fitnessGoalId,
    required Map<String, dynamic> plan,
    required List<Map<String, dynamic>> workouts,
  }) async {
    await _deactivatePriorPlan(userId);

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

  // (#) Switches which existing plan is the active one and restarts its clock.
  Future<void> setActivePlan({
    required String userId,
    required String planId,
  }) async {
    await _deactivatePriorPlan(userId);

    await _client.from('fitness_plans').update({
      'is_active': true,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', planId).eq('user_id', userId);
  }
}

// (#) Riverpod provider handing out the plan gateway on the live client.
final planGatewayProvider =
    Provider<PlanGateway>((ref) => PlanGateway(Supabase.instance.client));
