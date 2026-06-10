// Shared enums mirroring the Postgres enum types (lowercase values match by name
// under json_serializable's default enum encoding). See supabase migrations.

enum UserRole { free, premium, expert, admin }

enum UserStatus { active, suspended }

enum PreferredUnits { metric, imperial }

enum FeelRating { great, good, okay, tough }

enum TrackSource { live, gpx }
