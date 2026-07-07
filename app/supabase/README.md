# Supabase backend — Wise Workout (FYP-26-S2-37)

Postgres schema, RLS, and seed for the Wise Workout app. **Generated from
[docs/reference/database-v1.md](../../docs/app/reference/database-v1.md)**, which is aligned to the **TDM v5 §8
ERD** (the schema of record — 26 entities). Treat the docs as the source of truth: change the schema there
first, then regenerate these files — don't hand-edit DDL in isolation.

## Layout

| File | What |
|---|---|
| `migrations/20260610090000_init_schema.sql` | Extensions, 28 enum types, the 26 tables (FKs, checks, indexes), and the `on_auth_user_created` signup trigger. |
| `migrations/20260610090100_rls_policies.sql` | Helper `is_admin()`, RLS enabled on every table, per-table policies, the role/status self-escalation guard, the two privacy views, and the trigger-function EXECUTE revokes. |
| `migrations/20260610120000_end_workout_session_rpc.sql` | The `end_workout_session` SECURITY DEFINER RPC (finalize session + XP + weekly streak + level_up post). |
| `migrations/20260610130000_fitness_profile_on_signup.sql` | Extends the signup trigger to also create the 1:1 `fitness_profiles` row (so `workout_sessions.user_id` FK resolves); backfills existing accounts. |
| `migrations/20260612090000_onboarding_completed_at.sql` | First-login onboarding gate on `profiles` (existing accounts backfilled complete). |
| `migrations/20260612100000_private_custom_catalog_entries.sql` | RLS: custom workout types + health tags visible only to their creator. |
| `migrations/20260612110000_admin_write_policy_checks.sql` | RLS: admin write policies keep owner checks for users while allowing admins to update target-user rows. |
| `migrations/20260706090000_social_friend_rpcs.sql` | `add_friend`/`remove_friend` SECURITY DEFINER RPCs (mutual Follow pair). |
| `migrations/20260706090100_challenge_leaderboards.sql` | `challenge_leaderboards(uuid[])` live-aggregation function. |
| `migrations/20260706090200_baseline_table_grants.sql` | Local-stack parity for hosted's default table grants. |
| `migrations/20260707090000_expert_request_rpcs.sql` | ServiceRequest lifecycle RPCs + `submit_expert_review` + grants lockdown. |
| `migrations/20260707100000_expert_earnings.sql` | `expert_profiles.total_earned_cents` aggregate (complete adds quoted price). |
| `migrations/20260708090000_start_premium_rpc.sql` | `start_premium()` (role flip past the guard via a txn-local flag) + subscriptions upsert. |
| `migrations/20260708100000_expert_profile_column_lockdown.sql` | Column-level UPDATE grants: experts edit only their descriptive columns. |
| `migrations/20260709090000_manual_entry_backdate.sql` | `end_workout_session` honours a backdated `started_at` (manual entry US13). |
| `migrations/20260709100000_avatars_bucket.sql` | Public `avatars` storage bucket + owner-folder write policies. |
| `migrations/20260709110000_ble_remote_id.sql` | `connected_devices.ble_remote_id` for real-BLE pairings. |
| `migrations/20260711090000_landing_site.sql` | Marketing-site integration: `public_testimonials` / `landing_pricing_plans` / `landing_media_assets` tables, anon read policy on `expert_categories`, the anon-callable `landing_metric_summary()` / `landing_featured_experts()` SECURITY DEFINER functions, and signup-trigger v3 (last_name mirroring + expert-application metadata → pending `expert_profiles` + document metadata). |
| `migrations/20260712090000_admin_portal.sql` | Admin portal surface: `review_expert_application` RPC (approve → verified + expert role) + admin read/write policy on `expert_services`. |
| `migrations/20260712100000_landing_faqs.sql` | `landing_faqs` (admin-editable FAQ; public reads active rows). |
| `migrations/20260712110000_landing_activity_and_ranking.sql` | `landing_activity_series()` (weekly sessions/minutes for the public chart) + `landing_featured_experts()` v2 — Bayesian weighted-rating ranking (IMDb WR, m=10) returned with a `score` column. |
| `seed.sql` | The three install-time catalogs: `workout_types`, `health_tags`, `expert_categories`. |
| `seed-demo.sql` | **Demo data** (not install data): two login accounts (`free@`/`premium@wiseworkout.test`, pw `Password123!`) + varied workout sessions, XP/streak, and share posts. Idempotent — re-run to reset the demo. |

> **Note on migration versions:** these files are the replayable local history. The hosted project was provisioned via the Supabase MCP, which assigned its own version timestamps (and split the RPC + trigger-grant changes into separate migrations) — so `supabase migration list` against the remote shows different version ids for the same final schema. Reconcile with `supabase migration repair` if/when adopting CLI `db push`.

## Running it

