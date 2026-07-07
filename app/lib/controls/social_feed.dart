import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/feed_post.dart';
import '../entities/post_comment.dart';
import 'authenticate.dart';

/// CONTROL — View Social Feed (US22, #11 Community). Friends + self, newest
/// first; the gateway reads through the privacy views.
final feedProvider = FutureProvider<List<FeedPost>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const <FeedPost>[];
  final gateway = ref.watch(socialGatewayProvider);
  SeqLog.msg('view-feed', 'ViewSocialFeed', 'SocialGateway', 'friendIds');
  final friends = await gateway.friendIds(userId);
  SeqLog.msg('view-feed', 'ViewSocialFeed', 'SocialGateway',
      'fetchFeed(${friends.length} friends)');
  return gateway.fetchFeed(userId: userId, friendIds: friends);
});

/// CONTROL — View Post Detail (#11.1). Single enriched post by id.
final postDetailProvider =
    FutureProvider.family<FeedPost?, String>((ref, postId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  SeqLog.msg('view-post', 'ViewPostDetail', 'SocialGateway',
      'fetchFeedPost($postId)');
  return ref.watch(socialGatewayProvider).fetchFeedPost(postId, me: userId);
});

/// CONTROL — List Post Comments (#11.1). Flat thread, oldest first.
final postCommentsProvider =
    FutureProvider.family<List<PostComment>, String>((ref, postId) {
  SeqLog.msg('view-post', 'ListPostComments', 'SocialGateway',
      'listComments($postId)');
  return ref.watch(socialGatewayProvider).listComments(postId);
});

/// CONTROL — Toggle Post Like (US23). Insert/delete on the composite key,
/// then refetch (invalidate) — the repo's mutation convention.
class TogglePostLike {
  TogglePostLike(this._ref);

  final Ref _ref;

  Future<void> call(String postId, {required bool currentlyLiked}) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    SeqLog.msg('toggle-like', 'PostCard', 'TogglePostLike', 'toggle($postId)');
    final gateway = _ref.read(socialGatewayProvider);
    if (currentlyLiked) {
      SeqLog.msg('toggle-like', 'TogglePostLike', 'SocialGateway', 'unlikePost');
      await gateway.unlikePost(postId, userId);
    } else {
      SeqLog.msg('toggle-like', 'TogglePostLike', 'SocialGateway', 'likePost');
      await gateway.likePost(postId, userId);
    }
    _ref.invalidate(feedProvider);
    _ref.invalidate(postDetailProvider(postId));
  }
}

final togglePostLikeProvider = Provider<TogglePostLike>(TogglePostLike.new);

/// CONTROL — Add Post Comment (US23). Rejects blank bodies.
class AddPostComment {
  AddPostComment(this._ref);

  final Ref _ref;

  Future<bool> call({required String postId, required String body}) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null || body.isBlank) return false;
    SeqLog.msg('add-comment', 'PostDetailScreen', 'AddPostComment', 'add($postId)');
    SeqLog.msg('add-comment', 'AddPostComment', 'SocialGateway', 'addComment');
    await _ref
        .read(socialGatewayProvider)
        .addComment(postId: postId, userId: userId, body: body);
    _ref.invalidate(postCommentsProvider(postId));
    _ref.invalidate(postDetailProvider(postId));
    _ref.invalidate(feedProvider);
    return true;
  }
}

final addPostCommentProvider = Provider<AddPostComment>(AddPostComment.new);

/// CONTROL — Delete Post Comment (own comments only; RLS enforces).
class DeletePostComment {
  DeletePostComment(this._ref);

  final Ref _ref;

  Future<void> call({required String postId, required String commentId}) async {
    SeqLog.msg('delete-comment', 'PostDetailScreen', 'DeletePostComment',
        'delete($commentId)');
    await _ref.read(socialGatewayProvider).deleteComment(commentId);
    _ref.invalidate(postCommentsProvider(postId));
    _ref.invalidate(postDetailProvider(postId));
    _ref.invalidate(feedProvider);
  }
}

final deletePostCommentProvider =
    Provider<DeletePostComment>(DeletePostComment.new);

/// CONTROL — Update Post Body (#11.1 caption edit; empty clears to null).
class UpdatePostBody {
  UpdatePostBody(this._ref);

  final Ref _ref;

  Future<void> call({required String postId, required String? body}) async {
    SeqLog.msg('edit-caption', 'PostDetailScreen', 'UpdatePostBody',
        'update($postId)');
    await _ref.read(socialGatewayProvider).updatePostBody(postId, body);
    _ref.invalidate(postDetailProvider(postId));
    _ref.invalidate(feedProvider);
  }
}

final updatePostBodyProvider = Provider<UpdatePostBody>(UpdatePostBody.new);

/// The current user's share-post id for a session (null = not shared).
/// #12.1 uses it to link a workout to its post's likes/comments.
final sessionSharePostProvider =
    FutureProvider.family<String?, String>((ref, sessionId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  SeqLog.msg('view-post', 'HistoryDetailScreen', 'SocialGateway',
      'findSharePostId($sessionId)');
  return ref
      .watch(socialGatewayProvider)
      .findSharePostId(sessionId: sessionId, me: userId);
});
