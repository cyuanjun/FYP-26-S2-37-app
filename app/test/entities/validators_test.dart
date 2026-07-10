import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/validators.dart';

void main() {
  group('Validators.validHeightCm', () {
    test('accepts a plausible height (positive)', () {
      expect(Validators.validHeightCm(178), isTrue);
      expect(Validators.validHeightCm(100), isTrue); // lower bound
      expect(Validators.validHeightCm(250), isTrue); // upper bound
    });
    test('rejects out-of-range and null (negative)', () {
      expect(Validators.validHeightCm(99), isFalse);
      expect(Validators.validHeightCm(251), isFalse);
      expect(Validators.validHeightCm(0), isFalse);
      expect(Validators.validHeightCm(null), isFalse);
    });
    test('error message is null only when valid', () {
      expect(Validators.heightCmError(178), isNull);
      expect(Validators.heightCmError(999), isNotNull);
    });
  });

  group('Validators.validWeightKg', () {
    test('accepts in-range incl. bounds (positive)', () {
      expect(Validators.validWeightKg(74), isTrue);
      expect(Validators.validWeightKg(30), isTrue);
      expect(Validators.validWeightKg(250), isTrue);
    });
    test('rejects out-of-range and null (negative)', () {
      expect(Validators.validWeightKg(29), isFalse);
      expect(Validators.validWeightKg(300), isFalse);
      expect(Validators.validWeightKg(null), isFalse);
    });
  });

  group('Validators.validRestingHr (optional field)', () {
    test('null is allowed (optional)', () {
      expect(Validators.validRestingHr(null), isTrue);
    });
    test('in-range accepted, out-of-range rejected (negative)', () {
      expect(Validators.validRestingHr(52), isTrue);
      expect(Validators.validRestingHr(29), isFalse);
      expect(Validators.validRestingHr(121), isFalse);
    });
  });

  group('Validators.validYearsCoaching', () {
    test('accepts 0..80 (positive), rejects outside + null (negative)', () {
      expect(Validators.validYearsCoaching(0), isTrue);
      expect(Validators.validYearsCoaching(80), isTrue);
      expect(Validators.validYearsCoaching(-1), isFalse);
      expect(Validators.validYearsCoaching(81), isFalse);
      expect(Validators.validYearsCoaching(null), isFalse);
    });
  });

  group('Validators.validPositiveTarget', () {
    test('positive only (positive), rejects 0/negative/null (negative)', () {
      expect(Validators.validPositiveTarget(1), isTrue);
      expect(Validators.validPositiveTarget(0), isFalse);
      expect(Validators.validPositiveTarget(-5), isFalse);
      expect(Validators.validPositiveTarget(null), isFalse);
    });
  });

  group('Validators.validPriceCents', () {
    test('non-negative accepted (positive), negative/null rejected (negative)', () {
      expect(Validators.validPriceCents(0), isTrue);
      expect(Validators.validPriceCents(8000), isTrue);
      expect(Validators.validPriceCents(-1), isFalse);
      expect(Validators.validPriceCents(null), isFalse);
    });
  });
}
