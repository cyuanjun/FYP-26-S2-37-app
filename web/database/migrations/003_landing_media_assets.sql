-- Landing page media references.
-- Draft migration for the shared FYP-26-S2-37-app Supabase/Postgres database.
--
-- Files should live in Supabase Storage. This table stores stable references.

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

create index idx_landing_media_active_key
  on landing_media_assets (is_active, asset_key);

alter table landing_media_assets enable row level security;

-- Public landing page can read active media references.
create policy "Public can read active landing media assets"
  on landing_media_assets
  for select
  using (is_active);

-- Admins can manage landing media references.
create policy "Admins can manage landing media assets"
  on landing_media_assets
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
