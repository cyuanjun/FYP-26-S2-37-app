# Wise Workout — Mobile App Build Plan

The engineering plan for building the **Flutter app on Android + iOS**. This is the *technical* companion to the team's two approved requirement documents — it makes the build decisions, and the PRD/SRS are updated to match as those decisions firm up (requirements evolve; the docs follow the engineering).

> **Source-of-truth docs (read these first):** the **PRD v2.0** (research, business model, WBS, project schedule/Gantt, roles, dev tools, methodology, risk) and the **SRS v2.0** (functional + non-functional requirements, 64 use cases). Where this build plan and the PRD/SRS disagree, the newer engineering decision wins and the PRD/SRS get a follow-up edit (tracked in §10).

**Constraints driving every decision:**

- **Time:** Apr–Aug 2026, two terms (per PRD §8.2 milestones). Term 1 → research/design/basic prototype (End-of-Term-1 review 20 Jun); Term 2 → modules, integration, final demo (22 Aug).
- **Team:** 4 people — roles per PRD §8.4 (Yuan Jun: coordination/docs/planning · Devanandi: mobile app + UI · Foong: backend/DB/API · Jedidiah: marketing website + expert/admin features).
- **Backend:** managed (Supabase) — no servers to host; see §2.
- **Sensors:** phone-only now; BLE / smartwatch added later (architecture made additive).
- **Optimising for:** rubric coverage — every project-brief requirement visibly demonstrable; build core flows first (matches the PRD risk plan: "prioritise core features first").

> The flow-explorer (React mock) is the **executable spec**, not the app. Per-screen reads/writes are in [database-v1.md](../reference/database-v1.md)'s screen→data map and the specs under [screens/](../reference/screens/). The real app is greenfield Flutter.

---

## 1. Scope & the three-layer model

The platform has **five roles** (Unregistered, Free, Premium, Expert, Admin) and a **three-layer business model** (PRD §4, SRS §2.3) — this distinction drives the whole design:

- **Free tier** — core self-guided tracking + basic analytics + **basic AI** progress summaries & plan suggestions + social + expert browsing.
- **Premium tier** — everything Free, plus advanced analytics, full history, detailed reports, and **personalised AI** summaries/suggestions + personalised reminders.
- **Expert-services layer (separate paid add-on)** — verified experts sell services, custom plans, and purchasable content. **Both Free and Premium users buy these à la carte** (simulated payment); it is *not* bundled into Premium. AI ≠ expert: the AI only does summaries + suggestions; all human coaching/custom plans live here.

All five roles are in scope (the SRS specs all 64 use cases). **Build order, not scope-cutting:** follow the PRD's 8 Agile sprints (§10.3) — accounts → profile/tracking → dashboard/analytics → AI + reminders → expert services → social/competitions/subscription/admin → testing. The PRD risk plan already says **prioritise core features first**, so if a term runs short, depth on expert-content and admin-monitoring yields before the core **capture → analyse → AI-summary → share** loop, which is the spine and the demo.

The **marketing website** (Next.js, Jedidiah) is a *separate* deliverable — already deployed (fyp-26-s2-37-website.vercel.app) — and is the registration/login/expert-application entry point. The app handles login only; admins manage the site's content from inside the system (SRS US63).

---

## 2. Tech stack

