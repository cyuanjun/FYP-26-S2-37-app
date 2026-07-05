import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// ENTITY — a polymorphic feed entry (#11 Social). Exactly one of
/// [workoutSessionId] / [challengeId] / [level] is non-null, decided by [kind]:
/// workout_share wraps a session, challenge_result wraps a challenge, level_up
/// carries the level reached (auto-inserted by the end_workout_session RPC).
@freezed
abstract class Post with _$Post {
  const Post._();

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

  bool get isWorkoutShare => kind == PostKind.workoutShare;
  bool get isChallengeResult => kind == PostKind.challengeResult;
  bool get isLevelUp => kind == PostKind.levelUp;
}
