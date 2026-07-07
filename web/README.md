# Wise Workout Landing Page

This folder is the Wise Workout marketing website (Vue 3 + Vite + TypeScript), built with the same BCE-oriented structure as the Flutter app in `../app/`.

The code is organized so user-facing UI calls controllers, and controllers call gateway boundaries. The site shares the app's Supabase database (`../app/supabase/`): metrics, pricing, testimonials, and featured experts are live reads; registration, login, expert applications, and the contact form write real rows. Bundled seed JSON remains as the offline fallback. Its docs live in [../docs/web/](../docs/web/).

## Current Status

Implemented:

- Vue 3 + Vite + TypeScript landing page.
- BCE folder structure.
- Public landing sections:
  - hero
  - features
  - statistics
  - featured experts
  - pricing
  - testimonials
  - CTA row
  - FAQ
  - contact
- User registration UI at `/register`.
- Expert application UI at `/expert-application`.
  - Collects account/profile fields.
  - Requires one identity document and at least one certification document.
  - Accepts PDF, JPG, PNG, and WebP files up to 5 MB each.
- Login UI at `/login`.
- Shared-database gateways (live Supabase reads with bundled-seed fallback).
- Real Supabase Auth for registration, login, and expert applications.
- Contact form inserts into the shared `contact_messages` table.
- BCE dependency checker.
- Test, presentation, and demo documentation.

Not yet built:

- Deployment (the site runs locally).
- Persistent login sessions / logout on the site (login validates and points at the app).
- Admin editing pages.
- Real uploaded media (verification documents are metadata-only).

See [docs/limitations.md](../docs/web/limitations.md) for the full limitation list.

## Run Locally

Install dependencies:

```bash
npm install
```

Start the dev server:

```bash
npm run dev -- --host 127.0.0.1
```

The site talks to the hosted Supabase project by default (publishable key — RLS-gated).
To use the local stack instead (`cd ../app && supabase start`), create `.env.local`:

```bash
VITE_SUPABASE_URL=http://127.0.0.1:55321
VITE_SUPABASE_ANON_KEY=<local anon key from `supabase status`>
```

Open:

```text
http://127.0.0.1:5173/
```

## Verify

Run:

```bash
npm run verify
```

This runs:

```bash
npm run check:bce
npm run build
```

## BCE Structure

```text
src/
  boundary/
    ui/          Vue components that users interact with
    gateways/    seed data now, future DB/API/Supabase access

  controller/    use-case coordination and validation

  entity/        domain concepts
```

Main rule:

```text
User -> boundary UI -> controller -> gateway/entity
```

The code enforces this with:

```bash
npm run check:bce
```

## Seed Data

Bundled demo data is stored under:

```text
src/boundary/gateways/seed/
```

The seed files now serve two purposes: page structure/copy that stays client-side (section order, labels, growth percentages), and the **offline fallback** every live gateway returns when the database is unreachable.

## Database

The landing add-ons are **live** in the shared schema — finalised from the drafts in
`database/migrations/` (kept for provenance) as
`../app/supabase/migrations/20260711090000_landing_site.sql`:

- `public_testimonials` (admin-moderated; anon reads approved rows)
- `landing_pricing_plans` (display copy; $9.99/mo premium)
- `landing_media_assets` (Storage references; not yet used)
- `landing_metric_summary()` + `landing_featured_experts()` (the anon read functions)
- signup trigger v3 (profile mirroring + expert applications)

See [docs/database changes.md](<../docs/web/database changes.md>) and [database/README.md](database/README.md).

## Useful Docs

- [docs/README.md](../docs/web/README.md)
- [docs/plan.md](../docs/web/plan.md)
- [docs/limitations.md](../docs/web/limitations.md)
- [docs/database changes.md](<../docs/web/database changes.md>)
- [docs/test plan.md](<../docs/web/test plan.md>)
- [docs/demo checklist.md](<../docs/web/demo checklist.md>)
- [docs/presentation guide.md](<../docs/web/presentation guide.md>)
- [docs/todo.md](../docs/web/todo.md)
