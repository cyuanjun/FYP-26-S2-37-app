# PUM — Net-New Sections (drop-in drafts)

Draft content for the **Preliminary User Manual**. The PUM is the smaller deliverable (sample ≈33 pp, 4 sections): mostly **mock/TDM screenshots + walkthrough text**. With no live build yet, the TDM wireframes are the "preliminary GUIs" — that's exactly what *preliminary* means here.

Copy into the Word template, drop the matching **TDM §7 screenshot** above each walkthrough, and adjust to team voice. Figures consistent with the [reconciliation log](doc-reconciliation-log.md) (premium = **$9.99/mo**, payment simulated).

---

## Document Control

| Version | Date | Modified By | Description |
|---|---|---|---|
| 1.0 | <date> | All team members | Initial preliminary user manual |

---

## §1 Introduction

**Wise Workout** is a cross-platform mobile fitness application (Android + iOS) that helps users record workouts, track progress, receive AI-assisted summaries and plan suggestions, connect with verified fitness experts, and stay motivated through a social feed and challenges.

This Preliminary User Manual introduces the application's main features and walks through the key screens a user encounters. It is written for **end users** — primarily registered free and premium users — and previews the interface and core flows of the app at its current design stage. Because the system is still in development, the screens shown are **preliminary wireframes** and may change in the final release.

The app supports five roles — unregistered visitor, registered free user, registered premium user, verified expert, and system administrator — but this manual focuses on the everyday user journey (free and premium). Expert and admin tools are summarised briefly.

---

## §2 Installation Instructions

> **Preliminary** — these are the planned installation paths; final store links will be confirmed at release.

### Android
1. Visit the Wise Workout marketing website (`fyp-26-s2-37-website.vercel.app`) and create an account, or open the **Download** section.
2. Tap **Download for Android** to get the app package (`.apk`, ~45 MB).
3. If prompted, allow installation from your browser/unknown sources, then open the downloaded file to install.
4. Launch **Wise Workout** and sign in with your account.

### iOS
1. During the project phase, the iOS build is distributed for testing (e.g. via TestFlight / a development build) rather than the public App Store.
2. Accept the test invitation, install, and open **Wise Workout**.
3. Sign in with your account.

### First-run permissions
On first use the app will request:
- **Location** — to record GPS distance/route for outdoor workouts.
- **Motion & fitness** — to count steps and detect activity.
- **Notifications** — for workout reminders and summaries.

Granting these enables full tracking; they can be changed later in your device settings. Workouts can still be logged **manually** without sensor permissions.

---

## §3 Key Features

| Feature | What the user can do |
|---|---|
| **Workout tracking** | Record workouts using phone sensors (GPS + step/motion) or enter them manually; start a **suggested** session from a plan or a **freeform** session on the spot. |
| **Progress & history** | View workout history and basic analytics (day/week/month); Premium adds advanced analytics — HR zones, workload ratio, training load, personal bests. |
| **AI-assisted support** | Receive AI progress summaries and AI plan suggestions; Premium gets personalised plans and detailed workout breakdowns. |
| **Fitness profile & goals** | Set body metrics, training experience, preferences, and a primary goal with a target and timeline; track goal progress. |
| **Experts & services** | Browse verified experts and their service listings, view profiles and reviews, request paid services, and receive expert deliverables. |
| **Social & challenges** | Share posts to a community feed, like/comment, add friends, and join or create challenges with leaderboards; share achievements to Facebook / Instagram / Twitter / TikTok. |
| **Reminders & notifications** | Workout, missed-session, inactivity, and rest reminders; Premium reminders adapt to your schedule. |
| **Subscription** | Upgrade to Premium ($9.99/mo, simulated payment) for advanced analytics, personalised AI, and enhanced reminders; expert services are purchased separately. |

---

## §4 Initial GUIs — Screen Walkthrough

