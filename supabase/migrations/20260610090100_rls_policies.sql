-- Wise Workout (FYP-26-S2-37) — Row-Level Security starter
-- Turns each documented invariant from database-v1.md into a policy. This is where the project
-- earns its security marks (build-plan §3). Policies target Supabase's `authenticated` role unless noted.
--
-- Column-level privacy (which RLS alone can't express) is handled with two SECURITY DEFINER views:
--   • public_profiles          — safe identity columns + level/streak; hides email & notification_prefs.
--   • public_workout_sessions  — every session column EXCEPT `notes` (the always-private invariant).
-- The app reads OTHER users' data through these views; base tables stay owner-scoped.
--
-- This is a STARTER: it covers the core invariants. Multi-step/atomic mutations (endWorkoutSession bumping
-- XP + emitting a level_up post, startPremium, etc.) should land as SECURITY DEFINER RPCs later (build-plan §3);
-- a few column-level rules (no self role-escalation) are enforced by trigger below.

-- ============================================================================
-- HELPERS
-- ============================================================================

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

-- ============================================================================
-- ENABLE RLS ON EVERY TABLE
-- ============================================================================

alter table profiles                       enable row level security;
alter table fitness_profiles               enable row level security;
alter table connected_devices              enable row level security;
alter table workout_types                  enable row level security;
alter table health_tags                    enable row level security;
alter table fitness_goals                  enable row level security;
alter table fitness_plans                  enable row level security;
alter table planned_workouts               enable row level security;
alter table workout_sessions               enable row level security;
alter table exercise_logs                  enable row level security;
alter table challenges                     enable row level security;
alter table posts                          enable row level security;
alter table post_likes                     enable row level security;
alter table post_comments                  enable row level security;
alter table challenge_participants         enable row level security;
alter table follows                        enable row level security;
alter table expert_categories              enable row level security;
alter table expert_profiles                enable row level security;
alter table expert_services                enable row level security;
alter table service_requests               enable row level security;
alter table expert_reviews                 enable row level security;
alter table expert_verification_documents  enable row level security;
alter table deliverables                   enable row level security;
alter table feedback                       enable row level security;
alter table contact_messages               enable row level security;
alter table subscriptions                  enable row level security;

-- ============================================================================
-- PROFILES — base table is self/admin only; others read via public_profiles view.
-- ============================================================================

create policy profiles_select_self_or_admin on profiles
  for select to authenticated using (id = auth.uid() or is_admin());

create policy profiles_update_self on profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy profiles_admin_update on profiles
  for update to authenticated using (is_admin()) with check (is_admin());

-- (INSERT is via the on_auth_user_created trigger; no client INSERT policy by design.)

-- Prevent a non-admin from escalating their own role or self-suspending/un-suspending.
-- "Only admins can change role/status" (database-v1.md, build-plan §3).
create or replace function public.guard_profile_privileged_columns()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if not is_admin() then
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

create trigger trg_guard_profile_privileged_columns
  before update on profiles
  for each row execute function public.guard_profile_privileged_columns();

-- Safe public view: identity + computed level/streak. No email, no notification_prefs.
-- Level = floor(total_xp / 200) + 1 (database-v1.md FitnessProfile note).
create view public_profiles
with (security_invoker = false) as
  select
    p.id,
    p.role,
    p.first_name,
    p.last_name,
    p.username,
    p.avatar_url,
    p.bio,
    coalesce(fp.total_xp, 0)                       as total_xp,
    coalesce(floor(coalesce(fp.total_xp, 0) / 200) + 1, 1) as level,
    coalesce(fp.current_streak, 0)                as current_streak
  from profiles p
  left join fitness_profiles fp on fp.id = p.id;

grant select on public_profiles to authenticated;

-- ============================================================================
-- FITNESS PROFILE / GOALS / PLANS — owner-scoped (sensitive body metrics).
-- Public level/streak is exposed via public_profiles above, not this table.
-- ============================================================================

create policy fitness_profiles_owner on fitness_profiles
  for all to authenticated using (id = auth.uid() or is_admin()) with check (id = auth.uid());

create policy fitness_goals_owner on fitness_goals
  for all to authenticated using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

create policy fitness_plans_owner on fitness_plans
  for all to authenticated using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

-- Planned workouts inherit their plan's owner.
create policy planned_workouts_owner on planned_workouts
  for all to authenticated using (
    exists (select 1 from fitness_plans fp where fp.id = fitness_plan_id and (fp.user_id = auth.uid() or is_admin()))
  ) with check (
    exists (select 1 from fitness_plans fp where fp.id = fitness_plan_id and fp.user_id = auth.uid())
  );

create policy connected_devices_owner on connected_devices
  for all to authenticated using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

-- ============================================================================
-- WORKOUT SESSIONS — owner-only on the base table (protects `notes`).
-- Social feed / challenge leaderboards / public profiles read public_workout_sessions (no notes).
-- ============================================================================

create policy workout_sessions_owner on workout_sessions
  for all to authenticated using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

-- Exercise logs inherit their session's owner.
create policy exercise_logs_owner on exercise_logs
  for all to authenticated using (
    exists (select 1 from workout_sessions ws where ws.id = workout_session_id and (ws.user_id = auth.uid() or is_admin()))
  ) with check (
    exists (select 1 from workout_sessions ws where ws.id = workout_session_id and ws.user_id = auth.uid())
  );

-- Notes-free projection for everyone-else reads. Runs as view owner (bypasses base-table RLS),
-- so it exposes session metrics platform-wide WHILE keeping `notes` unreadable by anyone but the owner.
create view public_workout_sessions
with (security_invoker = false) as
  select
    id, user_id, workout_type_id, planned_workout_id, connected_device_id,
    started_at, ended_at, duration_seconds, calories_burned,
    avg_heart_rate, max_heart_rate, distance_meters, feel_rating,
    custom_name, track_points, track_source
    -- `notes` intentionally omitted — always private (database-v1.md WorkoutSession).
  from workout_sessions;

grant select on public_workout_sessions to authenticated;

-- ============================================================================
-- CATALOGS — readable by all; admin-managed, with user custom-entry inserts.
-- ============================================================================

create policy workout_types_read on workout_types for select to authenticated using (true);
create policy workout_types_admin_write on workout_types for all to authenticated
  using (is_admin()) with check (is_admin());
-- Users may add custom workout types (PickerModal search+add) for themselves.
create policy workout_types_user_custom_insert on workout_types for insert to authenticated
  with check (is_custom and created_by_user_id = auth.uid());

create policy health_tags_read on health_tags for select to authenticated using (true);
create policy health_tags_admin_write on health_tags for all to authenticated
  using (is_admin()) with check (is_admin());
create policy health_tags_user_custom_insert on health_tags for insert to authenticated
  with check (is_custom and created_by_user_id = auth.uid());

create policy expert_categories_read on expert_categories for select to authenticated using (true);
create policy expert_categories_admin_write on expert_categories for all to authenticated
  using (is_admin()) with check (is_admin());

-- ============================================================================
-- SOCIAL — public read across the platform; authors write their own rows.
-- ============================================================================

create policy posts_read on posts for select to authenticated using (true);
create policy posts_author_write on posts for all to authenticated
  using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

create policy post_likes_read on post_likes for select to authenticated using (true);
create policy post_likes_owner on post_likes for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy post_comments_read on post_comments for select to authenticated using (true);
create policy post_comments_author on post_comments for all to authenticated
  using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

create policy challenges_read on challenges for select to authenticated using (true);
create policy challenges_creator on challenges for all to authenticated
  using (created_by_user_id = auth.uid() or is_admin()) with check (created_by_user_id = auth.uid());

create policy challenge_participants_read on challenge_participants for select to authenticated using (true);
create policy challenge_participants_owner on challenge_participants for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Follows: anyone can read the graph; a user writes only rows where they are the follower.
-- (The mutual A→B + B→A pair is written by the followUser/unfollowUser control, one row each.)
create policy follows_read on follows for select to authenticated using (true);
create policy follows_owner on follows for all to authenticated
  using (follower_id = auth.uid()) with check (follower_id = auth.uid());

-- ============================================================================
-- EXPERTS — public marketplace reads; expert owns their listings/profile.
-- ============================================================================

create policy expert_profiles_read on expert_profiles for select to authenticated using (true);
create policy expert_profiles_owner on expert_profiles for all to authenticated
  using (id = auth.uid() or is_admin()) with check (id = auth.uid());

-- Browsable services: live ones to everyone; the owning expert (and admin) see all their statuses.
create policy expert_services_read_live on expert_services for select to authenticated
  using (status = 'live' or expert_user_id = auth.uid() or is_admin());
create policy expert_services_owner_write on expert_services for all to authenticated
  using (expert_user_id = auth.uid() or is_admin()) with check (expert_user_id = auth.uid());

-- Reviews are public; the reviewer writes their own (gated to a completed request at the app/RPC layer).
create policy expert_reviews_read on expert_reviews for select to authenticated using (true);
create policy expert_reviews_author on expert_reviews for all to authenticated
  using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

-- Verification docs: only the submitting expert and admins (the #27.1 reviewer).
create policy expert_docs_owner_or_admin on expert_verification_documents for all to authenticated
  using (user_id = auth.uid() or is_admin()) with check (user_id = auth.uid());

-- Service requests: visible to the client and the expert; either party acts within their lane.
create policy service_requests_party_read on service_requests for select to authenticated
  using (user_id = auth.uid() or expert_user_id = auth.uid() or is_admin());
create policy service_requests_client_insert on service_requests for insert to authenticated
  with check (user_id = auth.uid());
-- Client may cancel; expert may accept/complete. Column-level transition rules belong in an RPC;
-- here we gate row access to the two parties.
create policy service_requests_party_update on service_requests for update to authenticated
  using (user_id = auth.uid() or expert_user_id = auth.uid() or is_admin())
  with check (user_id = auth.uid() or expert_user_id = auth.uid() or is_admin());

-- Deliverables: the engagement's expert writes them; both parties read.
create policy deliverables_party_read on deliverables for select to authenticated
  using (
    exists (
      select 1 from service_requests sr
      where sr.id = service_request_id
        and (sr.user_id = auth.uid() or sr.expert_user_id = auth.uid() or is_admin())
    )
  );
create policy deliverables_expert_write on deliverables for all to authenticated
  using (
    exists (select 1 from service_requests sr where sr.id = service_request_id
            and (sr.expert_user_id = auth.uid() or is_admin()))
  )
  with check (
    exists (select 1 from service_requests sr where sr.id = service_request_id and sr.expert_user_id = auth.uid())
  );

-- ============================================================================
-- SUPPORT
-- ============================================================================

-- Feedback: a user creates their own; only admins read/triage (#28). Write-only for the submitter.
create policy feedback_insert_self on feedback for insert to authenticated
  with check (user_id = auth.uid());
create policy feedback_admin_read on feedback for select to authenticated using (is_admin());
create policy feedback_admin_update on feedback for update to authenticated
  using (is_admin()) with check (is_admin());

-- Contact messages: submitted by anyone from the marketing site (anon allowed); only admins read/answer.
create policy contact_insert_anyone on contact_messages for insert to anon, authenticated with check (true);
create policy contact_admin_read on contact_messages for select to authenticated using (is_admin());
create policy contact_admin_update on contact_messages for update to authenticated
  using (is_admin()) with check (is_admin());

-- Subscriptions: owner + admin. Creation/cancel run through startPremium/cancel controls (RPC later).
create policy subscriptions_owner on subscriptions for all to authenticated
  using (id = auth.uid() or is_admin()) with check (id = auth.uid());

-- ============================================================================
-- HARDENING — keep SECURITY DEFINER trigger functions off the PostgREST RPC surface.
-- Triggers still fire (they run as the table owner regardless of EXECUTE grants),
-- so revoking client EXECUTE is safe and clears the Supabase security advisor warning.
-- `is_admin()` is deliberately left executable: RLS policies reference it, and revoking
-- EXECUTE from `authenticated` would make those policies raise "permission denied".
-- ============================================================================

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.guard_profile_privileged_columns() from public, anon, authenticated;
