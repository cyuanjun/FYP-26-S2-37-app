-- Expert earnings (simulated): a lifetime aggregate on expert_profiles,
-- maintained by complete_service_request — NOT a ledger (payment stays
-- simulated; per-engagement amounts are the quoted_price_cents snapshots).

alter table public.expert_profiles
  add column if not exists total_earned_cents int not null default 0;

-- Backfill from already-completed engagements.
update public.expert_profiles ep
   set total_earned_cents = coalesce((
     select sum(sr.quoted_price_cents) from public.service_requests sr
      where sr.expert_user_id = ep.id and sr.status = 'completed'), 0)
 where ep.total_earned_cents = 0;

create or replace function public.complete_service_request(p_request uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v service_requests;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select * into v from service_requests where id = p_request;
  if v.id is null then raise exception 'Request % not found', p_request; end if;
  if v.expert_user_id <> auth.uid() then raise exception 'Only the expert can complete'; end if;
  if v.status <> 'accepted' then raise exception 'Request is %, expected accepted', v.status; end if;
  update service_requests set status = 'completed', completed_at = now() where id = p_request;
  update expert_profiles
     set client_count = client_count + 1,
         total_earned_cents = total_earned_cents + v.quoted_price_cents
   where id = auth.uid();
end $$;