| Layer | Choice | Why |
|---|---|---|
| App | **Flutter** (stable channel) | Android + iOS from one Dart codebase, as the brief requires |
| State | **Riverpod** | Async providers map cleanly onto Supabase queries (loading / data / error) |
| Routing | **go_router** | Declarative; role-based redirects for Free / Premium / Expert / Admin |
| Models | **freezed** + json_serializable | Immutable models + auto JSON ↔ Dart for the 26 entities |
| Backend | **Supabase** (Postgres + Auth + Storage + Realtime) + **Edge Functions** | Managed backend, no servers to host; Edge Functions (TypeScript/Deno) are the custom-API + AI-proxy layer → Foong's "backend/API" deliverable. **Supersedes the PRD's Node/Express + MySQL + Firebase Auth** (§10 lists the PRD edit). |
| AI | **OpenAI** (Gemini fallback) via an Edge Function | Two functions only: progress **summaries** + plan **suggestions** (§5). Key stays server-side. |
| Payment | **Simulated** (mock status / manual access grant) | Premium upgrade + expert-service purchase show the access-control flow; no real gateway (PRD §4.4). |
| Notifications | `flutter_local_notifications` now; FCM / scheduled function later | Local workout / inactivity / rest reminders now; server push later |
| Sensors | `geolocator` + `pedometer` now; `health` + `flutter_blue_plus` later | Phone capture now; wearables additive (see §4) |
| Marketing site | **Next.js** (separate repo, deployed) | Registration / login / expert-application entry point; admin-managed content |

**Through-line:** every choice minimises work for a 4-person team across two terms — one app codebase, a managed backend, a thin Edge-Function layer for custom logic + the AI proxy, and a sensor design where wearables are additive rather than a rewrite. **Why Supabase over the PRD's Node/Express + Firebase:** same functionality, far less ops; Foong still ships real backend work (SQL schema, RLS policies, Edge Functions, the AI proxy). Fold the change back into PRD §9.3 and SRS §3.8.

### Architecture — BCE (Boundary · Control · Entity)

The app is designed to **Jacobson's BCE** stereotypes so the design docs (robustness + sequence diagrams, traceability matrix) are FYP/TDM-compliant. Full detail — inventory, matrix, robustness diagrams, sequence diagrams, and a runtime logging convention — is in [bce-design.md](bce-design.md).

