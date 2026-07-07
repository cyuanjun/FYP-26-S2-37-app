# Database Changes

This file logs changes needed for the landing page when compared against the `../FYP-26-S2-37-app` Supabase schema.

The app schema is the source of truth. If the old `../fyp` prototype differs from the app schema, adapt the landing page to the app schema and record the difference here.

## Existing App Tables To Reuse

- `profiles`
- `expert_profiles`
- `expert_categories`
- `expert_services`
- `expert_reviews`
- `subscriptions`
- `contact_messages`

## Naming / Schema Alignment Notes

### Roles

Use the app schema roles:

- `free`
- `premium`
- `expert`
- `admin`

Do not use the old prototype role name `user` for new landing-page logic.

## Local Postgres To Supabase Strategy

Yes, local Postgres is a good development path before moving to Supabase, as long as the project uses Supabase-compatible SQL from the start.

Rules:

- Use one shared database design.
- Store schema changes as SQL migrations.
- Keep migrations compatible with Supabase Postgres.
- Avoid SQLite-only behavior or local-only schema shortcuts.
- Keep seed data in SQL or scripts that can be rerun against both local Postgres and Supabase.
- Treat Supabase Auth, Storage, and RLS as part of the final schema design even if local development temporarily stubs some behavior.

Migration path:

1. Run the same migrations against local Postgres during development.
2. Seed local Postgres with demo data.
3. When ready, apply the same migrations to Supabase.
4. Upload or seed required media into Supabase Storage.
5. Run the same seed data, adjusted only for environment-specific IDs or file paths.

Important:

- These schema changes affect the single shared app database.
- Final migrations should live with the app database project, `../FYP-26-S2-37-app`, because that is the database source of truth.

### Experts

Use:

- `profiles` for public identity fields such as name, username, avatar, and bio.
- `expert_profiles` for title, coaching years, about text, credentials, specialties, rating aggregate, review count, client count, and verification status.
- `expert_categories` for specialty labels and descriptions.
- `expert_reviews` as the source of truth for expert rating data.

Current repo note:

- Expert specialties are currently loaded from `src/boundary/gateways/seed/expert-categories.seed.json`.
- Later, the same gateway should read active rows from `expert_categories`.

## Required Additions

Draft SQL files for these additions are stored in:

```text
database/migrations/
```

These are planning drafts. Final migrations should live in `../FYP-26-S2-37-app` before real database integration.

### 1. Public Testimonials

Reason:

Public testimonials are different from `expert_reviews`. Expert reviews are tied to expert-service engagements. Public testimonials are general landing-page social proof submitted by registered users and displayed publicly only after approval.

Proposed schema:

```sql
create type public_testimonial_status as enum ('pending', 'approved', 'rejected');

create table public_testimonials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles (id) on delete cascade,
  display_name text not null,
  user_category text not null,
  rating int not null check (rating between 1 and 5),
  body text not null,
  status public_testimonial_status not null default 'pending',
  admin_reply text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index uq_public_testimonials_user on public_testimonials (user_id);
create index idx_public_testimonials_status on public_testimonials (status);
create index idx_public_testimonials_rating_count on public_testimonials (rating desc);
```

Rules:

- Only registered users can submit testimonials.
- Each registered user can submit only one public testimonial.
- New testimonials start as `pending`.
- Only approved testimonials can appear on the public landing page.
- Admins approve or reject testimonials later.

### 2. Landing Pricing Plans

Reason:

Pricing should be editable by admins and should not remain hardcoded in the frontend. For now, pricing is display text only and does not need payment product IDs.

`landing_pricing_plans` is the single source of truth for displayed pricing text. The frontend should read pricing from this table instead of keeping a separate hardcoded copy.

Proposed schema:

```sql
create table landing_pricing_plans (
  id uuid primary key default gen_random_uuid(),
  plan_key text not null unique,
  plan_name text not null,
  price_label text not null,
  description text not null,
  button_text text not null,
  button_url text not null,
  features text[] not null default '{}',
  display_order int not null default 0,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create index idx_landing_pricing_active_order
  on landing_pricing_plans (is_active, display_order);
```

Rules:

- Public landing page reads active pricing plans.
- Admins can update plan labels, prices, descriptions, feature lists, display order, and active status.
- Keep this as display content only for now.
- Do not duplicate editable pricing text in static frontend files.

### 3. Landing Media Assets

Reason:

Real media is expected on the landing page. Placeholder strings such as `hero_video_url` are not enough.

For the current local/demo pass, placeholders are acceptable. Before final delivery, replace placeholders with Supabase Storage-backed media references.

Proposed schema:

```sql
create table landing_media_assets (
  id uuid primary key default gen_random_uuid(),
  asset_key text not null unique,
  bucket text not null,
  storage_path text not null,
  alt_text text,
  media_type text not null check (media_type in ('image', 'video')),
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);
```

Rules:

- Store files in Supabase Storage.
- Store database references in `landing_media_assets`.
- Use stable `asset_key` values such as `hero_media`, `feature_recording`, and `feature_ai_summary`.
- Charts are generated automatically and do not need stored chart images.
- Restrict uploaded image sizes before storing or accepting them.
- Recommended image limits:
  - Logo/avatar-style images: max 512 x 512 px, max 500 KB.
  - Feature/expert card images: max 1200 x 900 px, max 1 MB.
  - Wide landing images: max 1600 x 900 px, max 1.5 MB.
  - Hero video/image media: keep compressed; avoid original camera exports.
