-- Live-computed challenge leaderboards (11-social.md "Progress / ranking
-- computation"): no stored currentValue — aggregate each participant's
-- qualifying sessions per the challenge metric. One set-returning call serves
-- every card on the Challenges tab (pass all visible challenge ids at once).
--
-- SECURITY INVOKER on purpose: it reads public_workout_sessions, the existing
-- privacy view that exposes everyone's session metrics but never notes.
--
-- challenge_result auto-posts at the deadline need a scheduler and are
-- deferred; the feed renders that post kind whenever rows exist.

create or replace function public.challenge_leaderboards(p_challenge_ids uuid[])
returns table (challenge_id uuid, user_id uuid, value numeric, rank bigint)
language sql stable set search_path = public
as $$
  with agg as (
    select c.id as challenge_id, cp.user_id, c.metric,
      case c.metric
        when 'total_distance'   then sum(coalesce(s.distance_meters, 0))
        when 'total_sessions'   then count(s.id)
        when 'total_calories'   then sum(coalesce(s.calories_burned, 0))
        when 'active_days'      then count(distinct (s.ended_at at time zone 'utc')::date)
        when 'fastest_time'     then min(s.duration_seconds)
        when 'longest_distance' then max(coalesce(s.distance_meters, 0))
        when 'most_calories'    then max(coalesce(s.calories_burned, 0))
      end::numeric as value
    from challenges c
    join challenge_participants cp on cp.challenge_id = c.id
    left join public_workout_sessions s
      on  s.user_id = cp.user_id
      and s.ended_at is not null
      and s.started_at between c.started_at and c.ended_at
      and (c.workout_type_id is null or s.workout_type_id = c.workout_type_id)
      and (c.metric <> 'fastest_time' or s.duration_seconds > 0)
      -- best_of: a locked workout_session_id restricts the entry; otherwise
      -- (and always for accumulator) every qualifying session counts.
      and (c.metric_kind = 'accumulator'
           or cp.workout_session_id is null
           or s.id = cp.workout_session_id)
    where c.id = any (p_challenge_ids)
    group by c.id, c.metric, cp.user_id
  )
  select a.challenge_id, a.user_id, a.value,
         rank() over (
           partition by a.challenge_id
           order by case when a.metric =  'fastest_time' then a.value end asc  nulls last,
                    case when a.metric <> 'fastest_time' then a.value end desc nulls last)
  from agg a
  where a.value is not null and a.value > 0;   -- zero-progress excluded (spec)
$$;

revoke execute on function public.challenge_leaderboards(uuid[]) from public, anon;
grant execute on function public.challenge_leaderboards(uuid[]) to authenticated;