- **Entity** = the 26 schema entities (freezed models) → `lib/entities/`
- **Boundary** = UI screens (actor-facing) + gateways for DB/AI/sensors/social/notifications (system-facing) → `lib/boundaries/{ui,gateways}/`
- **Control** = one class per use case (the mock's store actions) → `lib/controls/`

**Rule:** `Actor ─ Boundary ─ Control ─ Entity` — a screen never touches an entity or the DB directly; a Control always mediates. Riverpod implements Controls as Notifiers the UI watches, so idiomatic Flutter and BCE coincide.

---

## 3. Backend — the schema is 90% done

[database-v1.md](../reference/database-v1.md) + [database.dbml](../reference/database.dbml) translate almost 1:1 to Postgres.

- **Auth:** Supabase Auth owns login/identity. The `User` entity becomes a `profiles` table keyed on `auth.users.id` — matching the shared-key specialization design (`FitnessProfile`, `ExpertProfile`, `Subscription` are all 1:1 off `UserID`).
- **RLS (row-level security):** where we earn security marks. Turn each documented invariant into a policy — e.g. "users see only their own sessions," "`WorkoutSession.Notes` always private," "only admins can suspend."
- **Store actions = the API.** The mock's actions (`endWorkoutSession`, `createWorkoutSharePost`, `joinChallenge`, `requestService`, …) become either repository methods (simple CRUD) or Postgres **RPC functions** for multi-step atomic ops. Example: `endWorkoutSession` writes the session + bumps XP + may emit a `level_up` post in one transaction.
- **Port the math.** `lib/levelXp`, `lib/effectEstimate`, `lib/advancedAnalytics` from the mock → Dart (easier to unit-test) or SQL functions.
- **Realtime** drives the live social feed and challenge leaderboards for free — subscribe to `Post` / `WorkoutSession` changes.

**First backend deliverable:** Postgres DDL (tables + FKs + enums + RLS starters) generated from [database-v1.md](../reference/database-v1.md), plus a seed script.

---

## 4. Sensors — abstraction now, wearables later

One interface today means later work is a new class, not a refactor. The schema already supports this (`ConnectedDevice.deviceType` includes `phone_sensors`; `WorkoutSession.ConnectedDeviceID` null = manual entry).

```dart
abstract class WorkoutDataSource {
  Stream<LiveMetrics> get metrics;   // hr?, pace?, distance, cadence?, elev?
  Future<void> start();
  Future<void> stop();
}
```

- **Now — `PhoneSensorSource`:** `geolocator` (GPS distance / pace / route → `WorkoutSession.trackPoints`) + `pedometer` (steps / cadence).
- **Now — `ManualEntrySource`:** a form, counts as a third source.
- **Later (additive):** `HealthSource` (`health` plugin → HealthKit / Health Connect) and `BleHeartRateSource` (`flutter_blue_plus`, standard BLE HR profile — a cheap chest strap covers a demo). Each just implements `WorkoutDataSource`.

Satisfies the brief's "phone sensors *or* wearables" with a clean, examiner-friendly upgrade path.

---

## 5. AI scope — exactly two functions (SRS §3.9)

The AI scope is **deliberately narrow** (a graded, defensible boundary): AI does **only** (1) progress summaries and (2) fitness-plan *suggestions*. Everything else is **rule-based** or **human-expert**:

| Job | Engine | Notes |
|---|---|---|
| Reminders, inactivity, **rest/over-training** alerts | **Rule-based** (deterministic, configurable) | Thresholds over recent 7/30-day frequency + schedule; transparent and testable. |
| **Basic plan structure** (fallback skeleton from goal + preferred types + rest days) | **Rule-based fallback** | Used only when the AI is unavailable — since 12 Jun both tiers get AI-generated plans (decision per WBS/SRS, recon log C4-cancelled). |
| **Progress summary** (interpret the data in plain language) | **AI** | "Your frequency is up, consistency dipped mid-week, on track for your goal." Free = basic; Premium = personalised w/ longer history + wearable metrics. |
| **Plan suggestion** (generate the full goal timeline) | **AI** (suggest-plan Edge Function, gpt-4o-mini live) | Free = basic depth; Premium = personalised. Preferences are a strict contract (only chosen types scheduled); rule skeleton is the offline fallback. |
| Coaching / custom plans / nutrition / recovery | **Human expert** (paid layer) | Explicitly *not* AI — the interface must label which is which (SRS §3.8.1, NFR-USA-02/03). |

**Implementation:**
- **Path:** app → Edge Function (holds `OPENAI_API_KEY` as a Supabase secret) → OpenAI (Gemini fallback) → app. Never put the key in the app bundle.
- **Two wrapped functions:** `summariseProgress(profile, history)` and `suggestPlan(profile, goal, history)` — not raw model calls scattered around, so the provider/model is a one-file swap.
- **Structured output:** the suggestion returns strict JSON for the plan rows (OpenAI JSON-schema mode); the summary returns prose. Tier (`basic` vs `personalised`) selects the prompt + input depth.
- **Honest-AI rule:** outputs are labelled AI-assisted, never imply medical advice or guaranteed outcomes (SRS §3.9.3, NFR).
- **Model + pricing:** pick a current model and verify name/price on the provider's docs at build time — don't hard-code from memory.

---

## 6. Rubric-coverage map — don't lose easy marks

| Brief requirement | Delivered by |
|---|---|
| Collect exercise data (phone / wearable) | §4 capture → `WorkoutSession` + `trackPoints` |
| Estimate effects & analysis (day/week/month) | History + Advanced Analytics; rule-based trend engine + **AI progress summary** (§5) |
| Fitness advice + schedulable, customisable plan | **AI plan generation both tiers** (§5; rule fallback); goals + customisation (Premium) |
| Remind to exercise / rest | Local notifications driven by the rule-based reminder/inactivity/**rest** engine |
| Social + competitions + share to named platforms | Social feed, `Challenge`, native share to **Facebook / Instagram / Twitter / TikTok** |
| User profiling | Onboarding + Fitness Profile (goals, preferences, health tags) |
| Intelligent content delivery / recommendations | Basic vs personalised AI tier; dashboard "today" derivation |
| Incentive / gamification | XP / levels / streak; badges + challenges + level-up posts |
| Analytics incl. predictive | Trends + one honest goal projection ("on track to hit −5 kg by week 8") |
| Expert services | Verified-expert marketplace + custom plans + purchasable content (paid add-on layer) |
| Product marketing website | ✅ Next.js, already deployed (separate repo) |
| SaaS business model | Three-layer: Free / Premium / paid Expert-services (simulated payment) |

Two usual weak spots — cover deliberately: **predictive analytics** (add one honest projection, don't fake ML) and **sharing to the *named* platforms** (`share_plus` + platform intents; IG/TikTok via image-to-story share).

---

## 7. Schedule, sprints & roles — see the PRD (don't duplicate)

The authoritative schedule lives in the **PRD** and is not re-invented here:
- **Milestones + Gantt:** PRD §8.1–8.3 (project begins 4 Apr; basic prototype + this PTD/PUM ~10–13 Jun; End-of-Term-1 review 20 Jun; module testing 11 Jul; integration 1 Aug; final demo 13–22 Aug).
- **8 Agile sprints:** PRD §10.3 — accounts → profile/tracking → dashboard/analytics → AI summaries/suggestions + reminders → expert services → social/competitions/subscription/admin → testing.
- **Roles:** PRD §8.4 (see §intro).

**One engineering rule to add on top:** build the **vertical slice first** — log in → record a phone-GPS workout → see it in history → get an AI summary → share a post — before anyone goes deep. It proves Flutter ↔ Supabase ↔ sensors ↔ AI all connect and de-risks the rest. This maps onto PRD Sprints 1–4.

---

## 8. Risks

The full risk register is **PRD §8.5**. Engineering call-outs:
1. **iOS testing** needs a Mac + device (and an Apple dev account for HealthKit later) — sort early.
2. **Scope** — hold the build-order in §1; let expert-content/admin-monitoring depth yield before the core loop.
3. **Social platform SDKs** (esp. TikTok / Instagram) are fiddly — prototype the share path early, not in the final sprint.
4. **AI scope creep** — keep AI to the two functions in §5; everything else is rule-based or expert. Drifting here is both a marks risk (over-claiming) and a build risk.

---

## 9. Immediate next steps

1. Align [database-v1.md](../reference/database-v1.md) to the **TDM §8 ERD** (the schema of record), then generate Postgres DDL + RLS starter + seed from it — see §10 and the [reconciliation log](../../deliverables/doc-reconciliation-log.md) §D.
2. Scaffold the Flutter project (structure, Riverpod + go_router + Supabase client, design tokens from [palette.md](../reference/palette.md)).
3. Build the vertical slice (§7).

---

## 10. Doc reconciliation — see the log

The running list of edits needed across **PRD v2.0 / SRS v2.0 / TDM v5** to keep the submitted deliverables consistent with current engineering decisions now lives in **[../deliverables/doc-reconciliation-log.md](../../deliverables/doc-reconciliation-log.md)**. Highlights:

- **Backend → Supabase** + Edge Functions (PRD §9.3, SRS §3.8, TDM §4) — supersedes Node/Express + MySQL + Firebase.
- **AI = summaries + suggestions only** — confirmed by TDM §3.4; rest rule-based/expert.
- **Payment is simulated** — no gateway, price fields only.
- **TDM-internal fixes:** premium price ($9.90 web vs $9.99 app), a stray "SQLite DB" caption, and the empty §6 sequence-diagram placeholder.

> **Database question — RESOLVED by TDM §8.** The team-approved ERD keeps `ExpertReview` and models the expert layer as `ExpertService → ServiceRequest → Deliverable` with simulated payment via price fields. [database-v1.md](../reference/database-v1.md) should now be **aligned to the TDM ERD**, and the DDL generated from that — see the log's section D.
