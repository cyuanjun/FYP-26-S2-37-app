# Wise Workout — Module Test Plan

**Milestone:** 11 Jul 2026 — *Individual Functional Modules · Centralized DB · Module Test Plan*
**Build under test:** `main` (feature-complete, 238 automated cases) · **Prepared by:** FYP-26-S2-37 team

> **Plan vs. report.** This document is the **plan**: it defines the modules, the test approach, the environment, the entry/exit and pass/fail criteria, the planned test cases (with expected results), and the requirements traceability. The **execution evidence** — every case with its actual result — lives in the companion **[module-test-report.md](module-test-report.md)**, whose test-case tables are the enumerated realisation of this plan.

---

## 1. Purpose & scope

Verify each **functional module** of Wise Workout in isolation, before system/integration testing, so that a defect can be attributed to a single module. "Module" is defined by the app's **Boundary–Control–Entity (BCE)** architecture: a module is one **Control** (use case) plus the **Entity** rules it drives. Screens (Boundaries) and the database are stubbed so the module is exercised alone.

**In scope**
- The 9 functional modules of the Flutter app (§6).
- The **Centralized DB** (§3) as the shared system of record the modules persist to.
- Automated module tests + declared manual module procedures.

**Out of scope for this plan** (covered elsewhere / later milestones)
- System/integration testing across modules against the live backend (manual only for now; see Risks §10).
- UI/widget automation of Boundaries.
- The marketing website's own module tests — see [../../web/test plan.md](../../web/test%20plan.md).
- Performance, load, and security testing.

## 2. Test items

| Item | What it is | Source |
|---|---|---|
| Entity modules | Pure domain rules (XP/level/streak, MET calories, ACWR, HR zones, training effect, formatting) | `app/lib/entities/` |
| Control modules | One class per use case (the module under test) | `app/lib/controls/` |
| Gateways (as test doubles) | System-facing boundaries, replaced by in-memory fakes | `app/test/helpers/fakes.dart` |
| Centralized DB | Shared hosted Supabase project (30 tables, RLS, RPCs) | `app/supabase/` |

## 3. Centralized database (system of record)

All modules persist to **one shared hosted Supabase project** — the same database the mobile app and the marketing/admin website use. This satisfies the milestone's "Centralized DB" item.

- **30 public tables** — the 26 core TDM §8 entities (`profiles`, `fitness_profiles`, `workout_sessions`, `challenges`, `expert_services`, …) plus the landing/admin extension tables (`landing_*`, `expert_verification_documents`, …).
- **Row-Level Security** on every table (owner-scoped; documented invariants e.g. private notes).
- **SECURITY DEFINER RPCs** for multi-step rules (`end_workout_session`, `add_friend`/`remove_friend`, `challenge_leaderboards`, service-request lifecycle, `submit_expert_review`, `start_premium`).
- Local mirror available (`cd app && supabase start`, ports 55321-9) for offline testing; migrations apply identically to local and hosted.

**Module isolation from the DB:** automated module tests never touch this DB. Each gateway is replaced by an in-memory fake (§4), so a Control's logic is verified without network or Postgres. The DB is exercised by the **manual** procedures (§7) and by direct SQL verification.

## 4. Test approach / strategy

**Technique — component testing with test doubles.** Each Control is a Riverpod provider depending on gateway providers. A test builds a `ProviderContainer` and **overrides** those dependencies with fakes:

```dart
final container = ProviderContainer(overrides: [
  currentUserIdProvider.overrideWithValue('u1'),      // drive auth state
  socialGatewayProvider.overrideWithValue(fakeSocial), // swap real gateway → fake
]);
```

The 12 `Fake*Gateway` classes implement the real gateway interfaces, hold in-memory state, **and record calls** (e.g. `joinCalls`, `createdChallenges`). Each case therefore asserts both:
1. the resulting state / return value, and
2. that the module called its gateway with the correct arguments.

**Entity modules** are pure functions and are tested directly (no doubles).

**Coverage rule:** every module has **positive** cases and **negative/guard** cases (signed-out → no-op, blank input rejected, boundary conditions).

