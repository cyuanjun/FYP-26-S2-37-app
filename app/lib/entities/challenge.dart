import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/format.dart';
import 'enums.dart';

part 'challenge.freezed.dart';
part 'challenge.g.dart';

/// ENTITY — a community challenge (#11/#11.3): two orthogonal axes,
/// [visibility] (public / invite-only) × [metricKind] (accumulator races a
/// [targetValue]; best_of ranks a single best effort). Progress is never
/// stored — leaderboards aggregate qualifying sessions live.
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
    @Default(ChallengeVisibility.public) ChallengeVisibility visibility,
    required ChallengeMetricKind metricKind,
    required ChallengeMetric metric,
    int? targetValue,
    String? workoutTypeId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) = _Challenge;

  factory Challenge.fromJson(Map<String, dynamic> json) =>
      _$ChallengeFromJson(json);

  bool isActive(DateTime now) =>
      !now.isBefore(startedAt) && now.isBefore(endedAt);

  bool isPast(DateTime now) => !now.isBefore(endedAt);

  bool get isAccumulator => metricKind == ChallengeMetricKind.accumulator;

  /// (day X, of Y) — date-based, clamped to the window.
  (int, int) dayXofY(DateTime now) {
    DateTime d(DateTime t) {
      final l = t.toLocal();
      return DateTime(l.year, l.month, l.day);
    }

    final total = d(endedAt).difference(d(startedAt)).inDays + 1;
    final x = (d(now).difference(d(startedAt)).inDays + 1).clamp(1, total);
    return (x, total);
  }

  /// fastest_time ranks ascending; everything else descending.
  bool get lowerWins => metric == ChallengeMetric.fastestTime;

  /// Which metrics each kind can race (create-modal filter).
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

  /// One formatter for card previews, detail rows, and result panels so the
  /// unit rendering can't drift (distances arrive in metres, times in secs).
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
