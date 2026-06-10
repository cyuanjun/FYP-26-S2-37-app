# STATUS — where we are, what's next

**Read this first when resuming.** Single source for current progress. Last updated **10 Jun 2026**.

## One-line state
Docs-only phase. **PRD/SRS/TDM are submitted and reconciled; PTD/PUM net-new writing is drafted.** No app code scaffolded yet. Next code step (after the PTD/PUM are assembled) is schema alignment → DDL → Flutter scaffold.

## Calendar
- **~13 Jun** — PTD + PUM due (basic-prototype milestone, PRD §8.2).
- **20 Jun** — End-of-Term-1 review.
- 11 Jul module testing · 1 Aug integration · 13–22 Aug final demo.

---

## Done (this work block)
1. **Reconciled all docs to PRD v2.0 + SRS v2.0**, then to **TDM v3.0** (5 Jun). Engineering decisions lead; submitted docs follow.
2. **Database question resolved** — the TDM §8 ERD is the schema of record (`ExpertReview` kept; expert layer = `ExpertService → ServiceRequest → Deliverable`; payment simulated). database-v1.md flagged to align to it.
3. **Cross-doc change log created** — [deliverables/doc-reconciliation-log.md](deliverables/doc-reconciliation-log.md): every edit needed in PRD/SRS/TDM, plus TDM-internal fixes.
4. **Price decided** — premium = **$9.99/mo** (was $9.90 on the website page).
5. **PTD net-new sections drafted** — [deliverables/ptd-net-new-sections.md](deliverables/ptd-net-new-sections.md) (SWOT, USP, charter, comms plan, legal/regulatory, level-1 DFD, glossary).
6. **PUM net-new sections drafted** — [deliverables/pum-net-new-sections.md](deliverables/pum-net-new-sections.md) (doc control, intro, install, key features, 10-screen walkthrough).
7. **bce-design.md aligned** to the narrow AI scope — `GenerateFitnessPlan` → `BuildPlanSkeleton` (rule) + `SuggestPlan` (AI); added `SummariseProgress`; `OpenAIPlanGateway` → `AiGateway`. Control list, traceability matrix, robustness §4.2 and sequence §5.3 all updated.
8. **CLAUDE.md / README aligned** — TDM v3.0 marked canonical; new docs indexed; settled figures noted.

## Open — team's Word assembly (no code, due ~13 Jun)
- Assemble PTD: copy/reformat PRD+SRS+TDM into the 18-section structure; drop in the net-new drafts; render diagrams to PNG.
- Assemble PUM: layout the net-new drafts + mock/TDM §7 screenshots.
- **Fold reconciliation-log edits into the submitted docs** (Supabase stack, $9.99, simulated payment, AI scope).
- **Fill TDM §6 Sequence Diagrams** (currently an empty placeholder) from bce-design.md §5.

## Next — engineering (after the 13th; not blocked)
1. **Align [reference/database-v1.md](reference/database-v1.md) to the TDM §8 ERD**, then generate **Postgres DDL + RLS starter + seed**.
2. **Scaffold the Flutter project** — BCE folders (`lib/entities`, `lib/controls`, `lib/boundaries/{ui,gateways}`), Riverpod + go_router + Supabase client, design tokens from [reference/palette.md](reference/palette.md).
3. **Vertical slice** — log in → record a phone-GPS workout → history → AI summary → share. (build-plan §7.)

> User flagged for the legal section: confirm whether a privacy policy + minimum-age requirement exist yet or are "preliminary."

---

## Decisions locked (don't re-litigate)
Flutter + Riverpod + go_router + freezed · **Supabase** (Postgres/Auth/Storage/Realtime) + Edge Functions · **OpenAI** primary, Gemini fallback · AI = summaries + suggestions only · three-layer model (Free / Premium / à-la-carte Expert services) · simulated payment · BCE architecture · named social platforms (FB/IG/Twitter/TikTok) · premium $9.99/mo. Rationale lives in [architecture/build-plan.md](architecture/build-plan.md) and CLAUDE.md.