**Input validation (defence in depth).** User input is validated at **both** layers against one source of truth — the pure [`Validators`](../../../app/lib/entities/validators.dart) module (height/weight/resting-HR ranges, positive goal/challenge targets, non-negative price, years-coaching range). The **Boundary** uses it to bound pickers and disable submit, so input is cleaned before it is sent; the **Control** re-checks it and **rejects** anything invalid before calling a gateway, so the rule holds even if the UI is bypassed. The validators are unit-tested directly (ENT), and each guarded Control has a negative test proving invalid input never reaches its gateway (AUTH/SOC/MKT).

**Two evidence streams**
- **Automated** — `flutter test` (238 cases), grouped by module, each with a case ID (e.g. `SOC-31`).
- **Manual** — scripted procedures on the simulator against the live backend, verifying the Boundary↔Control↔DB path the fakes stub out.

**Static analysis** — `flutter analyze` runs clean as a gate before the suite.

## 5. Environment, entry & exit criteria

**Environment**
- Flutter stable · iPhone 17 simulator (iOS 26) + Pixel API 35 emulator · Supabase local stack (55321-9) mirroring hosted.
- Command: `cd app && flutter analyze && flutter test`.

**Entry criteria** — module code compiles; `flutter analyze` clean; fakes exist for every gateway the module uses.

**Exit criteria** — 100 % of planned automated cases pass; all declared manual procedures pass (or a residual is explicitly declared as a limitation); `flutter analyze` clean.

**Pass/fail** — a case passes only if the actual state **and** the recorded gateway interaction match the expected result. Any assertion failure fails the case and blocks the exit criteria.

## 6. Module inventory & planned coverage

| # | Module | Under test (Controls / Entities) | Planned cases | Technique |
|---|---|---|---|---|
| ENT | Entity rules (incl. **`Validators`**) | XP/level/streak, MET calories, ACWR, HR zones, training effect, formatters, **input validators** | 88 | Direct (pure functions) |
| AUTH | Auth & profile | `Authenticate`, profile/account/fitness-profile controls (incl. numeric-range guards) | 28 | Fakes |
| CAP | Capture & devices | `ActiveWorkout`, `ManageConnectedDevice`, HR sources, BLE GATT parsing | 22 | Fakes + pure parser |
| HIST | History & analytics | `WorkoutHistory`, history search, `SummariseProgress` | 14 | Fakes |
| PLAN | Plans & AI | `GeneratePlan` (AI + rule fallback), plan selection | 15 | Fakes |
| SOC | Social & challenges | feed/likes/comments, friends, share, challenges, **`FindChallengeByCode`** | 34 | Fakes |
| MKT | Marketplace & expert portal | browse experts, request service, expert request lifecycle, publish service | 20 | Fakes |
| PREM | Premium subscription | `StartPremium`, `ManageSubscription` | 6 | Fakes |
| NOTIF | Notifications | `ScheduleReminders` rule engine | 11 | Fakes |
| | **Total** | | **238** | |

The **enumerated test cases** for each module (ID · description · expected result) are listed in [module-test-report.md](module-test-report.md) §Detailed cases — those tables are the case-level realisation of this plan.

## 7. Manual module procedures (planned)

Each is executed on the simulator against the centralized DB, verifying the Boundary↔Control↔DB path the automated fakes stub out.

| ID | Procedure | Expected result |
|---|---|---|
| MAN-01 | Core loop: login → capture → summary → history → AI summary → share | Session persists; XP/streak update; AI summary renders; post appears in feed |
| MAN-02 | Wearable pairing → live HR → avg/max persisted | Paired device streams HR; avg/max stored on the session |
| MAN-03 | Challenge join code: enter code → review detail → join; invite popup copy/share | Code resolves to the challenge; join increments count; code copies/shares |
| MAN-04 | Free caps & locks: month cap, search lock → #16, regen cap | Free limits enforced; locked features route to upgrade |
| MAN-05 | Premium upgrade → live flip → #13.6 cancel/resume → revert | Role flips to premium live; subscription row correct at each step |
| MAN-06 | Premium History search: filter, aggregates, miss state | Results filter; aggregates narrow; empty state on miss |
| MAN-07 | #12.2 Advanced Analytics: ACWR band, trends, zones, bests | Analytics compute from history and render |
| MAN-08 | Training Effect card: band/score/split on #12.1 | Correct band/score; honest "unavailable" when HR-less |
| MAN-09 | Social: 5-voice feed, like/comment, leaderboard | Feed scoped to self+friends; interactions persist; leaderboard live |

