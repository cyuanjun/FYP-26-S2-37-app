import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// BOUNDARY (gateway) — the `posts` table. Sharing a workout means a
/// `workout_share` Post exists for the session (database-v1.md).
class SocialGateway {
  SocialGateway(this._client);

  final SupabaseClient _client;

  Future<String> createWorkoutSharePost({
    required String userId,
    required String workoutSessionId,
    String? body,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
      'kind': 'workout_share',
      'workout_session_id': workoutSessionId,
    };
    if (body != null && body.trim().isNotEmpty) payload['body'] = body.trim();
    final row = await _client.from('posts').insert(payload).select('id').single();
    return row['id'] as String;
  }

  Future<void> deletePost(String postId) =>
      _client.from('posts').delete().eq('id', postId);
}

final socialGatewayProvider = Provider<SocialGateway>((ref) => SocialGateway(Supabase.instance.client));
