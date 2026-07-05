import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/strings.dart';
import '../../entities/feed_post.dart';
import '../../entities/post_comment.dart';

/// BOUNDARY (gateway) — posts, likes, and comments (#11 Social). Sharing a
/// workout means a `workout_share` Post exists for the session; the feed is
/// read through the privacy views (`public_profiles`, `public_workout_sessions`
/// — never notes or emails).
class SocialGateway {
  SocialGateway(this._client);

  final SupabaseClient _client;

  /// One embedded select per feed row: post + author + wrapped session +
  /// like/comment rows (counted client-side — PostgREST aggregates are
  /// disabled on hosted). The FK hints disambiguate posts→public_profiles
  /// (author FK vs the many-to-many through post_likes).
  static const _feedSelect = '''
    id, user_id, kind, workout_session_id, challenge_id, level, body, created_at,
    author:public_profiles!posts_user_id_fkey(
      id, first_name, last_name, username, avatar_url, level),
    session:public_workout_sessions!posts_workout_session_id_fkey(
      id, user_id, workout_type_id, started_at, ended_at, duration_seconds,
      distance_meters, calories_burned, avg_heart_rate, max_heart_rate,
      feel_rating, custom_name),
    likes:post_likes(user_id),
    comments:post_comments(id)
  ''';

  /// Feed scope is friends + self (11-social.md — no see-everyone mode).
  Future<List<FeedPost>> fetchFeed({
    required String userId,
    required List<String> friendIds,
    int limit = 50,
  }) async {
    final rows = await _client
        .from('posts')
        .select(_feedSelect)
        .inFilter('user_id', [userId, ...friendIds])
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map((r) => FeedPost.fromRow(r, me: userId)).toList();
  }

  Future<FeedPost?> fetchFeedPost(String postId, {required String me}) async {
    final row = await _client
        .from('posts')
        .select(_feedSelect)
        .eq('id', postId)
        .maybeSingle();
    return row == null ? null : FeedPost.fromRow(row, me: me);
  }

  Future<List<PostComment>> listComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select('*, author:public_profiles!post_comments_user_id_fkey('
            'id, first_name, last_name, username, avatar_url, level)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return rows.map(PostComment.fromJson).toList();
  }

  /// Idempotent — a double-tap can't error on the composite key.
  Future<void> likePost(String postId, String userId) =>
      _client.from('post_likes').upsert(
        {'post_id': postId, 'user_id': userId},
        onConflict: 'post_id,user_id',
        ignoreDuplicates: true,
      );

  Future<void> unlikePost(String postId, String userId) => _client
      .from('post_likes')
      .delete()
      .match({'post_id': postId, 'user_id': userId});

  /// Returns the inserted row so the thread can append without refetching.
  Future<PostComment> addComment({
    required String postId,
    required String userId,
    required String body,
  }) async {
    final row = await _client
        .from('post_comments')
        .insert({'post_id': postId, 'user_id': userId, 'body': body.trim()})
        .select()
        .single();
    return PostComment.fromJson(row);
  }

  Future<void> deleteComment(String commentId) =>
      _client.from('post_comments').delete().eq('id', commentId);

  /// Caption edit (#11.1); a trimmed-empty caption clears to null.
  Future<void> updatePostBody(String postId, String? body) =>
      _client.from('posts').update(
          {'body': body.isNotBlank ? body!.trim() : null}).eq('id', postId);

  /// One direction suffices — friendships are stored as mutual pairs.
  Future<List<String>> friendIds(String userId) async {
    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return rows.map((r) => r['following_id'] as String).toList();
  }

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
    if (body.isNotBlank) payload['body'] = body!.trim();
    final row = await _client.from('posts').insert(payload).select('id').single();
    return row['id'] as String;
  }

  Future<void> deletePost(String postId) =>
      _client.from('posts').delete().eq('id', postId);
}

final socialGatewayProvider = Provider<SocialGateway>((ref) => SocialGateway(Supabase.instance.client));
