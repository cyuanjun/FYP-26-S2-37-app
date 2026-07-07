# Limitations

This page lists the current limitations of the landing-page repo. These are known and intentionally separated from user-facing UI copy.

## Data Source Limitations

- The landing page currently uses hardcoded seed JSON files under `src/boundary/gateways/seed/`.
- The seed files stand in for future Postgres/Supabase gateway reads.
- Contact form submission currently goes through a placeholder gateway and does not insert into `contact_messages`.
- Registration and expert application currently go through placeholder gateways and do not create real Supabase Auth users.

## Authentication Limitations

- Login UI exists, but real Supabase Auth sessions are not connected yet.
- Logout is not implemented yet.
- Supabase Auth is not connected yet.
- Email verification is not implemented yet.
- Role-based post-login home pages are not implemented yet.
- User registration UI exists, but real account creation is not connected yet.
- Expert application UI exists, but real account/profile creation is not connected yet.

## Expert Verification Limitations

- Expert verification document fields are present on the expert application form.
- Actual file upload/storage is not implemented yet.
- The future implementation should write to the existing app schema table `expert_verification_documents`.
- Current expert application passes document metadata through the placeholder gateway only.
- Accepted document types are PDF, JPG, PNG, and WebP.
- Each document is limited to 5 MB in controller validation.

## Admin Limitations

- Admin login is not implemented yet.
- Admin pages are not implemented yet.
- Admin editing for pricing, testimonials, experts, categories, media, and landing sections is not implemented yet.
- Draft RLS policies assume admins are identified by `profiles.role = 'admin'`.

## Database Limitations

- SQL files in `database/migrations/` are draft add-ons for the shared `FYP-26-S2-37-app` database.
- They have not been applied to a live local Postgres or Supabase instance from this repo.
- Final migrations should live in `../FYP-26-S2-37-app` because that project owns the shared database schema.
- RLS policies are drafted but not tested against a connected Supabase project.
- `expert_profiles.rating_avg` and `review_count` still need an aggregate synchronization strategy in the app DB.
- `expert_profiles.specialties` is a `text[]`; Postgres cannot enforce foreign keys inside the array, so validation must be handled in controller/gateway logic unless the app schema changes to a join table.

## Media Limitations

- Current media uses placeholders.
- Real media upload/storage is not connected yet.
- Final media should use Supabase Storage with database references in `landing_media_assets`.
- Rendered image sizes are constrained in CSS, but upload validation is not implemented yet.

## Testing Limitations

- Current automated checks cover BCE imports and production build only.
- Browser automation tests are not implemented.
- DB integration tests are not implemented.
- RLS tests are not implemented.
- Supabase Auth tests are not implemented.

## Payment/Pricing Limitations

- Pricing is display text only.
- Pricing is not connected to a payment provider.
- Future admin editing should use `landing_pricing_plans` as the single source of truth.
