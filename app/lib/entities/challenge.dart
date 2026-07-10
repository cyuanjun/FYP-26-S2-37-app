import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/format.dart';
import 'enums.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

// (#) A community challenge people can join and race in. Holds the name, dates,
// (#) which metric it competes on and the target. Your own progress is never
// (#) kept here, the leaderboards work out standings live from qualifying sessions.
@freezed
abstract class Challenge with _$Challenge {
  const Challenge._();

  const factory Challenge({
    required String id,
    String? createdByUserId, // (#) who made it, null for built-in challenges
    required String name,
    required String shortName,
    String? description,
    required String icon,
    @Default('') String joinCode, // server-assigned shareable code (#11)
    @Default(ChallengeVisibility.public) ChallengeVisibility visibility, // (#) public or invite-only
    required ChallengeMetricKind metricKind, // (#) accumulate-a-total vs single-best-effort
    required ChallengeMetric metric, // (#) exactly what gets measured
    int? targetValue, // (#) goal to reach, only for accumulator challenges
    String? workoutTypeId, // (#) limits it to one workout type when set
    required DateTime startedAt,
    required DateTime endedAt,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFromJson(json);

  // (#) true while now sits inside the start-to-end window
  bool isActive(DateTime now) =>
      !now.isBefore(startedAt) && now.isBefore(endedAt);

  // (#) true once the challenge has finished
  bool isPast(DateTime now) => !now.isBefore(endedAt);

  // (#) true when it's the run-up-a-total kind rather than best-effort
  bool get isAccumulator => metricKind == ChallengeMetricKind.accumulator;

  // (#) returns (which day we're on, total days) clamped inside the window
  (int, int) dayXofY(DateTime now) {
    DateTime d(DateTime t) {
      final l = t.toLocal();
      return DateTime(l.year, l.month, l.day);
    }

    final total = d(endedAt).difference(d(startedAt)).inDays + 1;
    final x = (d(now).difference(d(startedAt)).inDays + 1).clamp(1, total);
    return (x, total);
  }

  // (#) true when a smaller number wins (only fastest-time works that way)
  bool get lowerWins => metric == ChallengeMetric.fastestTime;

  // (#) the metrics that make sense for a given kind, used to filter the create form
  static List<ChallengeMetric> metricsFor(ChallengeMetricKind kind) =>
      switch (kind) {
        ChallengeMetricKind.accumulator => const [
            ChallengeMetric.totalDistance,
            ChallengeMetric.totalSessions,
            ChallengeMetric.totalCalories,
            ChallengeMetric.activeDays,
          ],
        ChallengeMetricKind.bestOf => const [
            ChallengeMetric.fastestTime,
            ChallengeMetric.longestDistance,
            ChallengeMetric.mostCalories,
          ],
      };

  // (#) single place that turns a raw value into display text so units stay
  // (#) consistent everywhere (distances come in metres, times in seconds)
  String formatValue(num v) => switch (metric) {
        ChallengeMetric.totalDistance ||
        ChallengeMetric.longestDistance =>
          '${fmtKm(v.toDouble())} km',
        ChallengeMetric.totalSessions => '${v.toInt()}',
        ChallengeMetric.activeDays => '${v.toInt()} days',
        ChallengeMetric.totalCalories ||
        ChallengeMetric.mostCalories =>
          '${v.toInt()} kcal',
        ChallengeMetric.fastestTime =>
          fmtDuration(Duration(seconds: v.toInt())),
      };
}
