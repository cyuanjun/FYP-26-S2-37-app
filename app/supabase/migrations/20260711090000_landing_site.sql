-- Landing-site integration: the marketing website (web/) reads and writes the
-- SAME database as the app. Finalises the drafts the site shipped with
-- (web/database/migrations/001–004) and opens the minimal anon surface the
-- public pages need. Design notes:
--   • Public reads go through two SECURITY DEFINER functions returning only
--     public-safe columns (no emails, no suspended accounts) — anon gets NO
--     direct view of profiles.
--   • contact_messages already accepts anon inserts (init schema by design).
--   • Signup: the site calls supabase.auth.signUp with profile fields in the
--     user metadata; handle_new_user() v3 mirrors them (now incl. last_name)
--     and, for expert applications, creates the PENDING expert_profiles row +
--     document metadata — role stays 'free' until an admin approves (US06).
--     Document files are metadata-only for now (expert_verification_documents
--     stores names, not blobs — init-schema convention).

-- ============================================================================
-- 1. PUBLIC TESTIMONIALS (draft 001) — submitted by registered users,
--    admin-moderated, only 'approved' rows are publicly readable.
-- ============================================================================

create type public_testimonial_status as enum ('pending', 'approved', 'rejected');

create table public_testimonials (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references profiles (id) on delete cascade,
  display_name  text not null,                          -- shown publicly, e.g. 'Mia P.'
  user_category text not null,                          -- e.g. 'Premium runner'
  rating        int not null check (rating between 1 and 5),
  body          text not null,
  status        public_testimonial_status not null default 'pending',
  admin_reply   text,
  submitted_at  timestamptz not null default now(),
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now(),
  unique (user_id)                                      -- one public testimonial per user
);
create index idx_public_testimonials_status on public_testimonials (status);

alter table public_testimonials enable row level security;

create policy testimonials_public_read on public_testimonials
  for select using (status = 'approved');
create policy testimonials_submit_own on public_testimonials
  for insert to authenticated with check (user_id = auth.uid() and status = 'pending');
create policy testimonials_admin_all on public_testimonials
  for all to authenticated using (is_admin()) with check (is_admin());

-- ============================================================================
-- 2. LANDING PRICING PLANS (draft 002) — display copy only; no payment IDs.
-- ============================================================================

create table landing_pricing_plans (
  id            uuid primary key default gen_random_uuid(),
  plan_key      text not null unique,
  plan_name     text not null,
  price_label   text not null,
  description   text not null,
  button_text   text not null,
  button_url    text not null,
  features      text[] not null default '{}',
  display_order int not null default 0,
  is_active     boolean not null default true,
  updated_at    timestamptz not null default now()
);

alter table landing_pricing_plans enable row level security;

create policy pricing_public_read on landing_pricing_plans
  for select using (is_active);
create policy pricing_admin_all on landing_pricing_plans
  for all to authenticated using (is_admin()) with check (is_admin());

-- ============================================================================
-- 3. LANDING MEDIA ASSETS (draft 003) — stable references to Storage files.
-- ============================================================================

create table landing_media_assets (
  id           uuid primary key default gen_random_uuid(),
  asset_key    text not null unique,
  bucket       text not null,
  storage_path text not null,
  alt_text     text,
  media_type   text not null check (media_type in ('image', 'video')),
  is_active    boolean not null default true,
  updated_at   timestamptz not null default now()
);

alter table landing_media_assets enable row level security;

create policy media_public_read on landing_media_assets
  for select using (is_active);
create policy media_admin_all on landing_media_assets
  for all to authenticated using (is_admin()) with check (is_admin());

-- ============================================================================
-- 4. ANON CATALOG READ — active expert categories are public-safe copy.
-- ============================================================================

create policy expert_categories_public_read on expert_categories
  for select to anon using (is_active);

-- ============================================================================
-- 5. PUBLIC READ FUNCTIONS — the landing page's whole anon read surface.
-- ============================================================================

