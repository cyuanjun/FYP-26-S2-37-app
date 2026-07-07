-- Landing page public testimonials.
-- Draft migration for the shared FYP-26-S2-37-app Supabase/Postgres database.
--
-- Public means "displayed on the public landing page after approval".
-- Submission still requires a registered user.

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

create unique index uq_public_testimonials_user
  on public_testimonials (user_id);

create index idx_public_testimonials_status
  on public_testimonials (status);

create index idx_public_testimonials_rating_count
  on public_testimonials (rating desc);

alter table public_testimonials enable row level security;

-- Public landing page can read approved testimonials only.
create policy "Public can read approved public testimonials"
  on public_testimonials
  for select
  using (status = 'approved');

-- Registered users can submit exactly their own pending testimonial.
create policy "Authenticated users can submit own pending testimonial"
  on public_testimonials
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and status = 'pending'
  );

-- Admins can moderate public testimonials.
create policy "Admins can manage public testimonials"
  on public_testimonials
  for all
  to authenticated
  using (
    exists (
      select 1
      from profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );
