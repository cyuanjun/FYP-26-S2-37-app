import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/deliverable.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/expert_profile.dart';
import 'package:wise_workout/entities/expert_service.dart';
import 'package:wise_workout/entities/expert_summary.dart';
import 'package:wise_workout/entities/public_profile.dart';
import 'package:wise_workout/entities/service_request.dart';
import 'package:wise_workout/entities/service_request_summary.dart';

// (#) Builds a fake expert service at a given price.
ExpertService _service(String id, int cents) => ExpertService(
      id: id,
      expertUserId: 'x1',
      status: ServiceStatus.live,
      name: 'Service $id',
      category: 'strength',
      fulfillment: FulfillmentType.review,
      priceCents: cents,
    );

// (#) Builds a fake service request in a given status.
ServiceRequest _request(ServiceRequestStatus status) => ServiceRequest(
      id: 'r1',
      userId: 'u1',
      expertServiceId: 's1',
      expertUserId: 'x1',
      quotedPriceCents: 4500,
      status: status,
      requestMessage: 'help',
      requestedAt: DateTime.utc(2026, 7, 1),
    );

// (#) Tests the expert marketplace entity rules: price labels, request state gates, directory search, deliverables.
void main() {
  // (#) Group covering how prices render as dollar labels.
  group('ExpertService price formatting', () {
    // (#) (+) Check if whole dollars drop the cents and fractional amounts keep 2 decimals.
    test('whole dollars drop cents; fractional keep 2dp', () {
      expect(_service('a', 12000).priceLabel, r'$120');
      expect(_service('a', 4550).priceLabel, r'$45.50');
      expect(_service('a', 0).priceLabel, r'$0');
    });

    // (#) (+) Check if recurring services append /mo while one-off ones do not.
    test('recurring services get /mo', () {
      final s = _service('a', 8000).copyWith(pricingModel: PricingModel.recurring);
      expect(s.priceWithModel, r'$80/mo');
      expect(_service('a', 8000).priceWithModel, r'$80');
    });
  });

  // (#) Group covering the request-status gating of UI actions.
  group('ServiceRequest footer rules', () {
    // (#) (-) Check if only a cancelled request frees the footer while other statuses block a new request.
    test('cancelled frees the footer; everything else blocks (negative)', () {
      expect(_request(ServiceRequestStatus.cancelled).blocksNewRequest, isFalse);
      expect(_request(ServiceRequestStatus.pending).blocksNewRequest, isTrue);
      expect(_request(ServiceRequestStatus.accepted).blocksNewRequest, isTrue);
      expect(_request(ServiceRequestStatus.completed).blocksNewRequest, isTrue);
    });

    // (#) (+) Check if deliverables show only once the request is accepted or completed.
    test('deliverables visible once accepted or completed', () {
      expect(_request(ServiceRequestStatus.pending).deliverablesVisible, isFalse);
      expect(_request(ServiceRequestStatus.accepted).deliverablesVisible, isTrue);
      expect(_request(ServiceRequestStatus.completed).deliverablesVisible, isTrue);
    });

    // (#) (+) Check if the review option unlocks only when completed and not already reviewed.
    test('review unlocks only when completed and not yet reviewed', () {
      expect(
          ServiceRequestSummary(request: _request(ServiceRequestStatus.completed))
              .reviewUnlocked,
          isTrue);
      expect(
          ServiceRequestSummary(
                  request: _request(ServiceRequestStatus.completed),
                  reviewed: true)
              .reviewUnlocked,
          isFalse);
      expect(
          ServiceRequestSummary(request: _request(ServiceRequestStatus.accepted))
              .reviewUnlocked,
          isFalse);
    });
  });

  // (#) Group covering the marketplace directory card and search.
  group('ExpertSummary directory rules', () {
    final expert = ExpertSummary(
      identity: const PublicProfile(id: 'x1', firstName: 'Sam', lastName: 'Rivera'),
      profile: const ExpertProfile(
          id: 'x1', title: 'Strength Coach', specialties: ['strength']),
      services: [_service('a', 12000), _service('b', 4500)],
    );

    // (#) (+) Check if the cheapest service sets the min price and the "from $" label.
    test('min price + from label', () {
      expect(expert.minPriceCents, 4500);
      expect(expert.fromPriceLabel, r'from $45');
    });

    // (#) (+) Check if a text query matches name/title and a category matches specialties.
    test('query matches name/title; category matches specialties', () {
      expect(expert.matchesQuery('sam'), isTrue);
      expect(expert.matchesQuery('strength coach'), isTrue);
      expect(expert.matchesQuery('yoga'), isFalse);
      expect(expert.matchesCategory(null), isTrue);
      expect(expert.matchesCategory('strength'), isTrue);
      expect(expert.matchesCategory('nutrition'), isFalse);
    });
  });

  // (#) Group covering parsing a deliverable section from text lines.
  group('DeliverableSection.fromLines', () {
    // (#) (+) Check if each non-blank line becomes one trimmed item.
    test('one trimmed item per non-blank line', () {
      final s = DeliverableSection.fromLines('Day A', 'Squat 4x6\n\n  Bench 3x8  \n');
      expect(s.heading, 'Day A');
      expect(s.items.map((i) => i.label), ['Squat 4x6', 'Bench 3x8']);
    });
  });
}
