-- Wise Workout (FYP-26-S2-37) — initial schema
-- Generated from docs/reference/database-v1.md, aligned to the TDM v3.0 §8 ERD (26 entities).
-- Target: Supabase Postgres. Naming: snake_case tables/columns (Postgres + Supabase convention);
-- the docs use PascalCase entities — freezed/json_serializable map via @JsonKey on the Dart side.
--
-- Mapping decisions (locked, see CLAUDE.md "Locked architecture"):
--   • The `User` entity becomes `profiles`, keyed on auth.users.id (Supabase Auth owns identity/password).
--   • Shared-key 1:1 specializations off profiles.id: fitness_profiles, expert_profiles, subscriptions.
--   • Merged junctions are array columns: profiles.followed_expert_ids,
--     fitness_profiles.health_tag_ids / preferred_workout_type_ids.
--   • JSON blobs (jsonb): notification_prefs, planned_workouts.segments, workout_sessions.track_points,
--     deliverables.sections.
--
-- RLS lives in the next migration (20260610090100_rls_policies.sql). Tables are created RLS-off here;
-- that migration enables it and adds policies. Seed catalogs live in supabase/seed.sql.

create extension if not exists pgcrypto;  -- gen_random_uuid()

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

create type user_role               as enum ('free', 'premium', 'expert', 'admin');
create type user_status             as enum ('active', 'suspended');         -- profiles.status null = active
create type preferred_units         as enum ('metric', 'imperial');
create type sex                     as enum ('female', 'male', 'other');
create type activity_level          as enum ('sedentary', 'light', 'moderate', 'active');
create type training_experience     as enum ('beginner', 'intermediate', 'advanced');
create type health_tag_kind         as enum ('diet', 'allergy', 'injury');
create type primary_goal            as enum ('lose_weight', 'build_muscle', 'improve_endurance', 'maintain_fitness');
create type target_unit             as enum ('kg', 'minutes', 'reps', 'km', 'steps_per_day');
create type generation_strategy     as enum ('basic', 'personalised');
create type device_type             as enum ('apple_watch', 'fitbit', 'garmin', 'polar', 'oura', 'phone_sensors', 'other');
create type feel_rating             as enum ('great', 'good', 'okay', 'tough');
create type track_source            as enum ('live', 'gpx');
create type post_kind               as enum ('workout_share', 'challenge_result', 'level_up');
create type challenge_visibility    as enum ('public', 'invite_only');
create type challenge_metric_kind   as enum ('accumulator', 'best_of');
create type challenge_metric        as enum ('total_distance', 'total_sessions', 'total_calories',
                                             'active_days', 'fastest_time', 'longest_distance', 'most_calories');
create type verification_status     as enum ('pending', 'verified', 'rejected');
create type expert_doc_type         as enum ('identity', 'certification');
create type service_status          as enum ('draft', 'live', 'archived');
create type fulfillment_type        as enum ('workout_plan', 'nutrition', 'review', 'session', 'coaching');
create type pricing_model           as enum ('one_time', 'recurring');
create type response_time           as enum ('24h', '48h', '72h');
create type service_request_status  as enum ('pending', 'accepted', 'completed', 'cancelled');
create type feedback_category       as enum ('bug', 'feature_request', 'general');
create type feedback_status         as enum ('new', 'reviewed');
create type contact_status          as enum ('open', 'resolved');
create type subscription_status     as enum ('active', 'cancelled', 'past_due');

-- ============================================================================
-- IDENTITY & AUTH
-- ============================================================================

