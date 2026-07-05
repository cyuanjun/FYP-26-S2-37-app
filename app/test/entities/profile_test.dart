import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';

void main() {
  Profile base({String? first, String? last, String? username, UserRole role = UserRole.free}) =>
      Profile(id: 'u1', email: 'u1@example.com', role: role, firstName: first, lastName: last, username: username);

  group('Profile.displayName', () {
    test('full name when both present', () {
      expect(base(first: 'Mia', last: 'Patel').displayName, 'Mia Patel');
    });
    test('first or last alone', () {
      expect(base(first: 'Mia').displayName, 'Mia');
      expect(base(last: 'Patel').displayName, 'Patel');
    });
    test('falls back to username then email', () {
      expect(base(username: 'mia').displayName, 'mia');
      expect(base().displayName, 'u1@example.com');
    });
  });

  group('Profile.isPremium', () {
    test('true only for premium role', () {
      expect(base(role: UserRole.premium).isPremium, isTrue);
      expect(base(role: UserRole.free).isPremium, isFalse);
      expect(base(role: UserRole.expert).isPremium, isFalse);
    });
  });

  group('Profile.fromJson', () {
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

    test('defaults preferred_units to metric when absent', () {
      final p = Profile.fromJson({'id': 'u1', 'email': 'a@b.c', 'role': 'free'});
      expect(p.preferredUnits, PreferredUnits.metric);
      expect(p.firstName, isNull);
    });
  });
}
