# Gateway Seed Data

These JSON files are hardcoded demo data used by the gateway boundary while the shared Postgres/Supabase database is not connected yet.

They are not the final database source of truth.

Current purpose:

- Keep the landing page populated for local development and presentation.
- Make it explicit which data is temporary.
- Allow gateway files to be swapped from JSON reads to database queries later without changing boundary UI components.

Later replacement:

- `landing-page.seed.json` -> `landing_sections` / static landing content / media references
- `pricing.seed.json` -> `landing_pricing_plans`
- `expert-categories.seed.json` -> `expert_categories`
- `metrics.seed.json` -> `landing_metric_summary`
- `experts.seed.json` -> `profiles`, `expert_profiles`, `expert_categories`, `expert_reviews`
- `testimonials.seed.json` -> `public_testimonials`
