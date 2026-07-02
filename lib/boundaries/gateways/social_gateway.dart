import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../entities/challenge.dart';
import '../../entities/post.dart';
import '../../entities/workout_session.dart';

/// BOUNDARY (gateway) — all Social DB operations.
/// Covers posts, likes, comments, friends (follows), and challenges.
/// The UI never queries Supabase directly — always via a Control → this gateway.
class SocialGateway {
  SocialGateway(this._client);

  final SupabaseClient _client;

  // ── Posts ──────────────────────────────────────────────────────────────────

  /// Creates a `workout_share` Post for [workoutSessionId]. Returns the new post id.
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

  /// Deletes a Post row (cascades likes + comments via FK).
  Future<void> deletePost(String postId) =>
      _client.from('posts').delete().eq('id', postId);

  /// Updates the public caption ([body]) of a post. Passing null clears it.
  Future<void> updatePostBody(String postId, String? body) async {
    final value = (body != null && body.trim().isNotEmpty) ? body.trim() : null;
    await _client.from('posts').update({'body': value}).eq('id', postId);
  }

  // ── Feed ───────────────────────────────────────────────────────────────────

  /// Returns the friend ids (following_id) of [userId].
  /// Used to scope the feed to friends + self.
  Future<List<String>> fetchFriendIds(String userId) async {
    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return rows.map<String>((r) => r['following_id'] as String).toList();
  }

