-- Atomic "end a workout" use case (EndWorkoutSession control → this RPC).
-- One transaction: finalize the session, bump XP, recompute the weekly streak,
-- and emit a level_up post if a 200-XP threshold was crossed.
-- SECURITY DEFINER so the multi-table write is atomic; still owner-gated via auth.uid().

create or replace function public.end_workout_session(
  p_session_id uuid,
  p_metrics    jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user        uuid;
  v_started     timestamptz;
  v_planned     uuid;
  v_slug        text;
  v_is_cardio   boolean;
  v_duration    int;
  v_distance    int;
  v_km          numeric;
  v_xp_gain     int;
  v_old_xp      int;
  v_new_xp      int;
  v_old_level   int;
  v_new_level   int;
  v_streak      int;
begin
  select ws.user_id, ws.started_at, ws.planned_workout_id, wt.slug
    into v_user, v_started, v_planned, v_slug
  from workout_sessions ws
  join workout_types wt on wt.id = ws.workout_type_id
  where ws.id = p_session_id;

  if v_user is null then
    raise exception 'Workout session % not found', p_session_id;
  end if;
  if v_user <> auth.uid() then
    raise exception 'Not your workout session';
  end if;

  v_is_cardio := v_slug in ('running','cycling','swimming','walking','hiit','rowing','hiking');
  v_duration  := coalesce((p_metrics->>'duration_seconds')::int,
                          greatest(0, extract(epoch from (now() - v_started))::int));
  v_distance  := nullif(p_metrics->>'distance_meters','')::int;
  v_km        := coalesce(v_distance, 0) / 1000.0;

  update workout_sessions set
    ended_at        = now(),
    duration_seconds = v_duration,
    distance_meters = v_distance,
    calories_burned = nullif(p_metrics->>'calories_burned','')::int,
    avg_heart_rate  = nullif(p_metrics->>'avg_heart_rate','')::int,
    max_heart_rate  = nullif(p_metrics->>'max_heart_rate','')::int,
    track_points    = case when p_metrics ? 'track_points' then p_metrics->'track_points' else track_points end,
    track_source    = case when p_metrics ? 'track_points' then 'live'::track_source else track_source end
  where id = p_session_id;

  v_xp_gain := 20 + floor(v_duration / 60.0)::int
             + case when v_is_cardio then floor(v_km * 5)::int else 0 end
             + case when v_planned is not null then 10 else 0 end;

  select coalesce(total_xp, 0) into v_old_xp from fitness_profiles where id = v_user;
  v_new_xp    := v_old_xp + v_xp_gain;
  v_old_level := floor(v_old_xp / 200) + 1;
  v_new_level := floor(v_new_xp / 200) + 1;

  with weeks as (
    select distinct date_trunc('week', ended_at)::date as wk
    from workout_sessions
    where user_id = v_user and ended_at is not null
  ),
  ranked as (
    select wk, row_number() over (order by wk desc) as rn from weeks
  )
  select count(*) into v_streak
  from ranked
  where wk = (date_trunc('week', now())::date - ((rn - 1) * 7)::int);

  update fitness_profiles
    set total_xp = v_new_xp, current_streak = coalesce(v_streak, 1)
  where id = v_user;

  if v_new_level > v_old_level then
    insert into posts (user_id, kind, level) values (v_user, 'level_up', v_new_level);
  end if;

  return jsonb_build_object(
    'session_id', p_session_id,
    'xp_gained', v_xp_gain,
    'total_xp', v_new_xp,
    'old_level', v_old_level,
    'new_level', v_new_level,
    'leveled_up', v_new_level > v_old_level,
    'current_streak', coalesce(v_streak, 1)
  );
end;
$$;

revoke execute on function public.end_workout_session(uuid, jsonb) from public, anon;
grant execute on function public.end_workout_session(uuid, jsonb) to authenticated;
