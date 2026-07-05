import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'expert_service.dart';

part 'service_request.freezed.dart';
part 'service_request.g.dart';

/// ENTITY — one client↔expert engagement. Lifecycle: pending → accepted |
/// cancelled (expert decides) → completed (expert-only; unlocks the review).
/// [quotedPriceCents] snapshots the price at request time — no payment moves.
@freezed
abstract class ServiceRequest with _$ServiceRequest {
  const ServiceRequest._();

  const factory ServiceRequest({
    required String id,
    required String userId,
    required String expertServiceId,
    required String expertUserId,
    required int quotedPriceCents,
    @Default(ServiceRequestStatus.pending) ServiceRequestStatus status,
    required String requestMessage,
    required DateTime requestedAt,
    DateTime? completedAt,
  }) = _ServiceRequest;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) =>
      _$ServiceRequestFromJson(json);

  bool get isPending => status == ServiceRequestStatus.pending;
  bool get isAccepted => status == ServiceRequestStatus.accepted;
  bool get isCompleted => status == ServiceRequestStatus.completed;
  bool get isCancelled => status == ServiceRequestStatus.cancelled;

  /// A declined (cancelled) engagement lets the client request again;
  /// anything else occupies the #6.2 footer.
  bool get blocksNewRequest => !isCancelled;

  /// The expert's docs appear once work has started (accepted or done).
  bool get deliverablesVisible => isAccepted || isCompleted;

  String get quotedPriceLabel => ExpertService.formatCents(quotedPriceCents);
}
