import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/expert_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/expert_requests.dart';
import 'package:wise_workout/entities/deliverable.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/profile.dart';
import 'package:wise_workout/entities/service_request.dart';
import 'package:wise_workout/entities/service_request_summary.dart';

import '../helpers/fakes.dart';

const _expertProfile =
    Profile(id: 'x1', email: 'sam@test', role: UserRole.expert);
const _freeProfile = Profile(id: 'u1', email: 'mia@test', role: UserRole.free);

ProviderContainer _container(FakeExpertGateway gateway, Profile profile) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(profile.id),
    currentProfileProvider.overrideWith((ref) async => profile),
    expertGatewayProvider.overrideWithValue(gateway),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('incomingRequestsProvider', () {
    final summary = ServiceRequestSummary(
      request: ServiceRequest(
        id: 'r1',
        userId: 'u1',
        expertServiceId: 's1',
        expertUserId: 'x1',
        quotedPriceCents: 4500,
        requestMessage: 'goal',
        requestedAt: DateTime.utc(2026, 7, 1),
      ),
    );

    test('expert sees the inbox (positive)', () async {
      final gateway = FakeExpertGateway()..incomingRequests = [summary];
      final c = _container(gateway, _expertProfile);
      expect(await c.read(incomingRequestsProvider.future), hasLength(1));
    });

    test('non-expert gets an empty inbox without a fetch (negative)', () async {
      final gateway = FakeExpertGateway()..incomingRequests = [summary];
      final c = _container(gateway, _freeProfile);
      expect(await c.read(incomingRequestsProvider.future), isEmpty);
    });
  });

  group('transitions', () {
    test('accept / decline / complete forward the request id', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway, _expertProfile);

      await c.read(acceptServiceRequestProvider).call('r1');
      await c.read(declineServiceRequestProvider).call('r2');
      await c.read(completeServiceRequestProvider).call('r3');
      expect(gateway.acceptCalls.single, 'r1');
      expect(gateway.declineCalls.single, 'r2');
      expect(gateway.completeCalls.single, 'r3');
    });
  });

  group('SendDeliverable', () {
    test('builds one section from lines; note optional (positive)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway, _expertProfile);

      final ok = await c.read(sendDeliverableProvider).call(
            requestId: 'r1',
            title: 'Weeks 1-4',
            sectionHeading: 'Day A',
            sectionLines: 'Squat 4x6\nBench 3x8',
          );
      expect(ok, isTrue);
      final call = gateway.deliverableCalls.single;
      expect(call['title'], 'Weeks 1-4');
      final sections = call['sections'] as List<DeliverableSection>;
      expect(sections.single.items, hasLength(2));
    });

    test('blank title rejected; empty section omitted (negative)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway, _expertProfile);

      expect(
          await c
              .read(sendDeliverableProvider)
              .call(requestId: 'r1', title: '  '),
          isFalse);
      expect(gateway.deliverableCalls, isEmpty);

      await c
          .read(sendDeliverableProvider)
          .call(requestId: 'r1', title: 'Note only');
      expect(
          (gateway.deliverableCalls.single['sections'] as List), isEmpty);
    });
  });
}
