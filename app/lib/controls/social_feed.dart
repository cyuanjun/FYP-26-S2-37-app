import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/feed_post.dart';
import '../entities/post_comment.dart';
import 'authenticate.dart';

// (#) View Social Feed use case (US22, #11 Community). Loads the current user's and
// (#) their friends' posts, newest first; the gateway respects the privacy views.
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

// (#) View Post Detail (#11.1): fetches one full post by id, with like/comment info.
final postDetailProvider =
    FutureProvider.family<FeedPost?, String>((ref, postId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  SeqLog.msg('view-post', 'ViewPostDetail', 'SocialGateway',
      'fetchFeedPost($postId)');
  return ref.watch(socialGatewayProvider).fetchFeedPost(postId, me: userId);
});

// (#) List Post Comments (#11.1): the comment thread for a post, oldest first.
final postCommentsProvider =
    FutureProvider.family<List<PostComment>, String>((ref, postId) {
  SeqLog.msg('view-post', 'ListPostComments', 'SocialGateway',
      'listComments($postId)');
  return ref.watch(socialGatewayProvider).listComments(postId);
});

// (#) Toggle Post Like use case (US23). Depending on whether the user already liked
// (#) it, adds or removes the like row via the gateway, then refreshes feed and post.
class TogglePostLike {
  TogglePostLike(this._ref);

  final Ref _ref;

  // (#) Calls likePost or unlikePost based on currentlyLiked, then invalidates the
  // (#) feed and this post so counts update.
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

// (#) Provider the post card and detail screen use to like/unlike.
final togglePostLikeProvider = Provider<TogglePostLike>(TogglePostLike.new);

// (#) Add Post Comment use case (US23). Turns down a blank body, writes the comment
// (#) via the gateway, then reloads the thread, post, and feed.
class AddPostComment {
  AddPostComment(this._ref);

  final Ref _ref;

  // (#) Guards against no-login and blank body, saves through the gateway, and
  // (#) invalidates comments, post, and feed. Returns true when it wrote.
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

// (#) Provider the post detail screen uses to add a comment.
final addPostCommentProvider = Provider<AddPostComment>(AddPostComment.new);

// (#) Delete Post Comment use case. Removes a comment through the gateway; the
// (#) database RLS makes sure you can only delete your own.
class DeletePostComment {
  DeletePostComment(this._ref);

  final Ref _ref;

  // (#) Deletes the comment, then refreshes the thread, post, and feed.
  Future<void> call({required String postId, required String commentId}) async {
    SeqLog.msg('delete-comment', 'PostDetailScreen', 'DeletePostComment',
        'delete($commentId)');
    await _ref.read(socialGatewayProvider).deleteComment(commentId);
    _ref.invalidate(postCommentsProvider(postId));
    _ref.invalidate(postDetailProvider(postId));
    _ref.invalidate(feedProvider);
  }
}

// (#) Provider the post detail screen uses to delete a comment.
final deletePostCommentProvider =
    Provider<DeletePostComment>(DeletePostComment.new);

// (#) Update Post Body use case (#11.1 caption edit). Saves the new caption through
// (#) the gateway; an empty caption clears it back to null.
class UpdatePostBody {
  UpdatePostBody(this._ref);

  final Ref _ref;

  // (#) Writes the new caption, then refreshes the post and feed.
  Future<void> call({required String postId, required String? body}) async {
    SeqLog.msg('edit-caption', 'PostDetailScreen', 'UpdatePostBody',
        'update($postId)');
    await _ref.read(socialGatewayProvider).updatePostBody(postId, body);
    _ref.invalidate(postDetailProvider(postId));
    _ref.invalidate(feedProvider);
  }
}

// (#) Provider the post detail screen uses to edit a caption.
final updatePostBodyProvider = Provider<UpdatePostBody>(UpdatePostBody.new);

// (#) Looks up whether a given workout session was shared as a post, returning that
// (#) post's id (null means not shared). The #12.1 detail screen uses it to link a
// (#) workout to its post's likes and comments.
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
