# Wise Workout — Free User Screens (v1)

Index of the Free-user screens (27 spec files; Premium/Expert/Admin tracked below). Each screen has its own file under [screens/free/](screens/free/) with purpose, UI elements (referencing [palette.md](palette.md) for colours and [typography.md](typography.md) for type sizes), and incoming/outgoing edges. Data each screen touches is tracked in parallel in [database-v1.md](database-v1.md).

Status legend: ✅ done · 🟡 in progress · ⬜ pending · 🟪 temporary stub · 📐 spec-only (design locked, code not built)

> **⚠️ Spec-vs-build drift (noted 13 Jun, from the PUM screenshot pass):** these specs describe the **design intent**; some built screens are currently simpler. Known cases: **Dashboard (#5)** is a minimal "Get moving" slice (no digest/weekly-stats/goal card); **Fitness Goals (#13.2)** has no target/timeline controls (only primary goal + weekly commitment); **Account Settings (#13.3)** has no phone field; **Login (#2)** has no "Remember me"; **Train (#7)** card is compact (no VIEW WORKOUT/START PLAN buttons). The PUM walkthrough was written from the **actual build** (see [STATUS.md](../STATUS.md)); reconcile these specs to the build when revisiting them. *Build-side additions since (8–10 Jul): Dashboard gained the Free **Go Premium banner** + MY PURCHASES; Train gained **"Log a workout manually"** (US13); History gained Premium **search**, the **Advanced ›** drill-in (#12.2), and the shared-post link; #10/#12.1 gained the **TRAINING EFFECT** card; Profile gained photo upload + the Premium Manage Subscription row.*

> ⚠️ **The Status column below tracks the React mock, not the Flutter app.** The Flutter build
> state of each screen lives in its spec file's frontmatter `status:` (`built` | `spec-only` |
> `draft`). As of 12 Jun, built in Flutter: #1, #2, #3 (onboarding wizard — no spec file;
> see `lib/boundaries/ui/onboarding/onboarding_flow.dart`), #4, #4.1, #5 (minimal), #7, #7.1,
> #8, #9, #10, #12, #12.1, #13, #13.1–#13.5.

## Auth & onboarding

| # | Screen | File | Status |
|---|---|---|---|
| 1 | Splash | [screens/free/01-splash.md](screens/free/01-splash.md) | ✅ |
| 2 | Login | [screens/free/02-login.md](screens/free/02-login.md) | ✅ |
| 3 | Onboarding (post-login) | _no spec file — built directly; wizard in `onboarding_flow.dart`_ | ✅ (Flutter) |
| 4 | Forgot password | [screens/free/04-forgot-password.md](screens/free/04-forgot-password.md) | ✅ |
| 4.1 | Forgot password — link sent (sub) | [screens/free/04.1-forgot-password-sent.md](screens/free/04.1-forgot-password-sent.md) | ✅ |

## Main