-- User → profiles (keyed on auth.users.id). email mirrors auth.users.email for in-app reads (#14).
create table profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  email               text not null unique,
  role                user_role not null default 'free',
  status              user_status,                          -- null = active; admin sets 'suspended' on #26.1
  first_name          text,
  last_name           text,
  username            text unique,                          -- @handle, stored without leading @
  avatar_url          text,
  preferred_units     preferred_units not null default 'metric',
  bio                 text,
  notification_prefs  jsonb not null default '{}'::jsonb,   -- NotificationTypeKey -> bool (#13.4)
  followed_expert_ids uuid[] not null default '{}',         -- one-way marketplace bookmarks (#6/#6.1)
  created_at          timestamptz not null default now()
);

-- FitnessProfile — 1:1 specialization for athlete roles (shared key).
create table fitness_profiles (
  id                         uuid primary key references profiles (id) on delete cascade,
  date_of_birth              date,
  sex                        sex,
  height_cm                  int,
  weight_kg                  numeric(5,2),
  activity_level             activity_level,
  training_experience        training_experience,
  resting_heart_rate         int,                           -- bpm; null = use population default 60
  health_tag_ids             uuid[] not null default '{}',  -- → health_tags (diet/allergy/injury), #13.1
  preferred_workout_type_ids uuid[] not null default '{}',  -- → workout_types, #13.1
  total_xp                   int not null default 0,
  current_streak             int not null default 0         -- consecutive Mon–Sun weeks with ≥1 ended workout
);

create table connected_devices (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references profiles (id) on delete cascade,
  device_type    device_type not null,
  device_name    text not null,
  last_synced_at timestamptz,
  is_active      boolean not null default true
);
create index idx_connected_devices_user on connected_devices (user_id);

-- ============================================================================
-- CATALOGS
-- ============================================================================

create table workout_types (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null unique,
  slug               text not null unique,                  -- drives the rendered glyph
  is_custom          boolean not null default false,
  created_by_user_id uuid references profiles (id) on delete set null   -- set when is_custom
);

create table health_tags (
  id                 uuid primary key default gen_random_uuid(),
  kind               health_tag_kind not null,
  name               text not null,
  is_custom          boolean not null default false,
  created_by_user_id uuid references profiles (id) on delete set null,
  unique (kind, name)                                       -- names unique within a kind
);

-- ============================================================================
-- TRAINING & ACTIVITY
-- ============================================================================

create table fitness_goals (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references fitness_profiles (id) on delete cascade,
  primary_goal          primary_goal not null,
  target_value          numeric(8,2),                       -- polymorphic; meaning set by target_unit
  target_unit           target_unit,
  starting_value        numeric(8,2),
  timeline_weeks        int,                                -- 4|8|12|16|24; null for maintain_fitness
  weekly_commitment_days int check (weekly_commitment_days between 1 and 7),
  created_at            timestamptz not null default now(),
  achieved_at           timestamptz                         -- null = active goal
);
create index idx_fitness_goals_user on fitness_goals (user_id);
-- One active goal per user (AchievedAt IS NULL).
create unique index uq_fitness_goals_active on fitness_goals (user_id) where achieved_at is null;

create table fitness_plans (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references fitness_profiles (id) on delete cascade,
  fitness_goal_id     uuid not null references fitness_goals (id) on delete cascade,
  name                text not null,
  description         text,
  duration_weeks      int not null,
  workouts_per_week   int not null,
  generation_strategy generation_strategy not null default 'basic',   -- basic=Free, personalised=Premium
  regenerated_count   int not null default 0,
  started_at          timestamptz,
  is_active           boolean not null default true
);
create index idx_fitness_plans_user on fitness_plans (user_id);
-- One active plan per user.
create unique index uq_fitness_plans_active on fitness_plans (user_id) where is_active;

create table planned_workouts (
  id               uuid primary key default gen_random_uuid(),
  fitness_plan_id  uuid not null references fitness_plans (id) on delete cascade,
  workout_type_id  uuid not null references workout_types (id),
  week_number      int not null,
  day_of_week      int not null check (day_of_week between 1 and 7),
  duration_minutes int not null,
  name             text,
  descriptor       text,
  order_index      int not null default 0,
  segments         jsonb,                                   -- Premium; WorkoutSegment[] {label, detail, sub?}
  coaching_cues    text[]                                   -- Premium
);
create index idx_planned_workouts_plan on planned_workouts (fitness_plan_id);

create table workout_sessions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references fitness_profiles (id) on delete cascade,
  workout_type_id     uuid not null references workout_types (id),
  planned_workout_id  uuid references planned_workouts (id) on delete set null,  -- null = free-form
  connected_device_id uuid references connected_devices (id) on delete set null, -- null = manual entry
  started_at          timestamptz not null,
  ended_at            timestamptz,
  duration_seconds    int not null default 0,
  calories_burned     int,
  avg_heart_rate      int,
  max_heart_rate      int,
  distance_meters     int,
  feel_rating         feel_rating,
  notes               text,                                 -- ALWAYS PRIVATE — enforced in RLS migration
  custom_name         text,
  track_points        jsonb,                                -- TrackPoint[] {t,hr?,cad?,elev?,pace?}; null = none
  track_source        track_source
);
create index idx_workout_sessions_user on workout_sessions (user_id);
create index idx_workout_sessions_type on workout_sessions (workout_type_id);
create index idx_workout_sessions_started on workout_sessions (started_at);

create table exercise_logs (
  id                 uuid primary key default gen_random_uuid(),
  workout_session_id uuid not null references workout_sessions (id) on delete cascade,
  exercise_name      text not null,
  sets               int not null check (sets >= 1),
  reps               int not null,
  weight_kg          numeric(5,2),                          -- null = bodyweight
  order_index        int not null default 0
);
create index idx_exercise_logs_session on exercise_logs (workout_session_id);

-- ============================================================================
-- SOCIAL
-- (challenges declared before posts: posts.challenge_id references challenges)
-- ============================================================================

create table challenges (
  id                 uuid primary key default gen_random_uuid(),
  created_by_user_id uuid references profiles (id) on delete set null,   -- null = system/curator-seeded
  name               text not null,
  short_name         text not null,
  description        text,
  icon               text not null,                         -- emoji glyph
  visibility         challenge_visibility not null default 'public',
  metric_kind        challenge_metric_kind not null,
  metric             challenge_metric not null,
  target_value       int,                                   -- required for accumulator; null for best_of
  workout_type_id    uuid references workout_types (id),    -- null = any type qualifies
  started_at         timestamptz not null,
  ended_at           timestamptz not null
);
create index idx_challenges_window on challenges (started_at, ended_at);

create table posts (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references profiles (id) on delete cascade,
  kind               post_kind not null,
  workout_session_id uuid references workout_sessions (id) on delete cascade,  -- kind=workout_share
  challenge_id       uuid references challenges (id) on delete cascade,        -- kind=challenge_result
  level              int,                                   -- kind=level_up
  body               text,                                  -- public caption
  created_at         timestamptz not null default now()
);
create index idx_posts_user on posts (user_id);
create index idx_posts_created on posts (created_at desc);

create table post_likes (
  post_id uuid not null references posts (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  primary key (post_id, user_id)
);

create table post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references posts (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  body       text not null,
  created_at timestamptz not null default now()
);
create index idx_post_comments_post on post_comments (post_id);

create table challenge_participants (
  challenge_id       uuid not null references challenges (id) on delete cascade,
  user_id            uuid not null references profiles (id) on delete cascade,
  workout_session_id uuid references workout_sessions (id) on delete set null,  -- best_of entry; null for accumulator
  primary key (challenge_id, user_id)
);
create index idx_challenge_participants_user on challenge_participants (user_id);

-- Mutual friendship — materialised as a pair of rows (A→B + B→A); see database-v1.md.
create table follows (
  follower_id  uuid not null references profiles (id) on delete cascade,
  following_id uuid not null references profiles (id) on delete cascade,
  primary key (follower_id, following_id),
  check (follower_id <> following_id)                       -- no self-follow
);
create index idx_follows_following on follows (following_id);

-- ============================================================================
-- EXPERTS
-- ============================================================================

create table expert_categories (
  id          text primary key,                             -- stable slug, e.g. 'strength'
  label       text not null,
  description text not null,
  is_active   boolean not null default true                 -- false = retired (hidden, still resolves labels)
);

-- ExpertProfile — 1:1 specialization for role='expert' (shared key).
create table expert_profiles (
  id                  uuid primary key references profiles (id) on delete cascade,
  title               text not null,
  years_coaching      int not null default 0,
  about               text not null default '',
  credentials         text[] not null default '{}',
  specialties         text[] not null default '{}',         -- expert_categories.id slugs (see app-level FK note)
  rating_avg          numeric(2,1) not null default 0,      -- stored lifetime aggregate
  review_count        int not null default 0,
  client_count        int not null default 0,
  verification_status verification_status not null default 'pending'
);

create table expert_services (
  id                     uuid primary key default gen_random_uuid(),
  expert_user_id         uuid not null references expert_profiles (id) on delete cascade,
  status                 service_status not null default 'draft',
  name                   text not null,
  description            text,
  detail_bullets         text[] not null default '{}',
  category               text not null references expert_categories (id),
  fulfillment            fulfillment_type not null,
  pricing_model          pricing_model not null default 'one_time',
  price_cents            int not null default 0,            -- 0 = unset (draft); simulated payment
  duration_weeks         int,                               -- null for one-off calls/reviews
  accepting_bookings     boolean not null default true,
  available_days         int[] not null default '{}',      -- 1–7 (Mon–Sun)
  max_concurrent_clients int,                               -- null = uncapped
  response_time          response_time not null default '48h',
  created_at             timestamptz not null default now()
);
create index idx_expert_services_expert on expert_services (expert_user_id);
create index idx_expert_services_category on expert_services (category);

create table service_requests (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references profiles (id) on delete cascade,        -- the client
  expert_service_id  uuid not null references expert_services (id) on delete cascade,
  expert_user_id     uuid not null references profiles (id) on delete cascade,        -- denormalised
  quoted_price_cents int not null,                          -- snapshot at request time (no payment in mock)
  status             service_request_status not null default 'pending',
  request_message    text not null,                         -- client's goal note (required)
  requested_at       timestamptz not null default now(),
  completed_at       timestamptz                            -- stamped on expert-marked completion (#23.1)
);
create index idx_service_requests_client on service_requests (user_id);
create index idx_service_requests_expert on service_requests (expert_user_id);

create table expert_reviews (
  id                 uuid primary key default gen_random_uuid(),
  expert_user_id     uuid not null references expert_profiles (id) on delete cascade,
  user_id            uuid not null references profiles (id) on delete cascade,        -- the reviewer (client)
  service_request_id uuid not null references service_requests (id) on delete cascade,
  rating             int not null check (rating between 1 and 5),
  body               text not null,
  created_at         timestamptz not null default now(),
  unique (service_request_id)                               -- one review per completed engagement
);
create index idx_expert_reviews_expert on expert_reviews (expert_user_id);

create table expert_verification_documents (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references expert_profiles (id) on delete cascade,  -- the expert who submitted
  doc_type    expert_doc_type not null,
  title       text not null,
  file_name   text not null,                                -- mock metadata; production stores a URL
  uploaded_at timestamptz not null default now()
);
create index idx_expert_docs_expert on expert_verification_documents (user_id);

create table deliverables (
  id                 uuid primary key default gen_random_uuid(),
  service_request_id uuid not null references service_requests (id) on delete cascade,
  title              text not null,
  note               text,
  sections           jsonb not null default '[]'::jsonb,    -- DeliverableSection[] {heading, items:WorkoutSegment[]}
  created_at         timestamptz not null default now()
);
create index idx_deliverables_request on deliverables (service_request_id);

-- ============================================================================
-- SUPPORT
-- ============================================================================

create table feedback (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles (id) on delete cascade,
  category   feedback_category not null,
  body       text not null,                                 -- ≥10 chars enforced client-side
  status     feedback_status not null default 'new',        -- admin triage (#28)
  created_at timestamptz not null default now()
);

-- Submitted on the external marketing site (open to anyone) — no User FK.
create table contact_messages (
  id              uuid primary key default gen_random_uuid(),
  submitter_name  text not null,
  submitter_email text not null,
  message         text not null,
  status          contact_status not null default 'open',
  response        text,                                     -- admin reply on #28.1; null while open
  created_at      timestamptz not null default now()
);

-- Subscription — 1:1 specialization for the premium role (shared key).
create table subscriptions (
  id          uuid primary key references profiles (id) on delete cascade,
  status      subscription_status not null default 'active',
  started_at  timestamptz not null default now(),
  renews_at   timestamptz not null,
  price_cents int not null default 999                      -- 999 = $9.99/mo (settled price)
);

-- ============================================================================
-- AUTH TRIGGER — create a profiles row on signup
-- Marketing-site signup writes auth.users; this mirrors the row into profiles.
-- first_name / username come from auth metadata when present.
-- ============================================================================

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
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
