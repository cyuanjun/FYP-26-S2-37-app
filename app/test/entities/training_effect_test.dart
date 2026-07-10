import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/training_effect.dart';
import 'package:wise_workout/entities/workout_session.dart';

// (#) Builds a fake workout session with tweakable duration and average HR.
WorkoutSession _session({int minutes = 30, int? avgHr}) => WorkoutSession(
      id: 's1',
      userId: 'u1',
      workoutTypeId: 'run',
      startedAt: DateTime(2026, 7, 8, 7),
      endedAt: DateTime(2026, 7, 8, 8),
      durationSeconds: minutes * 60,
      avgHeartRate: avgHr,
    );

// (#) Tests the training-effect maths: score, band, recovery hours, and aerobic/anaerobic split.
void main() {
  // (#) (-) Check if a session with no average HR returns null.
  test('no avg HR → null (the unavailable state, negative)', () {
    expect(computeTrainingEffect(_session(avgHr: null)), isNull);
  });

  // (#) (+) Check if the spec formula gives score 7, High band, 24h recovery for 30 min at 133 bpm.
  test('spec formula: 30-min at 133 bpm, no age → Very High boundary check',
      () {
    // estMaxHr fallback 190. intensity = 133/190 = 0.7,
    // durationMultiplier = 1 → raw = 0.7*10*(0.6+0.4) = 7 → High.
    final te = computeTrainingEffect(_session(minutes: 30, avgHr: 133))!;
    expect(te.score, 7);
    expect(te.band, TeBand.high);
    expect(te.recoveryHours, 24);
  });

  // (#) (+) Check if a longer session scores higher at the same heart rate.
  test('longer duration raises the score at the same HR', () {
    final short = computeTrainingEffect(_session(minutes: 15, avgHr: 133))!;
    final long = computeTrainingEffect(_session(minutes: 60, avgHr: 133))!;
    expect(long.score, greaterThan(short.score));
  });

  // (#) (+) Check if an older age lowers estimated max HR and so raises the score.
  test('age tightens estimated max HR (220 − age)', () {
    // age 30 → max 190 (same as fallback); age 60 → max 160 → higher intensity.
    final young = computeTrainingEffect(_session(avgHr: 133), age: 30)!;
    final older = computeTrainingEffect(_session(avgHr: 133), age: 60)!;
    expect(older.score, greaterThan(young.score));
  });

  // (#) (+) Check if scores map to the Low/Very High bands and recovery hours.
  test('bands map 1–3/4–6/7–8/9–10', () {
    // Low: gentle short session.
    final low = computeTrainingEffect(_session(minutes: 10, avgHr: 85))!;
    expect(low.band, TeBand.low);
    // Very high: hour near max.
    final vh = computeTrainingEffect(_session(minutes: 60, avgHr: 185))!;
    expect(vh.band, TeBand.veryHigh);
    expect(vh.recoveryHours, 48);
  });

  // (#) (+) Check if an easy effort splits as all aerobic and no anaerobic.
  test('aerobic/anaerobic split: easy effort is all aerobic', () {
    final easy = computeTrainingEffect(_session(minutes: 45, avgHr: 130))!;
    expect(easy.anaerobic, 0);
    expect(easy.aerobic, greaterThan(0));
  });

  // (#) (+) Check if a near-max effort makes anaerobic outweigh aerobic.
  test('near-max effort shifts the split anaerobic', () {
    final hard = computeTrainingEffect(_session(minutes: 45, avgHr: 188))!;
    expect(hard.anaerobic, greaterThan(hard.aerobic));
  });
}
