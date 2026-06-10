-- Fix: workout_sessions.user_id references fitness_profiles(id), but the signup
-- trigger only created a profiles row. Every new account is an athlete (role 'free')
-- by default, so create its 1:1 fitness profile on signup too — otherwise recording a
-- workout fails the FK and end_workout_session updates 0 rows (XP/streak lost).

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, username)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do nothing;

  insert into public.fitness_profiles (id) values (new.id)
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

-- Backfill any existing accounts that predate this fix.
insert into public.fitness_profiles (id)
select p.id from public.profiles p
where not exists (select 1 from public.fitness_profiles fp where fp.id = p.id);
