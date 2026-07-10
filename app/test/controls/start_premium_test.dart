import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/profile_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/start_premium.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';
import 'package:wise_workout/entities/subscription.dart';

import '../helpers/fakes.dart';

// (#) Tests the StartPremium and ManageSubscription controls plus Subscription entity rules.

const _free = Profile(id: 'u1', email: 'mia@test', role: UserRole.free);

// (#) Builds a ProviderContainer wired to the fake profile gateway and a signed-in user.
ProviderContainer _container(FakeProfileGateway gateway, {String? userId}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId ?? 'u1'),
    profileGatewayProvider.overrideWithValue(gateway),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // (#) Upgrading a Free account to Premium.
  group('StartPremium', () {
    // (#) (+) Check if the upgrade runs the RPC and refreshes the profile and subscription.
    test('runs the RPC and refreshes profile + subscription (positive)',
        () async {
      final gateway = FakeProfileGateway(profile: _free);
      final c = _container(gateway);

      // Prime the providers so invalidation is observable.
      expect(await c.read(subscriptionProvider.future), isNull);

      await c.read(startPremiumProvider).call();

      expect(gateway.startPremiumCalls, 1);
      expect(gateway.profile?.role, UserRole.premium);
      final sub = await c.read(subscriptionProvider.future);
      expect(sub, isNotNull);
      expect(sub!.isActive, isTrue);
    });

    // (#) (-) Check if an already-Premium account is blocked from upgrading again.
    test('a non-free account cannot upgrade (negative)', () async {
      final gateway = FakeProfileGateway(
          profile: _free.copyWith(role: UserRole.premium));
      final c = _container(gateway);

      await expectLater(
          c.read(startPremiumProvider).call(), throwsA(isA<Exception>()));
      expect(gateway.profile?.role, UserRole.premium);
    });
  });

  // (#) Cancelling and resuming a subscription.
  group('ManageSubscription', () {
    // (#) (+) Check if cancel then resume writes the cancelled and active status transitions.
    test('cancel then resume writes the status transitions', () async {
      final gateway = FakeProfileGateway(profile: _free);
      await gateway.startPremium();
      final c = _container(gateway);

      await c.read(manageSubscriptionProvider).cancel();
      expect(gateway.subscription?.status, SubscriptionStatus.cancelled);

      await c.read(manageSubscriptionProvider).resume();
      expect(gateway.subscription?.status, SubscriptionStatus.active);

      expect(gateway.subscriptionStatusWrites,
          [SubscriptionStatus.cancelled, SubscriptionStatus.active]);
    });
  });

  // (#) Data-owned pricing and billing-date logic on the Subscription entity.
  group('Subscription entity rules', () {
    final sub = Subscription(
      id: 'u1',
      startedAt: DateTime(2026, 3, 15),
      renewsAt: DateTime(2026, 8, 15),
    );

    // (#) (+) Check if priceLabel formats the settled $9.99 / mo price.
    test('priceLabel formats the settled price', () {
      expect(sub.priceLabel, r'$9.99 / mo');
    });

    // (#) (+) Check if billingDates lists one charge per month, newest first, excluding a future date.
    test('billingDates synthesises one charge per month, most recent first',
        () {
      final dates = sub.billingDates(DateTime(2026, 7, 8));
      // 15 Jul hasn't happened yet on 8 Jul, so June is the latest charge.
      expect(dates, [
        DateTime(2026, 6, 15),
        DateTime(2026, 5, 15),
        DateTime(2026, 4, 15),
        DateTime(2026, 3, 15),
      ]);
    });

    // (#) (+) Check if billingDates keeps only the 12 most recent charges.
    test('billingDates caps at the 12 most recent charges', () {
      final old = sub.copyWith(startedAt: DateTime(2024, 1, 1));
      final dates = old.billingDates(DateTime(2026, 7, 8));
      expect(dates, hasLength(12));
      expect(dates.first, DateTime(2026, 7, 1)); // most recent kept
      expect(dates.last, DateTime(2025, 8, 1)); // oldest trimmed away
    });
  });
}