- The frontend also constrains rendered media dimensions so large files cannot stretch the page layout.

### 4. Landing Metric Summary View

Reason:

Charts and figures should be derived from database counts, not manually stored.

Proposed view:

```sql
create view landing_metric_summary as
select
  (select count(*) from profiles) as total_users,
  (select count(*) from profiles where role = 'free') as free_users,
  (select count(*) from profiles where role = 'premium') as premium_users,
  (select count(*) from expert_profiles where verification_status = 'verified') as verified_experts,
  (select count(*) from expert_categories where is_active = true) as active_categories,
  (select count(*) from public_testimonials where status = 'approved') as approved_public_testimonials,
  (select coalesce(round(avg(rating)::numeric, 1), 0) from public_testimonials where status = 'approved') as average_public_testimonial_rating,
  (select count(*) from expert_reviews) as expert_review_count,
  (select count(*) from contact_messages where status = 'resolved') as resolved_contact_messages;
```

Rules:

- Only expose public-safe metrics.
- Do not expose pending applications, unresolved contact messages, suspended users, or admin-only counts.
- Charts should be generated in the frontend from the values returned by this view.

### 5. Optional Future Landing Sections

Reason:

The first version can keep most copy static, but admin editing is required later.

Proposed future schema:

```sql
create table landing_sections (
  section_key text primary key,
  content jsonb not null,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);
```

Suggested section keys:

- `hero`
- `features`
- `cta_row`
- `faq`
- `contact`

Rules:

- Do not store brand text, nav links, header actions, or footer links unless requirements change.
- Do not store pricing here if `landing_pricing_plans` exists.

## Required Policies / Access Rules

### Public Landing Reads

Allow anonymous/public reads only for:

- Approved `public_testimonials`.
- Verified `expert_profiles` joined with safe public `profiles` fields.
- Active `expert_categories`.
- Active `landing_pricing_plans`.
- Active `landing_media_assets`.
- Public-safe values from `landing_metric_summary`.

Do not expose:

- Pending/rejected testimonials.
- Contact message contents.
- Suspended users.
- Admin-only counts.
- Expert verification documents.

### Registered Testimonial Submission

Authenticated users can:

- Insert one testimonial for their own `profiles.id`.
- Only insert testimonials with `status = 'pending'`.

Authenticated users cannot:

- Approve/reject testimonials.
- Edit moderation fields.
- Submit testimonials for another user.

### Contact Messages

Anonymous visitors can:

- Insert contact messages.

Anonymous visitors cannot:

- Read, update, or delete contact messages.

Admins can:

- Read, respond to, and resolve contact messages.

### Admin Editing

Admins are identified through:

```text
profiles.role = 'admin'
```

Admins can edit:

- Landing pricing plans.
- Landing media references.
- Future landing sections.
- Testimonial moderation.
- Expert/category visibility where supported.
- Contact message responses/statuses.

## Seed Data Requirement

Seed data is expected for the first version/demo.

Seed:

- Active pricing plans in `landing_pricing_plans`.
- Real landing media records in `landing_media_assets`.
- Verified experts in `profiles` and `expert_profiles`.
- Active expert categories.
- Expert reviews or synchronized expert rating aggregates.
- Approved public testimonials.
- Enough users/reviews/contact rows for generated metrics and charts.

Because seed data is expected, empty expert/testimonial/chart sections are not a blocker for the first demo build. The frontend should still avoid crashing if a seed row is missing.

## Expert Ranking Logic

No manual featured expert table is needed.

Recommended ranking:

```text
verified experts only
recommended_score = rating_avg * ln(review_count + 1)
order by:
  recommended_score desc
  review_count desc
  rating_avg desc
  client_count desc
```

Reason:

This balances rating quality with rating volume. It prevents a 5.0 expert with one review from automatically outranking a 4.8 expert with many reviews.

Optional later rule:

- Require at least 3 reviews once there are enough verified experts.
- Until then, include all verified experts so the section is not empty.

## Auth / Registration Notes

Registration UI exists in this repo, but real Supabase-backed auth/database writes are still future work.

Required later:

- Real user registration through Supabase Auth.
- Real expert registration/application through Supabase Auth and app tables.
- Expert verification document storage.
- User/expert/admin login.
- Role-specific home pages after login.
- Admin editing pages.

Expert registration should eventually create or touch:

- `auth.users`
- `profiles`
- `expert_profiles`
- `expert_verification_documents`

The current expert application UI already asks for identity and certification documents. It validates PDF/JPG/PNG/WebP files up to 5 MB each and passes metadata to the placeholder auth gateway. Real file upload/storage is still future work.

This should remain one controller/use case later, not logic scattered across UI forms.

## Not Required Now

- Admin audit fields such as `updated_by`.
- Contact form CAPTCHA or spam protection.
- Payment product IDs in pricing.
- Manual featured expert curation.
- Stored chart images.

See [limitations.md](./limitations.md) for implementation limitations outside the schema.
