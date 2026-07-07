# Database Drafts

These migrations are drafts for the shared `FYP-26-S2-37-app` Postgres/Supabase database.

They are kept in this landing-page repo for planning and presentation, but final migrations should be copied into the app database project before real integration.

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
