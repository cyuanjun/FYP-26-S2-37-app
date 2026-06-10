# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

**Wise Workout** (FYP-26-S2-37) — a cross-platform (Android + iOS) mobile fitness app, the Final Year Project of a 4-person team at UOW/SIM. Think Strava-style: capture workouts from phone sensors (wearables later), AI-generated training plans, analytics, a social feed with challenges, an expert marketplace, and Free/Premium/Expert/Admin roles.

**Current state: docs only — the Flutter app has not been scaffolded yet.** This directory holds the planning, design, and reference material that fully specs the app. When you scaffold or build code, it goes in this repo root alongside `docs/`. The design decisions below are **already made** — implement to them; don't reopen them without being asked.

## Where the knowledge lives

**Canonical submitted docs:** the team's **PRD v2.0**, **SRS v2.0**, and **TDM v3.0** (5 Jun 2026; not in this repo) are the source of truth. PRD/SRS = *requirements, scope, business model, schedule, 64 use cases, FR/NFR*. **TDM v3.0 = system design: architecture (§4), context DFD (§3.3), activity diagrams (§5), wireframes (§7), and the ERD (§8) — the schema of record.** When these conflict with current engineering decisions, the newer decision wins and the submitted doc gets a follow-up edit — the running cross-doc edit-list is **[docs/deliverables/doc-reconciliation-log.md](docs/deliverables/doc-reconciliation-log.md)**.

**Resume point / current state:** see **[docs/STATUS.md](docs/STATUS.md)** first — it's the single "where we are, what's next" anchor.

Start at [docs/README.md](docs/README.md) for the index. The load-bearing docs in this repo:

- [docs/STATUS.md](docs/STATUS.md) — **current progress + next steps** (read this first when resuming).
- [docs/architecture/build-plan.md](docs/architecture/build-plan.md) — the **engineering plan**: scope/three-layer model, tech stack, AI scope, schedule pointers, rubric map, and the doc-reconciliation pointer (§10).
- [docs/architecture/bce-design.md](docs/architecture/bce-design.md) — BCE architecture, Boundary/Control/Entity inventory, traceability matrix, robustness + Mermaid sequence diagrams, runtime logging convention. (AI controls: `BuildPlanSkeleton` rule-based + `SuggestPlan`/`SummariseProgress` AI.)
- [docs/reference/database-v1.md](docs/reference/database-v1.md) — the **working data model** (from the React mock). The **TDM §8 ERD is now the schema of record**; align this file to it before generating DDL (reconciliation log §D — `ExpertReview` kept, expert layer = `ExpertService → ServiceRequest → Deliverable`, payment simulated). Companions: [database.dbml](docs/reference/database.dbml) (machine-readable, paste into dbdiagram.io) and [erd-relationships.md](docs/reference/erd-relationships.md) (the cardinality / crow's-foot checklist).
- [docs/reference/screens/](docs/reference/screens/) — **per-screen UI blueprints** (~28 files, indexed by [screens-v1.md](docs/reference/screens-v1.md)): purpose, UI elements, states, and incoming/outgoing edges per screen, citing [palette.md](docs/reference/palette.md) + [typography.md](docs/reference/typography.md). This is the spec to build each Flutter screen against — read the relevant file before implementing a Boundary. Frontmatter `status:` (e.g. `spec-only` = design locked, code not built).
- [docs/deliverables/](docs/deliverables/) — FYP deliverable prep: [doc-reconciliation-log.md](docs/deliverables/doc-reconciliation-log.md) (cross-doc edits), [ptd-pum-assembly.md](docs/deliverables/ptd-pum-assembly.md) (PTD/PUM mapping), and the net-new drafts [ptd-net-new-sections.md](docs/deliverables/ptd-net-new-sections.md) / [pum-net-new-sections.md](docs/deliverables/pum-net-new-sections.md).
- [docs/requirements/urs.md](docs/requirements/urs.md) — **deprecated**, superseded by the SRS.

**Settled figures:** premium = **$9.99/mo**; payment is **simulated** (price fields only, no gateway/ledger).

There is no app source yet. The React flow-explorer mock these docs derive from is a **separate** repo (`../app-ui-FINAL/`) — an executable spec, not code to port verbatim.

## Locked architecture (do not re-litigate)

- **App:** Flutter (stable channel). **State:** Riverpod. **Routing:** go_router (role-based redirects). **Models:** freezed + json_serializable for the ~26 entities in the TDM §8 ERD.
- **Backend: Supabase** — Postgres + Auth + Storage + Realtime + Edge Functions. The schema in `database-v1.md` maps ~1:1 to Postgres; `User` becomes a `profiles` table keyed on `auth.users.id`; the shared-key specialization tables (`FitnessProfile`, `ExpertProfile`, `Subscription`) are 1:1 off the user id. Row-level security enforces the documented invariants (e.g. `WorkoutSession.Notes` is always private).
- **AI: OpenAI** (Gemini fallback; not Anthropic/Claude) via a Supabase **Edge Function** so the key never ships in the app. **AI scope is exactly two functions: progress *summaries* + plan *suggestions*** (build-plan §5, SRS §3.9). Reminders/inactivity/**rest** alerts and the basic plan skeleton are **rule-based**, not AI; coaching/custom plans are **human-expert**. Wrap as `summariseProgress(...)` / `suggestPlan(...)`. Free = basic, Premium = personalised. Label AI output as AI-assisted; never imply medical advice.
- **Sensors:** one `WorkoutDataSource` interface. `PhoneSensorSource` (geolocator + pedometer) and manual entry now; `HealthSource` (HealthKit/Health Connect) and `BleHeartRateSource` (flutter_blue_plus) are **additive later** — new classes, not a refactor. The schema already supports this (`ConnectedDevice.deviceType` includes `phone_sensors`; null `ConnectedDeviceID` = manual).
- **Notifications:** `flutter_local_notifications` now (exercise/rest reminders); FCM/push later.

## BCE — the architectural rule that governs all app code

The app follows **Boundary–Control–Entity** (Jacobson). This is an FYP design requirement, not a stylistic preference. Layout:

```
lib/entities/              ENTITY   — freezed models of the ~26 TDM §8 entities + data-owned rules (XP/level/streak)
lib/controls/              CONTROL  — one class per use case (= the mock's store actions, e.g. EndWorkoutSession)
lib/boundaries/ui/         BOUNDARY — actor-facing screens/widgets
lib/boundaries/gateways/   BOUNDARY — system-facing adapters (SupabaseGateway, AuthGateway, AiGateway, WorkoutDataSource, SocialShareGateway, NotificationGateway, StorageGateway)
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

## Commands

No build system exists yet (app not scaffolded). Once scaffolded as a standard Flutter project, expect:

```bash
flutter pub get                          # install dependencies
dart run build_runner build --delete-conflicting-outputs   # codegen for freezed / json_serializable
flutter run                              # run on a connected device/emulator
flutter test                             # run all tests
flutter test test/path/to/foo_test.dart # run a single test file
flutter analyze                          # lint / static analysis
```

The docs are plain Markdown with relative cross-links; `docs/reference/` was moved as a unit so its internal links resolve. A few `docs/archive/` files cite mock source paths (`../app/...`, `../CLAUDE.md`) that intentionally don't resolve here — they're provenance references to the separate React mock.
