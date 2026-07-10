# Landing Page BCE Plan

> **Updated 11 Jul 2026:** the site now shares the app's Supabase database — live reads (metrics, pricing, testimonials, experts), real Supabase Auth (register / login / expert application), and real `contact_messages` inserts, with the bundled seed as offline fallback. Statements below about placeholder/seed-only gateways are historical; see [limitations.md](./limitations.md) for the current truth.

## Current Objective

Build a Wise Workout landing page that visually follows the existing `../fyp` frontend while using a BCE-oriented architecture compatible with the shared `../FYP-26-S2-37-app` database direction.

## Current Implementation

The repo currently includes:

- Landing page UI copied/adapted from the original prototype.
- Login UI at `/login`.
- User registration UI at `/register`.
- Expert application UI at `/expert-application`.
  - Requires identity and certification documents.
  - Validates PDF/JPG/PNG/WebP files up to 5 MB each.
- BCE folders for boundary, controller, and entity.
- Gateway seed data under `src/boundary/gateways/seed/`.
- Draft database migrations under `database/migrations/`.
- BCE dependency checker at `scripts/check-bce.mjs`.
- Verification script: `npm run verify`.

## Stack

- Vue 3
- Vite
- TypeScript
- Vue Router
- Postgres/Supabase-compatible database plan

## BCE Structure

```text
src/
  boundary/
    ui/
      auth/
      common/
      landing/
    gateways/
      seed/

  controller/
    auth/
    landing/

  entity/
    expert/
    landing/
    support/
```

## BCE Rule

```text
User -> boundary UI -> controller -> gateway/entity
```

Rules:

- Users interact only with boundary UI components.
- Boundary UI handles clicks, forms, navigation, and visible feedback.
- Boundary UI calls controllers for use cases.
- Boundary UI must not call gateways directly.
- Boundary UI must not import entities directly.
- Controllers coordinate validation and use-case flow.
- Controllers call gateway boundaries for data access.
- Gateway boundaries represent external systems — now live Supabase reads/writes with bundled seed as the offline fallback.
- Entities must not import boundary or controller code.

The rule is enforced by:

```bash
npm run check:bce
```

## Current Routes

```text
/                    landing page
/login               login UI
/register            user registration UI
/expert-application  expert application UI
```

`/login` signs in against the shared project's Supabase Auth and shows the role-based destination.

## Current Data Flow

Landing page:

```text
LandingPage.vue
-> getLandingPage.ts
-> landingGateway.ts
-> seed/landing-page.seed.json
```

Featured experts:

```text
ExpertsSection.vue
-> getFeaturedExperts.ts
-> expertGateway.ts
-> seed/experts.seed.json
```

Expert specialties:

```text
ExpertApplicationPage.vue
-> getExpertSpecialties.ts
-> expertGateway.ts
-> seed/expert-categories.seed.json
```

Testimonials:

```text
TestimonialsSection.vue
-> getTestimonials.ts
-> testimonialGateway.ts
-> seed/testimonials.seed.json
```

Registration:

```text
RegisterPage.vue
-> registerUser.ts
-> authGateway.ts
```

Expert application:

```text
ExpertApplicationPage.vue
-> registerExpert.ts
-> authGateway.ts
```

The expert application validates document file type/size, records document metadata in `expert_verification_documents` via the signup trigger, **and uploads the files** to a private `expert-docs` Storage bucket (owner-write / owner+admin-read); the admin opens them via short-lived signed URLs at `/admin/applications`.

Login:

```text
LoginPage.vue
-> loginUser.ts
-> authGateway.ts
```

Contact:

```text
ContactSection.vue
-> submitContactMessage.ts
-> contactGateway.ts
```

## Database Direction

Use the `../FYP-26-S2-37-app` schema as the source of truth.

Existing app tables to reuse:

- `profiles`
- `expert_profiles`
- `expert_categories`
- `expert_services`
- `expert_reviews`
- `subscriptions`
- `contact_messages`
- `expert_verification_documents`

Landing-specific draft additions:

- `public_testimonials`
- `landing_pricing_plans`
- `landing_media_assets`
- `landing_metric_summary`

Draft SQL files are in:

```text
database/migrations/
```

Final migrations should move into `../FYP-26-S2-37-app`.

## Expert Ranking

Featured experts should be selected automatically, not manually curated.

Recommended score — **IMDb / Bayesian weighted rating** (as shipped; see [algorithms.md](./algorithms.md)):

```text
WR = (v / (v + m)) * R + (m / (v + m)) * C
  R = the expert's rating_avg
  v = the expert's review_count
  m = 10  (prior weight)
  C = mean rating across verified experts
```

Sort by:

```text
score desc      (the WR above, computed in the DB)
review_count desc
client_count desc
```

## Pricing

Pricing is database-backed through `landing_pricing_plans`.

For now:

- `pricing.seed.json` provides temporary gateway data.
- Pricing remains display text only.
- Payment product IDs are out of scope.

## Media

For now:

- Placeholders are acceptable.
- Rendered media dimensions are constrained in CSS.

Later:

- Upload real assets to Supabase Storage.
- Store references in `landing_media_assets`.

## Expert Documents

The expert application form currently asks for:

- one identity document
- at least one certification document
- up to four certification documents

Accepted file types:

- PDF
- JPG
- PNG
- WebP

Each file must be 5 MB or smaller.

Files are uploaded to the private `expert-docs` Supabase Storage bucket and recorded in `expert_verification_documents` (with a `storage_path`); the admin reviews them via signed URLs.

## Verification

Run:

```bash
npm run verify
```

This runs:

```bash
npm run check:bce
npm run build
```

## Limitations

Current limitations are tracked in [limitations.md](./limitations.md).

## Next Work

Implementation steps (all ✅ done except deploy):

1. ✅ Decide frontend-direct Supabase versus backend API access.
2. ✅ Add environment configuration for DB/Auth.
3. ✅ Move draft migrations into `../FYP-26-S2-37-app`.
4. ✅ Connect gateways to the shared local Postgres/Supabase DB.
5. ✅ Real Supabase-backed login (admin session + sign-out; member logins point at the app).
6. ✅ Real Supabase-backed registration.
7. ✅ Expert verification document storage (private `expert-docs` bucket + signed URLs).
8. ✅ Admin editing pages (`/admin` — users, applications, categories, pricing, FAQ, testimonials, feedback, contact).
9. ✅ Browser and DB integration tests.
10. ✅ Production deployment — deployed on Vercel (project `fyp-26-s2-37-wiseworkout`, git-linked, root `web/`, auto-deploys on push to `main`): [fyp-26-s2-37-wiseworkout.vercel.app](https://fyp-26-s2-37-wiseworkout.vercel.app).
