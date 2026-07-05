# User Stories — build tracker

All **64 user stories** from the **SRS v2.0 §3** (canonical; `../FYP_docs/Submissions/SRS/`),
mirrored here with engineering build status. **The SRS is the source of truth for wording and
scope** — update status here as features land; never edit story text without an SRS change
(log it in [../deliverables/doc-reconciliation-log.md](../deliverables/doc-reconciliation-log.md)).

Last updated **7 Jul 2026** (after the Experts cluster: US27–US29 ✅, US49–US51 🟨). Tally: 20 ✅ · 12 🟨 · 32 ⬜.

**Legend:** ✅ built & verified · 🟨 partial (see note) · ⬜ not started

**Score:** 13 built · 10 partial · 41 not started


## Unregistered user (US01–US06)

| ID | Status | User story | Build note |
|---|---|---|---|
| US01 | ⬜ | As an unregistered user, I want to view the Wise Workout marketing website so that I can understand the platform before creating an account. | Marketing website — separate deliverable, not the app |
| US02 | ⬜ | As an unregistered user, I want to view app features, subscription highlights, and pricing so that I can understand the difference between free and premium access. | Marketing website — separate deliverable, not the app |
| US03 | ⬜ | As an unregistered user, I want to view expert information so that I can understand what types of professional support are available through the platform. | Marketing website — separate deliverable, not the app |
| US04 | ⬜ | As an unregistered user, I want to contact support so that I can ask questions about the platform before creating an account. | Marketing website — separate deliverable, not the app |
| US05 | ⬜ | As an unregistered user, I want to create an account so that I can become a registered user and access the mobile application. | Signup lives on the website; app is login-only by design |
| US06 | ⬜ | As an unregistered user, I want to apply as an expert so that I can offer professional fitness or wellness services through the platform after approval. | Expert application — website + admin approval flow |

## Registered Free user (US07–US31)

