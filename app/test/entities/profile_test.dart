import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';

// (#) Tests the Profile entity rules: display name fallbacks, premium check, JSON decoding.
void main() {
  // (#) Builds a base profile with tweakable name fields and role.
  Profile base({String? first, String? last, String? username, UserRole role = UserRole.free}) =>
      Profile(id: 'u1', email: 'u1@example.com', role: role, firstName: first, lastName: last, username: username);

  // (#) Group covering the display-name fallback chain.
  group('Profile.displayName', () {
    // (#) (+) Check if the full name shows when first and last are both present.
    test('full name when both present', () {
      expect(base(first: 'Mia', last: 'Patel').displayName, 'Mia Patel');
    });
    // (#) (+) Check if first or last name alone is used when only one is present.
    test('first or last alone', () {
      expect(base(first: 'Mia').displayName, 'Mia');
      expect(base(last: 'Patel').displayName, 'Patel');
    });
    // (#) (+) Check if it falls back to username then email when no real name.
    test('falls back to username then email', () {
      expect(base(username: 'mia').displayName, 'mia');
      expect(base().displayName, 'u1@example.com');
    });
  });

  // (#) Group covering the premium-role flag.
  group('Profile.isPremium', () {
    // (#) (+) Check if isPremium is true only for the premium role, not free or expert.
    test('true only for premium role', () {
      expect(base(role: UserRole.premium).isPremium, isTrue);
      expect(base(role: UserRole.free).isPremium, isFalse);
      expect(base(role: UserRole.expert).isPremium, isFalse);
    });
  });

  // (#) Group covering JSON decoding of a profile row.
  group('Profile.fromJson', () {
    // (#) (+) Check if fromJson maps snake_case columns and enum values.
    test('maps snake_case columns + enums', () {
      final p = Profile.fromJson({
        'id': 'u1',
        'email': 'mia@example.com',
        'role': 'premium',
        'first_name': 'Mia',
        'last_name': 'Patel',
        'preferred_units': 'imperial',
      });
      expect(p.isPremium, isTrue);
      expect(p.displayName, 'Mia Patel');
      expect(p.preferredUnits, PreferredUnits.imperial);
    });

    // (#) (-) Check if preferred_units defaults to metric when the column is absent.
    test('defaults preferred_units to metric when absent', () {
      final p = Profile.fromJson({'id': 'u1', 'email': 'a@b.c', 'role': 'free'});
      expect(p.preferredUnits, PreferredUnits.metric);
      expect(p.firstName, isNull);
    });
  });
}
