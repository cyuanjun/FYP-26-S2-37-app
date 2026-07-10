import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/strings.dart';
import '../../entities/challenge.dart';
import '../../entities/feed_post.dart';
import '../../entities/post_comment.dart';
import '../../entities/public_profile.dart';

// (#) One row of a challenge leaderboard: who, their score, and their rank.
typedef LeaderboardRow = ({String challengeId, String userId, num value, int rank});

// (#) The whole social side of Supabase: feed posts, likes, comments, friends,
// (#) and challenges. Controls use it to read the feed and to like, comment, add
// (#) a friend, or join a challenge. Reads go through privacy views, never notes.
class SocialGateway {
  // (#) Keeps the Supabase client used across all social queries.
  SocialGateway(this._client);

  final SupabaseClient _client; // (#) the Supabase client for every query here

  // (#) The columns pulled for each feed row: the post, its author, the wrapped
  // (#) session, and the like/comment rows we count on the app side.
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

  // (#) Loads the feed, newest first, showing only the user's own and friends'
  // (#) posts. There is no see-everyone mode by design.
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

  // (#) Loads a single feed post by id, or null if it is gone.
  Future<FeedPost?> fetchFeedPost(String postId, {required String me}) async {
    final row = await _client
        .from('posts')
        .select(_feedSelect)
        .eq('id', postId)
        .maybeSingle();
    return row == null ? null : FeedPost.fromRow(row, me: me);
  }

  // (#) Finds the id of the user's share post for a session, if they shared it,
  // (#) so History can link over to it. Null when they never shared.
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

  // (#) Loads a post's comments oldest first, each with its author's public info.
  Future<List<PostComment>> listComments(String postId) async {
    final rows = await _client
        .from('post_comments')
        .select('*, author:public_profiles!post_comments_user_id_fkey('
            'id, first_name, last_name, username, avatar_url, level)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return rows.map(PostComment.fromJson).toList();
  }

  // (#) Likes a post. Safe to tap twice, a repeat like just does nothing.
  Future<void> likePost(String postId, String userId) =>
      _client.from('post_likes').upsert(
        {'post_id': postId, 'user_id': userId},
        onConflict: 'post_id,user_id',
        ignoreDuplicates: true,
      );

  // (#) Removes the user's like from a post.
  Future<void> unlikePost(String postId, String userId) => _client
      .from('post_likes')
      .delete()
      .match({'post_id': postId, 'user_id': userId});

  // (#) Adds a comment and returns the new row so the thread can show it at once.
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

  // (#) Deletes a comment by id.
  Future<void> deleteComment(String commentId) =>
      _client.from('post_comments').delete().eq('id', commentId);

  // (#) Edits a post's caption. An empty caption clears it back to null.
  Future<void> updatePostBody(String postId, String? body) =>
      _client.from('posts').update(
          {'body': body.isNotBlank ? body!.trim() : null}).eq('id', postId);

  // (#) Lists the ids of a user's friends. One direction is enough since
  // (#) friendships are stored as matching pairs.
  Future<List<String>> friendIds(String userId) async {
    final rows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return rows.map((r) => r['following_id'] as String).toList();
  }

  // (#) Friends live below. Both sides of a friendship are written by server
  // (#) RPCs in one go, since RLS won't let us insert the other person's row.

  // (#) Adds the target as a friend via the add_friend RPC.
  Future<void> addFriend(String targetId) =>
      _client.rpc('add_friend', params: {'p_target': targetId});

  // (#) Removes the target as a friend via the remove_friend RPC.
  Future<void> removeFriend(String targetId) =>
      _client.rpc('remove_friend', params: {'p_target': targetId});

  // (#) Checks whether two users are already friends.
  Future<bool> isFriend(String me, String other) async {
    final row = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', me)
        .eq('following_id', other)
        .maybeSingle();
    return row != null;
  }

  // (#) Loads a user's friends as public profiles for the friends list.
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

  // (#) Searches people by name or username, skipping the caller. Empty query
  // (#) returns nothing.
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

  // (#) Loads one user's public profile, or null if not found.
  Future<PublicProfile?> fetchPublicProfile(String userId) async {
    final row = await _client
        .from('public_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : PublicProfile.fromJson(row);
  }

  // (#) Counts a user's total workouts and how many distinct days they trained,
  // (#) for the stats row on their profile.
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

  // (#) Loads a user's own posts, newest first, for their profile's recent posts.
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

  // (#) Challenges live below. Standings are worked out on the fly by a SQL
  // (#) function, so nothing about progress is stored.

  // (#) Loads every challenge with the ids of who joined, for the challenge cards.
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

  // (#) Looks up a challenge by its shared join code, or null if none matches.
  Future<Challenge?> findChallengeByCode(String code) async {
    final row = await _client
        .from('challenges')
        .select()
        .eq('join_code', code)
        .maybeSingle();
    return row == null ? null : Challenge.fromJson(row);
  }

  // (#) Fetches leaderboard rows for many challenges at once via one RPC.
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

  // (#) Loads public profiles for a set of ids, used to name people on leaderboards.
  Future<List<PublicProfile>> profilesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('public_profiles')
        .select('id, first_name, last_name, username, avatar_url, level')
        .inFilter('id', ids);
    return rows.map(PublicProfile.fromJson).toList();
  }

  // (#) Joins a user to a challenge. Safe to call twice, a repeat does nothing.
  Future<void> joinChallenge(String challengeId, String userId) =>
      _client.from('challenge_participants').upsert(
        {'challenge_id': challengeId, 'user_id': userId},
        onConflict: 'challenge_id,user_id',
        ignoreDuplicates: true,
      );

  // (#) Removes a user from a challenge.
  Future<void> leaveChallenge(String challengeId, String userId) => _client
      .from('challenge_participants')
      .delete()
      .match({'challenge_id': challengeId, 'user_id': userId});

  // (#) Creates a challenge and joins its creator into it straight away.
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

  // (#) Posts a workout to the feed as a share, with an optional caption, and
  // (#) returns the new post's id.
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

  // (#) Deletes a post by id.
  Future<void> deletePost(String postId) =>
      _client.from('posts').delete().eq('id', postId);
}

// (#) Riverpod provider handing out the social gateway on the live client.
final socialGatewayProvider = Provider<SocialGateway>((ref) => SocialGateway(Supabase.instance.client));
