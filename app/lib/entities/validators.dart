// (#) One home for all the input validation rules, like the sane ranges for
// (#) height and weight. Both the screen and the control call these, so they
// (#) agree on what counts as valid. No UI, no database, just the rules.
class Validators {
  const Validators._();

  // (#) The lowest sensible height a person can enter, in centimetres.
  static const int minHeightCm = 100;
  // (#) The highest sensible height, in centimetres.
  static const int maxHeightCm = 250;
  // (#) The lowest sensible body weight, in kilograms.
  static const double minWeightKg = 30;
  // (#) The highest sensible body weight, in kilograms.
  static const double maxWeightKg = 250;
  // (#) The lowest believable resting heart rate.
  static const int minRestingHr = 30;
  // (#) The highest believable resting heart rate.
  static const int maxRestingHr = 120;

  // (#) Fewest years of coaching an expert can claim.
  static const int minYearsCoaching = 0;
  // (#) Most years of coaching an expert can claim.
  static const int maxYearsCoaching = 80;

  // (#) True when the height is present and inside the allowed range.
  static bool validHeightCm(num? v) =>
      v != null && v >= minHeightCm && v <= maxHeightCm;

  // (#) True when the weight is present and inside the allowed range.
  static bool validWeightKg(num? v) =>
      v != null && v >= minWeightKg && v <= maxWeightKg;

  // (#) Resting heart rate is optional, so blank passes, else it must be in range.
  static bool validRestingHr(num? v) =>
      v == null || (v >= minRestingHr && v <= maxRestingHr); // optional field

  // (#) True when the coaching years are present and inside the allowed range.
  static bool validYearsCoaching(num? v) =>
      v != null && v >= minYearsCoaching && v <= maxYearsCoaching;

  // (#) True for any target that is set and greater than zero, like a goal or challenge target.
  static bool validPositiveTarget(num? v) => v != null && v > 0;

  // (#) True for a price that is set and not negative, measured in cents.
  static bool validPriceCents(num? v) => v != null && v >= 0;

  // (#) Gives the inline error text for a bad height, or null when it is fine.
  static String? heightCmError(num? v) =>
      validHeightCm(v) ? null : 'Enter a height between $minHeightCm–$maxHeightCm cm';

  // (#) Gives the inline error text for a bad weight, or null when it is fine.
  static String? weightKgError(num? v) => validWeightKg(v)
      ? null
      : 'Enter a weight between ${minWeightKg.toInt()}–${maxWeightKg.toInt()} kg';
}
