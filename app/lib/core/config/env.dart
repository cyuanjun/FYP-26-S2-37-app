/// Runtime configuration. Values default to the Wise Workout Supabase project
/// (`zbeyytgilrqruttvecdc`) but can be overridden at build time with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
///
/// The publishable (anon) key is **safe to ship in the client** — every table is
/// gated by Row-Level Security (see supabase/migrations/*_rls_policies.sql).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zbeyytgilrqruttvecdc.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_lDdY_aQy82M2-S6zLCi83g_ejX5wiBK',
  );
}
