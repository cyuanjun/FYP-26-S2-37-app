import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'post.freezed.dart';
part 'post.g.dart';

// (#) One entry in the social feed. It can be a shared workout, a challenge
// (#) result or a level-up, and it carries whatever data that kind needs.
@freezed
abstract class Post with _$Post {
  const Post._();

  const factory Post({
    required String id,
    required String userId, // (#) who posted it
    required PostKind kind, // (#) which flavour of post this is, drives which field below is set
    String? workoutSessionId, // (#) set only when it is a shared workout
    String? challengeId, // (#) set only when it is a challenge result
    int? level, // (#) set only when it is a level-up, the level reached
    String? body, // (#) optional caption the user typed
    required DateTime createdAt,
  }) = _Post;

  // (#) Rebuilds a Post from its stored JSON.
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  // (#) True when this post is a shared workout.
  bool get isWorkoutShare => kind == PostKind.workoutShare;
  // (#) True when this post is a challenge result.
  bool get isChallengeResult => kind == PostKind.challengeResult;
  // (#) True when this post celebrates hitting a new level.
  bool get isLevelUp => kind == PostKind.levelUp;
}
