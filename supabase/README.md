# Supabase backend — Wise Workout (FYP-26-S2-37)

Postgres schema, RLS, and seed for the Wise Workout app. **Generated from
[docs/reference/database-v1.md](../docs/reference/database-v1.md)**, which is aligned to the **TDM v3.0 §8
ERD** (the schema of record — 26 entities). Treat the docs as the source of truth: change the schema there
first, then regenerate these files — don't hand-edit DDL in isolation.

## Layout

| File | What |
|---|---|
| `migrations/20260610090000_init_schema.sql` | Extensions, 28 enum types, the 26 tables (FKs, checks, indexes), and the `on_auth_user_created` signup trigger. |
| `migrations/20260610090100_rls_policies.sql` | Helper `is_admin()`, RLS enabled on every table, per-table policies, the role/status self-escalation guard, and the two privacy views. |
| `seed.sql` | The three install-time catalogs: `workout_types`, `health_tags`, `expert_categories`. |

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
- **Public reads** for the social graph and marketplace: `posts`, `post_likes`, `post_comments`,
  `challenges`, `challenge_participants`, `follows`, `expert_profiles`, `expert_reviews`, live
  `expert_services`, and the catalogs.
- **Admin-only**: reading `feedback` / `contact_messages`, suspending users (`role`/`status` changes are
  blocked for non-admins by the `guard_profile_privileged_columns` trigger).

### Deliberately deferred (not in this starter)

Multi-step atomic mutations belong in **SECURITY DEFINER RPCs**, added when their controls land (build-plan
§3) — e.g. `endWorkoutSession` (write session + bump XP + maybe emit a `level_up` post), `startPremium`
(role flip + `subscriptions` upsert), and the `ServiceRequest` status-transition rules (client cancels /
expert accepts+completes). The RLS here gates *row access*; these RPCs will enforce the *column-level
transition* logic.
