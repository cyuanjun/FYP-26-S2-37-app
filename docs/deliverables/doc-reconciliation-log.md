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
| A3 | **§6 Sequence Diagrams: empty in v3; v5 filled it per user story, but the team confirms those diagrams are WRONG (12 Jun).** | §6 (p16) | **Replace §6 wholesale** from [../architecture/bce-design.md](../architecture/bce-design.md) §5 (7 Mermaid sequence diagrams, matching the as-built BCE code) — **DONE 12 Jun: all 58 per-story diagrams rendered** → [sequence-diagrams/](sequence-diagrams/) (PNG + Mermaid sources). Drop these into TDM §6 / PTD §16; do not use TDM v5 §6. |
| A4 | **Architecture is stack-agnostic.** §3.2/§4 describe a logical service layer (API Controller → Services → DAO → DB) without naming the stack. | §3.2, §4 | Add the concrete stack note (Supabase Postgres + Auth + Storage + Realtime, Edge Functions for AI/custom logic, Flutter client). See B1 — keep TDM, PRD, and PTD §12 identical. Flag the DAO/API-Controller tier as **logical**: physically, Flutter talks to Supabase directly (RLS-enforced) with Edge Functions for the AI proxy and custom rules. |

## B. PRD v2.0 edits to fold back

| # | Change | PRD location | Why |
|---|---|---|---|
| B1 | Backend → **Supabase** (Postgres + Auth + Storage + Realtime) + **Edge Functions**, replacing Node/Express + MySQL + Firebase Auth. | §9.3 | Engineering decision; must match TDM §4 and PTD §12. |
| B2 | AI provider → **OpenAI primary, Gemini fallback**. | §9.3 | Confirms the "OpenAI/Gemini" listing. |
| B3 | **Payment is simulated** for the FYP (no real gateway). The TDM's "Payment/Subscription Gateway" external box is a simulated/conceptual integration. | §4 (revenue), §9.x | TDM §3.4 already allows "conceptual or simplified" capabilities — make payment explicitly one of them. No payment-ledger entity exists in the ERD (price fields only). |
| B4 | **Premium price = $9.99/mo** (A1 decided). Update PRD §4 to $9.99. | §4 | Single price across all docs. |

## C. SRS v2.0 edits to fold back

| # | Change | SRS location | Why |
|---|---|---|---|
| C1 | Backend stack references → Supabase (mirror of B1). | §3.8.3 / §3.8.5 / §3.8.6 | Keep SRS env section consistent with PRD/TDM. |
| C2 | **AI scope = progress summaries + plan suggestions only** — everything else rule-based (reminders, inactivity/rest alerts, basic plan skeleton) or human-expert (coaching, custom plans). | §3.9 | TDM §3.4 confirms this narrow scope; SRS already aligned — just verify no over-claim remains and that build-plan §5 stays in sync. |
| C4 | **Reword US18** — "basic AI-assisted fitness plan suggestions" over-claims AI: the basic plan is the **rule-based** `BuildPlanSkeleton` (AI plan personalisation is Premium, US36/37). Proposed: *"…basic AI progress summaries and a simple suggested workout routine…"* (decided 12 Jun). | §3/§4 (US18) | Keeps the SRS consistent with the locked AI scope (C2); sequence diagram US18 already drawn to the corrected meaning. |
| C3 | Confirm the 64 use cases all map to an entity in the **TDM §8 ERD** (esp. expert reviews, deliverables, service requests, challenges, contact messages). | §4.x | The ERD is now the schema of record; any use case with no backing entity is a gap to close in one doc or the other. |

## D. Resolved by the TDM (no longer open)

| # | Was | Now resolved by |
|---|---|---|
| D1 | **`database-v1.md` reconciliation** — open question on expert reviews + whether paid services / custom plans / simulated payment were modelled. | **TDM §8 ERD settles it:** `ExpertReview` is **kept**; the expert layer = `ExpertService` (listings, `PricingModel`/`PriceCents`) → `ServiceRequest` (`QuotedPriceCents`, status) → `Deliverable` (expert-created content/plans to the client); subscriptions via `Subscription` (`PriceCents`, `RenewsAt`); payment **simulated** (price fields only, no transaction ledger). **Action: align [../reference/database-v1.md](../reference/database-v1.md) to TDM §8, then generate DDL from the TDM ERD** — not the other way round. |
| D2 | AI scope uncertainty. | TDM §3.4 confirms summaries + suggestions only (see C2). |

### TDM §8 ERD — entity roster (the schema of record, ~26 entities)
`User` · `FitnessProfile` · `FitnessGoal` · `FitnessPlan` · `PlannedWorkout` · `WorkoutType` · `WorkoutSession` · `ExerciseLog` · `ConnectedDevice` · `HealthTag` · `Subscription` · `Follow` · `Post` · `PostComment` · `PostLike` · `Challenge` · `ChallengeParticipant` · `ExpertProfile` · `ExpertService` · `ExpertCategory` · `ServiceRequest` · `Deliverable` · `ExpertReview` · `ExpertVerificationDocument` · `Feedback` · `ContactMessage`

Notable: AI **progress summaries are not a stored entity** (generated on demand); `FitnessPlan.GenerationStrategy` + `RegeneratedCount` distinguish rule-based (basic) from AI-suggested (personalised) plans; `WorkoutSession.Notes` stays private (privacy invariant).

---

## How to use this log
- Before re-rendering any deliverable (PTD/PUM included), clear the rows that touch it.
- The **PTD's tech-stack (§12) and architecture (§16.2) must match B1/A4** or the PTD contradicts itself — see [ptd-pum-assembly.md](ptd-pum-assembly.md) §12/§16.
- When a row is folded into a submitted doc, move it to a "Done" note with the doc's new revision number.
