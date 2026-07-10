import 'package:freezed_annotation/freezed_annotation.dart';

import 'challenge.dart';
import 'public_profile.dart';

part 'challenge_summary.freezed.dart';

// (#) A ready-to-draw bundle for the Challenges tab. Wraps a challenge with
// (#) whether I joined, my current number and the ranked standings. Put together
// (#) by the ViewChallenges control, so there's no fromJson here.
@freezed
abstract class ChallengeSummary with _$ChallengeSummary {
  const ChallengeSummary._();

  const factory ChallengeSummary({
    required Challenge challenge,
    @Default(0) int participantCount, // (#) how many people are in it
    @Default(false) bool joined, // (#) whether the current user is taking part
    @Default(0) num myValue, // (#) my running total or best so far
    @Default(<ChallengeStanding>[]) List<ChallengeStanding> standings, // (#) leaderboard rows, already ranked
  }) = _ChallengeSummary;

  // (#) fraction 0 to 1 for the accumulator progress bar against the target
  double progressToTarget() {
    final target = challenge.targetValue;
    if (target == null || target <= 0) return 0;
    return (myValue / target).clamp(0.0, 1.0).toDouble();
  }
}

// (#) One row on a challenge leaderboard, a person and their ranked score
@freezed
abstract class ChallengeStanding with _$ChallengeStanding {
  const factory ChallengeStanding({
    required String userId,
    required num value, // (#) their score on the challenge metric
    required int rank, // (#) their place on the board
    PublicProfile? user, // (#) their public identity for display, if loaded
  }) = _ChallengeStanding;
}
