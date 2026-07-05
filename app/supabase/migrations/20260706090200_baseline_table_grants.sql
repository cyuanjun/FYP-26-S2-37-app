-- Baseline table grants (local-stack parity).
--
-- Hosted Supabase configures default privileges so anon/authenticated/
-- service_role get full DML on new public tables and RLS does the gating.
-- The local CLI stack (found 6 Jul, first local run) does NOT — tables created
-- by our migrations were unreadable by the API roles. Grant the standard
-- Supabase baseline explicitly so `supabase db reset` reproduces the hosted
-- behaviour. Security is unchanged: every table has RLS enabled and policies
-- from 20260610090100_rls_policies.sql.

grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete on all tables in schema public
  to anon, authenticated, service_role;

grant usage, select on all sequences in schema public
  to anon, authenticated, service_role;

-- Future tables created by the postgres role inherit the same baseline.
alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant usage, select on sequences to anon, authenticated, service_role;
