import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/expert_service.dart';
import '../entities/service_request_summary.dart';
import 'authenticate.dart';
import 'browse_experts.dart';

// (#) The client side of the expert marketplace: buying a service, reading your own
// (#) purchases, and leaving a review after a job.

// (#) Read provider for the MY PURCHASES list. Returns the signed-in user's service
// (#) requests, or empty when nobody is logged in.
final myServiceRequestsProvider =
    FutureProvider<List<ServiceRequestSummary>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <ServiceRequestSummary>[]);
  SeqLog.msg('view-purchases', 'ViewMyPurchases', 'ExpertGateway',
      'listMyRequests');
  return ref.watch(expertGatewayProvider).listMyRequests(userId);
});

// (#) For one service, finds the live request that should sit in its #6.2 footer:
// (#) the newest one that still blocks a fresh request (cancelled/declined ones free it).
final activeRequestForServiceProvider =
    FutureProvider.family<ServiceRequestSummary?, String>((ref, serviceId) async {
  final all = await ref.watch(myServiceRequestsProvider.future);
  return all
      .where((s) =>
          s.request.expertServiceId == serviceId &&
          s.request.blocksNewRequest)
      .firstOrNull;
});

// (#) The Request Service use case (US29). Creates a pending request with the price
// (#) copied from the listing (payment is only simulated) then refreshes the purchases.
class RequestService {
  RequestService(this._ref);

  final Ref _ref;

  // (#) Rejects a blank message and no-login, otherwise calls the expert gateway to
  // (#) create the request, invalidates MY PURCHASES, and returns true on success.
  Future<bool> call({
    required ExpertService service,
    required String message,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null || message.isBlank) return false;
    SeqLog.msg('request-service', 'ServiceDetailScreen', 'RequestService',
        'request(${service.id})');
    SeqLog.msg('request-service', 'RequestService', 'ExpertGateway',
        'createRequest(quoted: ${service.priceCents})');
    await _ref
        .read(expertGatewayProvider)
        .createRequest(userId: userId, service: service, message: message);
    _ref.invalidate(myServiceRequestsProvider);
    return true;
  }
}

// (#) The Submit Review use case. After a completed job the client rates the expert;
// (#) an RPC enforces the rules (client only, completed only, once), then the whole
// (#) expert directory refreshes so the new rating shows everywhere.
class SubmitReview {
  SubmitReview(this._ref);

  final Ref _ref;

  // (#) Checks the 1-5 rating and non-blank body, posts through the gateway's review RPC,
  // (#) then invalidates purchases plus the expert and listing providers.
  Future<bool> call({
    required String requestId,
    required int rating,
    required String body,
  }) async {
    if (rating < 1 || rating > 5 || body.isBlank) return false;
    SeqLog.msg('submit-review', 'ServiceDetailScreen', 'SubmitReview',
        'review($requestId, $rating★)');
    SeqLog.msg('submit-review', 'SubmitReview', 'ExpertGateway',
        'submit_expert_review(rpc)');
    await _ref
        .read(expertGatewayProvider)
        .submitReview(requestId: requestId, rating: rating, body: body);
    _ref.invalidate(myServiceRequestsProvider);
    _ref.invalidate(expertsProvider);
    _ref.invalidate(serviceListingsProvider);
    return true;
  }
}

// (#) Providers the service detail screen uses to buy and to review.
final requestServiceProvider = Provider<RequestService>(RequestService.new);
final submitReviewProvider = Provider<SubmitReview>(SubmitReview.new);
