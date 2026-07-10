import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/validators.dart';

// (#) Tests the input Validators: range checks for height, weight, resting HR, coaching years, targets, price.
void main() {
  // (#) Group covering the height range validator.
  group('Validators.validHeightCm', () {
    // (#) (+) Check if a plausible height including the 100 and 250 bounds is accepted.
    test('accepts a plausible height (positive)', () {
      expect(Validators.validHeightCm(178), isTrue);
      expect(Validators.validHeightCm(100), isTrue); // lower bound
      expect(Validators.validHeightCm(250), isTrue); // upper bound
    });
    // (#) (-) Check if out-of-range heights and null are rejected.
    test('rejects out-of-range and null (negative)', () {
      expect(Validators.validHeightCm(99), isFalse);
      expect(Validators.validHeightCm(251), isFalse);
      expect(Validators.validHeightCm(0), isFalse);
      expect(Validators.validHeightCm(null), isFalse);
    });
    // (#) (+) Check if the height error message is null when valid and set when invalid.
    test('error message is null only when valid', () {
      expect(Validators.heightCmError(178), isNull);
      expect(Validators.heightCmError(999), isNotNull);
    });
  });

  // (#) Group covering the weight range validator.
  group('Validators.validWeightKg', () {
    // (#) (+) Check if in-range weights including the 30 and 250 bounds are accepted.
    test('accepts in-range incl. bounds (positive)', () {
      expect(Validators.validWeightKg(74), isTrue);
      expect(Validators.validWeightKg(30), isTrue);
      expect(Validators.validWeightKg(250), isTrue);
    });
    // (#) (-) Check if out-of-range weights and null are rejected.
    test('rejects out-of-range and null (negative)', () {
      expect(Validators.validWeightKg(29), isFalse);
      expect(Validators.validWeightKg(300), isFalse);
      expect(Validators.validWeightKg(null), isFalse);
    });
  });

  // (#) Group covering the optional resting-HR validator.
  group('Validators.validRestingHr (optional field)', () {
    // (#) (+) Check if null is allowed since resting HR is optional.
    test('null is allowed (optional)', () {
      expect(Validators.validRestingHr(null), isTrue);
    });
    // (#) (-) Check if in-range resting HR passes and out-of-range is rejected.
    test('in-range accepted, out-of-range rejected (negative)', () {
      expect(Validators.validRestingHr(52), isTrue);
      expect(Validators.validRestingHr(29), isFalse);
      expect(Validators.validRestingHr(121), isFalse);
    });
  });

  // (#) Group covering the years-coaching validator.
  group('Validators.validYearsCoaching', () {
    // (#) (-) Check if 0..80 is accepted while out-of-range values and null are rejected.
    test('accepts 0..80 (positive), rejects outside + null (negative)', () {
      expect(Validators.validYearsCoaching(0), isTrue);
      expect(Validators.validYearsCoaching(80), isTrue);
      expect(Validators.validYearsCoaching(-1), isFalse);
      expect(Validators.validYearsCoaching(81), isFalse);
      expect(Validators.validYearsCoaching(null), isFalse);
    });
  });

  // (#) Group covering the positive-target validator.
  group('Validators.validPositiveTarget', () {
    // (#) (-) Check if only positive targets pass while 0, negative, and null are rejected.
    test('positive only (positive), rejects 0/negative/null (negative)', () {
      expect(Validators.validPositiveTarget(1), isTrue);
      expect(Validators.validPositiveTarget(0), isFalse);
      expect(Validators.validPositiveTarget(-5), isFalse);
      expect(Validators.validPositiveTarget(null), isFalse);
    });
  });

  // (#) Group covering the price-in-cents validator.
  group('Validators.validPriceCents', () {
    // (#) (-) Check if non-negative prices pass while negative and null are rejected.
    test('non-negative accepted (positive), negative/null rejected (negative)', () {
      expect(Validators.validPriceCents(0), isTrue);
      expect(Validators.validPriceCents(8000), isTrue);
      expect(Validators.validPriceCents(-1), isFalse);
      expect(Validators.validPriceCents(null), isFalse);
    });
  });
}
