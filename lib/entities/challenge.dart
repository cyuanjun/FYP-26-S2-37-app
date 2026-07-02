import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

/// ENTITY — unified group-activity entity (#11 Challenges tab, #11.3 detail).
/// Two orthogonal axes drive behaviour:
///   [visibility] — public (browseable on Active sub-tab) vs invite_only.
///   [metricKind] — accumulator (fill toward [targetValue]) vs best_of (rank by session).
@freezed
abstract class Challenge with _$Challenge {
  const Challenge._();

  const factory Challenge({
    required String id,
    String? createdByUserId,
    required String name,
    required String shortName,
    String? description,
    required String icon,
    required ChallengeVisibility visibility,
    required ChallengeMetricKind metricKind,
    required ChallengeMetric metric,
    int? targetValue,
    String? workoutTypeId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) => _$ChallengeFromJson(json);

  bool get isEnded => DateTime.now().toUtc().isAfter(endedAt);
  bool get isActive => !isEnded && !DateTime.now().toUtc().isBefore(startedAt);

  int get totalDays => endedAt.difference(startedAt).inDays + 1;
  int get currentDayNumber {
    final day = DateTime.now().toUtc().difference(startedAt).inDays + 1;
    return day.clamp(1, totalDays);
  }
}

/// ENTITY — junction: which users have joined a [Challenge].
/// [workoutSessionId] is null for accumulator challenges (progress summed live);
/// for best_of, it holds the participant's chosen submission (null until picked).
@freezed
abstract class ChallengeParticipant with _$ChallengeParticipant {
  const factory ChallengeParticipant({
    required String challengeId,
    required String userId,
    String? workoutSessionId,
  }) = _ChallengeParticipant;

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      _$ChallengeParticipantFromJson(json);
}
