import 'package:freezed_annotation/freezed_annotation.dart';

import 'public_profile.dart';

part 'post_comment.freezed.dart';
part 'post_comment.g.dart';

/// ENTITY — a flat (non-threaded) comment on a Post (#11.1). [author] is
/// populated by the gateway's embedded `public_profiles` join.
@freezed
abstract class PostComment with _$PostComment {
  const PostComment._();

  const factory PostComment({
    required String id,
    required String postId,
    required String userId,
    required String body,
    required DateTime createdAt,
    PublicProfile? author,
  }) = _PostComment;

  factory PostComment.fromJson(Map<String, dynamic> json) =>
      _$PostCommentFromJson(json);
}
