import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/challenge.dart';
import '../entities/enums.dart';
import '../entities/workout_session.dart';
import '../entities/workout_type.dart';
import 'authenticate.dart';

// ── View models ───────────────────────────────────────────────────────────────

/// Lightweight author snapshot embedded in a [FeedPost].
class PostAuthor {
  const PostAuthor({
    required this.id,
    required this.displayName,
    this.handle,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? handle;
  final String? avatarUrl;

  static PostAuthor fromMap(Map<String, dynamic> m) => PostAuthor(
        id: m['id'] as String,
        displayName: _name(m),
        handle: m['username'] as String?,
        avatarUrl: m['avatar_url'] as String?,
      );

  static String _name(Map<String, dynamic> m) {
    final first = m['first_name'] as String? ?? '';
    final last = m['last_name'] as String? ?? '';
    final full = '$first $last'.trim();
    return full.isNotEmpty ? full : (m['username'] as String? ?? 'User');
  }
}

/// Assembled view model for one entry in the Social community feed.
/// Combines post data, author profile, optional session/challenge payload,
/// and like/comment interaction counts. Not a freezed entity — assembled in
/// the control layer from multiple Supabase queries.
class FeedPost {
  const FeedPost({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.author,
    this.body,
    // workout_share fields
    this.sessionId,
    this.sessionDurationSeconds,
    this.sessionDistanceMeters,
    this.sessionCaloriesBurned,
    this.sessionCustomName,
    this.sessionTypeName,
    this.sessionTypeSlug,
    this.sessionTypeId,
    // challenge_result fields
    this.challenge,
    // level_up fields
    this.level,
    // interaction counts
    this.likeCount = 0,
    this.likedByMe = false,
    this.commentCount = 0,
  });

  final String id;
  final PostKind kind;
  final DateTime createdAt;
  final PostAuthor author;
  final String? body;

  // workout_share
  final String? sessionId;
  final int? sessionDurationSeconds;
  final int? sessionDistanceMeters;
  final int? sessionCaloriesBurned;
  final String? sessionCustomName;
  final String? sessionTypeName;
  final String? sessionTypeSlug;
  final String? sessionTypeId;

  // challenge_result
  final Challenge? challenge;

  // level_up
  final int? level;

  // interaction
  final int likeCount;
  final bool likedByMe;
  final int commentCount;

  FeedPost withCounts({
    required int likeCount,
    required bool likedByMe,
    required int commentCount,
  }) =>
      FeedPost(
        id: id,
        kind: kind,
        createdAt: createdAt,
        author: author,
        body: body,
        sessionId: sessionId,
        sessionDurationSeconds: sessionDurationSeconds,
        sessionDistanceMeters: sessionDistanceMeters,
        sessionCaloriesBurned: sessionCaloriesBurned,
        sessionCustomName: sessionCustomName,
        sessionTypeName: sessionTypeName,
        sessionTypeSlug: sessionTypeSlug,
        sessionTypeId: sessionTypeId,
        challenge: challenge,
        level: level,
        likeCount: likeCount,
        likedByMe: likedByMe,
        commentCount: commentCount,
      );

  /// Parses a raw Supabase row (from [SocialGateway.fetchFeedPosts]) into a
  /// [FeedPost], excluding interaction counts (those are fetched separately).
  static FeedPost fromMap(Map<String, dynamic> m) {
    final authorMap = m['author'] as Map<String, dynamic>?;
    final author = authorMap != null
        ? PostAuthor.fromMap(authorMap)
        : PostAuthor(id: m['user_id'] as String, displayName: 'User');

    final sessionMap = m['session'] as Map<String, dynamic>?;
    final typeMap = sessionMap != null
        ? sessionMap['type'] as Map<String, dynamic>?
        : null;

    final challengeMap = m['challenge'] as Map<String, dynamic>?;
    final challenge =
        challengeMap != null ? Challenge.fromJson(challengeMap) : null;

    return FeedPost(
      id: m['id'] as String,
      kind: PostKind.values.byName(_camel(m['kind'] as String)),
      createdAt: DateTime.parse(m['created_at'] as String),
      author: author,
      body: m['body'] as String?,
      sessionId: sessionMap?['id'] as String?,
      sessionDurationSeconds: sessionMap?['duration_seconds'] as int?,
      sessionDistanceMeters: sessionMap?['distance_meters'] as int?,
      sessionCaloriesBurned: sessionMap?['calories_burned'] as int?,
      sessionCustomName: sessionMap?['custom_name'] as String?,
      sessionTypeName: typeMap?['name'] as String?,
      sessionTypeSlug: typeMap?['slug'] as String?,
      sessionTypeId: typeMap?['id'] as String?,
      challenge: challenge,
      level: m['level'] as int?,
    );
  }

  /// Converts a snake_case DB enum string to camelCase for Dart enum lookup.
  /// e.g. "workout_share" → "workoutShare"
  static String _camel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  WorkoutType? get sessionType => sessionTypeSlug == null
      ? null
      : WorkoutType(
          id: sessionTypeId ?? '',
          name: sessionTypeName ?? '',
          slug: sessionTypeSlug!,
        );

  WorkoutSession? get session => sessionId == null
      ? null
      : WorkoutSession(
          id: sessionId!,
          userId: author.id,
          workoutTypeId: sessionTypeId ?? '',
          startedAt: DateTime.fromMillisecondsSinceEpoch(0),
          durationSeconds: sessionDurationSeconds ?? 0,
          distanceMeters: sessionDistanceMeters,
          caloriesBurned: sessionCaloriesBurned,
          customName: sessionCustomName,
        );
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Current user's friend IDs. Invalidated when FollowUser / UnfollowUser runs.
final friendIdsProvider = FutureProvider<List<String>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  SeqLog.msg('view-social-feed', 'SocialFeedTab', 'SocialGateway',
      'fetchFriendIds($userId)');
  return ref.read(socialGatewayProvider).fetchFriendIds(userId);
});

/// Community feed: posts from current user + friends, newest-first.
/// Re-fetches when [friendIdsProvider] or a new post is created/deleted.
final feedProvider = FutureProvider<List<FeedPost>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final friendIds = await ref.watch(friendIdsProvider.future);
  final feedIds = [userId, ...friendIds];

  final gw = ref.read(socialGatewayProvider);
  SeqLog.msg('view-social-feed', 'ViewSocialFeed', 'SocialGateway',
      'fetchFeedPosts(${feedIds.length} users)');
  final rawPosts = await gw.fetchFeedPosts(feedIds);
  if (rawPosts.isEmpty) return const [];

  final posts = rawPosts.map(FeedPost.fromMap).toList();
  final postIds = posts.map((p) => p.id).toList();

  // Batch-fetch interaction counts in parallel.
  final futures = await Future.wait([
    gw.fetchLikeCounts(postIds),
    gw.fetchMyLikedPostIds(userId, postIds),
    gw.fetchCommentCounts(postIds),
  ]);
  final likeCounts = futures[0] as Map<String, int>;
  final myLikes = futures[1] as Set<String>;
  final commentCounts = futures[2] as Map<String, int>;

  return posts
      .map((p) => p.withCounts(
            likeCount: likeCounts[p.id] ?? 0,
            likedByMe: myLikes.contains(p.id),
            commentCount: commentCounts[p.id] ?? 0,
          ))
      .toList();
});
