---
name: seq-diagrams
description: Continue the per-user-story BCE sequence diagram review/redraw for Wise Workout — walk US-by-US with the user, redraw to the sample-PTD convention, re-render PNGs, update the review state, commit.
---

# Sequence-diagram review & redraw (Wise Workout FYP)

You are continuing an in-progress, story-by-story review of the 58 sequence diagrams
(one per SRS user story US07–US64; US01–US06 are the marketing website and have no
app diagram). The user confirms or corrects each diagram's *meaning*; you redraw,
re-render, and commit.

## Where everything lives

- **Diagrams:** `docs/deliverables/sequence-diagrams/USnn-<slug>.png` (drop into Word)
- **Sources:** `docs/deliverables/sequence-diagrams/src/USnn-<slug>.mmd` (Mermaid)
- **Verbatim stories + build status:** `docs/requirements/user-stories.md`
- **BCE vocabulary** (Boundary/Control/Entity names): `docs/architecture/bce-design.md`
  §2.2–§2.4 — built stories use shipped class names from `lib/`, unbuilt stories use the
  §2.4 design inventory. Never invent names when one exists there.
- **Folder README:** `docs/deliverables/sequence-diagrams/README.md` (format contract)

## The format contract (sample-PTD convention — do not deviate)

Exactly this shape per diagram:

```
---
title: "USnn — Short title"
---
sequenceDiagram
  actor A as <Role>                      %% Registered Free User / Registered Premium User / Expert User / System Admin
  participant B as «Boundary»<br/><Screen>
  participant C as «Control»<br/><UseCaseControl>
  participant E as «Entity»<br/><DomainEntity from the 26-entity ERD>
  ... messages ...
  alt <normal> ... else <alternate> ... end     %% only when a real alternate exists
  note over E: <gateway/Supabase truth, e.g. "persisted via WorkoutGateway → Supabase (RLS)">
```

Rules learned the hard way:
- **Three lifelines + actor, always.** The third box is «Entity» (sample convention), NOT
  «Gateway» — the gateway/Supabase path goes in the closing `note over E`.
- Entities must be real ERD entities (roster in `docs/deliverables/doc-reconciliation-log.md`
  §D). Auth flows with no domain entity use `User credentials (auth.users)` + a note that
  Supabase Auth owns it. Never show an entity validating credentials.
- **No semicolons in message labels** (Mermaid statement separator — broke 6 renders). Use
  dashes. Avoid double quotes inside labels except short UI strings.
- Keep diagrams SIMPLE: one flow, ≤ ~12 messages, one alt block max.
- Architecture facts to keep truthful where relevant: Free history cap = current calendar
  month (query-level); calories = MET × kg × h computed at session end and SAVED;
  both tiers get AI plans (Free basic / Premium personalised) via the suggest-plan Edge
  Function with rule-based fallback; plans are a 4-week monthly cycle; preferences are a
  strict contract (only preferred workout types scheduled); payment simulated ($9.99/mo);
  share = named FB/IG/Twitter/TikTok buttons; reminders/alerts are rule-based, not AI;
  wearable pairing is mock-BLE with simulated HR (real BLE later, same interface).

## Render command (per changed file)

```bash
cd docs/deliverables/sequence-diagrams
npx -y @mermaid-js/mermaid-cli -i src/USnn-<slug>.mmd -o USnn-<slug>.png -b white -s 2
```

## The working loop (one story at a time)

1. Read the next story's row in `docs/requirements/user-stories.md` and its `.mmd` source.
2. Present to the user: the **verbatim story**, your **plain-English reading of what it
   means**, and the current diagram's flow in one short block. Ask if it matches.
3. If the user corrects the meaning: update the `.mmd` (and, if the correction changes
   scope, the story's build-status note in `user-stories.md`; log requirements-level
   changes in `docs/deliverables/doc-reconciliation-log.md` §C and defects in
   `docs/testing/bug-log.md` DOC- table).
4. Re-render the PNG, update the **Review state** below, commit with a message like
   `USnn: <what changed>`.
5. Move to the next story. Keep answers terse — the user reviews fast.

## Review state (UPDATE THIS SECTION as you go)

- **Reviewed & confirmed:** US07–US09, US11, US13, US15
- **Reviewed & corrected:** US10 (website login-gated app download — just the download,
  no auth sub-flow), US12 (continuous recording loop: GPS/HR/steps + manage note),
  US14 (pairing only — ConnectedDevice; recording lives in US12), US16 (estimates
  computed once at session end and SAVED, then read back), US17 (numeric tiles with
  +/− deltas, NO charts at basic tier — wording fix queued as log C5), US18 (SPLIT into
  US18a basic AI summary + US18b basic AI plan; both tiers AI per WBS/SRS; C4 cancelled)
- **PAUSED MID-QUESTION at US19:** asked the user whether the diagram should focus on
  the settings toggle that schedules the reminder (current drawing) or on the moment the
  reminder arrives (phone buzzes). Resume by re-asking exactly that.
- **Not yet reviewed:** US19–US64 (skip re-reviewing US14/US16-18 content already settled
  above; US20–21 carry a tier-TBD note — rest alerts Free per SRS vs Premium per WBS,
  decision still open with the team).

## Decisions already locked (do not re-litigate)

- TDM v5 canonical EXCEPT §6 (wrong — these diagrams replace it; PTD sources from here)
- US10 = website download gate; app is login-only; accounts created on website only
- Free tier DOES get basic AI plans and AI summaries (stub→OpenAI gpt-4o-mini live)
- US25 "badges" = XP/levels in our build (SRS wording divergence, logged)
- US30/US48 expert content modelled as ServiceRequest→Deliverable (scope note on diagrams)
- US52 drawn from the admin's side (expert receives the outcome)
