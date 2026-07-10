# Test Plan

> **Updated 11 Jul 2026:** the site now shares the app's Supabase database — live reads (metrics, pricing, testimonials, experts), real Supabase Auth (register / login / expert application), and real `contact_messages` inserts, with the bundled seed as offline fallback. Statements below about placeholder/seed-only gateways are historical; see [limitations.md](./limitations.md) for the current truth.

This project includes a landing-page slice plus user/expert registration UI. Data access is live against the shared Supabase database with bundled-seed fallback. The most important automated tests are architecture checks, build checks, and simple UI behavior checks; DB-backed flows were verified manually end-to-end on 11 Jul 2026 (headless-browser runs with row-level checks, local + hosted).

## Automated Checks

Run:

```bash
npm run verify
```

This runs:

```bash
npm run check:bce
npm run build
```

## Positive Tests

### 1. BCE Dependency Check Passes

Command:

```bash
npm run check:bce
```

Expected:

```text
BCE dependency check passed.
```

Purpose:

Confirms the current code obeys the intended dependency rules.

### 2. Production Build Passes

Command:

```bash
npm run build
```

Expected:

```text
built successfully
```

Purpose:

Confirms TypeScript, Vue templates, and Vite bundling are valid.

### 3. Landing Page Loads

Manual steps:

1. Run `npm run dev`.
2. Open `http://127.0.0.1:5173/`.

Expected:

- Header appears.
- Hero section appears.
- Features, statistics, experts, pricing, testimonials, FAQ, and contact sections appear.
- No visible runtime error.

### 4. Seeded Experts Display

Manual steps:

1. Open the landing page.
2. Scroll to Featured Experts.

Expected:

- Expert cards appear from `experts.seed.json`.
- Cards use initials placeholders for now.
- Experts are auto-ranked by the gateway/controller flow.

### 5. Seeded Testimonials Display

Manual steps:

1. Open the landing page.
2. Scroll to Testimonials.

Expected:

- Approved testimonials appear from `testimonials.seed.json`.
- Rating summary is calculated from approved seed rows.

### 6. Seeded Pricing Displays

Manual steps:

1. Open the landing page.
2. Scroll to Pricing.

Expected:

- Pricing cards appear from `pricing.seed.json`.
- The frontend does not hardcode a separate pricing source.

### 7. Contact Form Positive Flow

Manual steps:

1. Fill name, email, and message.
2. Tick the agreement checkbox.
3. Submit.

Expected:

- Success message appears.
- Form fields reset.

Note:

The gateway inserts into the shared `contact_messages` table (anon insert by design).

### 8. Login Positive Flow

Manual steps:

1. Open `/login`.
2. Enter an email and password.
3. Submit.

Expected:

- Success message appears.
- An **admin** account lands in the `/admin` portal (real session). A **member** account shows its role-based destination (member accounts are for the app, no persistent web session).

Note:

The gateway signs in via Supabase Auth and reads the caller's own `profiles` row.

### 9. User Registration Positive Flow

Manual steps:

1. Open `/register`.
2. Fill all fields with matching passwords.
3. Submit.

Expected:

- Success message appears.
- Form fields reset.

Note:

The gateway signs up via Supabase Auth; the DB trigger mirrors profiles (and expert applications).

### 10. Expert Registration Positive Flow

Manual steps:

1. Open `/expert-application`.
2. Fill account fields.
3. Fill title, years, about, one credential, and one specialty.
4. Upload one identity document.
5. Upload at least one certification document.
6. Submit.

Expected:

- Success message appears.
- Specialty options load from the expert category gateway seed.

Note:

The form requires document files, validates type/size, and **uploads them** to the private `expert-docs` Storage bucket (the admin reviews them via signed URLs).
Accepted files are PDF, JPG, PNG, and WebP up to 5 MB each.

## Negative Tests

### 1. BCE Violation Fails

Temporary manual test:

1. Add a forbidden import in a boundary UI component, for example:

```ts
import type { LandingSection } from "@/entity/landing/LandingSection";
```

2. Run:

```bash
npm run check:bce
```

Expected:

- The command fails.
- It reports that boundary UI must not import entities directly.

Important:

Remove the temporary import after testing.

### 2. Boundary UI Cannot Import Gateway Directly

Temporary manual test:

1. Add this import to a boundary UI component:

```ts
import { readLandingSeed } from "@/boundary/gateways/landingGateway";
```

2. Run:

```bash
npm run check:bce
```

Expected:

- The command fails.
- It reports that boundary UI must call controllers, not gateways directly.

Important:

Remove the temporary import after testing.

### 3. Contact Form Without Agreement

Manual steps:

1. Fill the contact fields.
2. Leave the agreement checkbox unticked.
3. Submit.

Expected:

- Error message appears.
- Form does not submit.

### 4. Contact Form Missing Fields

Manual steps:

1. Leave one or more required contact fields empty.
2. Submit.

Expected:

- Browser validation or controller validation prevents submission.

### 5. Pending Testimonials Are Hidden

Temporary manual test:

1. Change one row in `testimonials.seed.json` to:

```json
"status": "pending"
```

2. Reload the landing page.

Expected:

- That testimonial does not appear.

Important:

Restore the seed file after testing.

### 6. Missing Expert Images Do Not Break Layout

Current expected state:

- Expert `avatar_url` values are `null`.

Expected:

- Initials placeholders appear.
- Card sizes remain stable.

### 7. Registration Password Mismatch

Manual steps:

1. Open `/register`.
2. Enter different password and confirm-password values.
3. Submit.

Expected:

- Error message appears.
- The registration gateway is not called (validation fails first).

### 8. Login Missing Password

Manual steps:

1. Open `/login`.
2. Enter an email and leave password empty.
3. Submit.

Expected:

- Browser validation or controller validation prevents submission.

### 9. Expert Application Missing Specialty

Manual steps:

1. Open `/expert-application`.
2. Fill required fields but do not select a specialty.
3. Submit.

Expected:

- Error message appears.
- The expert-application gateway is not called (validation fails first).

### 10. Expert Application Missing Documents

Manual steps:

1. Open `/expert-application`.
2. Fill required fields but do not upload identity/certification documents.
3. Submit.

Expected:

- Error message appears.
- The expert-application gateway is not called (validation fails first).

## Deferred Integration Tests

- RLS policy tests.
- Public read policy tests.
- Admin write policy tests.
- Real contact-message insert tests.
- Registered-user testimonial submission tests.
- Supabase Storage media tests.
- Real Supabase Auth/login/register tests.
  - Login and registration UI exist now, but real Supabase Auth integration tests are deferred.

These need the shared local Postgres/Supabase database connected first.

See [limitations.md](./limitations.md) for the current limitation list.
