# TODO

> **Updated 11 Jul 2026:** the site now shares the app's Supabase database — live reads (metrics, pricing, testimonials, experts), real Supabase Auth (register / login / expert application), and real `contact_messages` inserts, with the bundled seed as offline fallback. Statements below about placeholder/seed-only gateways are historical; see [limitations.md](./limitations.md) for the current truth.

## Future Auth Work

### Supabase Login Sessions

Connect the existing login UI to Supabase Auth.

Future implementation:

- Sign in with email and password.
- Fetch the related `profiles` row after authentication.
- Block suspended users.
- Route by role:
  - `admin` -> admin home
  - `expert` -> expert home
  - `free` / `premium` -> member home
- Add logout.

### Email Verification

Add email verification for new registrations.

Likely approach:

- Send an OTP or email verification code after registration.
- Require the user to verify the code before full account access.
- Store verification state through Supabase Auth or a related profile/auth metadata field.
- Apply the same flow to user registration and expert registration.

Notes:

- This is not implemented yet.
- Registration UI currently collects the fields needed for account creation, but does not verify email ownership.
- Final implementation should decide whether to use Supabase built-in email confirmation or a custom OTP flow.

### Expert Verification Document Storage — ✅ DONE

Expert verification document upload is connected to Storage and the shared app schema.

Behavior:

- One identity document is required.
- At least one certification document is required.
- Accepted file types: PDF, JPG, PNG, WebP.
- Max file size: 5 MB each.
- Files are **uploaded** to a private `expert-docs` Storage bucket (owner-write / owner+admin-read), and `expert_verification_documents` rows record the `storage_path`.
- The admin opens each document via a short-lived **signed URL** at `/admin/applications` (migration `20260713090000_expert_docs_storage.sql`).
