-- Wise Workout — DEMO seed (not the catalog seed; that's seed.sql).
--
-- Creates two demo login accounts and a varied set of workout sessions so the
-- History / analytics / AI-summary / share surfaces look realistic in a demo.
-- Idempotent: re-running resets the two accounts' workout data to this exact set.
--
--   Accounts (password for both: Password123!):
--     free@wiseworkout.test     — Mia Patel (Free)
--     premium@wiseworkout.test  — Alex Tan  (Premium)
--
-- Run against the hosted project (psql / Supabase SQL editor / MCP). Requires the
-- Supabase Auth schema (auth.users) + this app's schema (migrations applied).
-- "Today" is derived from now(); the dates below assume a demo around 2026-06-10.

-- The role/status guard blocks non-admin role changes; disable it for this seed.
alter table public.profiles disable trigger trg_guard_profile_privileged_columns;

-- ----------------------------------------------------------------------------
-- 1. Ensure the two demo auth users + profiles exist.
--    Manually-inserted auth.users need empty-string (not NULL) token columns or
--    GoTrue 500s on login — hence the explicit ''s.
-- ----------------------------------------------------------------------------
do $$
declare
  rec record;
  uid uuid;
begin
  for rec in
    select * from (values
      ('free@wiseworkout.test',    'Mia',  'Patel', 'free'),
      ('premium@wiseworkout.test', 'Alex', 'Tan',   'premium')
    ) as t(email, first_name, last_name, role)
  loop
    select id into uid from auth.users where email = rec.email;
    if uid is null then
      uid := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_app_meta_data, raw_user_meta_data,
        confirmation_token, recovery_token, email_change, email_change_token_new,
        email_change_token_current, phone_change, phone_change_token, reauthentication_token
      ) values (
        '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', rec.email,
        crypt('Password123!', gen_salt('bf')), now(), now(), now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('first_name', rec.first_name, 'username', lower(rec.first_name)),
        '', '', '', '', '', '', '', ''
      );
      insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), uid,
        jsonb_build_object('sub', uid::text, 'email', rec.email), 'email', uid::text, now(), now(), now());
    end if;

    update public.profiles
      set role = rec.role::user_role, first_name = rec.first_name, last_name = rec.last_name
      where id = uid;
    insert into public.fitness_profiles (id) values (uid) on conflict (id) do nothing;
    if rec.role = 'premium' then
      insert into public.subscriptions (id, renews_at) values (uid, now() + interval '30 days')
        on conflict (id) do nothing;
    end if;
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 2. Reset + seed workout sessions for both demo users.
-- ----------------------------------------------------------------------------
delete from public.posts
  where user_id in (select id from public.profiles where email in ('free@wiseworkout.test','premium@wiseworkout.test'));
delete from public.workout_sessions
  where user_id in (select id from public.profiles where email in ('free@wiseworkout.test','premium@wiseworkout.test'));

insert into public.workout_sessions (
  user_id, workout_type_id, started_at, ended_at, duration_seconds,
  distance_meters, calories_burned, avg_heart_rate, max_heart_rate, feel_rating, custom_name
)
select pr.id, wt.id, d.start_ts, d.start_ts + (d.dur || ' seconds')::interval, d.dur,
       d.dist, d.cal, d.ahr, d.mhr, d.feel::feel_rating, d.cname
