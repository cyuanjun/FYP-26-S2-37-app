-- Manual workout entry (US13): the ONLY change vs 20260610120000 is an
-- optional `started_at` in p_metrics. Manual sessions reuse the exact same
-- finalize path (XP, weekly streak, level_up post) — the app inserts a
-- started session with connected_device_id = null, then calls this RPC with
-- the user-entered start time + duration. When `started_at` is present the
-- session is backdated and ended_at derives from start + duration (capped at
-- now); live sessions keep the ended_at = now() behaviour, bit for bit.

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
  v_user         uuid;
  v_started      timestamptz;
  v_planned      uuid;
  v_slug         text;
  v_is_cardio    boolean;
  v_manual_start timestamptz;
  v_duration     int;
  v_distance     int;
  v_km           numeric;
  v_xp_gain      int;
  v_old_xp       int;
  v_new_xp       int;
  v_old_level    int;
  v_new_level    int;
  v_streak       int;
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

  -- Manual entry: an explicit start time backdates the session.
  v_manual_start := nullif(p_metrics->>'started_at','')::timestamptz;
  if v_manual_start is not null then
    if v_manual_start > now() then
      raise exception 'Manual start time cannot be in the future';
    end if;
    v_started := v_manual_start;
  end if;

  v_is_cardio := v_slug in ('running','cycling','swimming','walking','hiit','rowing','hiking');
  v_duration  := coalesce((p_metrics->>'duration_seconds')::int,
                          greatest(0, extract(epoch from (now() - v_started))::int));
  v_distance  := nullif(p_metrics->>'distance_meters','')::int;
  v_km        := coalesce(v_distance, 0) / 1000.0;

  update workout_sessions set
    started_at      = v_started,
    ended_at        = case when v_manual_start is not null
                           then least(now(), v_started + make_interval(secs => v_duration))
                           else now() end,
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
