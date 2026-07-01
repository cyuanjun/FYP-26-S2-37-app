# Wise Workout — Docs

Documentation for the **Wise Workout** mobile app (FYP-26-S2-37). The app code lives in this repo's root; this folder holds the planning, design, and reference material.

## Layout

> **Resuming work?** Read **[STATUS.md](STATUS.md)** first — current progress and next steps.

| Folder | What's in it | Start here |
|---|---|---|
| **Requirements** | **The official SRS v2.0 is canonical** (64 use cases + FR/NFR). [requirements/user-stories.md](requirements/user-stories.md) mirrors all 64 user stories with **build status** (the engineering tracker). [requirements/urs.md](requirements/urs.md) is **deprecated** — superseded by the SRS. | [user-stories.md](requirements/user-stories.md) + SRS v2.0 (team docs) |
| **[deliverables/](deliverables/)** | FYP submission-document prep — assembly checklists, cross-doc change log, and the PTD/PUM net-new drafts | [ptd-pum-assembly.md](deliverables/ptd-pum-assembly.md), [doc-reconciliation-log.md](deliverables/doc-reconciliation-log.md), [ptd-net-new-sections.md](deliverables/ptd-net-new-sections.md), [pum-net-new-sections.md](deliverables/pum-net-new-sections.md) |
| **[architecture/](architecture/)** | How the real Flutter app is built | [build-plan.md](architecture/build-plan.md), [bce-design.md](architecture/bce-design.md) |
| **[reference/](reference/)** | The spec carried over from the design phase — data model, design system, screen-by-screen specs | [database-v1.md](reference/database-v1.md), [screens-v1.md](reference/screens-v1.md) |
| **[testing/](testing/)** | QA evidence — the running **[bug-log.md](testing/bug-log.md)** (symptom → root cause → fix → commit), feeds PTD testing + module testing | [bug-log.md](testing/bug-log.md) |
| **[archive/](archive/)** | Legacy docs for the React flow-explorer mock (kept for provenance; not the build target) | — |
| [prototype-demo-guide.md](prototype-demo-guide.md) | **Run & demo the prototype** — setup, walkthroughs, test accounts, backend verification | start here to demo |
| [project-description.md](project-description.md) | The FYP project brief | — |

## Reading order for someone new

0. [STATUS.md](STATUS.md) — current progress + what's next (if you're resuming).
0b. [prototype-demo-guide.md](prototype-demo-guide.md) — **run & demo the prototype**: setup, manual-test walkthrough (do this → see this), test accounts, backend verification.
1. [project-description.md](project-description.md) — what we're required to build.
2. **PRD v2/v3 + SRS v2.0 + TDM v5** (the team's submitted docs; TDM §6 superseded by our sequence-diagram set) — canonical requirements (PRD/SRS) and system design: architecture, ERD (§8), wireframes (TDM). Divergences between them and engineering decisions are tracked in [deliverables/doc-reconciliation-log.md](deliverables/doc-reconciliation-log.md). ([requirements/urs.md](requirements/urs.md) is deprecated.)
3. [architecture/build-plan.md](architecture/build-plan.md) — scope, stack, roadmap, team split.
4. [architecture/bce-design.md](architecture/bce-design.md) — BCE architecture + robustness/sequence diagrams + traceability.
5. [reference/database-v1.md](reference/database-v1.md) — the 26-entity schema and screen→data map.
6. [reference/screens-v1.md](reference/screens-v1.md) — per-screen UI specs.
7. [reference/calorie-estimation.md](reference/calorie-estimation.md) — MET calorie method + accuracy caveat (US16).
8. [simplify.md](simplify.md) — code-structure map (for presentations) + redundancy/simplification candidates.

## Notes

- **`reference/` is now canonical.** It's a copy of the design-phase docs; treat it as the source of truth for the build and let the original flow-explorer copies go stale.
- Some `archive/` docs cite mock source paths (`../app/src/...`, `../CLAUDE.md`) that don't exist in this repo — they're provenance references to the React mock, intentionally left as-is.
