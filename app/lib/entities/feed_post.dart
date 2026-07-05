import 'package:freezed_annotation/freezed_annotation.dart';

import 'post.dart';
import 'public_profile.dart';
import 'workout_session.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

/// ENTITY (read model) — one enriched feed row (#11): the [post] plus its
/// [author], the wrapped [session] for workout_share posts, and like/comment
/// tallies. Built by [FeedPost.fromRow] from the gateway's single embedded
/// select; counts are client-side because PostgREST aggregates are disabled.
@freezed
abstract class FeedPost with _$FeedPost {
  const FeedPost._();

  const factory FeedPost({
    required Post post,
    required PublicProfile author,
    WorkoutSession? session,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool likedByMe,
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) =>
      _$FeedPostFromJson(json);

  /// Decodes one embedded PostgREST row:
  /// `posts.* , author:public_profiles, session:public_workout_sessions,
  ///  likes:post_likes(user_id), comments:post_comments(id)`.
  factory FeedPost.fromRow(Map<String, dynamic> row, {required String me}) {
    final likes = (row['likes'] as List? ?? const [])
        .map((l) => (l as Map<String, dynamic>)['user_id'] as String)
        .toList();
    final comments = row['comments'] as List? ?? const [];
    return FeedPost(
      post: Post.fromJson(row),
      author: PublicProfile.fromJson(row['author'] as Map<String, dynamic>),
      session: row['session'] == null
          ? null
          : WorkoutSession.fromJson(row['session'] as Map<String, dynamic>),
      likeCount: likes.length,
      commentCount: comments.length,
      likedByMe: likes.contains(me),
    );
  }
}
