import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// ENTITY — a polymorphic feed entry on Social (#11).
/// Exactly one of [workoutSessionId] / [challengeId] / [level] is non-null
/// depending on [kind]. `notes` on the linked WorkoutSession are always
/// private; [body] here is the public caption the author writes.
@freezed
abstract class Post with _$Post {
  const factory Post({
    required String id,
    required String userId,
    required PostKind kind,
    String? workoutSessionId,
    String? challengeId,
    int? level,
    String? body,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

/// ENTITY — a single comment in the flat thread under a Post (#11.1).
/// Sorted by [createdAt] ASC (natural conversation order). No threading in v1.
@freezed
abstract class PostComment with _$PostComment {
  const factory PostComment({
    required String id,
    required String postId,
    required String userId,
    required String body,
    required DateTime createdAt,
  }) = _PostComment;

  factory PostComment.fromJson(Map<String, dynamic> json) => _$PostCommentFromJson(json);
}