One sub-section per screen: **insert the TDM §7 screenshot**, then the step text below. Covered here are the core user journey screens; the full screen inventory is in the TDM §7 and [../reference/screens-v1.md](../reference/screens-v1.md).

### 4.1 Sign in / Register *(TDM §7.2.3)*
The app opens to the sign-in screen. Enter your email and password and tap **Log in**, or tap the sign-up link to register on the website. Use **Remember me** to stay signed in, or **Forgot password?** to receive a reset link.

### 4.2 Home Dashboard *(TDM §7.2.5)*
After signing in you land on **Home**. It shows your greeting, current level and XP, this week's workout/active-day/minute counts, your active goal with progress, and your active plans. The bottom bar navigates between **Home, Experts, Train, Social, History**.

### 4.3 Record a Workout — Train *(TDM §7.2.19, §7.2.22–7.2.23)*
Open **Train**. To follow your plan, tap **Start suggested workout**; to log something unstructured, tap **Start freeform workout** and pick a type. The live screen shows a timer plus base metrics (time, heart rate) and, for cardio, distance/pace/elevation. Tap **Start** to begin and the control to finish.

### 4.4 Save & Share a Workout *(TDM §7.2.24)*
When you finish, the **Workout Complete** summary shows duration, distance, pace, calories, and heart-rate stats, plus XP earned. Name the workout, record how it felt, optionally add **private notes**, toggle **Share to social**, then **Save & Finish**.

### 4.5 View History *(TDM §7.2.29–7.2.30)*
Open **History** for your past workouts and basic analytics (day/week/month, with vs-last-week comparison). Tap a workout to see its details — duration, calories, heart-rate graph, and training effect. Premium unlocks full history and advanced analytics.

### 4.6 AI Suggested Plan *(TDM §7.2.20–7.2.21)*
In **Train**, open **View full plan** to see your AI-suggested plan (both tiers; rule-based fallback) — a weekly schedule of sessions. Tap a session for details. Premium upgrades these to personalised plans with sets, reps, target zones, and coaching cues.

### 4.7 Experts & Services *(TDM §7.2.15–7.2.18)*
Open **Experts** to browse verified experts or their **service listings**, filter by category, and sort by rating. Open an expert to see their profile, credentials, specialties, and reviews; open a listing to see what's included and the price, then **Request** the service.

### 4.8 Social & Challenges *(TDM §7.2.25–7.2.28)*
Open **Social**. The **Community** tab is your feed — like, comment, and share posts, and find friends. The **Challenges** tab lets you join active challenges or create your own; each challenge shows your progress and a leaderboard.

### 4.9 Profile, Goals & Settings *(TDM §7.2.9–7.2.14)*
Open **Profile** from Home. Here you manage **Account settings**, **Fitness profile** (body metrics, experience, preferences), **Fitness goals** (primary goal, target, weekly commitment, timeline), **Notification settings**, and **Submit feedback**. Free users see **Go Premium** here.

### 4.10 Upgrade to Premium *(TDM §7.2.32)*
**Go Premium** opens the upgrade screen listing Premium unlocks (personalised AI plans, detailed breakdowns, advanced insights, unlimited history) at **$9.99/mo**. Tap **Start Premium** to subscribe (simulated payment); expert services are billed separately.

> **Briefly, for other roles:** Verified experts use a separate set of tabs — **Services, Requests, Clients, Profile** — to publish listings, accept/decline requests, and send deliverables (TDM §7.4). Admins manage users, expert verification, feedback/contact, and categories from the admin portal (TDM §7.5).

---

## Assembly notes
- **Screenshots:** pull the phone-frame renders from **TDM §7** (or the flow-explorer mock) — they're already iPhone-framed.
- **Length:** the sample PUM is ~33 pp; §4 carries most of it via screenshots, so this is mostly a layout exercise.
- **Naming / cover:** `FYP-26-S2-37_PrelimUserManual`; cover page matches the PTD (CSIT-26-S2-05, Group FYP-26-S2-37, Supervisor Mr Premrajan).
