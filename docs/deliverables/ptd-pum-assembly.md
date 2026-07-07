# PTD & PUM — Assembly Checklist

How to assemble the two deliverables due **~10–13 June** (basic-prototype milestone, PRD §8.2 #5):

- **PTD** — Preliminary Technical Documentation (the comprehensive technical doc; sample ≈184 pp, 18 sections)
- **PUM** — Preliminary User Manual (focused; sample ≈33 pp, 4 sections)

> **PTD STATUS (13 Jun): assembled.** Full content built into the v1 Word template →
> `../../FYP_docs/Submissions/PTD/FYP-26-S2-37-PTD-v1-FILLED.docx` (outside this repo), with
> copy-ready sources `PTD-content.md` + `PTD-content-tabs.txt` alongside it. ~23k words / 93 tables
> at PRD/SRS depth (all 64 user stories + 64 full use cases, FR1-12, 6 NFR categories, 15-risk
> register, business model tables, SWOT, charter, comms plan, glossary, appendix). All net-new
> sections below are written **and dropped in**. Figures numbered 1-20. Sample-template wording
> scrubbed (no "property datasets" / sample-citation leftovers). **Remaining:** insert the
> 20 figure images + draw the level-1 DFD (§16.1); update the Word TOC field; apply the 2 deferred
> fixes (reconciliation **B5** matrix-vs-USP, and confirm **107** via `flutter test`).

**The big realisation:** you've already written most of the PTD. It is essentially your **PRD v2/v3 + SRS v2.0 + TDM v5** (5 Jun system-design doc — architecture, activity diagrams, ERD, wireframes) reorganised into the sample PTD structure. The genuine remaining work is **(a) consolidation/reformatting**, **(b) a handful of small net-new sections** (SWOT, USP, charter, comms plan, level-1 DFD, glossary), and **(c) applying the current prototype reconciliation edits** (Supabase stack, simulated payment, AI scope, full-timeline plans, My Plans). Don't rewrite what the PRD/SRS/TDM already contain. Before assembling, clear the [reconciliation log](doc-reconciliation-log.md) rows that touch the stack/architecture.

### Status legend
- 🟢 **Have** — content exists in PRD/SRS/TDM; copy/reformat
- 🟡 **Adapt** — related material exists; light reshaping
- 🔴 **Write** — net-new (all small unless noted)

### Owners (PRD §8.4)
Yuan Jun = coordination/docs · Devanandi = mobile/UI · Foong = backend/DB/API · Jedidiah = website/expert/admin. Fill the **Owner** column before starting.

---

## PTD — section-by-section (mapped to your existing docs)

| § | Section | Status | Source — where it already lives | Owner |
|---|---|---|---|---|
| — | Document Control | 🟡 | Copy the PRD/SRS revision-table format; start fresh for the PTD | |
| 1 | Introduction (problem, purpose, scope, objectives) | 🟢 | **PRD §1** (overview, problem statement, scope, objectives table) | |
| 2.1 | Competitor Market Research | 🟢 | **PRD §2.2** (Strava, MyFitnessPal, adidas, Google Fit, Freeletics, MapMyFitness, Lyfta) | |
| 2.2 | Product Comparison Table | 🟢 | **PRD §2.3** (the colour-coded feature grid) | |
| 2.3 | Key Findings / Conceptualisation | 🟢 | **PRD §2.4** key findings + §2.6 case studies | |
| 2.4 | SWOT Analysis | 🔴 | Net-new (½ pg) — derive S/W/O/T from PRD §2.5 research gap + §6.3 value prop | |
| 2.5 | Unique Selling Point | 🟡 | **PRD §2.5 research gap + §6.3 value prop** → restate as USP (integrated tracking + AI summaries/suggestions + expert layer) | |
| 2.6 | Target Users | 🟢 | **PRD §5** (5 user categories) / **SRS §3.3** user classes | |
| 2.7 | Business Model | 🟢 | **PRD §4** (three-layer model, tiers, revenue, cost, channels) | |
| 3–4 | Data Collection / Acquisition | 🟢 | **PRD §2.7** (connectivity protocols) + **SRS §3.9.8** (data processing) + build-plan §4 (sensor design) | |
| 5.1 | Project Milestones | 🟢 | **PRD §8.2** milestone table | |
| 5.2 | Gantt Chart | 🟢 | **PRD §8.1** Gantt (already drawn) | |
| 5.3 | Work Breakdown Structure | 🟢 | **PRD §3 / SRS §1** WBS diagram (the updated one) | |
| 5.4 | Project Charter | 🔴 | Net-new (1 pg) — objectives/scope/team/supervisor/success criteria; pull from PRD §1 + §8.4 | |
| 5.5 | Communication Management Plan | 🔴 | Net-new (½–1 pg) — stakeholders, channels, cadence, escalation, doc-revision protocol | |
| 5.6 | Roles & Responsibilities | 🟢 | **PRD §8.4** roles table | |
| 6 | Requirement Definition (process) | 🟡 | **SRS §2** + PRD §2 — narrate how requirements were gathered (research, brief, supervisor) & analysed | |
| 7 | Functional Requirements / Hierarchy | 🟢 | **SRS §5** (FR tables) + **PRD §6.4** (FR1–12) + WBS = functional hierarchy + access levels | |
| 8 | Non-functional Requirements | 🟢 | **SRS §6** (security/reliability/performance/maintainability/scalability/usability) | |
| 9 | Other Requirements (user / legal / system-ops) | 🟡 | User = SRS; system/ops = **SRS §3.4 operating env**; **legal/regulatory** 🔴 net-new (PDPA, health-data, app-store, social-platform ToS) | |
| 10 | Risk Management | 🟢 | **PRD §8.5** risk register | |
| 11 | Development Methodologies | 🟢 | **PRD §10** (Agile, sprints, collaboration, testing) | |
| 12 | Technical Stack | 🟡 | **PRD §9** — **update to Supabase** per the [reconciliation log](doc-reconciliation-log.md) (B1/A4) before copying; must match TDM §4 | |
| 13 | User Stories | 🟢 | **SRS §4.x.1** (US01–US64) / PRD §7.1 | |
| 14 | Use Case Descriptions | 🟢 | **SRS §4.x.2** — full descriptions already written for the major use cases | |
| 15 | Use Case Diagrams | 🟢 | **SRS §4.x / PRD §7.2** (5 PlantUML diagrams) | |
| 16.1 | Data Flow Diagram | 🟡 | **TDM §3.3** already has the **context-level DFD** (the Wise Workout Platform Process figure, p8) — reuse it; only the **level-1 DFD** is net-new | |
| 16.2 | System Architecture Design | 🟢 | **TDM §4** (client-server architecture diagram, p10) + [../architecture/bce-design.md](../app/architecture/bce-design.md) — name the concrete stack (Flutter + Supabase Postgres/Auth/Storage/Realtime + Edge Functions + OpenAI/Gemini fallback) per reconciliation A4 | |
| 16.3 | Database Design | 🟢 | **TDM §8 ERD is the schema of record** (reconciliation **D1 — resolved**); render it directly. [../reference/database-v1.md](../app/reference/database-v1.md) is the working copy to align to it | |
| 16.4 | Wireframe Design | 🟢 | **TDM** wireframes + flow-explorer mock renders + [../reference/screens-v1.md](../app/reference/screens-v1.md) | |
| 17 | Conclusion | 🟢 | **PRD §12** | |
| 18 | Glossary | 🔴 | Net-new (½ pg) — BCE, RLS, Edge Function, HR zones, AI-summary vs expert, etc. | |
| 19 | References | 🟢 | **PRD §13** (23 refs) | |

### Genuine net-new for the PTD (all small)

> **Drafts written:** [ptd-net-new-sections.md](ptd-net-new-sections.md) contains drop-in drafts for §2.4 SWOT, §2.5 USP, §5.4 Charter, §5.5 Comms plan, §9.2 Legal/Regulatory, §16.1 level-1 DFD, and §18 Glossary. Copy into the Word template and adjust to team voice.

1. **§16.1 level-1 DFD** (S) — the context DFD already exists in TDM §3.3; only the level-1 expansion is new.
2. **§2.4 SWOT** + **§2.5 USP** (S) — derive from existing research/value-prop.
3. **§5.4 Charter** + **§5.5 Comms plan** (S).
4. **§9.2 Legal & Regulatory** (S–M).
5. **§18 Glossary** (S).
6. **Reconcile §12 Technical Stack** to Supabase — see the [reconciliation log](doc-reconciliation-log.md) (B1/A4). §16.3 DB design is **resolved** (use the TDM §8 ERD).

The TDM (**v5, 6 Jun — the canonical version**) **covers §16 System Design well**: §4 architecture, §3.3 context DFD, §5 activity diagrams, §7 wireframes, §8 ERD. ⚠️ **Its §6 sequence diagrams are wrong (team-confirmed 12 Jun)** — do **not** copy them; use the **58 rendered per-story diagrams in [sequence-diagrams/](sequence-diagrams/)** (one per US07–US64, simplified BCE style; sources included). Also remember PRD v3 ≡ v2: apply the reconciliation log §B edits (Supabase stack, $9.99, simulated payment, current AI-plan scope) to any PRD-sourced PTD section during assembly.

---

## PUM — section-by-section

> **PUM STATUS (13 Jun): built.** Generated by `scripts/build_pum.py` into the v1 PUM Word template →
> `../../FYP_docs/Submissions/PUM/FYP-26-S2-37-PUM-v1-FILLED.docx` (outside this repo), with single-source
> content in `PUM-content.md` and **19 real app screenshots embedded inline** (in `…/PUM/screenshots/`).
> Scope is **built-only** (the 19 screens that actually exist); unbuilt screens were dropped and §1/§3
> trimmed to match. Each screen has a description + a "How to use:" step list. Only manual step left:
> update the TOC field in Word. `build_pum.py` is the authoritative source — re-run to regenerate.

| § | Section | Status | Source / what to do | Owner |
|---|---|---|---|---|
| — | Document Version Control | 🟢 | Revision table (kept from the template) | |
| 1 | Introduction | 🟢 | Trimmed to built features (record → track → AI summaries/plans → goals/history) | |
| 2 | Installation Instructions | 🟢 | Prereqs + Android/iOS + first-run permissions | |
| 3 | Key Features | 🟢 | Built-only feature table | |
| 4 | Initial GUIs (screen walkthrough) | 🟢 | 19 built screens, each: description + "How to use:" + real screenshot | |

The PUM is the smaller lift — mostly screenshots plus walkthrough text. Screenshots are **live iOS-simulator captures** of the built screens (demo account Mia, backend reseeded). Descriptions were corrected to the actual build where it differed from the screen specs (see STATUS "spec-vs-build drift").

> **Superseded:** [pum-net-new-sections.md](pum-net-new-sections.md) was the earlier hand-draft (10 screens); the live document is now generated from `scripts/build_pum.py` (19 screens, built-only, embedded screenshots).

---

## Logistics

- **Format:** submitted PTD/PUM are Word/PDF. These markdown notes are the assembly map; the actual document is the team's Word template. Render PlantUML/Mermaid diagrams to PNG.
- **Naming:** `FYP-26-S2-37_PrelimTechDocs` / `FYP-26-S2-37_PrelimUserManual`.
- **Cover page:** CSIT-26-S2-05, Group FYP-26-S2-37, Supervisor Mr Premrajan, team table from [../project-description.md](../project-description.md), Revision/date footer to match PRD/SRS style.
- **Consistency check:** the PTD's tech-stack + architecture must match build-plan §2/§10 (Supabase, not the PRD's old Node/Express) — otherwise the PTD will contradict itself.
- **Prototype evidence to mention where useful:** Flutter Android/iOS prototype, Supabase backend, live `suggest-plan` / `summarise-progress` Edge Functions, 107 automated Flutter tests (confirm with `flutter test`), and Android emulator verification on Pixel API 35.
