import 'package:freezed_annotation/freezed_annotation.dart';

import 'public_profile.dart';

part 'post_comment.freezed.dart';
part 'post_comment.g.dart';

// (#) A comment left on a feed post. It is flat, so there are no replies to
// (#) replies, and it carries who wrote it so the UI can show their name and face.
@freezed
abstract class PostComment with _$PostComment {
  const PostComment._();

  const factory PostComment({
    required String id,
    required String postId, // (#) the post this comment hangs off
    required String userId, // (#) who wrote the comment
    required String body, // (#) the comment text itself
    required DateTime createdAt,
    PublicProfile? author, // (#) the writer's public info, joined in by the gateway
  }) = _PostComment;

  // (#) Rebuilds a PostComment from its stored JSON.
  factory PostComment.fromJson(Map<String, dynamic> json) =>
      _$PostCommentFromJson(json);
}
