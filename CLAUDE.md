# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**Wise Workout** (FYP-26-S2-37) — a cross-platform (Android + iOS) mobile fitness app, the Final Year Project of a 4-person team at UOW/SIM. Think Strava-style: capture workouts from phone sensors (wearables later), AI-generated training plans, analytics, a social feed with challenges, an expert marketplace, and Free/Premium/Expert/Admin roles.

**Current state: the Flutter app is built and running** (Android emulator + iOS simulator) against a live Supabase backend — vertical slice complete plus onboarding, AI plans (live OpenAI), My Plans + Plan Detail, connected devices, and the full Profile cluster; 112 tests. `docs/` holds the planning/design/reference material; **[docs/STATUS.md](docs/STATUS.md) is the up-to-date state**. The design decisions below are **already made** — implement to them; don't reopen them without being asked.

## Where the knowledge lives

**Canonical submitted docs:** the team's **PRD v2/v3**, **SRS v2.0**, and **TDM v5** (6 Jun 2026; not in this repo — `../FYP_docs/Submissions/`) are the source of truth. PRD/SRS = *requirements, scope, business model, schedule, 64 use cases (mirrored with build status in [docs/requirements/user-stories.md](docs/requirements/user-stories.md)), FR/NFR*. **TDM v5 = system design: architecture (§4), context DFD (§3.3), activity diagrams (§5), wireframes (§7), and the ERD (§8) — the schema of record. Exception: TDM §6 sequence diagrams are wrong (team-confirmed 12 Jun) — use [docs/architecture/bce-design.md](docs/architecture/bce-design.md) §5 instead.** PRD v3 is textually identical to v2 (reconciliation §B pending; PRD gets fixed post-submission — only PTD+PUM are submitted). When these conflict with current engineering decisions, the newer decision wins and the submitted doc gets a follow-up edit — the running cross-doc edit-list is **[docs/deliverables/doc-reconciliation-log.md](docs/deliverables/doc-reconciliation-log.md)**.

**Resume point / current state:** see **[docs/STATUS.md](docs/STATUS.md)** first — it's the single "where we are, what's next" anchor.

Start at [docs/README.md](docs/README.md) for the index. The load-bearing docs in this repo:

