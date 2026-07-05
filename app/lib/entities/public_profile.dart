import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'public_profile.freezed.dart';
part 'public_profile.g.dart';

/// ENTITY (read model) — a user as everyone else may see them: mirrors the
/// `public_profiles` privacy view (no email, no notification prefs). Feed
/// authors, friend lists, and leaderboard rows all render from this.
@freezed
abstract class PublicProfile with _$PublicProfile {
  const PublicProfile._();

  const factory PublicProfile({
    required String id,
    UserRole? role,
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
    String? bio,
    @Default(0) int totalXp,
    @Default(1) int level,
    @Default(0) int currentStreak,
  }) = _PublicProfile;

  factory PublicProfile.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileFromJson(json);

  String get displayName {
    final full = [firstName, lastName].whereType<String>().join(' ').trim();
    if (full.isNotEmpty) return full;
    return username ?? 'Member';
  }

  /// "MP"-style initials for the avatar fallback.
  String get initials {
    final parts = [firstName, lastName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .toList();
    if (parts.isEmpty) return (username ?? '?')[0].toUpperCase();
    return parts.join();
  }

  String get handle => username != null ? '@$username' : '';
}
