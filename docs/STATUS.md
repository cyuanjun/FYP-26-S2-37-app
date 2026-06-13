# STATUS — where we are, what's next

**Read this first when resuming.** Single source for current progress. Last updated **13 Jun 2026**.

> 🏃 **Want to run/demo the prototype?** See **[prototype-demo-guide.md](prototype-demo-guide.md)** — how to run, a step-by-step manual-test walkthrough (what to do + what you should see), test accounts, and how to verify the backend.

## One-line state
**App well past the vertical slice; AI is live; PTD assembled.** Backend on Supabase: 26 tables + RLS + `end_workout_session` RPC + **two Edge Functions (`summarise-progress`, `suggest-plan`) running OpenAI gpt-4o-mini** (Gemini → rule fallback). Flutter app (BCE, **107 tests**, Android + iOS verified): vertical slice ▸ 5-tab nav ▸ Profile cluster ▸ first-login onboarding wizard ▸ AI plan generation both tiers (full goal timelines, preference contract) ▸ My Plans + Plan Detail #8 ▸ connected devices #7.1 (mock BLE pairing + simulated wearable HR into sessions) ▸ Free month-cap enforced ▸ MET calories ▸ custom workout types/health tags (creator-private RLS). Trackers: [requirements/user-stories.md](requirements/user-stories.md) (13 ✅ · 10 🟨 · 41 ⬜) · [testing/bug-log.md](testing/bug-log.md). Next: insert figures into the assembled PTD, then Social cluster. (Details below.)

## 13 Jun — PTD assembly + sequence-diagram pass
- **PTD assembled** into the v1 Word template (A4, auto-numbered headings): `../FYP_docs/Submissions/PTD/FYP-26-S2-37-PTD-v1-FILLED.docx` (outside this repo). Content sources also kept in-repo-adjacent as `PTD-content.md` (markdown) + `PTD-content-tabs.txt` (tab tables). ~23k words / 93 tables — at PRD/SRS depth: full competitor write-ups, comparison matrix, SWOT, all **64 user stories** + **64 full use-case descriptions**, FR1-12, 6 NFR categories (31 NFR-IDs), 15-risk register, business model (Free-vs-Premium matrix + cost + channels), charter, comms plan, glossary, appendix. Figures renumbered **1-20**; §15 repointed to the real use-case diagrams (SRS §4 / PRD §7.2).
- **All 59 sequence diagrams** rewritten so arrow labels are the **real functions** (Control methods + gateway/RPC/Edge functions; built = `lib/` names, unbuilt = bce-design §2.4 planned names). Re-rendered. Convention recorded in the seq-diagrams skill.
- **Test count corrected to 107** across PTD + STATUS (was drifting to 109; canonical per CLAUDE.md / bug-log DOC-006). ⚠️ Re-run `flutter test` to confirm before final submission.
- **Deferred (2 items):** (1) reconciliation **B5** — the Product Comparison Matrix doesn't back the USP (and overclaims AI/nutrition rows); fix after assembly. (2) Confirm the test count with `flutter test`.

## Calendar
- **~13 Jun** — PTD + PUM due (basic-prototype milestone, PRD §8.2).
- **20 Jun** — End-of-Term-1 review.
- 11 Jul module testing · 1 Aug integration · 13–22 Aug final demo.

---

## Done (this work block)
1. **Reconciled all docs to PRD v2.0 + SRS v2.0**, then to **TDM v3.0** (5 Jun; **superseded by TDM v5 on 12 Jun** — v5 canonical except §6). Engineering decisions lead; submitted docs follow.
2. **Database question resolved** — the TDM §8 ERD is the schema of record (`ExpertReview` kept; expert layer = `ExpertService → ServiceRequest → Deliverable`; payment simulated). database-v1.md flagged to align to it.
3. **Cross-doc change log created** — [deliverables/doc-reconciliation-log.md](deliverables/doc-reconciliation-log.md): every edit needed in PRD/SRS/TDM, plus TDM-internal fixes.
4. **Price decided** — premium = **$9.99/mo** (was $9.90 on the website page).
5. **PTD net-new sections drafted** — [deliverables/ptd-net-new-sections.md](deliverables/ptd-net-new-sections.md) (SWOT, USP, charter, comms plan, legal/regulatory, level-1 DFD, glossary).
6. **PUM net-new sections drafted** — [deliverables/pum-net-new-sections.md](deliverables/pum-net-new-sections.md) (doc control, intro, install, key features, 10-screen walkthrough).
7. **bce-design.md aligned** to the narrow AI scope — `GenerateFitnessPlan` → `BuildPlanSkeleton` (rule) + `SuggestPlan` (AI); added `SummariseProgress`; `OpenAIPlanGateway` → `AiGateway`. Control list, traceability matrix, robustness §4.2 and sequence §5.3 all updated.
8. **CLAUDE.md / README aligned** — TDM marked canonical (v3.0 then, **v5 since 12 Jun**); new docs indexed; settled figures noted.

