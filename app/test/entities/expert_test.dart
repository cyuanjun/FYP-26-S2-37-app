import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/deliverable.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/expert_profile.dart';
import 'package:wise_workout/entities/expert_service.dart';
import 'package:wise_workout/entities/expert_summary.dart';
import 'package:wise_workout/entities/public_profile.dart';
import 'package:wise_workout/entities/service_request.dart';
import 'package:wise_workout/entities/service_request_summary.dart';

ExpertService _service(String id, int cents) => ExpertService(
      id: id,
      expertUserId: 'x1',
      status: ServiceStatus.live,
      name: 'Service $id',
      category: 'strength',
      fulfillment: FulfillmentType.review,
      priceCents: cents,
    );

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

void main() {
  group('ExpertService price formatting', () {
    test('whole dollars drop cents; fractional keep 2dp', () {
      expect(_service('a', 12000).priceLabel, r'$120');
      expect(_service('a', 4550).priceLabel, r'$45.50');
      expect(_service('a', 0).priceLabel, r'$0');
    });

    test('recurring services get /mo', () {
      final s = _service('a', 8000).copyWith(pricingModel: PricingModel.recurring);
      expect(s.priceWithModel, r'$80/mo');
      expect(_service('a', 8000).priceWithModel, r'$80');
    });
  });

  group('ServiceRequest footer rules', () {
    test('cancelled frees the footer; everything else blocks (negative)', () {
      expect(_request(ServiceRequestStatus.cancelled).blocksNewRequest, isFalse);
      expect(_request(ServiceRequestStatus.pending).blocksNewRequest, isTrue);
      expect(_request(ServiceRequestStatus.accepted).blocksNewRequest, isTrue);
      expect(_request(ServiceRequestStatus.completed).blocksNewRequest, isTrue);
    });

    test('deliverables visible once accepted or completed', () {
      expect(_request(ServiceRequestStatus.pending).deliverablesVisible, isFalse);
      expect(_request(ServiceRequestStatus.accepted).deliverablesVisible, isTrue);
      expect(_request(ServiceRequestStatus.completed).deliverablesVisible, isTrue);
    });

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

  group('ExpertSummary directory rules', () {
    final expert = ExpertSummary(
      identity: const PublicProfile(id: 'x1', firstName: 'Sam', lastName: 'Rivera'),
      profile: const ExpertProfile(
          id: 'x1', title: 'Strength Coach', specialties: ['strength']),
      services: [_service('a', 12000), _service('b', 4500)],
    );

    test('min price + from label', () {
      expect(expert.minPriceCents, 4500);
      expect(expert.fromPriceLabel, r'from $45');
    });

    test('query matches name/title; category matches specialties', () {
      expect(expert.matchesQuery('sam'), isTrue);
      expect(expert.matchesQuery('strength coach'), isTrue);
      expect(expert.matchesQuery('yoga'), isFalse);
      expect(expert.matchesCategory(null), isTrue);
      expect(expert.matchesCategory('strength'), isTrue);
      expect(expert.matchesCategory('nutrition'), isFalse);
    });
  });

  group('DeliverableSection.fromLines', () {
    test('one trimmed item per non-blank line', () {
      final s = DeliverableSection.fromLines('Day A', 'Squat 4x6\n\n  Bench 3x8  \n');
      expect(s.heading, 'Day A');
      expect(s.items.map((i) => i.label), ['Squat 4x6', 'Bench 3x8']);
    });
  });
}