Requires the [Supabase CLI](https://supabase.com/docs/guides/cli) + Docker.

```bash
supabase init           # once, if supabase/config.toml doesn't exist yet
supabase start          # boots local Postgres + Auth + Studio
supabase db reset       # applies migrations/ in order, then runs seed.sql
```

Against a hosted project: `supabase link --project-ref <ref>` then `supabase db push`.

> The schema references `auth.users` (Supabase Auth owns identity). It therefore expects the Supabase
> Postgres image — a bare `psql` against vanilla Postgres won't have `auth.users` or the `anon` /
> `authenticated` roles.

## Mapping decisions (doc entity → Postgres)

These are the deliberate translations from the PascalCase ERD to the physical schema:

- **`User` → `profiles`**, keyed on `auth.users.id`. Supabase Auth owns login/password; `profiles.email`
  mirrors `auth.users.email` for in-app reads (#14). A signup trigger (`handle_new_user`) inserts the
  `profiles` row.
- **Shared-key 1:1 specializations** off `profiles.id`: `fitness_profiles`, `expert_profiles`,
  `subscriptions` (PK = FK to `profiles.id`). Matches the ERD's shared-key pattern.
- **snake_case** everywhere (Postgres/Supabase convention). The Dart freezed models map back to the doc's
  camelCase via `@JsonKey` / a `fieldRename` setting.
- **Merged junctions → array columns:** `profiles.followed_expert_ids`, `fitness_profiles.health_tag_ids`,
  `fitness_profiles.preferred_workout_type_ids` (`uuid[]`). These are intentional denormalisations carried
  over from schema-v2 — see the notes in `database-v1.md`.
- **JSON blobs (`jsonb`):** `profiles.notification_prefs`, `planned_workouts.segments`,
  `workout_sessions.track_points`, `deliverables.sections`.
- **Enums → Postgres `enum` types** (self-documenting; one per categorical column).
- **`expert_*.specialties` / `category`** reference `expert_categories.id` (a text slug). `specialties` is a
  `text[]` of slugs, so it's an app-level FK (Postgres can't FK an array element); `expert_services.category`
  is a real FK.

## RLS model (where the security marks are)

- **Owner-scoped** private data: `fitness_profiles`, `fitness_goals`, `fitness_plans`, `planned_workouts`,
  `workout_sessions`, `exercise_logs`, `connected_devices`, `subscriptions`.
- **`workout_sessions.notes` is always private.** The base table is owner-only; everyone else reads the
  `public_workout_sessions` view, which omits `notes`. That enforces the documented invariant at the DB layer.
- **`public_profiles` view** exposes safe identity columns + computed `level` / `current_streak` (for Social
  #11.2) while keeping `email` and `notification_prefs` off-limits. Base `profiles` is self/admin only.
- **Reads** for the social graph and marketplace: `posts`, `post_likes`, `post_comments`,
  `challenges`, `challenge_participants`, `follows`, `expert_profiles`, `expert_reviews`, live
  `expert_services`, and the catalogs.
- **Admin-only**: reading `feedback` / `contact_messages`, suspending users (`role`/`status` changes are
  blocked for non-admins by the `guard_profile_privileged_columns` trigger).

### SECURITY DEFINER RPCs

Multi-step atomic mutations live in **SECURITY DEFINER RPCs**, added as their controls land (build-plan §3).
- ✅ **`end_workout_session`** (finalize session + bump XP + recompute streak + maybe emit a `level_up` post).
- ✅ **`add_friend` / `remove_friend`** (mutual Follow pair, atomic both directions).
- ✅ **`accept_service_request` / `decline_service_request` / `complete_service_request` / `submit_expert_review`**
  (the ServiceRequest status-lifecycle + review rules; complete bumps `client_count` and `total_earned_cents`,
  review recomputes `rating_avg`/`review_count`; direct writes revoked — RPCs are the only path).
- ✅ **`start_premium`** (the simulated Free→Premium upgrade: role flip + `subscriptions` upsert; the
  role-guard trigger admits it via a transaction-local flag, so client role writes stay blocked).
  Cancel/resume on #13.6 are deliberately NOT RPCs — owner-scoped status writes under `subscriptions_owner`.
- ⏳ Still deferred: client `cancel` of a pending ServiceRequest (no UI surface).

**Column-level grants** (beyond RLS): `expert_profiles` UPDATE is granted only on the five
self-descriptive columns (title/years/about/credentials/specialties) — the aggregates and
`verification_status` are unwritable from clients even on the owner's own row (20260708100000).

The RLS here gates *row access*; these RPCs enforce the *column-level transition* logic.


## Edge Functions (`functions/`)

| Function | Purpose |
|---|---|
| `summarise-progress` | AI progress summary from the caller's own weekly aggregates (RLS-scoped). |
| `suggest-plan` | AI plan generation, BOTH tiers (Free basic / Premium personalised), one 4-week monthly cycle, strict JSON schema + server-side validation. |

Both call **OpenAI `gpt-4o-mini`** with **Gemini fallback** and degrade to a deterministic stub
(same response shape) when no key is set or the AI fails. Secrets (Dashboard → Edge Functions →
Secrets): `OPENAI_API_KEY`, optional `GEMINI_API_KEY` — never shipped in the app.

## seed-demo.sql caveats

- Leaves `profiles.onboarding_completed_at` and `fitness_plans` untouched — reseeding does NOT
  re-trigger onboarding; use
  `update profiles set onboarding_completed_at = null where email = '<demo email>';`
- Seeded sessions carry no `connected_device_id` (null = manual entry per schema) even though
  they include HR values — cosmetic; live captures do link their source device.
