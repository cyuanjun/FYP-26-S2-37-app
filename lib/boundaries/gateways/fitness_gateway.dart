import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/enums.dart';
import '../../entities/fitness_goal.dart';
import '../../entities/fitness_profile.dart';
import '../../entities/health_tag.dart';

/// BOUNDARY (gateway) — `fitness_profiles`, `fitness_goals`, and the
/// `health_tags` catalog (#13.1 / #13.2). Controls call this; the UI never
/// queries Supabase directly.
class FitnessGateway {
  FitnessGateway(this._client);

  final SupabaseClient _client;

  Future<FitnessProfile> fetchFitnessProfile(String userId) async {
    final row = await _client.from('fitness_profiles').select().eq('id', userId).single();
    return FitnessProfile.fromJson(row);
  }

  /// Batched Save Profile commit (#13.1) — one update with every edited field.
  Future<void> updateFitnessProfile(String userId, Map<String, dynamic> patch) async {
    if (patch.isEmpty) return;
    await _client.from('fitness_profiles').update(patch).eq('id', userId);
  }

  Future<List<HealthTag>> listHealthTags() async {
    final rows = await _client.from('health_tags').select().order('name');
    return rows.map(HealthTag.fromJson).toList();
  }

  /// User-added catalog entry ("+ Add X" in the picker — e.g. "Sesame").
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

  /// The user's active goal (achieved_at IS NULL), or null when none set.
  Future<FitnessGoal?> fetchActiveGoal(String userId) async {
    final row = await _client
        .from('fitness_goals')
        .select()
        .eq('user_id', userId)
        .isFilter('achieved_at', null)
        .maybeSingle();
    return row == null ? null : FitnessGoal.fromJson(row);
  }

  /// Upsert-by-convention: patch the active goal or insert a fresh one.
  /// The unique partial index (user_id WHERE achieved_at IS NULL) guarantees
  /// at most one active row.
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

final fitnessGatewayProvider =
    Provider<FitnessGateway>((ref) => FitnessGateway(Supabase.instance.client));
