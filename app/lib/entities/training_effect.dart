import 'workout_session.dart';

// ENTITY rules — per-session Training Effect (#10/#12.1 spec, US35 short-term).
// Formula per the spec: intensity = avgHr / estMaxHr (220 − age, fallback 190
// when age is unknown); durationMultiplier = min(2, duration/1800) so longer
// easy sessions score meaningfully higher; raw = intensity × 10 ×
// (0.6 + 0.4 × durationMultiplier), clamped to a 1–10 integer.
// The Premium breakdown (aerobic/anaerobic split + recovery hours) uses
// indicative population-average formulas — descriptive, never prescriptive.

enum TeBand { low, moderate, high, veryHigh }

extension TeBandLabel on TeBand {
  String get label => switch (this) {
        TeBand.low => 'Low',
        TeBand.moderate => 'Moderate',
        TeBand.high => 'High',
        TeBand.veryHigh => 'Very High',
      };

  /// Canned per-band advice line (#10 spec) — recovery scales with the band.
  String get advice => switch (this) {
        TeBand.low =>
          'Light session. Great as a warmup or recovery — no rest needed.',
        TeBand.moderate =>
          'Solid effort with plenty in reserve. You can train again tomorrow.',
        TeBand.high =>
          'Strong workout. Plan a lighter day tomorrow to recover.',
        TeBand.veryHigh => 'Hard session. Prioritise rest and sleep tonight.',
      };
}

class TrainingEffect {
  const TrainingEffect({
    required this.score,
    required this.band,
    required this.aerobic,
    required this.anaerobic,
    required this.recoveryHours,
  });

  /// 1–10 integer.
  final int score;
  final TeBand band;

  /// 0–5, one decimal place of meaning.
  final double aerobic;
  final double anaerobic;

  /// Indicative recovery window, banded (4 / 12 / 24 / 48 h).
  final int recoveryHours;
}

/// Null when [session] has no avgHeartRate (manual entry / HR dropout) —
/// the card renders the spec's "effect estimate unavailable" state.
TrainingEffect? computeTrainingEffect(WorkoutSession session, {int? age}) {
  final hr = session.avgHeartRate;
  if (hr == null || session.durationSeconds <= 0) return null;

  final estMaxHr = age == null ? 190 : 220 - age;
  final intensity = (hr / estMaxHr).clamp(0.0, 1.0);
  final durationMultiplier =
      (session.durationSeconds / 1800.0).clamp(0.0, 2.0);
  final raw = intensity * 10 * (0.6 + 0.4 * durationMultiplier);
  final score = raw.round().clamp(1, 10);

  final band = switch (score) {
    <= 3 => TeBand.low,
    <= 6 => TeBand.moderate,
    <= 8 => TeBand.high,
    _ => TeBand.veryHigh,
  };

  // Split: effort above ~85% of est. max HR reads as anaerobic; the rest
  // is aerobic. Both scale with the overall score onto a 0–5 scale.
  final anaerobicShare = ((intensity - 0.85) / 0.15).clamp(0.0, 1.0);
  final anaerobic =
      double.parse((score / 2 * anaerobicShare).toStringAsFixed(1));
  final aerobic =
      double.parse((score / 2 * (1 - anaerobicShare)).toStringAsFixed(1));

  final recoveryHours = switch (band) {
    TeBand.low => 4,
    TeBand.moderate => 12,
    TeBand.high => 24,
    TeBand.veryHigh => 48,
  };

  return TrainingEffect(
    score: score,
    band: band,
    aerobic: aerobic,
    anaerobic: anaerobic,
    recoveryHours: recoveryHours,
  );
}
