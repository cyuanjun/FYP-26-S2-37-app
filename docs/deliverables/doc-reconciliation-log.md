# Document Reconciliation Log

Tracks where the three **submitted deliverables** — **PRD v2/v3**, **SRS v2.0**, **TDM v5** (6 Jun 2026) — diverge from each other or from current engineering decisions, and exactly what to fix on each document's next revision. Keep this current; it's the single source for "what still needs folding back."

> **Version decisions (12 Jun 2026):** **TDM v5 is canonical** — *except* its **§6 sequence diagrams, which the team confirmed are wrong** (replace from bce-design §5; see A3). **PRD v3 is textually identical to v2** — the §B edits were never folded in; the team will fix the PRD **after** the 13 Jun submission, since only the **PTD + PUM** are submitted. Anything the PTD copies from the PRD must apply §B during assembly.

> Driver: engineering decisions lead, documents follow ("requirements change as we continue"). The build-plan ([../architecture/build-plan.md](../architecture/build-plan.md)) and BCE design ([../architecture/bce-design.md](../architecture/bce-design.md)) are the technical source of truth; this log is the to-do list for the Word deliverables.

## Submitted-document versions
| Doc | Version | Date | Canonical for |
|---|---|---|---|
| PRD | v3 (≡ v2 text) | — | Business model, market research, schedule/Gantt, roles, risk register, FR/NFR |
| SRS | v2.0 | — | 64 use cases (mirrored with build status in [../requirements/user-stories.md](../requirements/user-stories.md)), FR/NFR tables, user classes |
| **TDM** | **v5** | **6 Jun 2026** | **Architecture, activity diagrams, the ERD (§8), all wireframes — but NOT §6 sequence diagrams (wrong; use bce-design §5)** |

The TDM is newest and supersedes earlier design material. Where the TDM and PRD/SRS disagree, **fix the older doc to match the TDM** unless noted.

---

## A. Fix *inside* the TDM (internal consistency — next TDM revision)

