# Wise Workout

**FYP-26-S2-37** · UOW/SIM · 4-person team — a cross-platform (Android + iOS) fitness app:
workout capture from phone sensors and wearables, AI training plans and progress summaries,
analytics, social sharing, an expert marketplace, and Free/Premium/Expert/Admin roles.

**Stack:** Flutter (Riverpod · go_router · freezed) on a strict **Boundary–Control–Entity**
architecture · **Supabase** (Postgres + Auth + RLS + Edge Functions) · **OpenAI** `gpt-4o-mini`
(Gemini → rule-based fallback) for the two AI surfaces (progress summaries, plan generation).

## Current state (10 Jul 2026) — feature-complete

Built, tested (221 tests), and verified on the Android emulator + iOS simulator against a live
backend: login → onboarding wizard → AI-generated training plan → phone-GPS capture with
wearable heart rate (simulated **and real BLE**) → manual entry → history + analytics (Premium
search, per-session **Training Effect**, **#12.2 Advanced Analytics** with ACWR/HR zones/bests)
→ AI progress summary → share to named platforms → **social cluster** (feed, likes/comments,
friends, challenges with live leaderboards) → **experts marketplace** (browse → request →
deliverable → review, simulated payment) **plus the complete expert portal** (services editor,
request triage, client engagements, professional info) → **premium upgrade** (simulated checkout,
live role flip, subscription management) → rule-based **notification reminders** → profile-photo
upload. A local Supabase stack (`supabase start`, ports 55321-9) mirrors hosted for development.
Remaining work is outside the app: the admin **web** portal, submitted-doc reconciliation edits,
and one physical-device pass (notifications firing + real-BLE pairing).

- 📍 **Where we are / what's next:** [docs/STATUS.md](docs/STATUS.md)
- 🏃 **Run & demo it** (setup, walkthroughs, test accounts): [docs/prototype-demo-guide.md](docs/prototype-demo-guide.md)
- 📋 **Requirements coverage** (all 64 user stories + build status): [docs/requirements/user-stories.md](docs/requirements/user-stories.md)
- 🐛 **Bug log:** [docs/testing/bug-log.md](docs/testing/bug-log.md)
- 🧭 **Docs index:** [docs/README.md](docs/README.md) · agent guidance: [CLAUDE.md](CLAUDE.md)

## Quick start

```bash
cd app                               # the Flutter project lives in app/
flutter pub get
dart run build_runner build          # freezed / json_serializable codegen
flutter run -d <device>              # device ids from `flutter devices`

flutter analyze                      # should report "No issues found!"
flutter test                         # 221 tests, all green
```

The app connects to the hosted Supabase project out of the box (publishable key in
`app/lib/core/config/env.dart`; safe in the client — everything is RLS-enforced). Demo accounts and
seeding: see the demo guide §3/§7.

## Layout

```
app/                         everything needed to run the product
  lib/
    entities/                ENTITY   — freezed domain models (TDM §8 ERD) + data-owned rules
    controls/                CONTROL  — one Riverpod control per use case
    boundaries/ui/           BOUNDARY — screens (actor-facing); ui/common/ = shared widget
                             library (StatTile · AppCard · StatusBadge · PremiumCta · SelectorPills · FieldLabel)
    boundaries/gateways/     BOUNDARY — Supabase / sensor / AI / share adapters (system-facing)
  test/                      221 entity/control/gateway tests
  supabase/                  backend: migrations · Edge Functions · seeds   (see app/supabase/README.md)
docs/                        everything else: requirements · architecture · screen specs · deliverables · QA · scripts
```

The architectural rule, graded as part of the FYP: `Actor ─ Boundary ─ Control ─ Entity` —
screens never touch entities or the database directly. Details: [docs/architecture/bce-design.md](docs/architecture/bce-design.md).
