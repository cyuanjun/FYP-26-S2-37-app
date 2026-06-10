// Unit tests for the Profile entity's data-owned rules. Pure Dart — no Supabase,
// no widget tree (the screens now require an initialized Supabase client).

import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';

void main() {
  group('Profile.displayName', () {
    Profile base({String? first, String? last, String? username}) => Profile(
          id: 'u1',
          email: 'u1@example.com',
          role: UserRole.free,
          firstName: first,
          lastName: last,
          username: username,
        );

    test('uses full name when present', () {
      expect(base(first: 'Mia', last: 'Patel').displayName, 'Mia Patel');
    });

    test('falls back to username, then email', () {
      expect(base(username: 'mia').displayName, 'mia');
      expect(base().displayName, 'u1@example.com');
    });
  });

  test('isPremium reflects role', () {
    final free = Profile(id: 'a', email: 'a@b.c', role: UserRole.free);
    final premium = Profile(id: 'b', email: 'b@b.c', role: UserRole.premium);
    expect(free.isPremium, isFalse);
    expect(premium.isPremium, isTrue);
  });

  test('fromJson maps snake_case Supabase columns', () {
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
}
