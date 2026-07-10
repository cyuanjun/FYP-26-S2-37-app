import 'package:freezed_annotation/freezed_annotation.dart';

import 'post.dart';
import 'public_profile.dart';
import 'workout_session.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

// (#) One social feed row carrying everything its card needs: the post, its
// (#) author, any shared workout, and the like and comment counts. The counts
// (#) are tallied on the client since the DB aggregates are turned off.
@freezed
abstract class FeedPost with _$FeedPost {
  const FeedPost._();

  const factory FeedPost({
    required Post post,
    required PublicProfile author, // (#) who posted it
    WorkoutSession? session, // (#) the shared workout, only on workout-share posts
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(false) bool likedByMe, // (#) whether I've already liked it
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) =>
      _$FeedPostFromJson(json);

  // (#) builds a feed row from one embedded query row, pulling out the author,
  // (#) session and counting the likes/comments, and flagging if "me" liked it
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