| ID | Status | User story | Build note |
|---|---|---|---|
| US07 | ✅ | As a registered free user, I want to log in securely so that I can access my account and use the basic features of the platform. | Login / log out (Profile #13) |
| US08 | ✅ | As a registered free user, I want to log out of my account so that I can securely end my session after using the platform. | Login / log out (Profile #13) |
| US09 | ✅ | As a registered free user, I want to reset my password so that I can regain access if I forget my login details. | Forgot Password #4 + Change Password (#13.3) reset email |
| US10 | ⬜ | As a registered free user, I want to access the mobile application after logging in so that I can install and use the application. | Website flow: log in on the site → download the app (clarified 12 Jun). The in-app splash auto-login (built) belongs to US07; website not built |
| US11 | ✅ | As a registered free user, I want to create and update my fitness profile so that the system can understand my goals, preferences, and fitness needs. | Fitness Profile #13.1 (batched save, custom tags) |
| US12 | ✅ | As a registered free user, I want to record and manage workout activities so that I can keep my exercise history accurate. | Capture #7/#9/#10 + edit/delete in History detail |
| US13 | ⬜ | As a registered free user, I want to manually enter workout details so that I can record activities that are not automatically detected. | Manual entry UI not built (schema supports it: null device) |
| US14 | ✅ | As a registered free user, I want to synchronise exercise data from smartphone sensors or supported wearable devices so that my fitness records are more complete. | Phone GPS/steps ✅ + wearable pairing (#7.1, mock BLE scan per spec) with simulated HR streaming into sessions (avg/max persisted, device linked); real BLE/HealthKit slots in behind the same WorkoutDataSource later |
| US15 | ✅ | As a registered free user, I want to view limited workout history and basic progress summaries so that I can understand my recent activity and consistency. | History #12 + analytics ✅; Free cap = current calendar month, enforced at the query level (12 Jun) |
| US16 | ✅ | As a registered free user, I want to view basic exercise effect estimates so that I can understand the results of my workout activities. | MET-based calorie estimate per session (entity rule, profile weight w/ sex-based default 70/55 kg) + XP; computed live since 12 Jun. Method + accuracy caveat: [reference/calorie-estimation.md](../reference/calorie-estimation.md) |
| US17 | 🟨 | As a registered free user, I want to view simple charts or reports so that my fitness progress is easier to understand. | Analytics tiles with +/- deltas ✅ - no graphical charts at basic tier by design. **Wording change queued (log C5): drop "charts"** |
| US18 | ✅ | As a registered free user, I want to receive basic AI progress summaries and basic AI-assisted fitness plan suggestions so that I can better understand my activity data and follow a simple workout routine. | AI summary + basic AI plan — **live on OpenAI gpt-4o-mini** (12 Jun); Gemini → rule fallback |
| US19 | 🟨 | As a registered free user, I want to receive workout reminders so that I can stay consistent with my planned exercise activities. | Preference toggles #13.4 ✅; flutter_local_notifications wired but no scheduling yet |
| US20 | ⬜ | As a registered free user, I want to receive inactivity alerts so that I am reminded when I have not met my scheduled exercise goals. | Pref toggles exist; rule-based alert engine pending |
| US21 | ⬜ | As a registered free user, I want to receive rest alerts when I may be exercising too much so that I can avoid overtraining. | Pref toggles exist; rule-based alert engine pending |
| US22 | ✅ | As a registered free user, I want to view community posts so that I can stay connected with other fitness users. | Community feed live (6 Jul): polymorphic posts (workout_share / level_up / challenge_result), friends+self scope |
| US23 | ✅ | As a registered free user, I want to create posts, like posts, and comment on posts so that I can participate in the Wise Workout community. | Share-post creation, like toggle, flat comments + owner caption edit/delete all live (6 Jul) |
| US24 | ✅ | As a registered free user, I want to follow other users so that I can keep up with their shared fitness progress. | Mutual friends model (6 Jul): search, Add Friend/Unfriend (atomic pair via add_friend RPC), User Profile #11.2 |
| US25 | ✅ | As a registered free user, I want to join simple fitness challenges and earn badges so that I can stay motivated. | Challenges live (6 Jul): join/leave/create, live-computed leaderboards (challenge_leaderboards RPC); "badges" = XP/levels per design (SRS lag noted) |
| US26 | ✅ | As a registered free user, I want to share selected achievements or challenge results so that I can show my progress while controlling what information is shared. | Named FB/IG/Twitter/TikTok buttons + workout_share post ✅; buttons open the OS share sheet (deep links = later sprint) |
| US27 | ✅ | As a registered free user, I want to browse expert profiles and service listings so that I can find professional support when needed. | #6 live (7 Jul): Experts/Service Listings sub-tabs, search, follow-heart; #6.1 Expert Detail |
| US28 | ✅ | As a registered free user, I want to browse expert categories so that I can identify what type of expert support may suit my fitness goals. | Category chips from the active expert_categories catalog filter both sub-tabs (7 Jul) |
| US29 | ✅ | As a registered free user, I want to request expert services as a paid add-on so that I can receive professional support when needed. | #6.2 request modal (simulated payment, price snapshot) → pending → deliverables → review; MY PURCHASES on #5 (7 Jul) |
| US30 | ⬜ | As a registered free user, I want to browse and purchase expert-created content so that I can access professional fitness guidance when needed. | Experts marketplace — placeholder tab |
| US31 | ⬜ | As a registered free user, I want to view upgrade options so that I can decide whether to subscribe to premium features. | Go Premium pill is a placeholder; Upgrade #16 pending |

## Registered Premium user (US32–US40)

| ID | Status | User story | Build note |
|---|---|---|---|
| US32 | ✅ | As a registered premium user, I want to access all registered free user features so that I can use the full platform experience. | Premium role inherits all Free features (role-aware UI) |
| US33 | ✅ | As a registered premium user, I want to view full workout history so that I can review my long-term activity records. | Premium queries lifetime history (no from-bound); Free is month-capped |
| US34 | ⬜ | As a registered premium user, I want to access advanced progress analytics so that I can understand my fitness trends in more detail. | Advanced analytics / detailed estimates pending |
| US35 | ⬜ | As a registered premium user, I want to view detailed short-term and long-term exercise effect summaries so that I can understand how my workouts affect my progress over time. | Advanced analytics / detailed estimates pending |
| US36 | 🟨 | As a registered premium user, I want to receive personalised AI progress summaries, fitness plan suggestions, and personalised fitness reports so that I can get more relevant guidance. | Personalised AI summary live (goal context, gpt-4o-mini); reports pending |
| US37 | ✅ | As a registered premium user, I want to receive personalised AI-assisted fitness plan suggestions based on my profile, activity history, and goals so that the guidance matches my needs. | Live AI plans (gpt-4o-mini, strict schema + validation); My Plans + Plan Detail #8 with regenerate (Free capped at 1) |
| US38 | ⬜ | As a registered premium user, I want to customise plan duration, workout frequency, preferred workout categories, target calories, daily or weekly weight loss goals, and preferred rest days so that the fitness plan fits my schedule and needs. | Personalised plans / reminders / subscription mgmt pending |
| US39 | ⬜ | As a registered premium user, I want to receive personalised workout reminders, inactivity alerts, and rest alerts so that I can maintain a balanced routine. | Personalised plans / reminders / subscription mgmt pending |
| US40 | ⬜ | As a registered premium user, I want to view or manage my subscription status so that I can understand and control my paid access. | Personalised plans / reminders / subscription mgmt pending |

## Expert user (US41–US52)

| ID | Status | User story | Build note |
|---|---|---|---|
| US41 | ⬜ | As an expert user, I want to register or apply as an expert so that I can offer professional fitness or wellness services through the platform. | Expert portal pending |
| US42 | 🟨 | As an expert user, I want to log in securely so that I can access my expert account and manage my expert functions. | Shared auth (login/logout/reset) works; expert portal pending |
| US43 | 🟨 | As an expert user, I want to log out of my expert account so that I can securely end my session. | Shared auth (login/logout/reset) works; expert portal pending |
| US44 | 🟨 | As an expert user, I want to reset my password so that I can regain access if I forget my login details. | Shared auth (login/logout/reset) works; expert portal pending |
| US45 | ⬜ | As an expert user, I want to create and manage my expert profile so that users can understand my background, specialisation, and services. | Expert portal pending |
| US46 | ⬜ | As an expert user, I want to manage my professional information and expertise categories so that my profile accurately represents my services. | Expert portal pending |
| US47 | ⬜ | As an expert user, I want to create and manage service listings so that users can request the services I offer. | Expert portal pending |
| US48 | ⬜ | As an expert user, I want to upload or manage expert-related content so that I can provide useful fitness or wellness information to users. | Expert portal pending |
| US49 | 🟨 | As an expert user, I want to view user service requests so that I can understand what support users are asking for. | Expert shell live (7 Jul): dedicated 5-tab nav (#20–24 track) w/ dashboard, services list, request inbox, clients, expert profile; create/edit services deferred |
| US50 | 🟨 | As an expert user, I want to accept or reject service requests so that I can manage the services I provide through the platform. | Accept/Decline live via RPC-guarded transitions (7 Jul); portal-grade management deferred |
| US51 | 🟨 | As an expert user, I want to respond with expert advice so that I can provide coaching advice, workout plans, nutrition support, or recovery guidance to users. | Deliverable composer (title/note/section) + Mark complete live (7 Jul); rich segment editor deferred |
| US52 | ⬜ | As an expert user, I want my profile to be verified by an admin so that users can trust the professional services offered on the platform. | Expert portal pending |

## System Admin (US53–US64)

| ID | Status | User story | Build note |
|---|---|---|---|
| US53 | 🟨 | As a system admin, I want to log in securely so that I can access administrative functions. | Shared auth works; admin portal pending |
| US54 | 🟨 | As a system admin, I want to log out securely so that I can end my administrative session. | Shared auth works; admin portal pending |
| US55 | 🟨 | As a system admin, I want to reset my password so that I can regain access to the admin system if needed. | Shared auth works; admin portal pending |
| US56 | ⬜ | As a system admin, I want to manage user accounts, roles, and access levels so that users can only access features suitable for their role and subscription tier. | Admin portal pending |
| US57 | ⬜ | As a system admin, I want to review, approve, or reject expert applications so that only suitable experts can provide services on the platform. | Admin portal pending |
| US58 | ⬜ | As a system admin, I want to manage expert categories so that expert services are organised clearly for users. | Admin portal pending |
| US59 | ⬜ | As a system admin, I want to monitor expert content and service listings so that inappropriate or low-quality content can be handled. | Admin portal pending |
| US60 | ⬜ | As a system admin, I want to manage feedback and platform activity so that the system remains reliable, organised, and trustworthy. | Admin triage pending; the user-side feedback pipeline is already built (no story covers it) |
| US61 | ⬜ | As a system admin, I want to monitor subscription-tier access so that premium features are only available to eligible users. | Admin portal pending |
| US62 | ⬜ | As a system admin, I want to manage subscription access so that free and premium access levels can be controlled correctly. | Admin portal pending |
| US63 | ⬜ | As a system admin, I want to manage the marketing website so that platform information, feature highlights, subscription details, and expert service information remain accurate. | Admin portal pending |
| US64 | ⬜ | As a system admin, I want to maintain platform quality and reliability so that users and experts can use the system safely and consistently. | Admin portal pending |

---

## Cross-check findings (12 Jun 2026)

Four-way trace: stories ↔ **PRD v3** ↔ **TDM v5** ↔ **latest WBS** ↔ **code**. Statuses above already reflect the code audit.

### Latest WBS (post-review drawio) vs stories
- **Stories with no WBS work package:** US13 manual entry (only a generic "Record Workout Activity" node), **US21 rest alerts — WBS plans them Premium-only but the SRS grants them to Free** (divergence to resolve), US30 + US48 expert *content* browse/purchase/upload (WBS only has service listings), US35 detailed effect estimates (nearest node is "View Advanced Workout Analytics"), US38 customise plan (absent from the Premium branch).
- **WBS work packages with no story:** Change Password (all four roles), Update Posts, Create Challenge, Quit Challenge, Save Expert (bookmark), Submit Feedback (Free + Expert "Misc"), Search Workout History (Premium), View Followed Users.

### PRD vs stories
- **PRD v3's body text is byte-identical to v2** — the reconciliation-log §B edits (Supabase stack, OpenAI provider, simulated payment, $9.99) are **still not folded in**: §9.3 still names Node.js/Express + MySQL/PostgreSQL + Firebase, and no premium price appears in the text. Feature scope itself matches the 64 stories (same role feature sets).

### TDM vs stories
- **TDM v5 (6 Jun) supersedes v3** — §6 Sequence Diagrams (empty in v3) is populated but wrong (replaced by our per-story set). ~~CLAUDE.md / STATUS / reconciliation log still say v3~~ → all repo docs re-cited to v5 (12 Jun consistency pass).
- **Design with no story:** ExpertReview (rate/review experts), user-*created* challenges, the XP/level/streak system (US25 still says "badges"), in-app Submit Feedback, expert bookmarking, post edit/delete.
- **Stories with weak/no design:** US20/US21/US39 (no alert-engine flow — prefs are just a JSON blob + toggles), US30/US48 (no content-library entity; only ExpertService → ServiceRequest → Deliverable), US61/US62 (no admin subscription screens).

### Code beyond the stories
Built and working, but mapped to no story: user-side Submit Feedback, XP/levels + auto level-up posts, weekly streak, Free-tier fitness goals, Day/Week/Month analytics with vs-prior deltas, custom health tags, AI-assisted labelling, metric/imperial preference, the 10-type notification catalog, pause/resume + GPS track points, anti-enumeration password reset.

### Suggested follow-ups
1. Fold reconciliation-log §B into the PRD (it was *not* done in v3) — deferred post-submission by decision. ~~Re-cite TDM v5 as canonical~~ ✅ done across all repo docs (12 Jun).
2. Resolve US21: rest alerts Free (SRS) vs Premium-only (WBS) — pick one, log it.
3. Ask the team whether the no-story items (change password, in-app feedback, save expert, create/quit challenge, post edit/delete, XP/levels replacing badges) should become SRS stories or stay implementation detail — they're all in the WBS or TDM, so the SRS is the lagging document.
4. ~~Either enforce the Free history cap or drop the cap banner (US15).~~ ✅ Done 12 Jun — cap enforced at the query level; Profile lifetime stats intentionally bypass it (#13 spec).