from (values
  -- Mia (Free) — this week (8-10 Jun), last week (1-5 Jun), earlier (23-27 May)
  ('free@wiseworkout.test','running', '2026-06-08 07:10:00+00'::timestamptz, 1920, 5200,  310, 148, 168, 'good',  null),
  ('free@wiseworkout.test','strength','2026-06-09 18:30:00+00'::timestamptz, 2700, null,  280, 122, 150, 'great', 'Upper body'),
  ('free@wiseworkout.test','cycling', '2026-06-10 06:40:00+00'::timestamptz, 3000, 18400, 420, 138, 160, 'okay',  null),
  ('free@wiseworkout.test','running', '2026-06-01 07:00:00+00'::timestamptz, 1680, 4800,  290, 150, 170, 'good',  null),
  ('free@wiseworkout.test','yoga',    '2026-06-03 19:00:00+00'::timestamptz, 2400, null,  130,  95, 110, 'great', null),
  ('free@wiseworkout.test','running', '2026-06-05 06:50:00+00'::timestamptz, 2100, 6000,  360, 152, 175, 'tough', null),
  ('free@wiseworkout.test','hiit',    '2026-05-27 18:00:00+00'::timestamptz, 1500, null,  320, 160, 182, 'tough', null),
  ('free@wiseworkout.test','hiking',  '2026-05-23 09:00:00+00'::timestamptz, 5400, 8500,  540, 118, 140, 'good',  'Morning trail'),
  -- Alex (Premium) — richer/longer history
  ('premium@wiseworkout.test','running', '2026-06-08 06:30:00+00'::timestamptz, 2400, 7000,  410, 145, 172, 'good',  '10k tempo'),
  ('premium@wiseworkout.test','swimming','2026-06-09 12:15:00+00'::timestamptz, 2100, 1500,  300, 130, 150, 'okay',  null),
  ('premium@wiseworkout.test','strength','2026-06-10 18:00:00+00'::timestamptz, 3300, null,  330, 120, 148, 'great', 'Leg day'),
  ('premium@wiseworkout.test','cycling', '2026-06-02 06:00:00+00'::timestamptz, 3600, 22000, 520, 140, 165, 'good',  null),
  ('premium@wiseworkout.test','running', '2026-06-04 06:40:00+00'::timestamptz, 2700, 8000,  470, 150, 178, 'tough', null),
  ('premium@wiseworkout.test','hiking',  '2026-05-30 08:00:00+00'::timestamptz, 7200, 12000, 720, 115, 138, 'great', 'Mountain loop'),
  ('premium@wiseworkout.test','hiit',    '2026-05-18 18:30:00+00'::timestamptz, 1800, null,  360, 162, 185, 'tough', null)
) as d(email, slug, start_ts, dur, dist, cal, ahr, mhr, feel, cname)
join public.profiles pr on pr.email = d.email
join public.workout_types wt on wt.slug = d.slug;

-- ----------------------------------------------------------------------------
-- 3. Recompute XP + weekly streak from the canonical formula
--    (mirrors end_workout_session: 20 + min + 5/km cardio).
-- ----------------------------------------------------------------------------
update public.fitness_profiles fp
set total_xp = sub.total, current_streak = sub.streak
from (
  select ws.user_id,
    sum(
      20 + floor(ws.duration_seconds / 60.0)
      + case when wt.slug in ('running','cycling','swimming','walking','hiit','rowing','hiking')
             then floor(coalesce(ws.distance_meters, 0) / 1000.0 * 5) else 0 end
    )::int as total,
    (
      select count(*) from (
        select wk, row_number() over (order by wk desc) as rn
        from (
          select distinct date_trunc('week', w2.ended_at)::date as wk
          from public.workout_sessions w2
          where w2.user_id = ws.user_id and w2.ended_at is not null
        ) z
      ) r
      where r.wk = (date_trunc('week', now())::date - ((r.rn - 1) * 7)::int)
    )::int as streak
  from public.workout_sessions ws
  join public.workout_types wt on wt.id = ws.workout_type_id
  where ws.ended_at is not null
    and ws.user_id in (select id from public.profiles where email in ('free@wiseworkout.test','premium@wiseworkout.test'))
  group by ws.user_id
) sub
where fp.id = sub.user_id;

-- ----------------------------------------------------------------------------
-- 4. Share one session per user to the feed (workout_share Post).
-- ----------------------------------------------------------------------------
insert into public.posts (user_id, kind, workout_session_id, body)
select distinct on (ws.user_id)
  ws.user_id, 'workout_share', ws.id,
  case when pr.email = 'free@wiseworkout.test' then 'Evening ride along the bay 🚴'
       else 'New 10k tempo this week! 🏃' end
from public.workout_sessions ws
join public.profiles pr on pr.id = ws.user_id
join public.workout_types wt on wt.id = ws.workout_type_id
where pr.email in ('free@wiseworkout.test','premium@wiseworkout.test')
  and wt.slug = case when pr.email = 'free@wiseworkout.test' then 'cycling' else 'running' end
order by ws.user_id, ws.started_at desc;

-- Re-enable the guard.
alter table public.profiles enable trigger trg_guard_profile_privileged_columns;
