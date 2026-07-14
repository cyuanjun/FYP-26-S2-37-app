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
- Login UI at `/login`, with a show/hide password toggle and a verify-your-email
  prompt (with a resend button) when an unconfirmed account tries to sign in.
- Registration shows a "check your email" popup on success, then routes to `/login`;
  both password fields have a show/hide toggle.
- Post-login pages: members land on `/download` (app-download placeholders), experts
  and applicants on `/expert` (approval status, or download once approved). The
  landing page and these pages share one auth-aware header — signed in, the
  login/register buttons become a profile avatar + a **Download** button (labelled
  "My application" for a pending/rejected applicant) + a logout button.
- Shared-database gateways (live Supabase reads with bundled-seed fallback).
- Real Supabase Auth for registration, login, and expert applications; member and
  admin logins both keep a persistent session with sign-out.
- Contact form inserts into the shared `contact_messages` table.
- **Admin portal at `/admin`** (role-guarded): overview, user management
  (suspend / tier switch), expert-application review, service-listing
  moderation, categories, pricing, FAQ editor, testimonials, feedback, and
  a contact inbox with mailto replies.
  Demo account: `admin@wiseworkout.test` / `Password123!`.
- Landing sections use real app media (hero screen-capture video + tab
  screenshots in a horizontal feature rail), a live SVG activity chart, and
  algorithm-ranked experts/testimonials (see `../docs/web/algorithms.md`).
- BCE dependency checker.
- Test, presentation, and demo documentation.
- **Deployed on Vercel** (see Deployment below).

Not yet built:

- Real App Store / Google Play download links (the `/download` and `/expert` pages show disabled placeholder buttons).
- Admin editing for landing **feature-card copy** specifically (FAQ, pricing, testimonials, categories, and contact/feedback moderation are already editable in `/admin`).

See [docs/limitations.md](../docs/web/limitations.md) for the full limitation list.

## Deployment

Live at **[fyp-26-s2-37-wiseworkout.vercel.app](https://fyp-26-s2-37-wiseworkout.vercel.app)**.

- **Host:** Vercel, project `fyp-26-s2-37-wiseworkout`, **git-linked** to `cyuanjun/FYP-26-S2-37-app` with **Root Directory `web/`** and production branch `main`. Every push to `main` auto-builds and deploys; PRs get preview URLs.
- **Config:** [`vercel.json`](vercel.json) — Vite framework, build `npm run build`, output `dist`, and an SPA rewrite (`/(.*) → /index.html`) so deep links like `/login` and `/admin` resolve on refresh.
- **Backend:** runs against the **shared hosted Supabase** (URL + publishable key default in `src/boundary/gateways/supabaseClient.ts`; no env vars needed). `web/.env.local-stack.disabled` is the old local-stack config, kept disabled.
- **Manual deploy** (optional, needs a Vercel token): `cd web && npx vercel deploy --prod`.

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
npm run check:bce   # BCE dependency rules
npm run test        # Vitest controller unit tests (positive + negative)
npm run build       # type-check + production build
```

`npm run test` (Vitest) runs 25 positive/negative unit tests over the controllers with the gateways faked in-memory. See [../docs/web/test plan.md](../docs/web/test%20plan.md) for the case list.

## BCE Structure

```text
src/
  boundary/
    ui/          Vue components that users interact with
    gateways/    live Supabase reads/writes with seed fallback

  controller/    use-case coordination + validation + view-models
```

The marketing/admin site is thin CRUD with no domain rules, so the Entity role
collapses into the controller's view-models (the shaped types components consume);
there is no separate `entity/` folder. The app (`app/lib/entities/`) keeps a real
Entity layer because it has genuine domain logic (XP, streak, training effect).

Main rule:

```text
User -> boundary UI -> controller -> gateway
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
