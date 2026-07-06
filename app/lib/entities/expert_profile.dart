import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'expert_service.dart';

part 'expert_profile.freezed.dart';
part 'expert_profile.g.dart';

/// ENTITY — the expert specialization row (1:1 off profiles, role=expert).
/// rating_avg / review_count / client_count are stored aggregates, kept
/// consistent by the submit_expert_review / complete_service_request RPCs.
@freezed
abstract class ExpertProfile with _$ExpertProfile {
  const ExpertProfile._();

  const factory ExpertProfile({
    required String id,
    required String title,
    @Default(0) int yearsCoaching,
    @Default('') String about,
    @Default(<String>[]) List<String> credentials,
    @Default(<String>[]) List<String> specialties,
    @Default(0) double ratingAvg,
    @Default(0) int reviewCount,
    @Default(0) int clientCount,
    @Default(0) int totalEarnedCents,
    @Default(VerificationStatus.pending) VerificationStatus verificationStatus,
  }) = _ExpertProfile;

  factory ExpertProfile.fromJson(Map<String, dynamic> json) =>
      _$ExpertProfileFromJson(json);

  bool get isVerified => verificationStatus == VerificationStatus.verified;

  /// "\$3720" — lifetime simulated earnings.
  String get earnedLabel => ExpertService.formatCents(totalEarnedCents);
}
