import 'package:freezed_annotation/freezed_annotation.dart';

import 'deliverable.dart';
import 'expert_service.dart';
import 'public_profile.dart';
import 'service_request.dart';

part 'service_request_summary.freezed.dart';

/// ENTITY (read model) — one engagement with everything its surfaces need:
/// the request + its service + the other party's identity + deliverables +
/// whether a review exists. Used by MY PURCHASES, the #6.2 footer, and the
/// expert's request inbox.
@freezed
abstract class ServiceRequestSummary with _$ServiceRequestSummary {
  const ServiceRequestSummary._();

  const factory ServiceRequestSummary({
    required ServiceRequest request,
    ExpertService? service,
    PublicProfile? otherParty,
    @Default(<Deliverable>[]) List<Deliverable> deliverables,
    @Default(false) bool reviewed,
  }) = _ServiceRequestSummary;

  /// #6.2 footer: "Leave a review" appears only here.
  bool get reviewUnlocked => request.isCompleted && !reviewed;
}
