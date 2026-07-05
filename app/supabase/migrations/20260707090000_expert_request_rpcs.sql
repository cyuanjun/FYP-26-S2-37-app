-- Service-request transition + review RPCs (the "column-level transition
-- rules belong in an RPC" the RLS starter deferred — rls_policies.sql §7).
--
-- Lifecycle (database-v1.md ServiceRequest): pending → accepted | cancelled
-- (expert decides) → completed (expert-only, so a client can't rage-quit an
-- engagement and still review it). Reviews are gated here too: client-only,
-- completed-only, one per engagement, and the stored expert aggregates
-- (rating_avg / review_count / client_count) are recomputed atomically.
--
-- Deliberate scope notes:
--  * No client cancel RPC — #6.2 has no cancel surface in v1.
--  * quoted_price_cents stays client-set on insert (a server-side snapshot
--    would need an insert RPC); acceptable for the simulated-payment FYP scope.

create or replace function public.accept_service_request(p_request uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v service_requests;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select * into v from service_requests where id = p_request;
  if v.id is null then raise exception 'Request % not found', p_request; end if;
  if v.expert_user_id <> auth.uid() then raise exception 'Only the expert can accept'; end if;
  if v.status <> 'pending' then raise exception 'Request is %, expected pending', v.status; end if;
  update service_requests set status = 'accepted' where id = p_request;
end $$;

create or replace function public.decline_service_request(p_request uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v service_requests;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select * into v from service_requests where id = p_request;
  if v.id is null then raise exception 'Request % not found', p_request; end if;
  if v.expert_user_id <> auth.uid() then raise exception 'Only the expert can decline'; end if;
  if v.status <> 'pending' then raise exception 'Request is %, expected pending', v.status; end if;
  update service_requests set status = 'cancelled' where id = p_request;
end $$;

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
  update expert_profiles set client_count = client_count + 1 where id = auth.uid();
end $$;

create or replace function public.submit_expert_review(p_request uuid, p_rating int, p_body text)
returns void
language plpgsql security definer set search_path = public
as $$
declare v service_requests;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select * into v from service_requests where id = p_request;
  if v.id is null then raise exception 'Request % not found', p_request; end if;
  if v.user_id <> auth.uid() then raise exception 'Only the client can review'; end if;
  if v.status <> 'completed' then raise exception 'Engagement not completed'; end if;
  if p_rating not between 1 and 5 or coalesce(btrim(p_body), '') = '' then
    raise exception 'Invalid review';
  end if;
  if exists (select 1 from expert_reviews where service_request_id = p_request) then
    raise exception 'Already reviewed';
  end if;
  insert into expert_reviews (expert_user_id, user_id, service_request_id, rating, body)
  values (v.expert_user_id, v.user_id, p_request, p_rating, btrim(p_body));
  update expert_profiles
     set rating_avg   = round(((rating_avg * review_count) + p_rating) / (review_count + 1), 1),
         review_count = review_count + 1
   where id = v.expert_user_id;
end $$;

revoke execute on function public.accept_service_request(uuid) from public, anon;
revoke execute on function public.decline_service_request(uuid) from public, anon;
revoke execute on function public.complete_service_request(uuid) from public, anon;
revoke execute on function public.submit_expert_review(uuid, int, text) from public, anon;
grant execute on function public.accept_service_request(uuid) to authenticated;
grant execute on function public.decline_service_request(uuid) to authenticated;
grant execute on function public.complete_service_request(uuid) to authenticated;
grant execute on function public.submit_expert_review(uuid, int, text) to authenticated;

-- Lockdown: with the RPCs in place they become the ONLY transition/review
-- path. SECURITY DEFINER runs as the table owner, unaffected by these
-- revokes; the loose service_requests_party_update policy stays but is now
-- unreachable for direct writes.
revoke update on public.service_requests from anon, authenticated;
revoke insert, update, delete on public.expert_reviews from anon, authenticated;
