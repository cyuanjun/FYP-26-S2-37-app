-- Wise Workout — DEMO seed (not the catalog seed; that's seed.sql).
--
-- Creates two demo login accounts and a varied set of workout sessions so the
-- History / analytics / AI-summary / share surfaces look realistic in a demo.
-- Idempotent: re-running resets the two accounts' workout data to this exact set.
--
--   Accounts (password for all: Password123!):
--     free@wiseworkout.test     — Mia Patel (Free)
--     premium@wiseworkout.test  — Alex Tan  (Premium)
--     expert@wiseworkout.test   — Sam Rivera (Expert)
--   Background athletes (§9, so the feed/leaderboards look alive):
--     jordan@ / priya@ / leo@wiseworkout.test — Free athletes w/ sessions,
--     posts, likes/comments, friendships with Mia+Alex, challenge entries.
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
      ('free@wiseworkout.test',    'Mia',  'Patel',  'free'),
      ('premium@wiseworkout.test', 'Alex', 'Tan',    'premium'),
      ('expert@wiseworkout.test',  'Sam',  'Rivera', 'expert'),
      ('jordan@wiseworkout.test',  'Jordan','Lee',   'free'),
      ('priya@wiseworkout.test',   'Priya', 'Nair',  'free'),
      ('leo@wiseworkout.test',     'Leo',   'Chen',  'free'),
      ('admin@wiseworkout.test',   'Ava',   'Admin',  'admin'),
      ('amelia@wiseworkout.test',  'Amelia','Tan',    'expert'),
      ('marcus@wiseworkout.test',  'Marcus','Lim',    'expert'),
      ('elena@wiseworkout.test',   'Elena', 'Ortiz',  'expert'),
      ('noah@wiseworkout.test',    'Noah',  'Reyes',  'free')
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

-- ----------------------------------------------------------------------------
-- 8. Expert marketplace demo (6-7 Jul): Sam Rivera, verified expert, with
--    3 live services and engagements exercising every #6.2 footer state.
--    Stored aggregates intentionally exceed the physical review rows (mock
--    convention per 06.1); the submit_expert_review RPC keeps them consistent
--    going forward.
-- ----------------------------------------------------------------------------
insert into public.expert_profiles (id, title, years_coaching, about, credentials,
                                    specialties, rating_avg, review_count, client_count,
                                    total_earned_cents, verification_status)
select id, 'Strength Coach', 9,
       'I help everyday athletes build strength that lasts — no fads, just progressive overload, honest feedback, and programming that fits your life.',
       array['NASM CPT', 'Precision Nutrition L1', 'BSc Exercise Science'],
       array['strength', 'mobility'], 4.8, 23, 41, 372000, 'verified'
from public.profiles where email = 'expert@wiseworkout.test'
on conflict (id) do update set
  title = excluded.title, years_coaching = excluded.years_coaching,
  about = excluded.about, credentials = excluded.credentials,
  specialties = excluded.specialties, rating_avg = excluded.rating_avg,
  review_count = excluded.review_count, client_count = excluded.client_count,
  total_earned_cents = excluded.total_earned_cents,
  verification_status = excluded.verification_status;

delete from public.expert_services
 where expert_user_id in (select id from public.profiles where email = 'expert@wiseworkout.test');
insert into public.expert_services (id, expert_user_id, status, name, description,
                                    detail_bullets, category, fulfillment, pricing_model,
                                    price_cents, duration_weeks, response_time)
select v.id::uuid, pr.id, 'live', v.name, v.description, v.bullets, v.category,
       v.fulfillment::fulfillment_type, v.pricing::pricing_model, v.price, v.weeks,
       v.rt::response_time
from (values
  ('e0000000-0000-4000-8000-000000000001', '12-Week Strength Block',
   'A fully periodised strength programme built around your schedule and equipment.',
   array['Personalised 12-week plan', 'Weekly check-in notes', 'Video form review each block'],
   'strength', 'workout_plan', 'one_time', 12000, 12, '48h'),
  ('e0000000-0000-4000-8000-000000000002', 'Form Check & Program Review',
   'Send your lifts and current programme — get a detailed written review.',
   array['Up to 5 lift videos reviewed', 'Written technique notes', 'Programme adjustments'],
   'strength', 'review', 'one_time', 4500, null, '24h'),
  ('e0000000-0000-4000-8000-000000000003', 'Mobility Reset Coaching',
   'Four weeks of guided mobility work to unlock stiff hips and shoulders.',
   array['Daily 15-min routines', 'Weekly progression', 'Direct message support'],
   'mobility', 'coaching', 'recurring', 8000, 4, '72h')
) as v(id, name, description, bullets, category, fulfillment, pricing, price, weeks, rt)
join public.profiles pr on pr.email = 'expert@wiseworkout.test';

delete from public.service_requests
 where expert_user_id in (select id from public.profiles where email = 'expert@wiseworkout.test');
-- Mia -> Strength Block: COMPLETED, has a deliverable, NOT yet reviewed
insert into public.service_requests (id, user_id, expert_service_id, expert_user_id,
                                     quoted_price_cents, status, request_message,
                                     requested_at, completed_at)
select 'a0000000-0000-4000-8000-000000000001', mia.id,
       'e0000000-0000-4000-8000-000000000001', sam.id, 12000, 'completed',
       'I want to squat 100 kg by the end of the year — three gym days a week.',
       now() - interval '20 days', now() - interval '3 days'
from public.profiles mia, public.profiles sam
where mia.email = 'free@wiseworkout.test' and sam.email = 'expert@wiseworkout.test';
-- Mia -> Mobility Reset: PENDING (demos the pending footer + Sam's inbox)
insert into public.service_requests (id, user_id, expert_service_id, expert_user_id,
                                     quoted_price_cents, status, request_message, requested_at)
select 'a0000000-0000-4000-8000-000000000002', mia.id,
       'e0000000-0000-4000-8000-000000000003', sam.id, 8000, 'pending',
       'Desk job has wrecked my hips — I want to move freely again.',
       now() - interval '1 day'
from public.profiles mia, public.profiles sam
where mia.email = 'free@wiseworkout.test' and sam.email = 'expert@wiseworkout.test';
-- Alex -> Form Check: COMPLETED + REVIEWED (demos the ✓ Reviewed footer)
insert into public.service_requests (id, user_id, expert_service_id, expert_user_id,
                                     quoted_price_cents, status, request_message,
                                     requested_at, completed_at)
select 'a0000000-0000-4000-8000-000000000003', alex.id,
       'e0000000-0000-4000-8000-000000000002', sam.id, 4500, 'completed',
       'Deadlift form check before I push heavier this block, please.',
       now() - interval '12 days', now() - interval '8 days'
from public.profiles alex, public.profiles sam
where alex.email = 'premium@wiseworkout.test' and sam.email = 'expert@wiseworkout.test';

insert into public.deliverables (service_request_id, title, note, sections)
values ('a0000000-0000-4000-8000-000000000001', 'Weeks 1-4 Training Block',
        'Start conservative — RPE 7 means two clean reps left in the tank.',
        '[{"heading":"Day A — Lower","items":[
            {"label":"Back squat","detail":"4x6","sub":"RPE 7"},
            {"label":"Romanian deadlift","detail":"3x8","sub":"slow eccentric"},
            {"label":"Walking lunges","detail":"3x12/leg"}]},
          {"heading":"Day B — Upper","items":[
            {"label":"Bench press","detail":"4x6","sub":"RPE 7"},
            {"label":"One-arm row","detail":"3x10/side"},
            {"label":"Face pulls","detail":"3x15"}]}]'::jsonb);

