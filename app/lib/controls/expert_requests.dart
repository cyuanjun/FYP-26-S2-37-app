import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../boundaries/gateways/expert_gateway.dart';
import '../core/seq_log.dart';
import '../core/strings.dart';
import '../entities/deliverable.dart';
import '../entities/service_request_summary.dart';
import 'authenticate.dart';
import 'browse_experts.dart';

// (#) This file is the expert's side of the marketplace: the list of incoming
// (#) requests plus the accept, decline, send-deliverable and complete actions.
// (#) The status changes go through SECURITY DEFINER RPCs in the gateway.

// (#) Loads the requests waiting for the signed-in expert; empty for non-experts.
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

// (#) Expert accepts a client's request. Runs the accept RPC through the gateway
// (#) and reloads the incoming list.
class AcceptServiceRequest {
  AcceptServiceRequest(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Marks the given request accepted.
  Future<void> call(String requestId) async {
    SeqLog.msg('accept-request', 'ExpertRequestsView', 'AcceptServiceRequest',
        'accept($requestId)');
    SeqLog.msg('accept-request', 'AcceptServiceRequest', 'ExpertGateway',
        'accept_service_request(rpc)');
    await _ref.read(expertGatewayProvider).acceptRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
  }
}

// (#) Expert turns down a request. Marks it declined via the gateway and reloads
// (#) the incoming list.
class DeclineServiceRequest {
  DeclineServiceRequest(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Marks the given request declined.
  Future<void> call(String requestId) async {
    SeqLog.msg('decline-request', 'ExpertRequestsView',
        'DeclineServiceRequest', 'decline($requestId)');
    await _ref.read(expertGatewayProvider).declineRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
  }
}

// (#) Expert sends the finished work to the client. Requires a title, builds an
// (#) optional section from the typed heading and lines, posts it through the
// (#) gateway and reloads the list. Returns false if the title is blank.
class SendDeliverable {
  SendDeliverable(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Validates the title, assembles the deliverable and submits it.
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

// (#) Expert closes out a finished job. Runs the complete RPC, then reloads both
// (#) the request list and the expert directory because the client count changes.
class CompleteServiceRequest {
  CompleteServiceRequest(this._ref);

  final Ref _ref; // (#) Riverpod handle for reading the gateway

  // (#) Marks the given request complete.
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

// (#) Providers that hand the expert-requests screen each of the four controls.
final acceptServiceRequestProvider =
    Provider<AcceptServiceRequest>(AcceptServiceRequest.new);
final declineServiceRequestProvider =
    Provider<DeclineServiceRequest>(DeclineServiceRequest.new);
final sendDeliverableProvider = Provider<SendDeliverable>(SendDeliverable.new);
final completeServiceRequestProvider =
    Provider<CompleteServiceRequest>(CompleteServiceRequest.new);
