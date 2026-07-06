-- start_premium() — the simulated Free→Premium upgrade (#16 Upgrade, US: premium tier).
-- Payment is SIMULATED for the FYP (settled: $9.99/mo, price fields only, no gateway/
-- ledger) — production would gate the role flip on a payment-webhook confirmation.
--
-- Why an RPC: guard_profile_privileged_columns blocks any non-admin role change
-- ("only admins change role/status"). The upgrade is the one legitimate self-service
-- role transition, so it runs SECURITY DEFINER and authorizes its own UPDATE via a
-- transaction-local GUC the guard now recognises. The flag dies with the transaction,
-- so direct role UPDATEs from clients stay blocked.
--
-- Cancel / resume (#13.6) are NOT RPCs: they are owner-scoped single-column status
-- writes on the caller's own subscriptions row with no cross-party or aggregate
-- rules — the subscriptions_owner RLS policy already says exactly who may do them.

create or replace function public.guard_profile_privileged_columns()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if not is_admin()
     and coalesce(current_setting('app.role_change_authorized', true), '') <> 'on' then
    if new.role is distinct from old.role then
      raise exception 'Only admins can change role';
    end if;
    if new.status is distinct from old.status then
      raise exception 'Only admins can change status';
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.start_premium()
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_role user_role;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  -- Lock the profile row so concurrent calls can't double-upgrade.
  select role into v_role from profiles where id = auth.uid() for update;
  if v_role is null then
    raise exception 'No profile for caller';
  end if;
  if v_role <> 'free' then
    raise exception 'Only free accounts can upgrade (current role: %)', v_role;
  end if;

  perform set_config('app.role_change_authorized', 'on', true);  -- txn-local
  update profiles set role = 'premium' where id = auth.uid();
  perform set_config('app.role_change_authorized', '', true);

  -- Shared-key 1:1: re-upgrading after a lapsed/cancelled subscription reuses the row.
  insert into subscriptions (id, status, started_at, renews_at, price_cents)
  values (auth.uid(), 'active', now(), now() + interval '1 month', 999)
  on conflict (id) do update
    set status     = 'active',
        started_at = now(),
        renews_at  = now() + interval '1 month';
end;
$$;

revoke execute on function public.start_premium() from public, anon;
grant execute on function public.start_premium() to authenticated;
