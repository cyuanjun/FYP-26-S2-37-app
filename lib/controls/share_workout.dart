import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../boundaries/gateways/social_share_gateway.dart';
import '../core/seq_log.dart';
import 'authenticate.dart';

/// CONTROL — CreateWorkoutSharePost: inserts a `workout_share` Post for a session.
class CreateWorkoutSharePost {
  CreateWorkoutSharePost(this._ref);

  final Ref _ref;

  Future<String> call({required String sessionId, String? caption}) {
    final userId = _ref.read(currentUserIdProvider)!;
    SeqLog.msg('share-workout', 'WorkoutSummaryScreen', 'CreateWorkoutSharePost', 'create($sessionId)');
    SeqLog.msg('share-workout', 'CreateWorkoutSharePost', 'SocialGateway', 'insert(workout_share)');
    return _ref.read(socialGatewayProvider).createWorkoutSharePost(
          userId: userId,
          workoutSessionId: sessionId,
          body: caption,
        );
  }
}

final createWorkoutSharePostProvider = Provider<CreateWorkoutSharePost>(CreateWorkoutSharePost.new);

/// CONTROL — ShareWorkoutToSocial: opens the system share to a named platform.
class ShareWorkoutToSocial {
  ShareWorkoutToSocial(this._ref);

  final Ref _ref;

  Future<void> call(SocialPlatform platform, {required String text}) {
    SeqLog.msg('share-workout', 'WorkoutSummaryScreen', 'ShareWorkoutToSocial', 'shareTo(${platform.name})');
    return _ref.read(socialShareGatewayProvider).shareTo(platform, text: text);
  }
}

final shareWorkoutToSocialProvider = Provider<ShareWorkoutToSocial>(ShareWorkoutToSocial.new);
