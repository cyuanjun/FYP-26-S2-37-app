import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

// (#) A user's core account details. This is the User from the ERD, stored as
// (#) the profiles table: email, role, name, avatar and units. Anything specific
// (#) to one role lives in its own separate 1:1 table.
@freezed
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    required String email,
    required UserRole role, // (#) free, premium, expert or admin, gates what they can do
    UserStatus? status, // (#) account standing, like active or suspended
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl, // (#) link to their uploaded profile picture
    @Default(PreferredUnits.metric) PreferredUnits preferredUnits, // (#) metric or imperial for display
    String? bio,
    @Default(<String, dynamic>{}) Map<String, dynamic> notificationPrefs, // (#) which reminders they turned on
    DateTime? onboardingCompletedAt, // (#) when they finished the intro wizard, null means not yet
    @Default(<String>[]) List<String> followedExpertIds, // (#) experts they follow
  }) = _Profile;

  // (#) Rebuilds a Profile from its stored JSON.
  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  // (#) Best name to show: full name if we have it, else the handle, else email.
  String get displayName {
    final full = [firstName, lastName].whereType<String>().join(' ').trim();
    if (full.isNotEmpty) return full;
    return username ?? email;
  }

  // (#) True when this is a paying premium user.
  bool get isPremium => role == UserRole.premium;

  // (#) True for the free tier, where the history cap and basic AI depth kick in.
  bool get isFree => role == UserRole.free;

  // (#) True for experts, whose Experts tab shows incoming requests instead.
  bool get isExpert => role == UserRole.expert;

  // (#) True until they have finished the first-run onboarding wizard.
  bool get needsOnboarding => onboardingCompletedAt == null;
}
