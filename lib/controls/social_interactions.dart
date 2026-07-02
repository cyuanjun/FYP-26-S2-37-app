import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../entities/post.dart';
import 'authenticate.dart';
import 'social_feed.dart';

// ── TogglePostLike ────────────────────────────────────────────────────────────

/// CONTROL — TogglePostLike: adds or removes the current user's like on a post
/// (US23). Invalidates the feed so counts refresh.
class TogglePostLike {
  TogglePostLike(this._ref);

  final Ref _ref;

  Future<void> call(String postId, {required bool currentlyLiked}) async {
    final userId = _ref.read(currentUserIdProvider)!;
    final gw = _ref.read(socialGatewayProvider);
    if (currentlyLiked) {
      SeqLog.msg('toggle-post-like', 'PostCard', 'TogglePostLike',
          'removeLike($postId)');
      SeqLog.msg('toggle-post-like', 'TogglePostLike', 'SocialGateway',
          'removeLike($postId, $userId)');
      await gw.removeLike(postId, userId);
    } else {
      SeqLog.msg('toggle-post-like', 'PostCard', 'TogglePostLike',
          'addLike($postId)');
      SeqLog.msg('toggle-post-like', 'TogglePostLike', 'SocialGateway',
          'addLike($postId, $userId)');
      await gw.addLike(postId, userId);
    }
    _ref.invalidate(feedProvider);
  }
}

final togglePostLikeProvider =
    Provider<TogglePostLike>(TogglePostLike.new);

// ── AddPostComment ────────────────────────────────────────────────────────────

/// CONTROL — AddPostComment: appends a comment to a post's thread (US23).
class AddPostComment {
  AddPostComment(this._ref);

  final Ref _ref;

  Future<PostComment> call(String postId, String body) async {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('add-comment', 'PostDetailScreen', 'AddPostComment',
        'add($postId)');
    SeqLog.msg('add-comment', 'AddPostComment', 'SocialGateway',
        'addPostComment($postId)');
    final comment = await _ref
        .read(socialGatewayProvider)
        .addPostComment(postId: postId, userId: userId, body: body);
    _ref.invalidate(feedProvider);
    return comment;
  }
}

final addPostCommentProvider =
    Provider<AddPostComment>(AddPostComment.new);

// ── DeletePostComment ─────────────────────────────────────────────────────────

/// CONTROL — DeletePostComment: removes the current user's own comment (US23).
class DeletePostComment {
  DeletePostComment(this._ref);

  final Ref _ref;

  Future<void> call(String commentId) async {
    SeqLog.msg('delete-comment', 'PostDetailScreen', 'DeletePostComment',
        'delete($commentId)');
    SeqLog.msg('delete-comment', 'DeletePostComment', 'SocialGateway',
        'deletePostComment($commentId)');
    await _ref.read(socialGatewayProvider).deletePostComment(commentId);
    _ref.invalidate(feedProvider);
  }
}

final deletePostCommentProvider =
    Provider<DeletePostComment>(DeletePostComment.new);

// ── UpdatePostBody ────────────────────────────────────────────────────────────

/// CONTROL — UpdatePostBody: edits the public caption on a post (US23).
/// Only the post author may call this; RLS enforces it at the DB level.
class UpdatePostBody {
  UpdatePostBody(this._ref);

  final Ref _ref;

  Future<void> call(String postId, String? body) async {
    SeqLog.msg('update-post-body', 'PostDetailScreen', 'UpdatePostBody',
        'update($postId)');
    SeqLog.msg('update-post-body', 'UpdatePostBody', 'SocialGateway',
        'updatePostBody($postId)');
    await _ref.read(socialGatewayProvider).updatePostBody(postId, body);
    _ref.invalidate(feedProvider);
  }
}

final updatePostBodyProvider =
    Provider<UpdatePostBody>(UpdatePostBody.new);

// ── Read-side providers ───────────────────────────────────────────────────────

/// Post-specific comment list for #11.1 Post Detail. Keyed by [postId].
final postCommentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, postId) async {
  SeqLog.msg('view-post-detail', 'PostDetailScreen', 'SocialGateway',
      'fetchPostComments($postId)');
  return ref.read(socialGatewayProvider).fetchPostComments(postId);
});

/// Full post data (with author, session, challenge) for #11.1.
final postDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, postId) async {
  SeqLog.msg('view-post-detail', 'PostDetailScreen', 'SocialGateway',
      'fetchPostById($postId)');
  return ref.read(socialGatewayProvider).fetchPostById(postId);
});
