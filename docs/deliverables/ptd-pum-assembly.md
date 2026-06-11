# PTD & PUM — Assembly Checklist

How to assemble the two deliverables due **~10–13 June** (basic-prototype milestone, PRD §8.2 #5):

- **PTD** — Preliminary Technical Documentation (the comprehensive technical doc; sample ≈184 pp, 18 sections)
- **PUM** — Preliminary User Manual (focused; sample ≈33 pp, 4 sections)

**The big realisation:** you've already written most of the PTD. It is essentially your **PRD v2.0 + SRS v2.0 + TDM v3.0** (5 Jun system-design doc — architecture, activity diagrams, ERD, wireframes) reorganised into the sample PTD structure. The genuine remaining work is **(a) consolidation/reformatting** and **(b) a handful of small net-new sections** (SWOT, USP, charter, comms plan, level-1 DFD, glossary). Don't rewrite what the PRD/SRS/TDM already contain. Before assembling, clear the [reconciliation log](doc-reconciliation-log.md) rows that touch the stack/architecture.

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
| 16.2 | System Architecture Design | 🟢 | **TDM §4** (client-server architecture diagram, p10) + [../architecture/bce-design.md](../architecture/bce-design.md) — name the concrete stack (Supabase/Edge/AI) per reconciliation A4 | |
| 16.3 | Database Design | 🟢 | **TDM §8 ERD is the schema of record** (reconciliation **D1 — resolved**); render it directly. [../reference/database-v1.md](../reference/database-v1.md) is the working copy to align to it | |
| 16.4 | Wireframe Design | 🟢 | **TDM** wireframes + flow-explorer mock renders + [../reference/screens-v1.md](../reference/screens-v1.md) | |
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

The TDM (**v5, 6 Jun — the canonical version**) **covers §16 System Design well**: §4 architecture, §3.3 context DFD, §5 activity diagrams, §7 wireframes, §8 ERD. ⚠️ **Its §6 sequence diagrams are wrong (team-confirmed 12 Jun)** — do **not** copy them; use the **58 rendered per-story diagrams in [sequence-diagrams/](sequence-diagrams/)** (one per US07–US64, simplified BCE style; sources included). Also remember PRD v3 ≡ v2: apply the reconciliation log §B edits (Supabase stack, $9.99, simulated payment) to any PRD-sourced PTD section during assembly.

---

## PUM — section-by-section

| § | Section | Status | Source / what to do | Owner |
|---|---|---|---|---|
| — | Document Control | 🔴 | Revision table | |
| 1 | Introduction | 🟢 | What the app is / who it's for — from PRD §1 + §6.2 | |
| 2 | Installation Instructions | 🟡 | **Preliminary**: planned path — Android APK via the marketing website after registration (PRD §6.5), iOS via TestFlight/dev; permissions (location, motion, notifications) | |
| 3 | Key Features | 🟢 | User-facing phrasing of **SRS §3.2** feature tables / WBS | |
| 4 | Initial GUIs (screen walkthrough) | 🟢 | **Flow-explorer mock screen renders** + TDM wireframes; one sub-section per screen with a screenshot + step text. Screens: [../reference/screens-v1.md](../reference/screens-v1.md) | |

The PUM is the smaller lift — mostly screenshots from the mock + walkthrough text. With no live app yet, the mock screens are the "preliminary GUIs" (exactly what "preliminary" means here).

> **Drafts written:** [pum-net-new-sections.md](pum-net-new-sections.md) has drop-in drafts for Document Control, §1 Introduction, §2 Installation Instructions, §3 Key Features, and §4 screen walkthroughs (10 core-journey screens, each keyed to its TDM §7 screenshot).

---

## Logistics

- **Format:** submitted PTD/PUM are Word/PDF. These markdown notes are the assembly map; the actual document is the team's Word template. Render PlantUML/Mermaid diagrams to PNG.
- **Naming:** `FYP-26-S2-37_PrelimTechDocs` / `FYP-26-S2-37_PrelimUserManual`.
- **Cover page:** CSIT-26-S2-05, Group FYP-26-S2-37, Supervisor Mr Premrajan, team table from [../project-description.md](../project-description.md), Revision/date footer to match PRD/SRS style.
- **Consistency check:** the PTD's tech-stack + architecture must match build-plan §2/§10 (Supabase, not the PRD's old Node/Express) — otherwise the PTD will contradict itself.