-- Aggregate counts for the statistics section. Growth %s stay client-side
-- (no history to derive them from); values here are live.
create or replace function public.landing_metric_summary()
returns jsonb
language sql stable
security definer set search_path = public
as $$
  select jsonb_build_object(
    'free_users',        (select count(*) from profiles where role = 'free'),
    'premium_users',     (select count(*) from profiles where role = 'premium'),
    'verified_experts',  (select count(*) from expert_profiles where verification_status = 'verified'),
    'approved_reviews',  (select count(*) from expert_reviews),
    'active_categories', (select count(*) from expert_categories where is_active),
    'contact_resolved',  (select case when count(*) = 0 then '—'
                                 else round(100.0 * count(*) filter (where status = 'resolved') / count(*)) || '%'
                            end
                          from contact_messages)
  );
$$;

-- Top verified experts for the FEATURED EXPERTS section. Same ranking the
-- site used against its seed: rating weighted by log review volume.
-- Public-safe columns only — no email; suspended accounts excluded.
create or replace function public.landing_featured_experts(p_limit int default 3)
returns table (
  user_id uuid, display_name text, avatar_url text, title text,
  years_coaching int, about text, credentials text[], specialties text[],
  rating_avg numeric, review_count int, client_count int
)
language sql stable
security definer set search_path = public
as $$
  select ep.id,
         trim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')),
         p.avatar_url, ep.title, ep.years_coaching, ep.about,
         ep.credentials, ep.specialties, ep.rating_avg, ep.review_count, ep.client_count
  from expert_profiles ep
  join profiles p on p.id = ep.id
  where ep.verification_status = 'verified'
    and coalesce(p.status::text, 'active') <> 'suspended'
  order by ep.rating_avg * ln(ep.review_count + 1) desc,
           ep.review_count desc, ep.rating_avg desc, ep.client_count desc
  limit greatest(1, least(coalesce(p_limit, 3), 12));
$$;

revoke all on function public.landing_metric_summary() from public;
revoke all on function public.landing_featured_experts(int) from public;
grant execute on function public.landing_metric_summary() to anon, authenticated;
grant execute on function public.landing_featured_experts(int) to anon, authenticated;

-- ============================================================================
-- 6. SIGNUP TRIGGER v3 — adds last_name mirroring and the expert-application
--    path (metadata → pending expert_profiles + document metadata). The
--    expert block never aborts account creation: malformed metadata is
--    logged and skipped.
-- ============================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  app jsonb := new.raw_user_meta_data -> 'expert_application';
begin
  insert into public.profiles (id, email, first_name, last_name, username)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'last_name', ''),
    nullif(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do nothing;

  insert into public.fitness_profiles (id) values (new.id)
  on conflict (id) do nothing;

  if app is not null and jsonb_typeof(app) = 'object' then
    begin
      insert into public.expert_profiles (id, title, years_coaching, about, credentials, specialties)
      values (
        new.id,
        coalesce(nullif(app ->> 'title', ''), 'Coach'),
        coalesce(nullif(app ->> 'years_coaching', '')::int, 0),
        coalesce(app ->> 'about', ''),
        coalesce((select array_agg(x) from jsonb_array_elements_text(app -> 'credentials') x), '{}'),
        coalesce((select array_agg(x) from jsonb_array_elements_text(app -> 'specialties') x), '{}')
      )
      on conflict (id) do nothing;
      -- verification_status defaults to 'pending'; role stays 'free' until approval.

      insert into public.expert_verification_documents (user_id, doc_type, title, file_name)
      select new.id,
             (d ->> 'doc_type')::expert_doc_type,
             coalesce(nullif(d ->> 'title', ''), d ->> 'file_name', 'Document'),
             coalesce(d ->> 'file_name', 'unnamed')
      from jsonb_array_elements(coalesce(app -> 'documents', '[]'::jsonb)) d
      where (d ->> 'doc_type') in ('identity', 'certification');
    exception when others then
      raise warning 'expert application metadata skipped for %: %', new.id, sqlerrm;
    end;
  end if;

  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