insert into public.expert_reviews (expert_user_id, user_id, service_request_id, rating, body)
select sam.id, alex.id, 'a0000000-0000-4000-8000-000000000003', 5,
       'Sharp, actionable feedback within a day. My deadlift lockout finally clicked.'
from public.profiles alex, public.profiles sam
where alex.email = 'premium@wiseworkout.test' and sam.email = 'expert@wiseworkout.test';

-- Mia already follows Sam (pre-filled heart on #6).
update public.profiles
   set followed_expert_ids = array[(select id from public.profiles where email = 'expert@wiseworkout.test')]
 where email = 'free@wiseworkout.test';

-- ----------------------------------------------------------------------------
-- 9. Background athletes (demo polish): Jordan, Priya, Leo. Sessions, one
--    shared post each, mutual friendships with Mia + Alex, likes/comments
--    both ways, and challenge entries so the #11 feed and #11.3 leaderboards
--    look alive with more than two people.
-- ----------------------------------------------------------------------------
update public.profiles set bio = v.bio
from (values
  ('jordan@wiseworkout.test', 'Chasing a sub-50 10k. Coffee first, always.'),
  ('priya@wiseworkout.test',  'Yoga mornings, trail weekends.'),
  ('leo@wiseworkout.test',    'Ride far, lift heavy, sleep well.')
) as v(email, bio)
where profiles.email = v.email;

delete from public.posts
  where user_id in (select id from public.profiles where email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test'));
delete from public.workout_sessions
  where user_id in (select id from public.profiles where email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test'));

insert into public.workout_sessions (
  user_id, workout_type_id, started_at, ended_at, duration_seconds,
  distance_meters, calories_burned, avg_heart_rate, max_heart_rate, feel_rating, custom_name
)
select pr.id, wt.id, d.start_ts, d.start_ts + (d.dur || ' seconds')::interval, d.dur,
       d.dist, d.cal, d.ahr, d.mhr, d.feel::feel_rating, d.cname
from (values
  -- Jordan — runner (feeds RUN 100K + 20 IN 30)
  ('jordan@wiseworkout.test','running', date_trunc('day', now()) - interval '3 days' + interval '06:45', 2520, 7500,  430, 149, 173, 'good',  'Progression run'),
  ('jordan@wiseworkout.test','running', date_trunc('day', now()) - interval '1 day'  + interval '06:50', 1800, 5000,  300, 146, 168, 'okay',  null),
  ('jordan@wiseworkout.test','strength',date_trunc('day', now()) - interval '6 days' + interval '18:20', 2400, null,  250, 118, 142, 'good',  null),
  ('jordan@wiseworkout.test','running', date_trunc('day', now()) - interval '8 days' + interval '07:05', 3300, 10000, 560, 151, 176, 'tough', 'Long run Sunday'),
  -- Priya — yoga + trails (feeds 20 IN 30 + BURN 5K)
  ('priya@wiseworkout.test','yoga',    date_trunc('day', now()) - interval '2 days' + interval '07:00', 2700, null,  140,  92, 108, 'great', 'Sunrise flow'),
  ('priya@wiseworkout.test','hiking',  date_trunc('day', now()) - interval '4 days' + interval '08:30', 6300, 9800,  610, 121, 145, 'great', 'Ridge trail'),
  ('priya@wiseworkout.test','yoga',    date_trunc('day', now())                     + interval '06:30', 2400, null,  120,  90, 104, 'good',  null),
  ('priya@wiseworkout.test','running', date_trunc('day', now()) - interval '7 days' + interval '17:40', 1620, 4200,  260, 143, 165, 'okay',  null),
  -- Leo — cyclist (feeds LONG RIDE + BURN 5K)
  ('leo@wiseworkout.test','cycling',  date_trunc('day', now()) - interval '2 days' + interval '06:15', 5400, 32000, 780, 141, 166, 'tough', 'Century prep'),
  ('leo@wiseworkout.test','strength', date_trunc('day', now()) - interval '5 days' + interval '19:00', 2700, null,  290, 116, 140, 'good',  null),
  ('leo@wiseworkout.test','cycling',  date_trunc('day', now()) - interval '9 days' + interval '06:30', 4200, 26000, 640, 138, 162, 'good',  null),
  ('leo@wiseworkout.test','rowing',   date_trunc('day', now()) - interval '1 day'  + interval '07:20', 1800, 4000,  270, 132, 154, 'okay',  null)
) as d(email, slug, start_ts, dur, dist, cal, ahr, mhr, feel, cname)
join public.profiles pr on pr.email = d.email
join public.workout_types wt on wt.slug = d.slug;

-- XP + streak for the athletes (same canonical formula as §3).
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
    and ws.user_id in (select id from public.profiles where email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test'))
  group by ws.user_id
) sub
where fp.id = sub.user_id;

-- One shared post each (their most on-brand session).
insert into public.posts (user_id, kind, workout_session_id, body)
select ws.user_id, 'workout_share', ws.id, v.body
from (values
  ('jordan@wiseworkout.test', 'Long run Sunday', 'Longest run of the block done 🙌'),
  ('priya@wiseworkout.test',  'Ridge trail',     'Trail therapy with a view ⛰️'),
  ('leo@wiseworkout.test',    'Century prep',    '32k before breakfast. Legs = jelly 🚴')
) as v(email, cname, body)
join public.profiles pr on pr.email = v.email
join public.workout_sessions ws on ws.user_id = pr.id and ws.custom_name = v.cname;

-- Friendships: each athlete ↔ Mia and ↔ Alex (mutual pairs; athletes are not
-- friends with each other so friend counts differ believably).
insert into public.follows (follower_id, following_id)
select a.id, b.id
from public.profiles a
join public.profiles b on a.id <> b.id
where (a.email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test')
       and b.email in ('free@wiseworkout.test','premium@wiseworkout.test'))
   or (b.email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test')
       and a.email in ('free@wiseworkout.test','premium@wiseworkout.test'))
on conflict do nothing;

-- Likes: Mia + Alex like every athlete post; athletes like Mia's and Alex's posts.
insert into public.post_likes (post_id, user_id)
select p.id, liker.id
from public.posts p
join public.profiles author on author.id = p.user_id
join public.profiles liker on liker.id <> author.id
where p.kind = 'workout_share'
  and (
    (author.email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test')
     and liker.email in ('free@wiseworkout.test','premium@wiseworkout.test'))
    or
    (author.email in ('free@wiseworkout.test','premium@wiseworkout.test')
     and liker.email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test'))
  )
on conflict do nothing;

-- A few comments so threads have depth.
insert into public.post_comments (post_id, user_id, body)
select p.id, commenter.id, v.body
from (values
  ('jordan@wiseworkout.test', 'free@wiseworkout.test',    'That pace over 10k?! Teach me 😅'),
  ('priya@wiseworkout.test',  'premium@wiseworkout.test', 'Adding this trail to my list.'),
  ('leo@wiseworkout.test',    'free@wiseworkout.test',    'Century soon then? 👀'),
  ('free@wiseworkout.test',   'jordan@wiseworkout.test',  'Bay loop is the best evening ride.'),
  ('premium@wiseworkout.test','priya@wiseworkout.test',   'Solid tempo, Alex!')
) as v(author_email, commenter_email, body)
join public.profiles author on author.email = v.author_email
join public.profiles commenter on commenter.email = v.commenter_email
join public.posts p on p.user_id = author.id and p.kind = 'workout_share';

-- Challenge entries: fill the leaderboards around Mia + Alex.
delete from public.challenge_participants
 where user_id in (select id from public.profiles where email in ('jordan@wiseworkout.test','priya@wiseworkout.test','leo@wiseworkout.test'));
insert into public.challenge_participants (challenge_id, user_id)
select v.cid::uuid, pr.id
from (values
  ('c0000000-0000-4000-8000-000000000002', 'jordan@wiseworkout.test'), -- 20 IN 30
  ('c0000000-0000-4000-8000-000000000002', 'priya@wiseworkout.test'),
  ('c0000000-0000-4000-8000-000000000002', 'leo@wiseworkout.test'),
  ('c0000000-0000-4000-8000-000000000001', 'jordan@wiseworkout.test'), -- RUN 100K
  ('c0000000-0000-4000-8000-000000000005', 'priya@wiseworkout.test'),  -- BURN 5K
  ('c0000000-0000-4000-8000-000000000005', 'leo@wiseworkout.test'),
  ('c0000000-0000-4000-8000-000000000004', 'leo@wiseworkout.test')     -- LONG RIDE
) as v(cid, email)
join public.profiles pr on pr.email = v.email;

-- ============================================================================
-- §11 MORE VERIFIED EXPERTS — gives the marketplace + the landing FEATURED
-- EXPERTS ranking real depth. Aggregates (rating/review/client counts) are
-- seeded directly per the mock convention (RPCs keep them consistent forward).
-- ============================================================================

insert into public.expert_profiles
  (id, title, years_coaching, about, credentials, specialties,
   rating_avg, review_count, client_count, verification_status)
select pr.id, v.title, v.years, v.about, v.credentials, v.specialties,
       v.rating, v.reviews, v.clients, 'verified'::verification_status
from (values
  ('amelia@wiseworkout.test', 'Strength & Mobility Coach', 9,
   'Helps busy members build sustainable strength routines with practical mobility work and recovery habits.',
   array['Certified Strength Coach', 'Mobility Specialist', 'Former national team trainer'],
   array['strength', 'mobility', 'recovery'], 4.9, 86, 240),
  ('marcus@wiseworkout.test', 'Endurance Performance Specialist', 11,
   'Designs running and cycling plans for users who want better pacing, safer progression, and clearer race prep.',
   array['Endurance Coach', 'Sports Science MSc', 'Marathon programme lead'],
   array['endurance', 'running', 'recovery'], 4.8, 112, 310),
  ('elena@wiseworkout.test', 'Yoga & Recovery Coach', 7,
   'Blends yoga, breathwork, and structured recovery weeks so hard training keeps paying off.',
   array['RYT-500', 'Recovery & Sleep Coach'],
   array['yoga', 'mobility', 'recovery'], 4.7, 54, 150)
) as v(email, title, years, about, credentials, specialties, rating, reviews, clients)
join public.profiles pr on pr.email = v.email
on conflict (id) do update set
  title = excluded.title, years_coaching = excluded.years_coaching,
  about = excluded.about, credentials = excluded.credentials,
  specialties = excluded.specialties, rating_avg = excluded.rating_avg,
  review_count = excluded.review_count, client_count = excluded.client_count,
  verification_status = excluded.verification_status;

insert into public.expert_services
  (id, expert_user_id, status, name, description, detail_bullets, category,
   fulfillment, pricing_model, price_cents, duration_weeks, response_time)
select v.id::uuid, pr.id, 'live'::service_status, v.name, v.description,
       v.bullets, v.category, v.fulfillment::fulfillment_type,
       v.pricing::pricing_model, v.price, v.weeks, v.rt::response_time
from (values
  ('e0000000-0000-4000-8000-000000000101', 'amelia@wiseworkout.test',
   '8-Week Strength Foundation', 'Progressive full-body block with weekly check-ins.',
   array['3 sessions/week programming', 'Form review on request', 'Weekly adjustments'],
   'strength', 'coaching', 'one_time', 9500, 8, '24h'),
  ('e0000000-0000-4000-8000-000000000102', 'marcus@wiseworkout.test',
   'Race-Ready Run Plan', 'Personalised 10K/half build with pacing targets.',
   array['Weekly mileage plan', 'Pace zones from your history', 'Race-week taper'],
   'endurance', 'coaching', 'one_time', 11000, 10, '48h'),
  ('e0000000-0000-4000-8000-000000000103', 'elena@wiseworkout.test',
   'Recovery Reset', 'Four weeks of mobility + breathwork to absorb hard training.',
   array['2 guided sessions/week', 'Sleep & recovery checklist', 'Deload planning'],
   'mobility', 'coaching', 'recurring', 6000, 4, '48h')
) as v(id, email, name, description, bullets, category, fulfillment, pricing, price, weeks, rt)
join public.profiles pr on pr.email = v.email
on conflict (id) do update set
  status = excluded.status, name = excluded.name, description = excluded.description,
  detail_bullets = excluded.detail_bullets, category = excluded.category,
  price_cents = excluded.price_cents, duration_weeks = excluded.duration_weeks;

-- ============================================================================
-- §10 LANDING SITE — approved public testimonials from the demo athletes
-- (web/ marketing site; one per user, upserted).
-- ============================================================================

insert into public.public_testimonials
  (user_id, display_name, user_category, rating, body, status, submitted_at, reviewed_at)
select pr.id, v.display_name, v.user_category, v.rating, v.body,
       'approved'::public_testimonial_status,
       now() - (v.days_ago || ' days')::interval,
       now() - (v.days_ago - 1 || ' days')::interval
from (values
  ('free@wiseworkout.test', 'Mia P.', 'Free runner', 5,
   'Wise Workout helped me keep my training consistent. The progress summaries make it much easier to understand what changed week by week.', 34),
  ('premium@wiseworkout.test', 'Alex T.', 'Premium athlete', 5,
   'The advanced analytics are the reason I upgraded — workload ratio and HR zones straight from my sessions, no spreadsheet needed.', 21),
  ('jordan@wiseworkout.test', 'Jordan L.', 'Distance runner', 4,
   'The workout history is clean and easy to scan. I like seeing my routine and AI notes together instead of across separate apps.', 12),
  ('priya@wiseworkout.test', 'Priya N.', 'Yoga & trails', 5,
   'Challenges with friends keep me moving. The leaderboards update live and the streaks are weirdly motivating.', 6)
) as v(email, display_name, user_category, rating, body, days_ago)
join public.profiles pr on pr.email = v.email
on conflict (user_id) do update set
  display_name = excluded.display_name, user_category = excluded.user_category,
  rating = excluded.rating, body = excluded.body, status = excluded.status,
  submitted_at = excluded.submitted_at, reviewed_at = excluded.reviewed_at;

-- ============================================================================
-- §12 ADMIN PORTAL DEMO STATE — every portal page has live rows to triage:
-- a PENDING expert application (Noah), a PENDING testimonial (Leo), open +
-- resolved contact messages, and feedback in both states. Fixed UUIDs keep
-- re-runs idempotent.
-- ============================================================================

-- Noah's pending expert application (role stays 'free' until approval)
insert into public.expert_profiles
  (id, title, years_coaching, about, credentials, specialties,
   rating_avg, review_count, client_count, verification_status)
select id, 'Running Coach', 5,
       'Track-and-field background; I coach 10K and half-marathon blocks around full-time work schedules.',
       array['UESCA Certified Running Coach'], array['endurance', 'running'],
       0, 0, 0, 'pending'::verification_status
from public.profiles where email = 'noah@wiseworkout.test'
on conflict (id) do update set verification_status = 'pending';

insert into public.expert_verification_documents (id, user_id, doc_type, title, file_name)
select v.id::uuid, pr.id, v.doc_type::expert_doc_type, v.title, v.file_name
from (values
  ('d0000000-0000-4000-8000-000000000201', 'identity',      'NRIC (front)',      'nric-front.jpg'),
  ('d0000000-0000-4000-8000-000000000202', 'certification', 'UESCA certificate', 'uesca-cert.pdf')
) as v(id, doc_type, title, file_name)
cross join (select id from public.profiles where email = 'noah@wiseworkout.test') pr
on conflict (id) do nothing;

-- Pending testimonial from Leo (his first — Mia/Alex/Jordan/Priya are approved)
insert into public.public_testimonials (user_id, display_name, user_category, rating, body, status)
select id, 'Leo C.', 'Cyclist', 5,
       'Century prep was way easier with the ride history and calorie numbers in one place. The challenges got my whole group on it.'
       , 'pending'
from public.profiles where email = 'leo@wiseworkout.test'
on conflict (user_id) do update set status = 'pending', body = excluded.body,
  display_name = excluded.display_name, user_category = excluded.user_category, rating = excluded.rating;

-- Contact inbox: two open, one already resolved
insert into public.contact_messages (id, submitter_name, submitter_email, message, status, response, created_at) values
  ('d0000000-0000-4000-8000-000000000301', 'Taylor Ng', 'taylor.ng@example.com',
   'Do you support corporate wellness plans for teams of 20-50 people?', 'open', null, now() - interval '2 days'),
  ('d0000000-0000-4000-8000-000000000302', 'Wei Lin', 'wei.lin@example.com',
   'Does the app work with a Polar H10 chest strap?', 'open', null, now() - interval '10 hours'),
  ('d0000000-0000-4000-8000-000000000303', 'Sofia Mendes', 'sofia.m@example.com',
   'Is my workout data private? Who can see my notes?', 'resolved',
   'Yes — workout notes are always private (enforced at the database level), and you choose what to share to the feed.', now() - interval '6 days')
on conflict (id) do update set status = excluded.status, response = excluded.response;

-- Feedback: one new bug, one new feature request, one already reviewed
insert into public.feedback (id, user_id, category, body, status, created_at)
select v.id::uuid, pr.id, v.category::feedback_category, v.body, v.status::feedback_status, now() - v.age
from (values
  ('d0000000-0000-4000-8000-000000000401', 'free@wiseworkout.test', 'feature_request',
   'Would love interval timers during freeform workouts.', 'new', interval '1 day'),
  ('d0000000-0000-4000-8000-000000000402', 'premium@wiseworkout.test', 'bug',
   'The pace chart flickers when I rotate the phone mid-session.', 'new', interval '3 days'),
  ('d0000000-0000-4000-8000-000000000403', 'jordan@wiseworkout.test', 'general',
   'Loving the challenges — leaderboard updates feel instant.', 'reviewed', interval '8 days')
) as v(id, email, category, body, status, age)
join public.profiles pr on pr.email = v.email
on conflict (id) do update set status = excluded.status, body = excluded.body;

-- Re-enable the guard.
alter table public.profiles enable trigger trg_guard_profile_privileged_columns;
