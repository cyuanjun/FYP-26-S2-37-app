import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'expert_service.dart';

part 'expert_profile.freezed.dart';
part 'expert_profile.g.dart';

// (#) The extra profile an expert carries on top of a normal user. Holds their
// (#) title, credentials and specialties, plus running rating, review and client
// (#) tallies. Sits 1:1 with the user row and only exists for expert accounts.
@freezed
abstract class ExpertProfile with _$ExpertProfile {
  const ExpertProfile._();

  const factory ExpertProfile({
    required String id,
    required String title, // (#) headline like "Strength Coach"
    @Default(0) int yearsCoaching,
    @Default('') String about,
    @Default(<String>[]) List<String> credentials, // (#) certs and qualifications
    @Default(<String>[]) List<String> specialties, // (#) category slugs they work in
    @Default(0) double ratingAvg, // (#) stored average, updated by the review RPC
    @Default(0) int reviewCount,
    @Default(0) int clientCount,
    @Default(0) int totalEarnedCents, // (#) lifetime simulated earnings
    @Default(VerificationStatus.pending) VerificationStatus verificationStatus, // (#) admin approval state
  }) = _ExpertProfile;

  factory ExpertProfile.fromJson(Map<String, dynamic> json) =>
      _$ExpertProfileFromJson(json);

  // (#) true once an admin has verified the application
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  // (#) earnings formatted as a dollar string like "$3720"
  String get earnedLabel => ExpertService.formatCents(totalEarnedCents);
}