## Open — team's Word assembly (no code, due ~13 Jun)
- Assemble PTD: copy/reformat PRD+SRS+TDM into the 18-section structure; drop in the net-new drafts; render diagrams to PNG.
- Assemble PUM: layout the net-new drafts + mock/TDM §7 screenshots.
- **Apply reconciliation-log §B during PTD assembly** (Supabase stack, $9.99, simulated payment, AI scope) — PRD v3 didn't fold them in; the PRD itself is fixed *after* submission (only PTD+PUM are submitted — decided 12 Jun).
- **PTD sequence diagrams: source from bce-design.md §5, NOT TDM §6** — TDM v5's §6 diagrams are wrong (team-confirmed 12 Jun; log A3). TDM v5 is otherwise canonical.

> 🐛 **Bug log:** [testing/bug-log.md](testing/bug-log.md) — every defect with root cause + fix commit (16 app bugs fixed, 5 doc defects, 4 open watch items).

> 📋 **Story-level progress:** [requirements/user-stories.md](requirements/user-stories.md) — all 64 SRS user stories with build status (✅/🟨/⬜), updated per cluster.

## Next — engineering (after the 13th; not blocked)
1. ✅ **Aligned [reference/database-v1.md](reference/database-v1.md) to the TDM §8 ERD** (rosters match at 26 entities) and generated **Postgres DDL + RLS starter + seed** → [`/supabase/`](../supabase/) (`migrations/` + `seed.sql`; see [supabase/README.md](../supabase/README.md)). ✅ **Applied to the hosted Supabase project** (`zbeyytgilrqruttvecdc`) via MCP on 10 Jun — 26 tables · 28 enums · 49 policies · 2 privacy views · catalogs seeded; security advisor triaged (trigger-function EXECUTE revoked; the 2 SECURITY DEFINER privacy views are intentional). *Still to do:* the SECURITY DEFINER RPCs (`endWorkoutSession`, `startPremium`, request transitions) when their controls land; note the MCP-applied migration history uses its own version ids — reconcile if/when adopting the Supabase CLI `db push`.
2. ✅ **Scaffolded the Flutter project** (10 Jun) — `flutter create` (pkg `wise_workout`, android/ios/web), BCE folders (`lib/entities`, `lib/controls`, `lib/boundaries/{ui,gateways}`), deps wired (flutter_riverpod, go_router, freezed + json_serializable, supabase_flutter, geolocator/pedometer, flutter_local_notifications), design tokens in `lib/core/theme/` (palette + iOS type scale), Supabase client initialized in `main.dart` (publishable key via `lib/core/config/env.dart`), go_router skeleton (Splash → Home), `AuthGateway` boundary. `flutter analyze` clean · widget test passes · `flutter build web` succeeds. *Toolchain note:* Android SDK + Xcode/CocoaPods not yet installed — web + connected devices work now.
3. **Vertical slice** — log in → record a phone-GPS workout → history → AI summary → share. (build-plan §7.) Plan: [~/.claude/plans/nested-questing-raccoon.md]; 5 phases (auth · capture · history · AI summary · share); decisions: slice-only, AI stubbed behind AiGateway (stub since replaced by live OpenAI, 12 Jun), test accounts via MCP.
   - ✅ **Phase 1 (auth slice + shell) done & verified on Android + iOS** (10 Jun): first freezed entity (`Profile`) + codegen pipeline; `build.yaml` snake_case; `seq_log`; `Authenticate` control + `ProfileGateway`; Login/Splash/HomeShell + go_router auth redirect. Two test accounts seeded in Supabase Auth (`free@`/`premium@wiseworkout.test`, pw `Password123!`). REST-verified auth + RLS (own-row only); login screen renders on emulator + iOS simulator. *Toolchain note:* manually-seeded `auth.users` needed empty-string token columns (not NULL) to avoid GoTrue 500s.
   - **Toolchains set up (10 Jun):** openjdk@17 + Android cmdline-tools/SDK/emulator (`pixel_api35` AVD), Xcode 26.5 + CocoaPods + iOS 26.5 simulator runtime. Android build needed core-library desugaring for flutter_local_notifications (in `android/app/build.gradle.kts`).
   - ✅ **Phase 2 (capture)** — `WorkoutDataSource`/`PhoneSensorSource` + permissions, `end_workout_session` RPC (XP/streak/level-up), Train/ActiveWorkout/Summary (spec-matched to #7/#9).
   - ✅ **Phase 3 (history)** — History (#12, analytics + grouped cards) + History Detail (#12.1, edit/delete); matches TDM activity diagram.
   - ✅ **Phase 4 (AI summary)** — `summarise-progress` Edge Function (stub, swappable) + `AiGateway` + `SummariseProgress` + History ✨ sheet (AI-assisted label).
   - ✅ **Phase 5 (share)** — `SocialShareGateway` (FB/IG/Twitter/TikTok) + `CreateWorkoutSharePost`/`ShareWorkoutToSocial` + Summary share section (creates `workout_share` Post).
   - ✅ **Vertical slice COMPLETE** — log in → record phone-GPS workout → history → AI summary → share, verified on Android emulator + iOS simulator. Test accounts: `free@`/`premium@wiseworkout.test` (pw `Password123!`).
4. **Breadth build-out** (11–12 Jun, with Claude Code; order: profile → plans → social → experts → premium → dashboard → portals):
   - ✅ **5-tab bottom nav** per spec (Home · Experts · Train · Social · History); Experts/Social are styled later-sprint placeholders (11 Jun).
   - ✅ **Onboarding + Plans COMPLETE** (12 Jun) — first-login wizard (#3: welcome → body metrics + name fallback → training context (+ custom workout types) → goal → AI plan), gated on `profiles.onboarding_completed_at`. **Both tiers get AI plans** (decision per WBS/SRS; recon C4 cancelled): `suggest-plan` Edge Function, Free basic / Premium personalised, **full timeline generation** (foundation→build→peak→recovery across `timeline_weeks`), preferences are a strict contract; `BuildPlanSkeleton` = rule fallback. Train shows the active-plan card (TODAY + current timeline week); **My Plans** lists active/saved plans and lets users activate an inactive plan; **Plan Detail #8** supports dynamic week selection, workout modal, start-today preselect, regenerate w/ Free cap of 1.
   - ✅ **AI LIVE** (12 Jun) — both Edge Functions call **OpenAI gpt-4o-mini** (strict JSON schema + server-side validation for plans; Gemini → deterministic stub degradation). Key in Supabase Edge Function secrets; never ships in the app.
   - ✅ **Connected devices #7.1** (12 Jun) — mock-BLE pairing (spec-sanctioned), phone-sensors pinned system device, simulated wearable HR streamed live into capture, avg/max HR persisted, sessions linked to their source device, last-synced stamps.
   - ✅ **Tiering + data correctness** (12 Jun) — Free history capped to the calendar month at the query level (Profile lifetime stats exempt per #13); MET calorie estimates computed at session end and saved; custom workout types + health tags creator-private via RLS (token-probe verified). **109 tests** green.
   - ✅ **Profile cluster (#13 + 13.1–13.5 + #4) COMPLETE** (12 Jun) — Profile hub (identity, level/XP bar, lifetime stats, Go Premium pill, log out), Fitness Profile (body metrics + activity/experience + preferred workouts + diet/allergy/injury pickers w/ custom tags, batched save), Fitness Goals (goal cards + target/commitment steppers + timeline, active-goal upsert), Account Settings (units instant-commit, change-password reset email), Notifications (10 toggles → `profiles.notification_prefs` jsonb), Submit Feedback (≥10-char guard → `feedback` row, in-screen success), Forgot Password (anti-enumeration sent card). Avatar entry on Home/Train headers; every flow verified on-device against live Supabase. (**71 tests** at the time; suite now 107.)

> User flagged for the legal section: confirm whether a privacy policy + minimum-age requirement exist yet or are "preliminary."

---

## Decisions locked (don't re-litigate)
Flutter + Riverpod + go_router + freezed · **Supabase** (Postgres/Auth/Storage/Realtime) + Edge Functions · **OpenAI** primary, Gemini fallback · AI = summaries + suggestions only · three-layer model (Free / Premium / à-la-carte Expert services) · simulated payment · BCE architecture · named social platforms (FB/IG/Twitter/TikTok) · premium $9.99/mo. Rationale lives in [architecture/build-plan.md](architecture/build-plan.md) and CLAUDE.md.