## 8. Per-module in-app demonstration (module-level demo)

Beyond the automated cases, **each module's functionality is demonstrated live in the running app** — this satisfies the milestone's "demonstrate functionalities at module level." One row per module: the exact in-app path and what an assessor should see. Run on the simulator against the centralized DB (accounts: `free@` / `premium@` / `expert@` / `admin@wiseworkout.test`, pw `Password123!`).

| Module | In-app path (screens / taps) | What it demonstrates (expected) |
|---|---|---|
| ENT — Entity rules | Complete a workout → **Profile** level/XP bar + streak; **History → session detail** calories; **Advanced Analytics** HR zones/ACWR | Domain rules made visible: XP/level/streak recompute, MET calories, HR zones — the entity logic behind the numbers |
| AUTH — Auth & profile | **Login** (email/password) → role-aware routing; **Profile → Account Settings** edit; **Log out**; admin account → redirected to `/admin` | Session auth works; role gates routing; profile edits persist |
| CAP — Capture & devices | **Train → Start Freeform Workout** → live timer + GPS/steps → **End** → Summary; **Devices → + Add device** → pair wearable → live ♥ HR | A session is captured atomically; a wearable streams HR; avg/max saved, session linked to the device |
| HIST — History & analytics | **History** tab: sessions grouped by week + analytics card with vs-prior deltas; Premium **search**; **Advanced ›** (#12.2) | History windows correct; search filters; advanced analytics render from real sessions |
| PLAN — Plans & AI | **Onboarding wizard** → live AI plan; **Train → VIEW PLANS → Plan Detail**; **Regenerate** (Free 1/month cap) | A personalised/basic AI plan is generated and viewable; regen cap enforced for Free |
| SOC — Social & challenges | **Social** feed: like/comment; **Challenges**: *enter a join code → detail → Join*, live leaderboard; **Share** to Facebook/Instagram/Twitter/TikTok | Feed scoped to self+friends; challenge join-by-code works; leaderboard live; named-platform share |
| MKT — Marketplace & expert portal | **Experts** → Expert Detail → Service Detail → **Request**; log in as `expert@` → portal (**Services / Requests / Clients**): triage, deliverable, mark complete | Client can request a service; expert portal runs the request lifecycle end to end |
| PREM — Premium subscription | As `free@`: upsell → **#16 Upgrade** → simulated payment → **live role flip**; **#13.6 Manage Subscription** cancel/resume | Free→Premium upgrade flips role live; subscription state correct at each step |
| NOTIF — Notifications | **Profile → Notifications (#13.4)**: reminder toggles + **UPCOMING** strip of the live schedule | Rule-based reminders schedule correctly; UPCOMING reflects the schedule (delivery = device-pass pending) |

## 9. Requirements traceability

| Module | User stories covered |
|---|---|
| ENT | US14–US18, US32–US35 (rules layer) |
| AUTH | US07–US09, US11, US14, US26, US31 hooks |
| CAP | US12, wearable scope (#7.1) *(US13 manual entry descoped — see reconciliation §C8)* |
| HIST | US15–US17, US33; #12 Search |
| PLAN | US18, US36–US37 |
| SOC | US22–US25 (US25 incl. challenge join codes) |
| MKT | US27–US29, US45–US51 |
| PREM | US31, US40 |
| NOTIF | US19–US21 |

Full story-level status: [../../requirements/user-stories.md](../../requirements/user-stories.md) (50 ✅ · 10 🟨 · 4 ⬜).

## 10. Risks, assumptions & limitations

- **Fakes ≠ backend.** Automated module tests stub the DB, so RLS/RPC behaviour and the network seam are **not** covered automatically; they are verified by the manual procedures (§7) and direct SQL checks. Integration testing across modules against the live backend is a later milestone.
- **No UI/widget automation.** Boundaries are verified manually on the simulator.
- **Physical-device pass pending.** Notification calendar delivery and real-BLE pairing are verified sim-safe only; a hardware pass remains (the one open exit-criteria residual, declared not hidden).
- **Assumption:** the centralized DB schema (migrations) is applied identically to local and hosted, so module behaviour is environment-independent.

## 11. Execution status

Planned cases: **238 automated + 9 manual procedures**. Latest execution: **all pass**, `flutter analyze` clean. Evidence and per-case results: **[module-test-report.md](module-test-report.md)**.
