/// ENTITY — input validation rules (single source of truth).
///
/// These pure, range-based rules are the authoritative definition of what
/// counts as valid user input. Both layers use them:
/// - **Boundary** (UI) calls them to bound pickers and show inline errors, so
///   invalid input is cleaned before it is ever submitted.
/// - **Control** calls them to *reject* anything invalid before persisting, so
///   the rule holds even if the UI is bypassed (defence in depth).
///
/// Each `valid*` returns whether the value is acceptable; each `*Error`
/// returns a human message (or null when valid) for inline UI feedback.
class Validators {
  const Validators._();

  // Fitness profile — physically plausible human ranges.
  static const int minHeightCm = 100;
  static const int maxHeightCm = 250;
  static const double minWeightKg = 30;
  static const double maxWeightKg = 250;
  static const int minRestingHr = 30;
  static const int maxRestingHr = 120;

  // Expert profile.
  static const int minYearsCoaching = 0;
  static const int maxYearsCoaching = 80;

  static bool validHeightCm(num? v) =>
      v != null && v >= minHeightCm && v <= maxHeightCm;

  static bool validWeightKg(num? v) =>
      v != null && v >= minWeightKg && v <= maxWeightKg;

  static bool validRestingHr(num? v) =>
      v == null || (v >= minRestingHr && v <= maxRestingHr); // optional field

  static bool validYearsCoaching(num? v) =>
      v != null && v >= minYearsCoaching && v <= maxYearsCoaching;

  /// A positive target (goal target, challenge accumulator target).
  static bool validPositiveTarget(num? v) => v != null && v > 0;

  /// A non-negative price in cents.
  static bool validPriceCents(num? v) => v != null && v >= 0;

  static String? heightCmError(num? v) =>
      validHeightCm(v) ? null : 'Enter a height between $minHeightCm–$maxHeightCm cm';

  static String? weightKgError(num? v) => validWeightKg(v)
      ? null
      : 'Enter a weight between ${minWeightKg.toInt()}–${maxWeightKg.toInt()} kg';

  static String? yearsCoachingError(num? v) => validYearsCoaching(v)
      ? null
      : 'Enter years between $minYearsCoaching–$maxYearsCoaching';
}
