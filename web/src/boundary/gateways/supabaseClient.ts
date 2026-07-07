import { createClient } from "@supabase/supabase-js";

// Same shared database as the Flutter app (see app/lib/core/config/env.dart).
// The publishable key is safe in the client — every table is RLS-gated, and the
// site's anon read surface is limited to the landing_* functions/policies
// (app/supabase/migrations/20260711090000_landing_site.sql).
// Override per environment with VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY
// (e.g. .env.local pointing at the local stack on :55321).
const url = import.meta.env.VITE_SUPABASE_URL ?? "https://zbeyytgilrqruttvecdc.supabase.co";
const anonKey =
  import.meta.env.VITE_SUPABASE_ANON_KEY ?? "sb_publishable_lDdY_aQy82M2-S6zLCi83g_ejX5wiBK";

export const supabase = createClient(url, anonKey);
