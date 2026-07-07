# Demo Checklist

## Before The Demo

Run:

```bash
npm run verify
```

Expected:

```text
BCE dependency check passed.
build completed successfully.
```

Start the app:

```bash
npm run dev -- --host 127.0.0.1
```

Open:

```text
http://127.0.0.1:5173/
```

## Demo Flow

### 1. Show The Landing Page

Say:

> This landing page recreates the frontend from the original `fyp` prototype, but the internal structure has been reorganized around BCE.

Show:

- Header
- Hero
- Features
- Statistics
- Featured experts
- Pricing
- Testimonials
- FAQ
- Contact
- Login page
- Register page
- Expert application page

### 2. Show The BCE Folders

Open:

```text
src/boundary/
src/controller/
src/entity/
```

Say:

> Boundary UI handles user interaction, controllers coordinate use cases, and entities describe domain concepts. Gateways are also boundaries because they represent external systems like the future database.

### 3. Show User -> Boundary -> Controller

Open:

```text
src/boundary/ui/landing/LandingPage.vue
```

Point to:

```ts
getLandingPage()
```

Then open:

```text
src/controller/landing/getLandingPage.ts
```

Say:

> The Vue boundary does not read seed data or the database directly. It calls a controller.

### 4. Show Controller -> Gateway

Open:

```text
src/controller/landing/getLandingPage.ts
src/boundary/gateways/landingGateway.ts
```

Say:

> The controller calls a gateway boundary. Right now that gateway reads hardcoded seed data. Later, this is where the Supabase/Postgres query will go.

### 5. Show Seed Data Is Explicit

Open:

```text
src/boundary/gateways/seed/README.md
src/boundary/gateways/seed/
```

Say:

> These files are intentionally grouped as seed data, so it is clear they are temporary demo data and not the real database.

### 6. Show BCE Enforcement

Run:

```bash
npm run check:bce
```

Say:

> The architecture rule is not only documented. This script checks that boundary UI does not import entities or gateways directly.

Optional file to show:

```text
scripts/check-bce.mjs
```

### 7. Show Database Add-On Plan

Open:

```text
database/README.md
database/migrations/
docs/database changes.md
```

Say:

> These migrations are add-ons to the existing app database. They do not replace the app schema. They add landing-specific tables for testimonials, pricing, media references, and public-safe metrics.

### 8. Show Test Plan

Open:

```text
docs/test plan.md
```

Say:

> Current tests focus on build correctness, BCE dependency rules, and manual positive/negative UI checks. Database and auth tests are deferred until the shared DB is connected.

### 9. Show Expert Application

Open:

```text
http://127.0.0.1:5173/expert-application
```

Say:

> The expert application asks for account details, expert profile information, active specialties from the gateway seed, and verification documents. The documents are validated now, while real storage is documented as a limitation.

### 10. Show Limitations

Open:

```text
docs/limitations.md
```

Say:

> Known limitations are documented separately from the UI. The app screens use product-facing copy, while this document explains what is placeholder-backed or deferred.

## Key Lines To Say

```text
User -> boundary UI -> controller -> gateway/entity
```

```text
Boundary UI does not touch the database directly.
```

```text
Seed data is temporary and isolated under the gateway boundary.
```

```text
Database changes are planned as add-ons to the existing app schema.
```

```text
Current limitations are documented in docs/limitations.md.
```

## If Asked What Is Not Done Yet

Answer:

> Admin editing, real media uploads, live Supabase reads, real login sessions, and logout are not implemented yet. Login, user registration, and expert application forms are present, but they submit to placeholder gateways until Supabase Auth and the shared database are connected. Expert document files are collected and validated, but real storage is not connected yet.

## Quick Recovery

If the dev server is already running, use:

```text
http://127.0.0.1:5173/
```

If the page looks stale, refresh the browser.

If asked to prove the code is valid, run:

```bash
npm run verify
```
