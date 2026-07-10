import 'package:freezed_annotation/freezed_annotation.dart';

import 'deliverable.dart';
import 'expert_service.dart';
import 'public_profile.dart';
import 'service_request.dart';

part 'service_request_summary.freezed.dart';

// (#) A booking bundled with everything the screens need around it: the request
// (#) itself, the service, the other person, any delivered files and whether a
// (#) review has been left. Saves the UI from stitching those together.
@freezed
abstract class ServiceRequestSummary with _$ServiceRequestSummary {
  const ServiceRequestSummary._();

  const factory ServiceRequestSummary({
    required ServiceRequest request, // (#) the core booking record
    ExpertService? service, // (#) the listing that was bought
    PublicProfile? otherParty, // (#) the person on the other end, client or expert
    @Default(<Deliverable>[]) List<Deliverable> deliverables, // (#) files the expert handed over
    @Default(false) bool reviewed, // (#) whether the client has already left a review
  }) = _ServiceRequestSummary;

  // (#) The "Leave a review" button shows only when the job is done and not yet reviewed.
  bool get reviewUnlocked => request.isCompleted && !reviewed;
}