Bottom nav has **5 tabs**: Home (#5 Dashboard) · Experts (#6) · Train (#7) · Social (#11) · History (#12). Profile (#13) is reached via the **top-right circular avatar** on every tab landing, not the nav.

**Header convention:**
- **Dashboard (#5)** uses the personalised "Hi, [name]" greeting on the left — it's the home/landing.
- **All other tab landings** (Train, Experts, Social, History) use a **section title** on the left (e.g. "TRAIN" in display caps).
- Right side is consistent across all tabs: 44 px circular avatar button → Profile.

| # | Screen | File | Status |
|---|---|---|---|
| 5 | Dashboard (Home) | [screens/free/05-dashboard.md](screens/free/05-dashboard.md) | ✅ |
| 6 | Experts | [screens/free/06-experts.md](screens/free/06-experts.md) | ✅ |
| 6.1 | Expert Detail (sub) | [screens/free/06.1-expert-detail.md](screens/free/06.1-expert-detail.md) | ✅ |
| 6.2 | Service Detail (sub) | [screens/free/06.2-service-detail.md](screens/free/06.2-service-detail.md) | ✅ |
| 7 | Train | [screens/free/07-train.md](screens/free/07-train.md) | ✅ |
| 7.1 | Connected Devices (sub) | [screens/free/07.1-connected-devices.md](screens/free/07.1-connected-devices.md) | ✅ |
| 8 | Plan Detail | [screens/free/08-plan-detail.md](screens/free/08-plan-detail.md) | ✅ |
| 9 | Active workout | [screens/free/09-active-workout.md](screens/free/09-active-workout.md) | ✅ |
| 10 | Workout summary | [screens/free/10-workout-summary.md](screens/free/10-workout-summary.md) | ✅ |
| 11 | Social | [screens/free/11-social.md](screens/free/11-social.md) | ✅ |
| 11.1 | Post Detail (sub) | [screens/free/11.1-post-detail.md](screens/free/11.1-post-detail.md) | ✅ |
| 11.2 | User Profile (sub) | [screens/free/11.2-user-profile.md](screens/free/11.2-user-profile.md) | ✅ |
| 11.3 | Challenge Detail (sub) | [screens/free/11.3-challenge-detail.md](screens/free/11.3-challenge-detail.md) | ✅ |
| 12 | History | [screens/free/12-history.md](screens/free/12-history.md) | ✅ |
| 12.1 | History Detail (sub) | [screens/free/12.1-history-detail.md](screens/free/12.1-history-detail.md) | ✅ |
| 13 | Profile (via avatar) | [screens/free/13-profile.md](screens/free/13-profile.md) | ✅ |
| 13.1 | Fitness Profile (sub) | [screens/free/13.1-fitness-profile.md](screens/free/13.1-fitness-profile.md) | ✅ |
| 13.2 | Fitness Goals (sub) | [screens/free/13.2-fitness-goals.md](screens/free/13.2-fitness-goals.md) | ✅ |
| 13.3 | Account Settings (sub) | [screens/free/13.3-account-settings.md](screens/free/13.3-account-settings.md) | ✅ |
| 13.4 | Notifications (sub) | [screens/free/13.4-notifications.md](screens/free/13.4-notifications.md) | ✅ |
| 13.5 | Submit Feedback (sub) | [screens/free/13.5-submit-feedback.md](screens/free/13.5-submit-feedback.md) | ✅ |
| 14 | My Plans | [screens/free/14-my-plans.md](screens/free/14-my-plans.md) | ✅ |

## Settings & upsell

| # | Screen | File | Status |
|---|---|---|---|
| 16 | Upgrade to Premium | [screens/free/16-upgrade.md](screens/free/16-upgrade.md) | ✅ |

## Premium (role: premium)

Premium reuses every Free screen with inline role-gated variants (flip `User.Role` via #16 or the explorer role selector). Only net-new Premium-only screens are listed here.

| # | Screen | File | Status |
|---|---|---|---|
| 13.6 | Subscription Management (sub) | [screens/premium/13.6-subscription-management.md](screens/premium/13.6-subscription-management.md) | ✅ |
| 12.2 | Advanced Workout Analytics (sub) | [screens/premium/12.2-advanced-analytics.md](screens/premium/12.2-advanced-analytics.md) | ✅ |

## Expert (role: expert)

The expert portal is its own track with a dedicated bottom nav — **5 tabs**: Home (#20 Dashboard) · Services (#21) · Requests (#22) · Clients (#23) · Profile (#24). Shared auth + account screens (Login, Account Settings, Notifications) are reused with role-aware content. Per-screen spec docs aren't written yet — these were built directly against the schema.

Fulfillment model: an `ExpertService` is a marketplace *listing* tagged by `Fulfillment` (workout_plan / nutrition / review / session / coaching). A client requests it (#6.2, with a goal message) → the expert accepts on #22 (status `pending → accepted`) → it becomes an engagement under **Clients (#23 Active)** → the expert delivers `Deliverable` documents on #23.1 (a generic sections→items form fitting any fulfillment) → the client reads them on #6.2 → the expert taps "Mark engagement complete" on #23.1 (`accepted → completed`, stamps `completedAt`) → engagement archives to #23 Past + the client's #14 Completed, and the Submit Review CTA appears on #6.2.

| # | Screen | File | Status |
|---|---|---|---|
| 20 | Expert Dashboard (Home) | — | ✅ |
| 21 | Services | — | ✅ |
| 21.1 | Service Detail (sub) | — | ✅ |
| 21.2 | Create/Edit Service (sub) | — | ✅ |
| 22 | Requests | — | ✅ |
| 23 | Clients | — | ✅ |
| 23.1 | Client Detail (sub) | — | ✅ |
| 24 | Expert Profile | — | ✅ |
| 24.1 | Manage Professional Info (sub) | — | ✅ |

## Admin (role: admin)

> **Realization decision (8 Jul 2026): the admin portal ships as a WEB app**, not in the Flutter mobile app. The mock's mobile wireframes below remain the design reference for the web screens' content/flows; layout adapts to desktop web.

The admin portal (in the mock) has a **5-tab bottom nav**: Home (#25) · Users (#26) · Experts (#27) · Monitor (#28) · Categories (#29), plus the shared auth/account screens (Login #2, Forgot Password #4/#4.1, Account Settings #13.3 = change password, Notifications #13.4). Log Out + account links live on **#25.1 Profile** (reached via the dashboard avatar, like the trainee #13). Built incrementally cluster by cluster; per-screen specs aren't written yet.

**#27.1 Expert Review** shows the expert's profile (about / credentials / specialties) alongside the **verification documents** they submitted at signup — an identity doc + certifications (`ExpertVerificationDocument`) — so the admin can verify identity / achievements before Approve / Reject.

**#28 Platform Monitoring** is a two-stream inbox laid out like #26 Users — **Feedback / Contact** bubbles, a keyword + submitter search, and a per-status filter (All/New/Reviewed or All/Open/Resolved with live counts). **Feedback** (`Feedback`) is triaged `new` → `reviewed` (one-way); **Contact** (`ContactMessage`, submitted via the external marketing-site contact form — open to anyone, so no user link) is answered with a `response` + resolved. Both open the polymorphic **#28.1 Monitor Detail** (`?type=feedback|contact&id=…`) to read + act.

**#29 Categories** manages the `ExpertCategory` catalog (the old `ExpertSpecialty` enum, now a CRUD-able entity): add / edit a **name + description**, and **suspend / restore** (no hard delete — a suspended category drops off new-selection pickers but keeps resolving for existing data). Each row shows the description + live usage (N services · M experts).

| # | Screen | File | Status |
|---|---|---|---|
| 25 | Admin Dashboard (Home) | — | ✅ |
| 25.1 | Admin Profile (sub) | — | ✅ |
| 26 | User Management | — | ✅ |
| 26.1 | User Detail (sub) | — | ✅ |
| 27 | Expert Verification | — | ✅ |
| 27.1 | Expert Review (sub) | — | ✅ |
| 28 | Platform Monitoring | — | ✅ |
| 28.1 | Monitor Detail (sub) | — | ✅ |
| 29 | Categories | — | ✅ |

---

## Per-screen file template

```markdown
---
screen: NN-slug
role: free
group: auth | main | settings
status: draft | review | done
---

# NN. Screen Name

**Purpose:** One sentence — why this screen exists.

## UI elements
- Bulleted list (top → bottom)
- Colour tokens from [palette.md](palette.md) (e.g. `accent`, `muted`, `bg`)
- Type tokens from [typography.md](typography.md) named with iOS style + px (e.g. "**Body** 17px", "**Subheadline** 15px", "**Caption 2** 11px")

## Edges
- **From:** which screens flow into this
- **To:** which screens this flows into (with the triggering action)

## Data touched
- **Reads:** entities/columns
- **Writes:** entities/columns
```
