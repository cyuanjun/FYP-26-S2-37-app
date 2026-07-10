// (#) Premium advanced-analytics maths. A grab-bag of pure functions that turn
// (#) a user's finished workouts into load scores, ACWR bands, weekly trends, HR
// (#) zones and personal bests. Nothing gets stored, it just returns numbers.
// ENTITY-layer rules for #12.2 Advanced Workout Analytics (Premium).
// Everything is derived from ended WorkoutSessions — no new stored entity.
// All functions are pure (take `now`) so the maths is unit-testable.
//
// Realization notes vs the spec (documented deviations):
// - The mock's computeTrainingEffect isn't ported; sessionLoad is a
//   Karvonen-flavoured 1–10 load score (duration × intensity from %HRR,
//   moderate fallback when no HR was recorded).
// - HR zones always use the avgHeartRate × duration fallback the spec
//   defines for untracked sessions — live track points carry GPS, not
//   per-second HR, in this build.
// - Personal bests swap the strength kg×reps tile (needs ExerciseLog data)
//   for "longest session".
import 'workout_session.dart';

// ---------------------------------------------------------------------------
// Karvonen helpers

// (#) fallback resting HR when the user never set one
const defaultRestingHr = 60;
// (#) fallback age when DOB is missing
const _defaultAge = 30;

// (#) classic 220 minus age estimate of max heart rate
int estimatedMaxHr(int? age) => 220 - (age ?? _defaultAge);

