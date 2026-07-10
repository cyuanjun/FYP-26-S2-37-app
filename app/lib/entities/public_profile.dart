import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'public_profile.freezed.dart';
part 'public_profile.g.dart';

// (#) The safe-to-show public version of a user. It is what other members get to
// (#) see: name, avatar, level and streak, but never email or private settings.
@freezed
abstract class PublicProfile with _$PublicProfile {
  const PublicProfile._();

  const factory PublicProfile({
    required String id,
    UserRole? role,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl, // (#) link to their profile picture
    String? bio,
    @Default(0) int totalXp, // (#) lifetime experience points earned
    @Default(1) int level, // (#) current level, starts at 1
    @Default(0) int currentStreak, // (#) how many days running they have been active
  }) = _PublicProfile;

  // (#) Rebuilds a PublicProfile from its stored JSON.
  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);

  // (#) Name to show: full name if present, else the handle, else just "Member".
  String get displayName {
    final full = [firstName, lastName].whereType<String>().join(' ').trim();
    if (full.isNotEmpty) return full;
    return username ?? 'Member';
  }

  // (#) Two-letter initials for the avatar circle when there is no picture.
  String get initials {
    final parts = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .toList();
    if (parts.isEmpty) return (username ?? '?')[0].toUpperCase();
    return parts.join();
  }

  // (#) The username with an @ in front, or empty when there is no username.
  String get handle => username != null ? '@$username' : '';
}
