# TODO

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

### Expert Verification Document Storage

Connect expert verification document upload to storage and the shared app schema.

Current UI behavior:

- One identity document is required.
- At least one certification document is required.
- Accepted file types: PDF, JPG, PNG, WebP.
- Max file size: 5 MB each.
- File metadata is currently passed through the placeholder gateway.

Future implementation:

- Upload files to Supabase Storage.
- Create rows in `expert_verification_documents`.
- Store file references or storage paths according to the app schema.
