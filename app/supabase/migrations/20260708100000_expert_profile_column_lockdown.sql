-- Column-level lockdown on expert_profiles, ahead of the #24.1 Manage
-- Professional Info UI. The owner RLS policy scopes *rows*, but UPDATE was
-- table-wide — once experts can edit their own row from the app, nothing
-- would stop a crafted request from also bumping rating_avg / review_count /
-- client_count / total_earned_cents or self-setting verification_status.
--
-- Postgres column-level grants close that: authenticated may UPDATE only the
-- self-descriptive columns. The aggregate/verification columns stay writable
-- solely through the SECURITY DEFINER RPCs (which run as the table owner and
-- bypass grants): submit_expert_review → rating_avg/review_count,
-- complete_service_request → client_count/total_earned_cents. Admin
-- verification (#27.1) lands later as an RPC for the same reason.
--
-- INSERT stays table-wide (expert rows are provisioned by seed/admin, and the
-- RLS with-check still requires id = auth.uid()).

revoke update on public.expert_profiles from anon, authenticated;
grant update (title, years_coaching, about, credentials, specialties)
  on public.expert_profiles to authenticated;
