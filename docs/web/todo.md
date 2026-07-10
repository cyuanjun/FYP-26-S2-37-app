# TODO

> **Updated 11 Jul 2026:** the site now shares the app's Supabase database — live reads (metrics, pricing, testimonials, experts), real Supabase Auth (register / login / expert application), and real `contact_messages` inserts, with the bundled seed as offline fallback. Statements below about placeholder/seed-only gateways are historical; see [limitations.md](./limitations.md) for the current truth.

## Future Auth Work

### Supabase Login Sessions — ✅ DONE

Login uses real Supabase Auth and keeps a persistent session (members and admins alike).

Behavior:

- Signs in with email and password (login page has a show/hide password toggle).
- Fetches the related `profiles` row after authentication and blocks suspended users.
- Routes by role + expert status:
  - `admin` -> `/admin`
  - `expert` / anyone with an expert application -> `/expert` (status / download)
  - `free` / `premium` -> `/download`
- Logout is implemented (header logout button ends the session and returns to the landing page).
- The landing page and post-login pages share one auth-aware header: signed in, login/register
  become a profile avatar + a Download button (`My application` for a pending/rejected applicant)
  + logout.

### Email Verification — ✅ DONE

Uses Supabase built-in email confirmation (not a custom OTP).

Behavior:

- Registration shows a "check your email" popup on success, then routes to `/login`.
- `signUp` sets `emailRedirectTo = <origin>/login`, so the confirmation link returns to the
  site's login page (needs the deployed URL in Supabase's Site URL / Redirect allow-list).
- Logging in before confirming shows a verify-your-email prompt with a resend button
  (the gateway tells "email not confirmed" apart from bad credentials).

Notes:

- Applies to both member registration and expert application.
- Free-plan mailer rate limit applies — see [limitations.md](./limitations.md).

### Expert Verification Document Storage — ✅ DONE

Expert verification document upload is connected to Storage and the shared app schema.

Behavior:

- One identity document is required.
- At least one certification document is required.
- Accepted file types: PDF, JPG, PNG, WebP.
- Max file size: 5 MB each.
- Files are **uploaded** to a private `expert-docs` Storage bucket (owner-write / owner+admin-read), and `expert_verification_documents` rows record the `storage_path`.
- The admin opens each document via a short-lived **signed URL** at `/admin/applications` (migration `20260713090000_expert_docs_storage.sql`).
