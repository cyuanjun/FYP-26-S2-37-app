-- Mutual friendship RPCs (database-v1.md: Follow = an atomic A→B + B→A pair).
-- RLS on follows only allows inserting rows where follower_id = auth.uid(), so
-- the reciprocal row must be written by a SECURITY DEFINER function — the same
-- pattern as end_workout_session. Both functions are idempotent.

create or replace function public.add_friend(p_target uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  if p_target is null or p_target = auth.uid() then
    raise exception 'Cannot friend yourself';
  end if;
  if not exists (select 1 from profiles where id = p_target) then
    raise exception 'User % not found', p_target;
  end if;
  insert into follows (follower_id, following_id)
  values (auth.uid(), p_target), (p_target, auth.uid())
  on conflict do nothing;
end $$;

create or replace function public.remove_friend(p_target uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  delete from follows
  where (follower_id = auth.uid() and following_id = p_target)
     or (follower_id = p_target   and following_id = auth.uid());
end $$;

revoke execute on function public.add_friend(uuid) from public, anon;
revoke execute on function public.remove_friend(uuid) from public, anon;
grant execute on function public.add_friend(uuid) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
