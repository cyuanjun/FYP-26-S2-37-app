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
-- All session dates are now()-relative (6 Jul), so re-running this file any time
-- yields a live-looking demo: recent sessions this/last week, capped sessions in
-- the previous month, and challenge-window overlap for leaderboards.

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
      set role = rec.role::user_role, first_name = rec.first_name, last_name = rec.last_name,
          onboarding_completed_at = coalesce(profiles.onboarding_completed_at, now())
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
  -- Dates are now()-relative so the demo stays evergreen (updated 6 Jul):
  -- recent days feed THIS WEEK/LAST WEEK groupings + live challenge windows;
  -- the date_trunc('month')-anchored rows always land in the PREVIOUS month
  -- to keep demonstrating the Free history cap.
  -- Mia (Free)
  ('free@wiseworkout.test','running', date_trunc('day', now()) - interval '2 days' + interval '07:10', 1920, 5200,  310, 148, 168, 'good',  null),
  ('free@wiseworkout.test','strength',date_trunc('day', now()) - interval '1 day'  + interval '18:30', 2700, null,  280, 122, 150, 'great', 'Upper body'),
  ('free@wiseworkout.test','cycling', date_trunc('day', now())                     + interval '06:40', 3000, 18400, 420, 138, 160, 'okay',  null),
  ('free@wiseworkout.test','running', date_trunc('day', now()) - interval '9 days' + interval '07:00', 1680, 4800,  290, 150, 170, 'good',  null),
  ('free@wiseworkout.test','yoga',    date_trunc('day', now()) - interval '7 days' + interval '19:00', 2400, null,  130,  95, 110, 'great', null),
  ('free@wiseworkout.test','running', date_trunc('day', now()) - interval '5 days' + interval '06:50', 2100, 6000,  360, 152, 175, 'tough', null),
  ('free@wiseworkout.test','hiit',    date_trunc('month', now()) - interval '4 days'  + interval '18:00', 1500, null,  320, 160, 182, 'tough', null),
  ('free@wiseworkout.test','hiking',  date_trunc('month', now()) - interval '8 days'  + interval '09:00', 5400, 8500,  540, 118, 140, 'good',  'Morning trail'),
  -- Alex (Premium) — richer/longer history
  ('premium@wiseworkout.test','running', date_trunc('day', now()) - interval '2 days' + interval '06:30', 2400, 7000,  410, 145, 172, 'good',  '10k tempo'),
  ('premium@wiseworkout.test','swimming',date_trunc('day', now()) - interval '1 day'  + interval '12:15', 2100, 1500,  300, 130, 150, 'okay',  null),
  ('premium@wiseworkout.test','strength',date_trunc('day', now())                     + interval '07:45', 3300, null,  330, 120, 148, 'great', 'Leg day'),
  ('premium@wiseworkout.test','cycling', date_trunc('day', now()) - interval '8 days' + interval '06:00', 3600, 22000, 520, 140, 165, 'good',  null),
  ('premium@wiseworkout.test','running', date_trunc('day', now()) - interval '6 days' + interval '06:40', 2700, 8000,  470, 150, 178, 'tough', null),
  ('premium@wiseworkout.test','hiking',  date_trunc('month', now()) - interval '1 day'  + interval '08:00', 7200, 12000, 720, 115, 138, 'great', 'Mountain loop'),
  ('premium@wiseworkout.test','hiit',    date_trunc('month', now()) - interval '13 days' + interval '18:30', 1800, null,  360, 162, 185, 'tough', null)
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

-- ----------------------------------------------------------------------------
-- 5. Mutual friendship Mia ↔ Alex (a pair of rows — add_friend RPC parity).
-- ----------------------------------------------------------------------------
delete from public.follows
 where follower_id  in (select id from public.profiles where email in ('free@wiseworkout.test','premium@wiseworkout.test'))
    or following_id in (select id from public.profiles where email in ('free@wiseworkout.test','premium@wiseworkout.test'));
insert into public.follows (follower_id, following_id)
select a.id, b.id
from public.profiles a
join public.profiles b on a.id <> b.id
where a.email in ('free@wiseworkout.test','premium@wiseworkout.test')
  and b.email in ('free@wiseworkout.test','premium@wiseworkout.test');

-- ----------------------------------------------------------------------------
-- 6. Each demo user likes + comments the other's shared post.
--    (Step 2's posts delete cascaded old likes/comments — clean slate.)
-- ----------------------------------------------------------------------------
insert into public.post_likes (post_id, user_id)
select p.id, liker.id
from public.posts p
join public.profiles author on author.id = p.user_id
join public.profiles liker  on liker.email in ('free@wiseworkout.test','premium@wiseworkout.test')
                           and liker.id <> author.id
where p.kind = 'workout_share'
  and author.email in ('free@wiseworkout.test','premium@wiseworkout.test');

insert into public.post_comments (post_id, user_id, body)
select p.id, commenter.id,
       case when commenter.email = 'free@wiseworkout.test'
            then 'Strong pace — nice one! 🔥' else 'Great ride, love that route!' end
from public.posts p
join public.profiles author    on author.id = p.user_id
join public.profiles commenter on commenter.email in ('free@wiseworkout.test','premium@wiseworkout.test')
                              and commenter.id <> author.id
where p.kind = 'workout_share'
  and author.email in ('free@wiseworkout.test','premium@wiseworkout.test');

-- ----------------------------------------------------------------------------
-- 7. Both demo users join the '20 IN 30' accumulator challenge (seed.sql
--    catalog id …0002). Their step-2 sessions fall inside the now()-relative
--    window, so challenge_leaderboards() shows live progress. If the demo
--    session dates drift out of the window, re-run this file.
-- ----------------------------------------------------------------------------
delete from public.challenge_participants
 where user_id in (select id from public.profiles where email in ('free@wiseworkout.test','premium@wiseworkout.test'));
insert into public.challenge_participants (challenge_id, user_id)
select 'c0000000-0000-4000-8000-000000000002', pr.id
from public.profiles pr
where pr.email in ('free@wiseworkout.test','premium@wiseworkout.test');

-- Re-enable the guard.
alter table public.profiles enable trigger trg_guard_profile_privileged_columns;
