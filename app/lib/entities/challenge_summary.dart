import 'package:freezed_annotation/freezed_annotation.dart';

import 'challenge.dart';
import 'public_profile.dart';

part 'challenge_summary.freezed.dart';

/// ENTITY (read model) — one Challenges-tab card / detail page worth of
/// state: the challenge + participation + the ranked standings (already
/// ordered by the `challenge_leaderboards` SQL; zero-progress excluded).
/// Assembled by the ViewChallenges control — no direct fromJson.
@freezed
abstract class ChallengeSummary with _$ChallengeSummary {
  const ChallengeSummary._();

  const factory ChallengeSummary({
    required Challenge challenge,
    @Default(0) int participantCount,
    @Default(false) bool joined,
    @Default(0) num myValue,
    @Default(<ChallengeStanding>[]) List<ChallengeStanding> standings,
  }) = _ChallengeSummary;

  /// 0..1 fill for the accumulator progress bar.
  double progressToTarget() {
    final target = challenge.targetValue;
    if (target == null || target <= 0) return 0;
    return (myValue / target).clamp(0.0, 1.0).toDouble();
  }
}

@freezed
abstract class ChallengeStanding with _$ChallengeStanding {
  const factory ChallengeStanding({
    required String userId,
    required num value,
    required int rank,
    PublicProfile? user,
  }) = _ChallengeStanding;
}
