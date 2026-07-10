import 'workout_session.dart';

// (#) The rules for scoring one workout's Training Effect. In short: intensity
// (#) is avg heart rate over an estimated max, a duration multiplier rewards
// (#) longer sessions, and the two combine into a 1 to 10 score. The aerobic and
// (#) anaerobic split plus recovery hours use rough population averages, they
// (#) describe the effort, they are not medical advice.

// (#) The four effort bands a score falls into, from an easy day to a hard one.
enum TeBand { low, moderate, high, veryHigh }

// (#) Adds human-friendly text on top of the plain TeBand enum values.
extension TeBandLabel on TeBand {
  // (#) The short label to print for each band, like "Low" or "Very High".
  String get label => switch (this) {
        TeBand.low => 'Low',
        TeBand.moderate => 'Moderate',
        TeBand.high => 'High',
        TeBand.veryHigh => 'Very High',
      };

  // (#) A canned advice line per band, where more recovery is suggested the harder it was.
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

// (#) The Training Effect of a single workout: a 1 to 10 score with its band, an
// (#) aerobic and anaerobic split, and a rough recovery time, all worked out from
// (#) the session's heart rate and how long it ran.
class TrainingEffect {
  const TrainingEffect({
    required this.score,
    required this.band,
    required this.aerobic,
    required this.anaerobic,
    required this.recoveryHours,
  });

  // (#) The overall effect score, a whole number from 1 to 10.
  final int score;
  // (#) Which band that score lands in.
  final TeBand band;

  // (#) The aerobic part of the effort on a 0 to 5 scale.
  final double aerobic;
  // (#) The anaerobic part of the effort on a 0 to 5 scale.
  final double anaerobic;

  // (#) Suggested rest window in hours, banded at 4, 12, 24 or 48.
  final int recoveryHours;
}

// (#) Works out the Training Effect for a session. Returns null when there is no
// (#) average heart rate, such as a manual entry, so the card can show "unavailable".
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