  /// Fetches feed posts for [feedUserIds] (friends + current user).
  /// Returns raw maps with nested author, session (+ type), and challenge data.
  /// Ordered newest-first; capped at 50.
  Future<List<Map<String, dynamic>>> fetchFeedPosts(List<String> feedUserIds) async {
    if (feedUserIds.isEmpty) return const [];
    final rows = await _client
        .from('posts')
        .select('''
          id, kind, body, level, created_at, user_id,
          workout_session_id, challenge_id,
          author:profiles!user_id (
            id, first_name, last_name, username, avatar_url
          ),
          session:workout_sessions (
            id, duration_seconds, distance_meters, calories_burned,
            feel_rating, custom_name, started_at, ended_at, workout_type_id,
            type:workout_types ( id, name, slug, is_custom )
          ),
          challenge:challenges (
            id, name, short_name, description, icon,
            visibility, metric_kind, metric, target_value,
            workout_type_id, started_at, ended_at
          )
        ''')
        .inFilter('user_id', feedUserIds)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Fetches a single post with the same nested data as [fetchFeedPosts].
  Future<Map<String, dynamic>> fetchPostById(String postId) async {
    final row = await _client
        .from('posts')
        .select('''
          id, kind, body, level, created_at, user_id,
          workout_session_id, challenge_id,
          author:profiles!user_id (
            id, first_name, last_name, username, avatar_url
          ),
          session:workout_sessions (
            id, duration_seconds, distance_meters, calories_burned,
            feel_rating, custom_name, started_at, ended_at, workout_type_id,
            type:workout_types ( id, name, slug, is_custom )
          ),
          challenge:challenges (
            id, name, short_name, description, icon,
            visibility, metric_kind, metric, target_value,
            workout_type_id, started_at, ended_at
          )
        ''')
        .eq('id', postId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  // ── Likes ──────────────────────────────────────────────────────────────────

  /// Adds a like from [userId] on [postId]. No-op if already liked (duplicate PK).
  Future<void> addLike(String postId, String userId) async {
    await _client
        .from('post_likes')
        .upsert({'post_id': postId, 'user_id': userId});
  }

  /// Removes the like from [userId] on [postId].
  Future<void> removeLike(String postId, String userId) async {
    await _client
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  /// Returns the set of post IDs from [postIds] that [userId] has liked.
  Future<Set<String>> fetchMyLikedPostIds(String userId, List<String> postIds) async {
    if (postIds.isEmpty) return const {};
    final rows = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    return rows.map<String>((r) => r['post_id'] as String).toSet();
  }

  /// Returns a map of post_id → like count for the given [postIds].
  Future<Map<String, int>> fetchLikeCounts(List<String> postIds) async {
    if (postIds.isEmpty) return const {};
    final rows = await _client
        .from('post_likes')
        .select('post_id')
        .inFilter('post_id', postIds);
    final counts = <String, int>{};
    for (final r in rows) {
      final pid = r['post_id'] as String;
      counts[pid] = (counts[pid] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns a map of post_id → comment count for the given [postIds].
  Future<Map<String, int>> fetchCommentCounts(List<String> postIds) async {
    if (postIds.isEmpty) return const {};
    final rows = await _client
        .from('post_comments')
        .select('post_id')
        .inFilter('post_id', postIds);
    final counts = <String, int>{};
    for (final r in rows) {
      final pid = r['post_id'] as String;
      counts[pid] = (counts[pid] ?? 0) + 1;
    }
    return counts;
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  /// Fetches all comments for [postId], oldest-first, with author profile data.
  Future<List<Map<String, dynamic>>> fetchPostComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select('''
          id, post_id, body, created_at, user_id,
          author:profiles!user_id (
            id, first_name, last_name, username, avatar_url
          )
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Inserts a new comment. Returns the created row.
  Future<PostComment> addPostComment({
    required String postId,
    required String userId,
    required String body,
  }) async {
    final row = await _client.from('post_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'body': body.trim(),
    }).select().single();
    return PostComment.fromJson(Map<String, dynamic>.from(row));
  }

  /// Deletes a comment by id (RLS ensures only the author can do this).
  Future<void> deletePostComment(String commentId) =>
      _client.from('post_comments').delete().eq('id', commentId);

  // ── Friends (Follows) ──────────────────────────────────────────────────────

  /// Inserts both directions of a mutual friendship atomically:
  /// A→B and B→A. RLS allows each user to write their own follower row.
  Future<void> followUser(String followerId, String followingId) async {
    await _client.from('follows').upsert([
      {'follower_id': followerId, 'following_id': followingId},
      {'follower_id': followingId, 'following_id': followerId},
    ]);
  }

  /// Removes both directions of a mutual friendship.
  Future<void> unfollowUser(String followerId, String followingId) async {
    await _client
        .from('follows')
        .delete()
        .or('and(follower_id.eq.$followerId,following_id.eq.$followingId),'
            'and(follower_id.eq.$followingId,following_id.eq.$followerId)');
  }

  /// Returns true when [userId] and [targetId] are mutual friends.
  Future<bool> isFriend(String userId, String targetId) async {
    final rows = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', userId)
        .eq('following_id', targetId)
        .limit(1);
    return rows.isNotEmpty;
  }

  /// Returns profile maps for all friends of [userId].
  Future<List<Map<String, dynamic>>> fetchFriendProfiles(String userId) async {
    final friendIds = await fetchFriendIds(userId);
    if (friendIds.isEmpty) return const [];
    final rows = await _client
        .from('profiles')
        .select('id, first_name, last_name, username, avatar_url')
        .inFilter('id', friendIds)
        .order('first_name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Case-insensitive user search by name or username (excluding [excludeId]).
  Future<List<Map<String, dynamic>>> searchUsers(
      String query, String excludeId) async {
    if (query.trim().isEmpty) return const [];
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await _client
        .from('profiles')
        .select('id, first_name, last_name, username, avatar_url')
        .or('first_name.ilike.$q,last_name.ilike.$q,username.ilike.$q')
        .neq('id', excludeId)
        .limit(20);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── User profile ───────────────────────────────────────────────────────────

  /// Fetches a lightweight profile map for any user.
  Future<Map<String, dynamic>> fetchUserById(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, first_name, last_name, username, avatar_url, bio')
        .eq('id', userId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  /// Total count of ended sessions for [userId] (all-time, no cap).
  Future<int> fetchUserWorkoutCount(String userId) async {
    final rows = await _client
        .from('workout_sessions')
        .select('id')
        .eq('user_id', userId)
        .not('ended_at', 'is', null);
    return rows.length;
  }

  /// Count of distinct calendar days with at least one ended session.
  Future<int> fetchUserActiveDays(String userId) async {
    final rows = await _client
        .from('workout_sessions')
        .select('ended_at')
        .eq('user_id', userId)
        .not('ended_at', 'is', null);
    final days = rows
        .map((r) => (r['ended_at'] as String).substring(0, 10))
        .toSet();
    return days.length;
  }

  /// Count of friends (follows where follower_id = userId).
  Future<int> fetchUserFriendCount(String userId) async {
    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return rows.length;
  }

  /// Posts authored by [userId], newest-first, with like/comment counts.
  Future<List<Map<String, dynamic>>> fetchUserPosts(String userId) async {
    final rows = await _client
        .from('posts')
        .select('''
          id, kind, body, level, created_at, user_id,
          workout_session_id, challenge_id,
          session:workout_sessions (
            id, custom_name, started_at,
            type:workout_types ( id, name, slug, is_custom )
          ),
          challenge:challenges ( id, name )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── Challenges ─────────────────────────────────────────────────────────────

  /// All challenges the user has joined that are still in-progress (Joined tab).
  Future<List<Challenge>> fetchJoinedChallenges(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final participantRows = await _client
        .from('challenge_participants')
        .select('challenge_id')
        .eq('user_id', userId);
    final ids =
        participantRows.map<String>((r) => r['challenge_id'] as String).toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('challenges')
        .select()
        .inFilter('id', ids)
        .gte('ended_at', now)
        .order('started_at', ascending: true);
    return rows.map((r) => Challenge.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  /// All public in-progress challenges (Active tab) — browseable by anyone.
  Future<List<Challenge>> fetchActiveChallenges() async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _client
        .from('challenges')
        .select()
        .eq('visibility', 'public')
        .gte('ended_at', now)
        .order('started_at', ascending: true);
    return rows.map((r) => Challenge.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  /// Challenges the user joined that have already ended (Past tab).
  Future<List<Challenge>> fetchPastChallenges(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final participantRows = await _client
        .from('challenge_participants')
        .select('challenge_id')
        .eq('user_id', userId);
    final ids =
        participantRows.map<String>((r) => r['challenge_id'] as String).toList();
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('challenges')
        .select()
        .inFilter('id', ids)
        .lt('ended_at', now)
        .order('ended_at', ascending: false);
    return rows.map((r) => Challenge.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  /// Single challenge by id.
  Future<Challenge> fetchChallengeById(String challengeId) async {
    final row =
        await _client.from('challenges').select().eq('id', challengeId).single();
    return Challenge.fromJson(Map<String, dynamic>.from(row));
  }

  /// Inserts a new challenge and auto-joins [creatorId] as a participant.
  /// Returns the created challenge.
  Future<Challenge> createChallenge({
    required String creatorId,
    required Map<String, dynamic> data,
  }) async {
    final row = await _client
        .from('challenges')
        .insert({...data, 'created_by_user_id': creatorId})
        .select()
        .single();
    final challenge = Challenge.fromJson(Map<String, dynamic>.from(row));
    await joinChallenge(challenge.id, creatorId);
    return challenge;
  }

  /// Adds [userId] as a participant. Idempotent (upsert).
  Future<void> joinChallenge(String challengeId, String userId) async {
    await _client.from('challenge_participants').upsert(
        {'challenge_id': challengeId, 'user_id': userId});
  }

  /// Removes [userId] from a challenge.
  Future<void> leaveChallenge(String challengeId, String userId) async {
    await _client
        .from('challenge_participants')
        .delete()
        .eq('challenge_id', challengeId)
        .eq('user_id', userId);
  }

  /// Returns the set of user IDs who have joined [challengeId].
  Future<Set<String>> fetchParticipantIds(String challengeId) async {
    final rows = await _client
        .from('challenge_participants')
        .select('user_id')
        .eq('challenge_id', challengeId);
    return rows.map<String>((r) => r['user_id'] as String).toSet();
  }

  /// Returns participants with their profile data for the leaderboard.
  Future<List<Map<String, dynamic>>> fetchParticipantsWithProfiles(
      String challengeId) async {
    final rows = await _client
        .from('challenge_participants')
        .select('''
          challenge_id, user_id, workout_session_id,
          profile:profiles!user_id (
            id, first_name, last_name, username, avatar_url
          )
        ''')
        .eq('challenge_id', challengeId);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Ended sessions for [userId] that fall within [windowStart]..[windowEnd],
  /// optionally filtered by [workoutTypeId]. Used for challenge progress.
  Future<List<WorkoutSession>> fetchSessionsInWindow({
    required String userId,
    required DateTime windowStart,
    required DateTime windowEnd,
    String? workoutTypeId,
  }) async {
    var query = _client
        .from('workout_sessions')
        .select()
        .eq('user_id', userId)
        .not('ended_at', 'is', null)
        .gte('started_at', windowStart.toUtc().toIso8601String())
        .lte('started_at', windowEnd.toUtc().toIso8601String());
    if (workoutTypeId != null) {
      query = query.eq('workout_type_id', workoutTypeId);
    }
    final rows = await query.order('started_at', ascending: true);
    return rows.map((r) => WorkoutSession.fromJson(Map<String, dynamic>.from(r))).toList();
  }
}

final socialGatewayProvider =
    Provider<SocialGateway>((ref) => SocialGateway(Supabase.instance.client));
