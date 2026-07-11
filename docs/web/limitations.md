# Limitations

This page lists the current limitations of the landing-page repo. These are known and intentionally separated from user-facing UI copy.

## Data Source Limitations

*(Updated 11 Jul 2026 — the site now shares the app's Supabase database; see `app/supabase/migrations/20260711090000_landing_site.sql`.)*

- Live reads: metrics (`landing_metric_summary()`), pricing (`landing_pricing_plans`), testimonials (`public_testimonials`), featured experts (`landing_featured_experts()`), expert categories. Page copy/structure and media placeholders stay in the bundled seed JSON.
- Growth percentages on the statistics section still come from the seed — the database has no month-over-month history to derive them from.
- Every live read falls back to the bundled seed when the database is unreachable (offline demo safety).
- Contact form inserts into the shared `contact_messages` table (anon insert is by design; admin triages on #28.1).

## Authentication Limitations

- Registration, login, and expert application use real Supabase Auth (`signUp` / `signInWithPassword`) against the shared project; `handle_new_user()` mirrors profile fields and creates the pending expert profile + document metadata.
- The hosted project has email confirmation enabled — a hosted signup must confirm via email before logging in (the local stack auto-confirms). The hosted mailer also rejects non-deliverable domains (e.g. `.test` addresses).
- **Email rate limit (Supabase free plan):** with the Site URL / Redirect URLs set, confirmation links resolve correctly and the register → verify → login flow works end to end. But the built-in shared mailer caps confirmation/verification emails at a low rate **project-wide (observed as a small daily allowance)**, so rapid signups or repeated "Resend verification email" taps return an `email rate limit exceeded` error. This is a plan constraint, not a code bug. Workarounds: for test/demo accounts, seed them with the SQL recipe in [app/supabase/README.md](../../app/supabase/README.md#creating-a-loginonboarding-test-account) — it sets `email_confirmed_at` directly, so **no email is sent and the quota is untouched**; to raise the live-signup limit, configure a custom SMTP provider (Authentication → Emails → SMTP) or upgrade the plan. Relevant to the register flow and the login verify-email resend button.
- Member logins now keep a Supabase session (like admins): after login they land on a role-based page (`/download` for members, `/expert` for experts/applicants). The landing page and these pages share one auth-aware header — signed in, the login/register buttons are replaced by a **Download** button (labelled "My application" for a pending/rejected applicant, since they can't download yet) plus a logout button.
- Member logout is implemented (header logout button ends the session and returns to the landing page). The post-login pages are still thin — download-app placeholders / expert-approval status — because the real product lives in the app.

## Expert Verification Limitations

- Expert applications now create the pending `expert_profiles` row and `expert_verification_documents` metadata rows via the signup trigger; role stays `free` until an admin approves (US06 approval flow is the admin portal's job).
- Document **files are uploaded to a private Storage bucket** (`expert-docs`, owner-write / owner+admin-read) and the admin opens them via short-lived signed URLs on `/admin/applications`. Upload needs the new account to have a session, so it runs on the local/demo stack (email auto-confirmed); on a project with email confirmation the application still succeeds but documents stay name-only until a session exists.
- Accepted document types are PDF, JPG, PNG, and WebP; each document is limited to 5 MB in controller validation.

## Admin Limitations

*(Updated 12 Jul 2026 — the admin portal is live at `/admin`.)*

- Admin login, logout, and role-guarded routes work against shared Supabase Auth (`profiles.role = 'admin'`, enforced by `is_admin()` RLS policies — the same identification the draft policies assumed).
- Built: overview, user management (suspend / tier switch), expert-application review, service-listing archive/restore, categories, pricing display copy, testimonial moderation, feedback triage, contact inbox.
- Not built: editing landing hero/feature copy from the portal (FAQ, pricing, testimonials, categories ARE editable; hero/feature media are real app captures swapped via `web/public/uploads/`); password-reset page inside the portal (the shared pre-auth reset flow serves admins).
- Contact replies open the admin's own mail client pre-filled (`Reply via email`) and the response is recorded on the message — there is no outbound mailer.
- Featured experts and testimonials are ranked by documented algorithms (see [algorithms.md](./algorithms.md)), logged to the console at runtime — not manually selected.

## Database Limitations

- The drafts in `database/migrations/` were finalised as `app/supabase/migrations/20260711090000_landing_site.sql` and applied to both the local stack and the hosted project (the drafts remain for provenance).
- RLS/policies are live and were smoke-tested as the `anon` role (approved testimonials, active pricing/categories, and the two landing functions are the whole anon read surface).
- `expert_profiles.rating_avg` / `review_count` are kept consistent by the app's `submit_expert_review` RPC (no separate sync needed).
- `expert_profiles.specialties` is a `text[]`; Postgres cannot enforce foreign keys inside the array, so validation stays in controller/gateway logic.

## Media Limitations

- Current media uses placeholders.
- Real media upload/storage is not connected yet.
- Final media should use Supabase Storage with database references in `landing_media_assets`.
- Rendered image sizes are constrained in CSS, but upload validation is not implemented yet.

## Testing Limitations

- Automated checks cover BCE imports, the production build, and **Vitest controller unit tests** (25 positive/negative cases over the auth + landing controllers, gateways faked in-memory). There is still no committed browser/DB/RLS test suite — those flows are verified manually (below).
- The 11 Jul integration was verified manually end-to-end: headless-browser runs of register/login/expert-application/contact against the local stack with row-level DB checks, plus a hosted signup-trigger test (rows verified, then removed).

## Payment/Pricing Limitations

- Pricing is display text only.
- Pricing is not connected to a payment provider.
- Future admin editing should use `landing_pricing_plans` as the single source of truth.
