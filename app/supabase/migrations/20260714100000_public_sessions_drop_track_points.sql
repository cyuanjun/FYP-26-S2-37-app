-- Location-privacy fix: public_workout_sessions (the notes-free, view-owner
-- projection everyone-else reads) also exposed `track_points` - raw GPS
-- breadcrumbs - to every authenticated user platform-wide. No feature reads
-- that column through the view (feed, profile stats, and challenge leaderboards
-- only use metrics; owners read their own route from the base table), so it is
-- dropped from the projection. Now both `notes` and raw location are owner-only.
--
-- CREATE OR REPLACE VIEW can't drop a column, so drop + recreate. Only a
-- function (challenge_leaderboards) references the view by name - not a hard
-- dependency - so the drop is safe and the function re-resolves at call time.

drop view if exists public_workout_sessions;

create view public_workout_sessions
with (security_invoker = false) as
  select
    id, user_id, workout_type_id, planned_workout_id, connected_device_id,
    started_at, ended_at, duration_seconds, calories_burned,
    avg_heart_rate, max_heart_rate, distance_meters, feel_rating,
    custom_name, track_source
    -- `notes` and `track_points` intentionally omitted - always private.
  from workout_sessions;

grant select on public_workout_sessions to authenticated;
