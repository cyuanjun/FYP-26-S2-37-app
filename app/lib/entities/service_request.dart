import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'expert_service.dart';

part 'service_request.freezed.dart';
part 'service_request.g.dart';

// (#) A job a client books with an expert. It follows a lifecycle from pending,
// (#) through accepted or cancelled, to completed, and it snapshots the price
// (#) as it was at the moment the client asked.
@freezed
abstract class ServiceRequest with _$ServiceRequest {
  const ServiceRequest._();

  const factory ServiceRequest({
    required String id,
    required String userId, // (#) the client who booked the job
    required String expertServiceId, // (#) which listed service was bought
    required String expertUserId, // (#) the expert doing the work
    required int quotedPriceCents, // (#) price locked in at request time, no real money moves
    @Default(ServiceRequestStatus.pending) ServiceRequestStatus status, // (#) where it sits in the lifecycle
    required String requestMessage, // (#) the note the client sent with the booking
    required DateTime requestedAt,
    DateTime? completedAt, // (#) when the expert marked it done, null until then
  }) = _ServiceRequest;

  // (#) Rebuilds a ServiceRequest from its stored JSON.
  factory ServiceRequest.fromJson(Map<String, dynamic> json) =>
      _$ServiceRequestFromJson(json);

  // (#) True while still waiting for the expert to accept or decline.
  bool get isPending => status == ServiceRequestStatus.pending;
  // (#) True once the expert has taken the job on.
  bool get isAccepted => status == ServiceRequestStatus.accepted;
  // (#) True once the expert has marked the work finished.
  bool get isCompleted => status == ServiceRequestStatus.completed;
  // (#) True when the expert declined it.
  bool get isCancelled => status == ServiceRequestStatus.cancelled;

  // (#) A cancelled job frees the client to book again, any other state blocks a new one.
  bool get blocksNewRequest => !isCancelled;

  // (#) The expert's delivered files only show once work has started or finished.
  bool get deliverablesVisible => isAccepted || isCompleted;

  // (#) The quoted price formatted for display, like "$40.00".
  String get quotedPriceLabel => ExpertService.formatCents(quotedPriceCents);
}