// (#) how hard the heart is working as a 0 to 1 slice of its reserve (Karvonen)
double hrrFraction(int hr, {int? restingHr, int? age}) {
  final rest = restingHr ?? defaultRestingHr;
  final max = estimatedMaxHr(age);
  if (max <= rest) return 0;
  return ((hr - rest) / (max - rest)).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// Session load (Training-Effect-flavoured 1–10)

// (#) turns one session into a 1 to 10 effort score, an hour of moderate work
// (#) lands near 5 and it scales up or down by heart-rate intensity when known
double sessionLoad(WorkoutSession s, {int? restingHr, int? age}) {
  final hours = s.durationSeconds / 3600.0;
  var intensity = 1.0; // moderate fallback (no HR recorded)
  final hr = s.avgHeartRate;
  if (hr != null) {
    intensity = 0.5 + hrrFraction(hr, restingHr: restingHr, age: age);
  }
  return (hours * 5.0 * intensity).clamp(1.0, 10.0);
}

// ---------------------------------------------------------------------------
// ACWR — Acute:Chronic Workload Ratio (always now-anchored)

// (#) the four risk zones an acute-to-chronic workload ratio can fall into
enum AcwrBand { detraining, sustainable, highLoad, overreaching }

// (#) gives each band its upper-case display text
extension AcwrBandLabel on AcwrBand {
  String get label => switch (this) {
        AcwrBand.detraining => 'DETRAINING',
        AcwrBand.sustainable => 'SUSTAINABLE',
        AcwrBand.highLoad => 'HIGH LOAD',
        AcwrBand.overreaching => 'OVERREACHING',
      };
}

// (#) the outcome of an ACWR calc, the ratio plus which band it sits in
class AcwrResult {
  const AcwrResult({required this.ratio, required this.band});

  final double? ratio; // (#) null when there isn't enough history to be meaningful
  final AcwrBand? band; // (#) null alongside a null ratio

  // (#) true once we actually have a ratio to show
  bool get hasEnoughHistory => ratio != null;
}

// (#) compares the last 7 days of load against the 28-day weekly average
AcwrResult computeAcwr(List<WorkoutSession> sessions,
    {required DateTime now, int? restingHr, int? age}) {
  double loadSince(Duration back) => sessions
      .where((s) =>
          s.isEnded && s.startedAt.toLocal().isAfter(now.subtract(back)))
      .fold(0.0,
          (sum, s) => sum + sessionLoad(s, restingHr: restingHr, age: age));

  final acute = loadSince(const Duration(days: 7));
  final chronicWeekly = loadSince(const Duration(days: 28)) / 4.0;
  if (chronicWeekly < 0.5) return const AcwrResult(ratio: null, band: null);

  final ratio = acute / chronicWeekly;
  final band = switch (ratio) {
    < 0.8 => AcwrBand.detraining,
    <= 1.3 => AcwrBand.sustainable,
    <= 1.5 => AcwrBand.highLoad,
    _ => AcwrBand.overreaching,
  };
  return AcwrResult(ratio: ratio, band: band);
}

// ---------------------------------------------------------------------------
// Weekly buckets (range-scoped trends)

// (#) one week's worth of totals, a single point on the trend charts
class WeekBucket {
  const WeekBucket({
    required this.weekStart,
    required this.sessions,
    required this.activeMinutes,
    required this.calories,
    required this.avgHr,
    required this.load,
  });

  final DateTime weekStart; // (#) Monday that starts this week
  final int sessions; // (#) how many workouts landed in the week
  final int activeMinutes;
  final int calories;

  final double? avgHr; // (#) null if nothing that week logged heart rate
  final double load; // (#) summed session-load score for the week
}

// (#) builds a run of weekly buckets back from now, zero-filling empty weeks so
// (#) gaps show honestly, pass weeks null for an all-time span
List<WeekBucket> weeklyBuckets(List<WorkoutSession> sessions,
    {required DateTime now, int? weeks, int? restingHr, int? age}) {
  DateTime weekStartOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  final ended = sessions.where((s) => s.isEnded).toList();
  final thisWeek = weekStartOf(now);
  DateTime first;
  if (weeks != null) {
    first = thisWeek.subtract(Duration(days: 7 * (weeks - 1)));
  } else if (ended.isEmpty) {
    first = thisWeek;
  } else {
    first = weekStartOf(ended
        .map((s) => s.startedAt.toLocal())
        .reduce((a, b) => a.isBefore(b) ? a : b));
  }

  final buckets = <WeekBucket>[];
  for (var wk = first;
      !wk.isAfter(thisWeek);
      wk = wk.add(const Duration(days: 7))) {
    final inWeek = ended.where((s) {
      final local = s.startedAt.toLocal();
      return !local.isBefore(wk) && local.isBefore(wk.add(const Duration(days: 7)));
    }).toList();
    final withHr = inWeek.where((s) => s.avgHeartRate != null).toList();
    buckets.add(WeekBucket(
      weekStart: wk,
      sessions: inWeek.length,
      activeMinutes:
          inWeek.fold(0, (sum, s) => sum + s.durationSeconds ~/ 60),
      calories: inWeek.fold(0, (sum, s) => sum + (s.caloriesBurned ?? 0)),
      avgHr: withHr.isEmpty
          ? null
          : withHr.fold(0, (sum, s) => sum + s.avgHeartRate!) /
              withHr.length,
      load: inWeek.fold(
          0.0, (sum, s) => sum + sessionLoad(s, restingHr: restingHr, age: age)),
    ));
  }
  return buckets;
}

// (#) flags when the newest week's load jumped more than 50% over the one before
bool hasAcuteSpike(List<WeekBucket> buckets) {
  if (buckets.length < 2) return false;
  final prev = buckets[buckets.length - 2].load;
  final last = buckets.last.load;
  return prev > 0 && last > prev * 1.5;
}

// ---------------------------------------------------------------------------
// HR zones (Karvonen %HRR, five canonical bands)

// (#) the five heart-rate zone names shown on the zones chart
const hrZoneLabels = ['Z1 Recovery', 'Z2 Aerobic', 'Z3 Tempo', 'Z4 Threshold', 'Z5 VO2 max'];

// (#) splits training time across the five zones as fractions that add to 1,
// (#) each session drops its whole duration into the zone its avg HR sits in,
// (#) very easy sub-zone-1 time is dropped as sedentary
List<double> computeHrZones(List<WorkoutSession> sessions,
    {int? restingHr, int? age}) {
  final seconds = List<double>.filled(5, 0);
  for (final s in sessions) {
    final hr = s.avgHeartRate;
    if (!s.isEnded || hr == null) continue;
    final f = hrrFraction(hr, restingHr: restingHr, age: age);
    if (f < 0.5) continue;
    final zone = (((f - 0.5) / 0.1).floor()).clamp(0, 4);
    seconds[zone] += s.durationSeconds;
  }
  final total = seconds.fold(0.0, (a, b) => a + b);
  if (total == 0) return List.filled(5, 0);
  return seconds.map((s) => s / total).toList();
}

// ---------------------------------------------------------------------------
// Personal bests (all-time, range-independent)

// (#) one personal-best tile, the already-formatted value and when it happened
class PersonalBest {
  const PersonalBest({required this.value, required this.date});

  final String value; // (#) display text like "12.40 km"
  final DateTime date; // (#) when the record was set
}

// (#) the full set of all-time bests shown on the analytics screen
class PersonalBests {
  const PersonalBests({
    this.longestDistance,
    this.fastestPace,
    this.longestSession,
    required this.longestStreakDays,
  });

  final PersonalBest? longestDistance;

  final PersonalBest? fastestPace; // (#) best pace, only over runs of 1 km plus so sprints don't skew it
  final PersonalBest? longestSession;

  final int longestStreakDays; // (#) longest run of back-to-back active days
}

// (#) scans every finished session to work out all of the personal bests
PersonalBests computePersonalBests(List<WorkoutSession> sessions) {
  final ended = sessions.where((s) => s.isEnded).toList();

  WorkoutSession? maxBy(
      Iterable<WorkoutSession> list, num Function(WorkoutSession) key) {
    WorkoutSession? best;
    for (final s in list) {
      if (best == null || key(s) > key(best)) best = s;
    }
    return best;
  }

  final distance = maxBy(
      ended.where((s) => (s.distanceMeters ?? 0) > 0),
      (s) => s.distanceMeters!);

  // Pace = seconds per km; lower is better, so maximise the negative.
  final pace = maxBy(
      ended.where(
          (s) => (s.distanceMeters ?? 0) >= 1000 && s.durationSeconds > 0),
      (s) => -(s.durationSeconds / (s.distanceMeters! / 1000)));

  final longest = maxBy(
      ended.where((s) => s.durationSeconds > 0), (s) => s.durationSeconds);

  // Consecutive-day streak over distinct active days.
  final days = ended
      .map((s) {
        final local = s.startedAt.toLocal();
        return DateTime(local.year, local.month, local.day);
      })
      .toSet()
      .toList()
    ..sort();
  var streak = 0, run = 0;
  DateTime? prev;
  for (final d in days) {
    run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
    if (run > streak) streak = run;
    prev = d;
  }

  String paceLabel(WorkoutSession s) {
    final secPerKm = s.durationSeconds / (s.distanceMeters! / 1000);
    final m = secPerKm ~/ 60, sec = (secPerKm % 60).round();
    return "$m:${sec.toString().padLeft(2, '0')} /km";
  }

  String durationLabel(WorkoutSession s) => '${s.durationSeconds ~/ 60} min';

  return PersonalBests(
    longestDistance: distance == null
        ? null
        : PersonalBest(
            value:
                '${(distance.distanceMeters! / 1000).toStringAsFixed(2)} km',
            date: distance.startedAt.toLocal()),
    fastestPace: pace == null
        ? null
        : PersonalBest(value: paceLabel(pace), date: pace.startedAt.toLocal()),
    longestSession: longest == null
        ? null
        : PersonalBest(
            value: durationLabel(longest), date: longest.startedAt.toLocal()),
    longestStreakDays: streak,
  );
}
