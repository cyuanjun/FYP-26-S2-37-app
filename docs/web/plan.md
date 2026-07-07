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

The expert application validates document file type/size and records document metadata in `expert_verification_documents` via the signup trigger (files themselves are not uploaded — see [limitations.md](./limitations.md)).

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

Recommended score:

```text
rating_avg * ln(review_count + 1)
```

Sort by:

```text
recommended_score desc
review_count desc
rating_avg desc
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

Later, files should be uploaded to Supabase Storage and recorded in `expert_verification_documents`.

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

Recommended next implementation steps:

1. Decide frontend-direct Supabase versus backend API access.
2. Add environment configuration for DB/Auth.
3. Move draft migrations into `../FYP-26-S2-37-app`.
4. Connect gateways to the shared local Postgres/Supabase DB.
5. Add real Supabase-backed login/logout.
6. Add real Supabase-backed registration.
7. Add expert verification document storage.
8. Add admin editing pages.
9. Add browser and DB integration tests.
