import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/boundaries/gateways/expert_gateway.dart';
import 'package:wise_workout/controls/authenticate.dart';
import 'package:wise_workout/controls/service_requests.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/expert_service.dart';
import 'package:wise_workout/entities/service_request.dart';
import 'package:wise_workout/entities/service_request_summary.dart';

import '../helpers/fakes.dart';

// (#) Tests the RequestService, active-request selection, and SubmitReview controls.

const _service = ExpertService(
  id: 's1',
  expertUserId: 'x1',
  status: ServiceStatus.live,
  name: 'Form Check',
  category: 'strength',
  fulfillment: FulfillmentType.review,
  priceCents: 4500,
);

// (#) Makes a request summary for the given service and status.
ServiceRequestSummary _summary(String serviceId, ServiceRequestStatus status,
        {DateTime? at}) =>
    ServiceRequestSummary(
      request: ServiceRequest(
        id: 'r-$serviceId-${status.name}',
        userId: 'u1',
        expertServiceId: serviceId,
        expertUserId: 'x1',
        quotedPriceCents: 4500,
        status: status,
        requestMessage: 'goal',
        requestedAt: at ?? DateTime.utc(2026, 7, 1),
      ),
    );

// (#) Builds a ProviderContainer wired to the fake expert gateway and a signed-in user.
ProviderContainer _container(FakeExpertGateway gateway, {String? userId = 'u1'}) {
  final c = ProviderContainer(overrides: [
    currentUserIdProvider.overrideWithValue(userId),
    expertGatewayProvider.overrideWithValue(gateway),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  // (#) Buying an expert service.
  group('RequestService', () {
    // (#) (+) Check if a request is created carrying the price snapshotted from the service.
    test('creates a request with the snapshotted price (positive)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway);

      final ok = await c
          .read(requestServiceProvider)
          .call(service: _service, message: 'Check my deadlift please');
      expect(ok, isTrue);
      final call = gateway.createRequestCalls.single;
      expect(call['serviceId'], 's1');
      expect(call['expertUserId'], 'x1');
      expect(call['price'], '4500');
    });

    // (#) (-) Check if a blank request message is rejected before hitting the gateway.
    test('blank message rejected before the gateway (negative)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway);

      expect(await c.read(requestServiceProvider).call(service: _service, message: '  '),
          isFalse);
      expect(gateway.createRequestCalls, isEmpty);
    });
  });

  // (#) Picking the request that governs a service's footer state.
  group('activeRequestForServiceProvider (footer selection)', () {
    // (#) (+) Check if a cancelled request frees the footer while a pending one still occupies it.
    test('cancelled requests free the footer; others occupy it', () async {
      final gateway = FakeExpertGateway()
        ..myRequests = [
          _summary('s1', ServiceRequestStatus.cancelled),
          _summary('s2', ServiceRequestStatus.pending),
        ];
      final c = _container(gateway);

      expect(await c.read(activeRequestForServiceProvider('s1').future), isNull);
      expect(
          (await c.read(activeRequestForServiceProvider('s2').future))!
              .request
              .isPending,
          isTrue);
    });
  });

  // (#) Leaving a review on a finished request.
  group('SubmitReview', () {
    // (#) (+) Check if a valid review forwards to the RPC and refreshes the directory.
    test('forwards to the RPC and refreshes the directory (positive)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway);

      final ok = await c
          .read(submitReviewProvider)
          .call(requestId: 'r1', rating: 5, body: 'Superb coaching');
      expect(ok, isTrue);
      expect(gateway.reviewCalls.single,
          {'requestId': 'r1', 'rating': 5, 'body': 'Superb coaching'});
    });

    // (#) (-) Check if a zero rating or a blank body is rejected before the gateway.
    test('invalid rating or blank body rejected (negative)', () async {
      final gateway = FakeExpertGateway();
      final c = _container(gateway);

      expect(await c.read(submitReviewProvider).call(requestId: 'r1', rating: 0, body: 'x'),
          isFalse);
      expect(await c.read(submitReviewProvider).call(requestId: 'r1', rating: 4, body: '  '),
          isFalse);
      expect(gateway.reviewCalls, isEmpty);
    });
  });
}
