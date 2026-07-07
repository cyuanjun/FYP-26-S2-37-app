-- Landing-page FAQ entries — admin-editable from the web portal (US63).
-- Same pattern as landing_pricing_plans: public reads active rows, admins
-- manage everything; `faq_key` keeps seeding idempotent.

create table landing_faqs (
  id            uuid primary key default gen_random_uuid(),
  faq_key       text not null unique,
  question      text not null,
  answer        text not null,
  display_order int not null default 0,
  is_active     boolean not null default true,
  updated_at    timestamptz not null default now()
);

alter table landing_faqs enable row level security;

create policy faqs_public_read on landing_faqs
  for select using (is_active);
create policy faqs_admin_all on landing_faqs
  for all to authenticated using (is_admin()) with check (is_admin());
