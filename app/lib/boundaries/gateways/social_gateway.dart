import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/strings.dart';
import '../../entities/challenge.dart';
import '../../entities/feed_post.dart';
import '../../entities/post_comment.dart';
import '../../entities/public_profile.dart';

/// One `challenge_leaderboards` RPC row.
typedef LeaderboardRow = ({String challengeId, String userId, num value, int rank});

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

  /// The caller's workout_share post for a session, if they shared it —
  /// backs the History→Social "View shared post" link (#12.1).
  Future<String?> findSharePostId(
      {required String sessionId, required String me}) async {
    final row = await _client
        .from('posts')
        .select('id')
        .eq('workout_session_id', sessionId)
        .eq('user_id', me)
        .eq('kind', 'workout_share')
        .maybeSingle();
    return row?['id'] as String?;
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

  // ---- Friends (#11.2, US24). Mutual pairs are written atomically by the
  // SECURITY DEFINER RPCs — RLS forbids inserting the reciprocal row. ----

  Future<void> addFriend(String targetId) =>
      _client.rpc('add_friend', params: {'p_target': targetId});

  Future<void> removeFriend(String targetId) =>
      _client.rpc('remove_friend', params: {'p_target': targetId});

  Future<bool> isFriend(String me, String other) async {
    final row = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', me)
        .eq('following_id', other)
        .maybeSingle();
    return row != null;
  }

  Future<List<PublicProfile>> listFriends(String userId) async {
    final rows = await _client
        .from('follows')
        .select('friend:public_profiles!follows_following_id_fkey('
            'id, first_name, last_name, username, avatar_url, level)')
        .eq('follower_id', userId);
    return rows
        .map((r) => PublicProfile.fromJson(r['friend'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<PublicProfile>> searchUsers(String query,
      {required String excludeId}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final rows = await _client
        .from('public_profiles')
        .select('id, first_name, last_name, username, avatar_url, level')
        .or('first_name.ilike.%$q%,last_name.ilike.%$q%,username.ilike.%$q%')
        .neq('id', excludeId)
        .limit(20);
    return rows.map(PublicProfile.fromJson).toList();
  }

  Future<PublicProfile?> fetchPublicProfile(String userId) async {
    final row = await _client
        .from('public_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : PublicProfile.fromJson(row);
  }

  /// Workouts + active-days for the #11.2 stats row, from the privacy view.
  Future<({int workouts, int activeDays})> userStats(String userId) async {
    final rows = await _client
        .from('public_workout_sessions')
        .select('ended_at')
        .eq('user_id', userId)
        .not('ended_at', 'is', null);
    final days = <String>{};
    for (final r in rows) {
      final d = DateTime.parse(r['ended_at'] as String).toLocal();
      days.add('${d.year}-${d.month}-${d.day}');
    }
    return (workouts: rows.length, activeDays: days.length);
  }

  /// A user's own posts, newest first (#11.2 Recent Posts).
  Future<List<FeedPost>> listUserPosts(String userId,
      {required String me, int limit = 20}) async {
    final rows = await _client
        .from('posts')
        .select(_feedSelect)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map((r) => FeedPost.fromRow(r, me: me)).toList();
  }

  // ---- Challenges (#11/#11.3, US25). Progress is live-computed by the
  // challenge_leaderboards SQL function — nothing stored. ----

  /// All challenges with their participant ids (count + joined-state in one
  /// call via the embedded rows).
  Future<List<(Challenge, List<String>)>> listChallenges() async {
    final rows = await _client
        .from('challenges')
        .select('*, participants:challenge_participants(user_id)')
        .order('ended_at', ascending: false);
    return rows.map((r) {
      final participants = (r['participants'] as List? ?? const [])
          .map((p) => (p as Map<String, dynamic>)['user_id'] as String)
          .toList();
      return (Challenge.fromJson(r), participants);
    }).toList();
  }

  /// Resolve a shared join code → the challenge (null if no match). Codes are
  /// stored uppercase; the caller normalises before calling.
  Future<Challenge?> findChallengeByCode(String code) async {
    final row = await _client
        .from('challenges')
        .select()
        .eq('join_code', code)
        .maybeSingle();
    return row == null ? null : Challenge.fromJson(row);
  }

  /// Batched leaderboards — one RPC for every visible challenge card.
  Future<List<LeaderboardRow>> leaderboards(List<String> challengeIds) async {
    if (challengeIds.isEmpty) return const [];
    final rows = await _client.rpc('challenge_leaderboards',
        params: {'p_challenge_ids': challengeIds}) as List;
    return rows
        .map((r) => (
              challengeId: (r as Map<String, dynamic>)['challenge_id'] as String,
              userId: r['user_id'] as String,
              value: r['value'] as num,
              rank: (r['rank'] as num).toInt(),
            ))
        .toList();
  }

  Future<List<PublicProfile>> profilesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('public_profiles')
        .select('id, first_name, last_name, username, avatar_url, level')
        .inFilter('id', ids);
    return rows.map(PublicProfile.fromJson).toList();
  }

  /// Idempotent join (composite key upsert).
  Future<void> joinChallenge(String challengeId, String userId) =>
      _client.from('challenge_participants').upsert(
        {'challenge_id': challengeId, 'user_id': userId},
        onConflict: 'challenge_id,user_id',
        ignoreDuplicates: true,
      );

  Future<void> leaveChallenge(String challengeId, String userId) => _client
      .from('challenge_participants')
      .delete()
      .match({'challenge_id': challengeId, 'user_id': userId});

  /// Insert + creator auto-join (spec-mandated, 11-social.md).
  Future<Challenge> createChallenge({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    final row = await _client
        .from('challenges')
        .insert({'created_by_user_id': userId, ...fields})
        .select()
        .single();
    final challenge = Challenge.fromJson(row);
    await joinChallenge(challenge.id, userId);
    return challenge;
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
