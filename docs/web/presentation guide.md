# Presentation Guide

> **Updated 11 Jul 2026:** the site now shares the app's Supabase database — live reads (metrics, pricing, testimonials, experts), real Supabase Auth (register / login / expert application), and real `contact_messages` inserts, with the bundled seed as offline fallback. Statements below about placeholder/seed-only gateways are historical; see [limitations.md](./limitations.md) for the current truth.

## One-Sentence Summary

This project recreates the existing Wise Workout landing page frontend while reorganizing the code using BCE: users interact only with boundary UI, boundary UI calls controllers, and controllers coordinate entities/gateways.

## What To Show First

Open the app:

```text
http://127.0.0.1:5173/
```

Say:

> The visual page is based on the existing `fyp` landing page. The difference is the internal structure: this version follows BCE so future database, auth, and admin features can be added cleanly.

## BCE Structure

```text
src/
  boundary/
    ui/          user-facing Vue components
    gateways/    database/API/media access boundary

  controller/
    landing/     use-case functions for the landing page

  entity/
    landing/     domain concepts
    expert/
    support/
```

## Main Rule

```text
User -> Boundary UI -> Controller -> Entity/Gateway
```

Important:

- The user only interacts with boundary UI components.
- UI components do not query the database directly.
- UI components do not import entities directly.
- Controllers coordinate the use case.
- Gateways are the only place that talks to Postgres/Supabase.

## Example Flow: Contact Form

```text
Visitor fills contact form
-> ContactSection.vue handles the submit event
-> submitContactMessage.ts validates/coordinatess the action
-> contactGateway.ts inserts into the shared contact_messages table
```

Current file path:

```text
src/boundary/ui/landing/components/ContactSection.vue
src/controller/landing/submitContactMessage.ts
src/boundary/gateways/contactGateway.ts
```

## Example Flow: Featured Experts

```text
ExpertsSection.vue
-> getFeaturedExperts.ts
-> expertGateway.ts
-> experts.seed.json for now
```

Later, `expertGateway.ts` will query the shared app database and rank verified experts using:

```text
rating_avg * ln(review_count + 1)
```

This avoids manually selecting featured experts.

## Why There Is Seed Data

The first build uses seed JSON files instead of a live database so the page can be presented and visually checked before database integration.

Seed files:

```text
src/boundary/gateways/seed/landing-page.seed.json
src/boundary/gateways/seed/experts.seed.json
src/boundary/gateways/seed/testimonials.seed.json
src/boundary/gateways/seed/metrics.seed.json
src/boundary/gateways/seed/pricing.seed.json
src/boundary/gateways/seed/expert-categories.seed.json
```

Presentation wording:

> These seed files are now the offline fallback behind the live Supabase reads. Because the UI talks to controllers and controllers talk to gateways, swapping seed reads for Supabase reads required no UI changes — which is exactly the BCE payoff.

## Example Flow: Expert Specialties

```text
ExpertApplicationPage.vue
-> getExpertSpecialties.ts
-> expertGateway.ts
-> expert-categories.seed.json for now
```

Later, `expertGateway.ts` should read active `expert_categories` rows from the shared app database.

## Database Story

Use the app schema as the source of truth:

```text
../FYP-26-S2-37-app
```

Schema changes/gaps are tracked in:

```text
docs/database changes.md
```

Important additions planned:

- `public_testimonials`
- `landing_pricing_plans`
- `landing_media_assets`
- `landing_metric_summary`

## Current Limitations

Current limitations are tracked in:

```text
docs/limitations.md
```

Short version:

- Login, registration, and expert application run against real Supabase Auth on the shared database.
- The site keeps no persistent session (accounts are for the app); logout UI is not implemented.
- Expert verification documents are metadata-only — the file blobs are not uploaded to Storage.
- Gateway data is currently seed-backed.
- Admin editing pages are not implemented yet.
- Real media upload/storage is not connected yet.

## Build Check

Use this to prove the project compiles:

```bash
npm run build
```

Current status:

```text
Build passes.
```

Use this to prove the BCE dependency rule is checked:

```bash
npm run check:bce
```

Current status:

```text
BCE dependency check passes.
```

## Simple Presentation Script

1. Show the landing page.
2. Explain that it visually matches the old page.
3. Show `src/boundary/ui/landing/LandingPage.vue`.
4. Show that it calls `getLandingPage()`, not the database.
5. Show `src/controller/landing/getLandingPage.ts`.
6. Show `src/boundary/gateways/landingGateway.ts`.
7. Explain that seed data is temporary and will be replaced by Supabase queries.
8. Show `docs/database changes.md` to prove database gaps are tracked.
9. Show `docs/limitations.md` to clearly separate known limitations from completed work.

For a shorter marking-focused checklist, use:

```text
docs/demo checklist.md
```

## Key Point To Emphasize

The landing page and registration forms are intentionally seed/placeholder-backed now, but the BCE boundaries are already in place. That means future login, admin editing, testimonials, pricing, expert ranking, and database integration can be added without making Vue components responsible for database logic.