| # | Issue | Where in TDM | Fix |
|---|---|---|---|
| A1 | **Premium price contradicts itself.** Website pricing page shows **$9.90/mth**; the app's Upgrade and Subscription screens show **$9.99/mo**. | §7.1.1 pricing (p19) vs §7.2.32 (p40) + §7.3.5 (p43) | **DECIDED: standardise on $9.99/mo.** Fix the website pricing page (§7.1.1) and PRD §4 to match the app screens. |
| A2 | **"SQLite DB" leakage.** Admin content-management wireframe caption says *"Edits are persisted to the SQLite DB."* That's leftover text from the React website mock. | §7.5.1 (p54) | Production backend is **Supabase Postgres**, not SQLite. Either reword the caption generically ("persisted to the database") or note the mock ran on SQLite while production uses Postgres. |
| A3 | **§6 Sequence Diagrams: empty in v3; v5 filled it per user story, but the team confirms those diagrams are WRONG (12 Jun).** | §6 (p16) | **Replace §6 wholesale** with the per-story diagram set (which superseded the earlier plan to render bce-design §5's 7 diagrams) — **DONE 12 Jun: all 59 per-story diagrams rendered (US18 split into US18a/US18b)** → [sequence-diagrams/](sequence-diagrams/) (PNG + Mermaid sources). Drop these into TDM §6 / PTD §16; do not use TDM v5 §6. |
| A4 | **Architecture is stack-agnostic.** §3.2/§4 describe a logical service layer (API Controller → Services → DAO → DB) without naming the stack. | §3.2, §4 | Add the concrete stack note (Supabase Postgres + Auth + Storage + Realtime, Edge Functions for AI/custom logic, Flutter client). See B1 — keep TDM, PRD, and PTD §12 identical. Flag the DAO/API-Controller tier as **logical**: physically, Flutter talks to Supabase directly (RLS-enforced) with Edge Functions for the AI proxy and custom rules. |

## B. PRD v2.0 edits to fold back

| # | Change | PRD location | Why |
|---|---|---|---|
| B1 | Backend → **Supabase** (Postgres + Auth + Storage + Realtime) + **Edge Functions**, replacing Node/Express + MySQL + Firebase Auth. | §9.3 | Engineering decision; must match TDM §4 and PTD §12. |
| B2 | AI provider → **OpenAI primary, Gemini fallback**. | §9.3 | Confirms the "OpenAI/Gemini" listing. |
| B3 | **Payment is simulated** for the FYP (no real gateway). The TDM's "Payment/Subscription Gateway" external box is a simulated/conceptual integration. | §4 (revenue), §9.x | TDM §3.4 already allows "conceptual or simplified" capabilities — make payment explicitly one of them. No payment-ledger entity exists in the ERD (price fields only). |
| B4 | **Premium price = $9.99/mo** (A1 decided). Update PRD §4 to $9.99. | §4 | Single price across all docs. |
| B5 | **Product Comparison Matrix doesn't evidence (and partly contradicts) the USP** — found 13 Jun, fix later. The matrix marks Wise Workout `Yes` on all 13 rows (so do most competitors → no visible differentiation), **omits the #1 USP** (verified human-expert marketplace) as a row, and **overclaims two rows vs scope/AI-policy**: "AI / Adaptive Coaching = Yes" (our AI scope is *summaries + suggestions only*; adaptive coaching is the human-expert job per C2) and "Nutrition Tracking = Yes" (nutrition is **out of scope** per PTD charter §5.4 / scope §5.6). Fixes: (a) **add row** "Verified Human-Expert Services (in-app, à la carte)" → competitors mostly `No`, us `Yes`; (b) **add/relabel** "Expert services separate from premium (à la carte)" → us `Yes`; (c) **rename** "AI / Adaptive Coaching" → "AI Progress Summaries & Plan Suggestions" and mark honestly (Freeletics `Yes`, Strava `Limited`, most `No/Limited`, us `Yes` — no adaptive-coaching claim); (d) **Nutrition Tracking → `No`/drop** for us. Apply to the PRD matrix (PRD §2.3, p16) **and** PTD §2.2 (rendered table + Figure 1 image) so they agree with §2.5 USP + SWOT. | PRD §2.3 (matrix) ↔ PTD §2.2 / §2.5 | The one table meant to prove differentiation currently shows parity and breaks the narrow-AI + nutrition-scope decisions. |

## C. SRS v2.0 edits to fold back

| # | Change | SRS location | Why |
|---|---|---|---|
| C1 | Backend stack references → Supabase (mirror of B1). | §3.8.3 / §3.8.5 / §3.8.6 | Keep SRS env section consistent with PRD/TDM. |
| C2 | **AI scope = progress summaries + plan suggestions only** — everything else rule-based (reminders, inactivity/rest alerts, basic plan skeleton) or human-expert (coaching, custom plans). | §3.9 | TDM §3.4 confirms this narrow scope; SRS already aligned — just verify no over-claim remains and that build-plan §5 stays in sync. |
| C6 | **AI-generated plans follow the user's selected goal timeline**, not a fixed 4-week/monthly cycle. Free plans are basic AI-assisted; Premium plans are personalised with richer workout detail. | US18 / US37 / fitness-goal use cases | Current `suggest-plan` and app fallback generate `timeline_weeks` worth of workouts. PTD/PUM must describe full-timeline plans and avoid saying plans are always one month. |
| C7 | **Plan viewing is now a My Plans flow:** Train → `VIEW PLANS` → My Plans list → Plan Detail. Users can open active/saved generated plans and activate a saved plan. | US18 / US37 / wireframe walkthrough text | The PUM should not say "View full plan" as the only action. PTD can mention saved-plan retention because old generated plans are preserved rather than deleted. |
| C5 | **Reword US17** — "simple charts or reports" over-claims: the basic tier shows **numeric stat tiles with +/- comparison values**, no graphical charts (charts live in Premium US34). Proposed: *"…view simple progress reports so that my fitness progress is easier to understand"* (decided 12 Jun). | §3/§4 (US17) | Matches the built Basic Workout Analytics card; sequence diagram US17 already drawn to the corrected meaning. |
| C4 | ~~Reword US18~~ **CANCELLED (12 Jun, later same day):** the team decided Free DOES get a **basic AI plan** (matches the SRS wording and the WBS "Basic AI Suggested Workout"). Both tiers now call the `suggest-plan` Edge Function — Free = basic depth, Premium = personalised; the rule-based skeleton is only the offline fallback. **No SRS edit needed for US18.** | §3/§4 (US18) | SRS was right after all; engineering realigned to it. |
| C3 | Confirm the 64 use cases all map to an entity in the **TDM §8 ERD** (esp. expert reviews, deliverables, service requests, challenges, contact messages). | §4.x | The ERD is now the schema of record; any use case with no backing entity is a gap to close in one doc or the other. |

## D. Resolved by the TDM (no longer open)

| # | Was | Now resolved by |
|---|---|---|
| D1 | **`database-v1.md` reconciliation** — open question on expert reviews + whether paid services / custom plans / simulated payment were modelled. | **TDM §8 ERD settles it:** `ExpertReview` is **kept**; the expert layer = `ExpertService` (listings, `PricingModel`/`PriceCents`) → `ServiceRequest` (`QuotedPriceCents`, status) → `Deliverable` (expert-created content/plans to the client); subscriptions via `Subscription` (`PriceCents`, `RenewsAt`); payment **simulated** (price fields only, no transaction ledger). **Action: align [../reference/database-v1.md](../reference/database-v1.md) to TDM §8, then generate DDL from the TDM ERD** — not the other way round. |
| D2 | AI scope uncertainty. | TDM §3.4 confirms summaries + suggestions only (see C2). |

### TDM §8 ERD — entity roster (the schema of record, ~26 entities)
`User` · `FitnessProfile` · `FitnessGoal` · `FitnessPlan` · `PlannedWorkout` · `WorkoutType` · `WorkoutSession` · `ExerciseLog` · `ConnectedDevice` · `HealthTag` · `Subscription` · `Follow` · `Post` · `PostComment` · `PostLike` · `Challenge` · `ChallengeParticipant` · `ExpertProfile` · `ExpertService` · `ExpertCategory` · `ServiceRequest` · `Deliverable` · `ExpertReview` · `ExpertVerificationDocument` · `Feedback` · `ContactMessage`

Notable: AI **progress summaries are not a stored entity** (generated on demand); `FitnessPlan.GenerationStrategy` records the AI depth tier — `basic` (Free) vs `personalised` (Premium); both are AI-generated since 12 Jun (C4-cancelled), with the rule skeleton as offline fallback. `FitnessPlan.DurationWeeks` follows the user's selected goal timeline (C6). `RegeneratedCount` gates Free regenerations; old plans are preserved and can be reselected through My Plans (C7); `WorkoutSession.Notes` stays private (privacy invariant).

---

## How to use this log
- Before re-rendering any deliverable (PTD/PUM included), clear the rows that touch it.
- The **PTD's tech-stack (§12) and architecture (§16.2) must match B1/A4** or the PTD contradicts itself — see [ptd-pum-assembly.md](ptd-pum-assembly.md) §12/§16.
- When a row is resolved, mark it inline (**DONE**/**CANCELLED** with date) — the convention used for A3 and C4.
