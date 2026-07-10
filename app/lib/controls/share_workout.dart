import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/social_gateway.dart';
import '../boundaries/gateways/social_share_gateway.dart';
import '../core/seq_log.dart';
import '../entities/enums.dart';
import 'authenticate.dart';

// (#) Shares a workout to the in-app feed. It asks the social gateway to insert a
// (#) workout_share post for the session and returns the new post id.
class CreateWorkoutSharePost {
  CreateWorkoutSharePost(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway and user id

  // (#) Posts a share for the given session with an optional caption.
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

// (#) Hands the summary screen the CreateWorkoutSharePost control.
final createWorkoutSharePostProvider = Provider<CreateWorkoutSharePost>(CreateWorkoutSharePost.new);

// (#) Shares a workout out to a named platform. It opens the system share for
// (#) Facebook, Instagram and the like through the share gateway.
class ShareWorkoutToSocial {
  ShareWorkoutToSocial(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the share gateway

  // (#) Opens the share sheet for the chosen platform with the given text.
  Future<void> call(SocialPlatform platform, {required String text}) {
    SeqLog.msg('share-workout', 'WorkoutSummaryScreen', 'ShareWorkoutToSocial', 'shareTo(${platform.name})');
    return _ref.read(socialShareGatewayProvider).shareTo(platform, text: text);
  }
}

// (#) Hands the summary screen the ShareWorkoutToSocial control.
final shareWorkoutToSocialProvider = Provider<ShareWorkoutToSocial>(ShareWorkoutToSocial.new);
