import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/deliverable.dart';
import '../entities/service_request_summary.dart';
import 'authenticate.dart';
import 'browse_experts.dart';

/// CONTROLs — the expert's side of the marketplace (US49–US51, minimal
/// realization): incoming requests + accept / decline / deliverable / complete.
/// Status transitions go through the SECURITY DEFINER RPCs.

final incomingRequestsProvider =
    FutureProvider<List<ServiceRequestSummary>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final profile = await ref.watch(currentProfileProvider.future);
  if (userId == null || !(profile?.isExpert ?? false)) {
    return const <ServiceRequestSummary>[];
  }
  SeqLog.msg('view-requests', 'ExpertRequestsView', 'ExpertGateway',
      'listIncomingRequests');
  return ref.watch(expertGatewayProvider).listIncomingRequests(userId);
});

class AcceptServiceRequest {
  AcceptServiceRequest(this._ref);

  final Ref _ref;

  Future<void> call(String requestId) async {
    SeqLog.msg('accept-request', 'ExpertRequestsView', 'AcceptServiceRequest',
        'accept($requestId)');
    SeqLog.msg('accept-request', 'AcceptServiceRequest', 'ExpertGateway',
        'accept_service_request(rpc)');
    await _ref.read(expertGatewayProvider).acceptRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
  }
}

class DeclineServiceRequest {
  DeclineServiceRequest(this._ref);

  final Ref _ref;

  Future<void> call(String requestId) async {
    SeqLog.msg('decline-request', 'ExpertRequestsView',
        'DeclineServiceRequest', 'decline($requestId)');
    await _ref.read(expertGatewayProvider).declineRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
  }
}

class SendDeliverable {
  SendDeliverable(this._ref);

  final Ref _ref;

  Future<bool> call({
    required String requestId,
    required String title,
    String? note,
    String? sectionHeading,
    String? sectionLines,
  }) async {
    if (title.isBlank) return false;
    SeqLog.msg('send-deliverable', 'DeliverableComposer', 'SendDeliverable',
        'send($requestId)');
    final sections = <DeliverableSection>[
      if (!sectionHeading.isBlank && !sectionLines.isBlank)
        DeliverableSection.fromLines(sectionHeading!.trim(), sectionLines!),
    ];
    SeqLog.msg('send-deliverable', 'SendDeliverable', 'ExpertGateway',
        'sendDeliverable(${sections.length} sections)');
    await _ref.read(expertGatewayProvider).sendDeliverable(
        requestId: requestId, title: title, note: note, sections: sections);
    _ref.invalidate(incomingRequestsProvider);
    return true;
  }
}

class CompleteServiceRequest {
  CompleteServiceRequest(this._ref);

  final Ref _ref;

  Future<void> call(String requestId) async {
    SeqLog.msg('complete-request', 'ExpertRequestsView',
        'CompleteServiceRequest', 'complete($requestId)');
    SeqLog.msg('complete-request', 'CompleteServiceRequest', 'ExpertGateway',
        'complete_service_request(rpc)');
    await _ref.read(expertGatewayProvider).completeRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
    _ref.invalidate(expertsProvider); // client_count bumped
  }
}

final acceptServiceRequestProvider =
    Provider<AcceptServiceRequest>(AcceptServiceRequest.new);
final declineServiceRequestProvider =
    Provider<DeclineServiceRequest>(DeclineServiceRequest.new);
final sendDeliverableProvider = Provider<SendDeliverable>(SendDeliverable.new);
final completeServiceRequestProvider =
    Provider<CompleteServiceRequest>(CompleteServiceRequest.new);
