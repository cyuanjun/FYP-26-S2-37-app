-- Landing page pricing display content.
-- Draft migration for the shared FYP-26-S2-37-app Supabase/Postgres database.
--
-- This is display text only for now. It is not linked to payment product IDs.

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

alter table landing_pricing_plans enable row level security;

-- Public landing page can read active pricing plans.
create policy "Public can read active landing pricing plans"
  on landing_pricing_plans
  for select
  using (is_active);

-- Admins can manage pricing display content.
create policy "Admins can manage landing pricing plans"
  on landing_pricing_plans
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
