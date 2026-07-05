import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/expert_service.dart';
import '../entities/service_request_summary.dart';
import 'authenticate.dart';
import 'browse_experts.dart';

/// CONTROLs — Request Expert Service (US29, bce-design §5.6) + the client's
/// engagement reads (MY PURCHASES, the #6.2 footer) + Submit Review.

final myServiceRequestsProvider =
    FutureProvider<List<ServiceRequestSummary>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(const <ServiceRequestSummary>[]);
  SeqLog.msg('view-purchases', 'ViewMyPurchases', 'ExpertGateway',
      'listMyRequests');
  return ref.watch(expertGatewayProvider).listMyRequests(userId);
});

/// The engagement occupying a service's #6.2 footer, if any: the newest
/// request that isn't cancelled (a declined request frees the footer).
final activeRequestForServiceProvider =
    FutureProvider.family<ServiceRequestSummary?, String>((ref, serviceId) async {
  final all = await ref.watch(myServiceRequestsProvider.future);
  return all
      .where((s) =>
          s.request.expertServiceId == serviceId &&
          s.request.blocksNewRequest)
      .firstOrNull;
});

/// CONTROL — Request Service: inserts a pending ServiceRequest with the
/// price snapshotted from the service (simulated payment — nothing charged).
class RequestService {
  RequestService(this._ref);

  final Ref _ref;

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

/// CONTROL — Submit Review: RPC-gated (client-only, completed-only, once);
/// refreshes the directory so the expert's aggregates update everywhere.
class SubmitReview {
  SubmitReview(this._ref);

  final Ref _ref;

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

final requestServiceProvider = Provider<RequestService>(RequestService.new);
final submitReviewProvider = Provider<SubmitReview>(SubmitReview.new);
