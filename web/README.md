# Wise Workout Landing Page

This folder is the Wise Workout marketing website (Vue 3 + Vite + TypeScript), built with the same BCE-oriented structure as the Flutter app in `../app/`.

The code is organized so user-facing UI calls controllers, and controllers call gateway boundaries. The current data source is explicit hardcoded seed data. Later, the gateway layer can be swapped to the shared Postgres/Supabase database in `../app/supabase/`. Its docs live in [../docs/web/](../docs/web/).

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
- Seed-backed gateway data.
- Draft database migrations for shared app DB add-ons.
- BCE dependency checker.
- Test, presentation, and demo documentation.

Not yet connected:

- Live Postgres/Supabase reads and writes.
- Supabase Auth.
- Real login/logout sessions.
- Admin editing pages.
- Real uploaded media.

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

Hardcoded demo data is stored under:

```text
src/boundary/gateways/seed/
```

These files are intentionally grouped as temporary gateway data sources. They are not the final database source of truth.

Current seed data includes landing content, pricing, metrics, testimonials, experts, and expert categories.

## Database Drafts

Draft database add-ons are stored in:

```text
database/migrations/
```

They are intended to be added after the existing `../app/supabase/migrations/` migrations.

Main planned additions:

- `public_testimonials`
- `landing_pricing_plans`
- `landing_media_assets`
- `landing_metric_summary`

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
