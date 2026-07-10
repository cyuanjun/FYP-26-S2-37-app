import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/expert_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/publish_service.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/expert_service.dart';

import '../helpers/fakes.dart';

ProviderContainer _container(FakeExpertGateway gateway, {String? userId = 'x1'}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId),
    expertGatewayProvider.overrideWithValue(gateway),
  ]);
  addTearDown(c.dispose);
  return c;
}

const _service = ExpertService(
  id: '',
  expertUserId: 'x1',
  status: ServiceStatus.live,
  name: 'Mobility Reset',
  category: 'mobility',
  fulfillment: FulfillmentType.coaching,
  pricingModel: PricingModel.recurring,
  priceCents: 8000,
);

void main() {
  group('PublishService', () {
    test('empty id creates, non-empty id updates', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway);

      await c.read(publishServiceProvider).call(_service);
      expect(gateway.createdServices, hasLength(1));
      expect(gateway.updatedServices, isEmpty);

      await c
          .read(publishServiceProvider)
          .call(_service.copyWith(id: 's1', priceCents: 9000));
      expect(gateway.updatedServices, hasLength(1));
      expect(gateway.updatedServices.single.priceCents, 9000);
    });
  });

  group('UpdateExpertProfile', () {
    test('writes the descriptive fields for the current user', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway);

      await c.read(updateExpertProfileProvider).call(
        title: 'Head Coach',
        yearsCoaching: 10,
        about: 'About me',
        credentials: ['NASM CPT'],
        specialties: ['strength', 'mobility'],
      );

      expect(gateway.profileUpdates, hasLength(1));
      final u = gateway.profileUpdates.single;
      expect(u['id'], 'x1');
      expect(u['title'], 'Head Coach');
      expect(u['specialties'], ['strength', 'mobility']);
    });

    test('signed out → no-op, nothing written (negative)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway, userId: null);

      await c.read(updateExpertProfileProvider).call(
        title: 'Head Coach',
        yearsCoaching: 10,
        about: 'About me',
        credentials: ['NASM CPT'],
        specialties: ['strength'],
      );

      expect(gateway.profileUpdates, isEmpty);
    });
  });

  group('service enum wire values', () {
    test('dbValue matches the Postgres enum spellings', () {
      expect(FulfillmentType.workoutPlan.dbValue, 'workout_plan');
      expect(FulfillmentType.coaching.dbValue, 'coaching');
      expect(PricingModel.oneTime.dbValue, 'one_time');
      expect(PricingModel.recurring.dbValue, 'recurring');
      expect(ResponseTime.h24.dbValue, '24h');
    });
  });
}
