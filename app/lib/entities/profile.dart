import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// ENTITY — the `User` of the TDM §8 ERD, stored as `profiles` (keyed on auth.users.id).
/// Role-specific data lives in 1:1 specialization tables (FitnessProfile, etc.).
@freezed
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    required String email,
    required UserRole role,
    UserStatus? status,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
    @Default(PreferredUnits.metric) PreferredUnits preferredUnits,
    String? bio,
    @Default(<String, dynamic>{}) Map<String, dynamic> notificationPrefs,
    DateTime? onboardingCompletedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  /// "MIA PATEL" style display name; falls back to the handle, then email.
  String get displayName {
    final full = [firstName, lastName].whereType<String>().join(' ').trim();
    if (full.isNotEmpty) return full;
    return username ?? email;
  }

  bool get isPremium => role == UserRole.premium;

  /// First-time users complete the post-login onboarding wizard (#3) before
  /// reaching the main shell.
  bool get needsOnboarding => onboardingCompletedAt == null;
}
