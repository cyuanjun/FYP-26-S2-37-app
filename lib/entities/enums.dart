// Shared enums mirroring the Postgres enum types (lowercase values match by name
// under json_serializable's default enum encoding). See supabase migrations.

enum UserRole { free, premium, expert, admin }

enum UserStatus { active, suspended }

enum PreferredUnits { metric, imperial }

enum FeelRating { great, good, okay, tough }

enum TrackSource { live, gpx }

/// Named social share targets (UI value type; no DB counterpart).
enum SocialPlatform { facebook, instagram, twitter, tiktok }

extension SocialPlatformLabel on SocialPlatform {
  String get label => switch (this) {
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.twitter => 'Twitter',
        SocialPlatform.tiktok => 'TikTok',
      };
}
