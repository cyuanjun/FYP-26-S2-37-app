import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/fitness_goal.dart';
import '../../entities/fitness_profile.dart';
import '../../entities/health_tag.dart';

// (#) Reads and writes the fitness_profiles and fitness_goals tables plus the
// (#) health-tag catalog. Controls use it to load and save a user's fitness
// (#) details and their current goal.
class FitnessGateway {
  // (#) Keeps the Supabase client used for all fitness queries.
  FitnessGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for table calls

  // (#) Loads a user's fitness profile row.
  Future<FitnessProfile> fetchFitnessProfile(String userId) async {
    final row = await _client.from('fitness_profiles').select().eq('id', userId).single();
    return FitnessProfile.fromJson(row);
  }

  // (#) Saves the edited fitness-profile fields in one update, skipping if empty.
  Future<void> updateFitnessProfile(String userId, Map<String, dynamic> patch) async {
    if (patch.isEmpty) return;
    await _client.from('fitness_profiles').update(patch).eq('id', userId);
  }

  // (#) Loads the whole health-tag catalog, sorted by name, for the pickers.
  Future<List<HealthTag>> listHealthTags() async {
    final rows = await _client.from('health_tags').select().order('name');
    return rows.map(HealthTag.fromJson).toList();
  }

  // (#) Adds a user's own health tag when they use the "+ Add" option.
  Future<HealthTag> addCustomHealthTag({
    required String userId,
    required HealthTagKind kind,
    required String name,
  }) async {
    final row = await _client.from('health_tags').insert({
      'kind': kind.name,
      'name': name.trim(),
      'is_custom': true,
      'created_by_user_id': userId,
    }).select().single();
    return HealthTag.fromJson(row);
  }

  // (#) Loads the user's current unachieved goal, or null if they have none.
  Future<FitnessGoal?> fetchActiveGoal(String userId) async {
    final row = await _client
        .from('fitness_goals')
        .select()
        .eq('user_id', userId)
        .isFilter('achieved_at', null)
        .maybeSingle();
    return row == null ? null : FitnessGoal.fromJson(row);
  }

  // (#) Saves the active goal: updates the existing one if there is one, else
  // (#) inserts a new one. A unique index keeps it to one active goal per user.
  Future<FitnessGoal> upsertActiveGoal({
    required String userId,
    required Map<String, dynamic> values,
  }) async {
    final existing = await fetchActiveGoal(userId);
    if (existing != null) {
      final row = await _client
          .from('fitness_goals')
          .update(values)
          .eq('id', existing.id)
          .select()
          .single();
      return FitnessGoal.fromJson(row);
    }
    final row = await _client
        .from('fitness_goals')
        .insert({'user_id': userId, ...values})
        .select()
        .single();
    return FitnessGoal.fromJson(row);
  }
}

// (#) Riverpod provider handing out the fitness gateway on the live client.
final fitnessGatewayProvider =
    Provider<FitnessGateway>((ref) => FitnessGateway(Supabase.instance.client));
