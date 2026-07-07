# Database Drafts

These migrations are drafts for the shared `FYP-26-S2-37-app` Postgres/Supabase database.

**Applied 11 Jul 2026** — these drafts were finalised as `app/supabase/migrations/20260711090000_landing_site.sql` (plus seed additions in `app/supabase/seed.sql` and `seed-demo.sql` §10) and are live on both the local stack and the hosted project. The files below are kept for provenance; the app migration is canonical. Differences from the drafts: policies use the shared `is_admin()` helper, the metric view became an anon-callable `landing_metric_summary()` function (plus `landing_featured_experts()`), premium price corrected to $9.99/mth, and `contact_messages` already existed in the app schema (no new table needed).

Current files:

- `001_landing_public_testimonials.sql`
- `002_landing_pricing_plans.sql`
- `003_landing_media_assets.sql`
- `004_landing_metric_summary.sql`
- `005_landing_seed_data.sql`

Important notes:

- Use the app schema as the source of truth.
- Keep SQL Supabase/Postgres-compatible.
- Do not use SQLite-only behavior.
- Public policies must expose only approved/active/public-safe data.
- Admin policies currently rely on `profiles.role = 'admin'`.

Related docs:

- `docs/README.md`
- `docs/database changes.md`
- `docs/limitations.md`
