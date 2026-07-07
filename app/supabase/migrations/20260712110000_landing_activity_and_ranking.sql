-- Landing-site data upgrades:
--   1. landing_activity_series() — real platform-activity numbers for the
--      statistics chart (weekly session count + active minutes, zero-filled).
--   2. landing_featured_experts() v2 — featured experts are now ranked by an
--      explicit ALGORITHM, not manual selection:
--
--        IMDb-style Bayesian weighted rating (the "true Bayesian estimate"):
--          WR = (v / (v + m)) · R  +  (m / (v + m)) · C
--        where R = the expert's stored rating_avg,
--              v = the expert's review_count,
--              m = 10 (confidence prior: reviews needed before an expert's own
--                      average dominates the global mean),
--              C = mean rating_avg across all verified experts.
--        Rank by WR desc; ties broken by review_count, then client_count.
--
--      This prevents a 5.0★ expert with 2 reviews outranking a 4.8★ expert
--      with 100 reviews. The score is returned so clients can log it.

-- ============================================================================
-- 1. PLATFORM ACTIVITY SERIES (public-safe aggregates only)
-- ============================================================================

create or replace function public.landing_activity_series(p_weeks int default 12)
returns table (week_start date, session_count int, active_minutes int)
language sql stable
security definer set search_path = public
as $$
  with weeks as (
    select generate_series(
      date_trunc('week', now()) - ((least(greatest(coalesce(p_weeks, 12), 4), 26) - 1) || ' weeks')::interval,
      date_trunc('week', now()),
      '1 week'::interval
    )::date as week_start
  )
  select w.week_start,
         count(s.id)::int,
         coalesce(sum(s.duration_seconds) / 60, 0)::int
  from weeks w
  left join workout_sessions s
    on s.ended_at is not null
   and date_trunc('week', s.started_at)::date = w.week_start
  group by w.week_start
  order by w.week_start;
$$;

revoke all on function public.landing_activity_series(int) from public;
grant execute on function public.landing_activity_series(int) to anon, authenticated;

-- ============================================================================
-- 2. FEATURED-EXPERT RANKING v2 (Bayesian weighted rating, m = 10)
-- ============================================================================

drop function public.landing_featured_experts(int);

create function public.landing_featured_experts(p_limit int default 3)
returns table (
  user_id uuid, display_name text, avatar_url text, title text,
  years_coaching int, about text, credentials text[], specialties text[],
  rating_avg numeric, review_count int, client_count int, score numeric
)
language sql stable
security definer set search_path = public
as $$
  with verified as (
    select ep.*, p.first_name, p.last_name, p.avatar_url as p_avatar
    from expert_profiles ep
    join profiles p on p.id = ep.id
    where ep.verification_status = 'verified'
      and coalesce(p.status::text, 'active') <> 'suspended'
  ),
  prior as (select coalesce(avg(rating_avg), 4.0) as c from verified)
  select v.id,
         trim(coalesce(v.first_name, '') || ' ' || coalesce(v.last_name, '')),
         v.p_avatar, v.title, v.years_coaching, v.about,
         v.credentials, v.specialties, v.rating_avg, v.review_count, v.client_count,
         round(
           (v.review_count::numeric / (v.review_count + 10)) * v.rating_avg
           + (10.0 / (v.review_count + 10)) * prior.c,
           3
         ) as score
  from verified v, prior
  order by score desc, v.review_count desc, v.client_count desc
  limit greatest(1, least(coalesce(p_limit, 3), 12));
$$;

revoke all on function public.landing_featured_experts(int) from public;
grant execute on function public.landing_featured_experts(int) to anon, authenticated;