- [docs/STATUS.md](docs/STATUS.md) — **current progress + next steps** (read this first when resuming).
- [docs/prototype-demo-guide.md](docs/prototype-demo-guide.md) — **how to run/demo the app**: setup, step-by-step manual-test walkthrough (what to do + what you should see), test accounts, backend verification.
- [docs/testing/bug-log.md](docs/testing/bug-log.md) — every defect with root cause + fix commit; check it before re-diagnosing a familiar symptom.
- [docs/simplify.md](docs/simplify.md) — plain-English **code map** (how the layers wire together, data flow, data-owned rules) + the redundancy/simplification list — **fully applied 6 Jul 2026** (incl. corrected false positives). Good orientation before touching `lib/`.
- [docs/architecture/build-plan.md](docs/architecture/build-plan.md) — the **engineering plan**: scope/three-layer model, tech stack, AI scope, schedule pointers, rubric map, and the doc-reconciliation pointer (§10).
- [docs/architecture/bce-design.md](docs/architecture/bce-design.md) — BCE architecture, Boundary/Control/Entity inventory, traceability matrix, robustness + Mermaid sequence diagrams, runtime logging convention. (AI: one `GeneratePlan` control — both tiers AI via the suggest-plan Edge Function, `BuildPlanSkeleton` rule fallback — plus `SummariseProgress`.)
- [docs/reference/database-v1.md](docs/reference/database-v1.md) — the **working data model** (from the React mock). The **TDM §8 ERD is now the schema of record**; align this file to it before generating DDL (reconciliation log §D — `ExpertReview` kept, expert layer = `ExpertService → ServiceRequest → Deliverable`, payment simulated). Companions: [database.dbml](docs/reference/database.dbml) (machine-readable, paste into dbdiagram.io) and [erd-relationships.md](docs/reference/erd-relationships.md) (the cardinality / crow's-foot checklist).
- [docs/reference/screens/](docs/reference/screens/) — **per-screen UI blueprints** (~28 files, indexed by [screens-v1.md](docs/reference/screens-v1.md)): purpose, UI elements, states, and incoming/outgoing edges per screen, citing [palette.md](docs/reference/palette.md) + [typography.md](docs/reference/typography.md). This is the spec to build each Flutter screen against — read the relevant file before implementing a Boundary. Frontmatter `status:` (e.g. `spec-only` = design locked, code not built). ⚠️ Several *built* screens are deliberately simpler than their specs (Dashboard, Fitness Goals, Account Settings, Login, Train card — found 13 Jun, STATUS.md): treat the spec as design intent; where code exists, the build is canonical.
- [docs/deliverables/](docs/deliverables/) — FYP deliverable prep: [doc-reconciliation-log.md](docs/deliverables/doc-reconciliation-log.md) (cross-doc edits), [ptd-pum-assembly.md](docs/deliverables/ptd-pum-assembly.md) (PTD/PUM mapping), and the net-new drafts [ptd-net-new-sections.md](docs/deliverables/ptd-net-new-sections.md) / [pum-net-new-sections.md](docs/deliverables/pum-net-new-sections.md). The submitted PTD/PUM Word docs are *generated* by the Python scripts in [docs/scripts/](docs/scripts/) (`expand_ptd.py`, `build_pum.py`, …) from content sources in `../FYP_docs/Submissions/` — edit the sources/scripts and regenerate; don't hand-edit the FILLED docx.
- [docs/requirements/urs.md](docs/requirements/urs.md) — **deprecated**, superseded by the SRS.

**Settled figures:** premium = **$9.99/mo**; payment is **simulated** (price fields only, no gateway/ledger).

The React flow-explorer mock these docs derive from is a **separate** repo (`../app-ui-FINAL/`) — an executable spec, not code to port verbatim.

## Locked architecture (do not re-litigate)

- **App:** Flutter (stable channel). **State:** Riverpod. **Routing:** go_router (role-based redirects). **Models:** freezed + json_serializable for the ~26 entities in the TDM §8 ERD.
- **Backend: Supabase** — Postgres + Auth + Storage + Realtime + Edge Functions. The schema in `database-v1.md` maps ~1:1 to Postgres; `User` becomes a `profiles` table keyed on `auth.users.id`; the shared-key specialization tables (`FitnessProfile`, `ExpertProfile`, `Subscription`) are 1:1 off the user id. Row-level security enforces the documented invariants (e.g. `WorkoutSession.Notes` is always private). **The actual backend lives in `app/supabase/`** — migrations (DDL, RLS policies, SECURITY DEFINER RPCs like `end_workout_session`), `seed.sql` (install catalogs) / `seed-demo.sql` (demo accounts: `free@`/`premium@wiseworkout.test`, pw `Password123!`), and the two `functions/` edge functions (`summarise-progress`, `suggest-plan`). **[app/supabase/README.md](app/supabase/README.md) is the backend reference** — read it for the entity→Postgres mapping, the RLS model, and which RPCs exist. DDL is *generated from the docs*: change the schema in `database-v1.md` first, then regenerate — don't hand-edit migrations in isolation. The hosted project is reached via the Supabase MCP (`project_ref` in `.mcp.json`).
- **AI: OpenAI** (Gemini fallback; not Anthropic/Claude) via a Supabase **Edge Function** so the key never ships in the app. **AI scope is exactly two functions: progress *summaries* + plan *suggestions*** (build-plan §5, SRS §3.9). Reminders/inactivity/**rest** alerts are **rule-based**, not AI (plans: both tiers call `suggestPlan` — Free basic depth, Premium personalised; the rule-based skeleton is the offline fallback — decided 12 Jun); coaching/custom plans are **human-expert**. Wrap as `summariseProgress(...)` / `suggestPlan(...)`. Free = basic, Premium = personalised. Label AI output as AI-assisted; never imply medical advice.
- **Sensors:** one `WorkoutDataSource` interface. Built: `PhoneSensorSource` (geolocator + pedometer) + `WearableHrSource` (simulated BLE HR behind mock pairing, #7.1) merged via `CompositeWorkoutDataSource`; sessions record their source device (null `ConnectedDeviceID` = manual; manual-entry UI itself still pending, US13). Real `BleHeartRateSource` (flutter_blue_plus) / `HealthSource` (HealthKit/Health Connect) are **additive later** — class swaps, not refactors.
- **Notifications:** preference toggles built (#13.4, jsonb on profiles); `flutter_local_notifications` is a dependency but scheduling is not wired yet (US19–21 pending); FCM/push later.

## BCE — the architectural rule that governs all app code

The app follows **Boundary–Control–Entity** (Jacobson). This is an FYP design requirement, not a stylistic preference.

**Repo split (13 Jun):** everything needed to run the product lives in **`app/`** (the Flutter project *and* `app/supabase/`); everything else — planning/design docs, deliverable tooling (`docs/scripts/`) — lives in **`docs/`**. Run all Flutter/Dart commands from `app/`. Layout inside `app/`:

```
app/lib/entities/              ENTITY   — freezed models of the ~26 TDM §8 entities + data-owned rules (XP/level/streak)
app/lib/controls/              CONTROL  — one class per use case (= the mock's store actions, e.g. EndWorkoutSession)
app/lib/boundaries/ui/         BOUNDARY — actor-facing screens/widgets; ui/common/ = the shared widget library (StatTile, AppCard, StatusBadge, PremiumCta, AvatarButton) — use these instead of hand-rolling stat rows / surface cards / status pills / gold CTAs
app/lib/boundaries/gateways/   BOUNDARY — system-facing adapters (Auth/Profile/Fitness/Plan/Workout/Social/Feedback/Device gateways + AiGateway, WorkoutDataSource, SocialShareGateway; Notification/Storage gateways pending)
app/lib/core/                  cross-cutting helpers — seq_log.dart (the SEQ logging convention below), format.dart, strings.dart (isBlank), config/env.dart, theme/ (palette + typography + app_buttons.dart outlined styles)
app/lib/router/                app_router.dart — the go_router config with role-based redirects
```

**The rule:** `Actor ─ Boundary ─ Control ─ Entity`. A screen NEVER touches an entity or the database directly — a Control always mediates. No Boundary↔Boundary or Boundary↔Entity calls. Riverpod implements a Control as a Notifier the UI watches, so idiomatic Flutter and BCE coincide. The mock's store actions (`endWorkoutSession`, `generatePlan`, `joinChallenge`, `requestService`, `startPremium`, …) each become exactly one Control — they are the use-case inventory, enumerated in `bce-design.md` §2.4.

When adding a feature, instrument its Control with the `SEQ <useCase> <from> -> <to> : <message>` logging convention (`bce-design.md` §6) so real run sequences can be regenerated into Mermaid sequence diagrams (design↔implementation traceability the FYP rewards).

## Scope discipline (this is graded as much as the code)

**Three-layer model** (build-plan §1, PRD §4): **Free** (basic tracking/analytics/AI + social + expert browsing) · **Premium** (advanced analytics + personalised AI + reports) · **Expert-services paid layer** (à-la-carte add-ons both Free *and* Premium buy; simulated payment; *not* bundled into Premium). All five roles (Unregistered/Free/Premium/Expert/Admin) are in scope — the SRS specs all 64 use cases.

Optimise for **rubric coverage**, build **core-first** (PRD §10.3 sprints + risk plan "prioritise core features"). If a term runs short, expert-content/admin-monitoring depth yields before the core **capture → analyse → AI-summary → share** loop — that's the spine and the demo. Build the vertical slice (log in → record a phone-GPS workout → history → AI summary → share) before going deep anywhere.

## Project-specific conventions

- **Toggle button labels are action-first (verb):** "Add Friend / Unfriend", not "Add Friend / Friends" — the label says what tapping *does*, not the current state.
- **Social sharing names the platforms explicitly** — Facebook / Instagram / Twitter / TikTok — not a generic share sheet (a grading requirement).
- **Web mock sizing mirrors Flutter conventions** (iPhone 16 Pro 402×874 logical viewport, safe areas inside the height) so screen specs translate 1:1.
- **camelCase ↔ snake_case is automatic:** `build.yaml` sets json_serializable `field_rename: snake` globally, so freezed entities use Dart camelCase and serialize to Postgres snake_case columns without per-field `@JsonKey`. Don't add a manual `@JsonKey(name:)` for case alone.

## Commands

Standard Flutter project — **run everything from `app/`**:

```bash
cd app
flutter pub get                          # install dependencies
dart run build_runner build --delete-conflicting-outputs   # codegen for freezed / json_serializable
flutter run                              # run on a connected device/emulator
flutter test                             # run all tests
flutter test test/path/to/foo_test.dart # run a single test file
flutter analyze                          # lint / static analysis
```

The docs are plain Markdown with relative cross-links; `docs/reference/` was moved as a unit so its internal links resolve. A few `docs/archive/` files cite mock source paths (`../app/...`, `../CLAUDE.md`) that intentionally don't resolve here — they're provenance references to the separate React mock.
