# Wise Workout

**FYP-26-S2-37** · UOW/SIM · 4-person team — a cross-platform (Android + iOS) fitness app:
workout capture from phone sensors and wearables, AI training plans and progress summaries,
analytics, social sharing, an expert marketplace, and Free/Premium/Expert/Admin roles.

**Stack:** Flutter (Riverpod · go_router · freezed) on a strict **Boundary–Control–Entity**
architecture · **Supabase** (Postgres + Auth + RLS + Edge Functions) · **OpenAI** `gpt-4o-mini`
(Gemini → rule-based fallback) for the two AI surfaces (progress summaries, plan generation).

## Current state (12 Jun 2026)

Built, tested (107 tests), and verified on the Android emulator + iOS simulator against a live
backend: login → first-run onboarding wizard → AI-generated 4-week training plan → Plan Detail →
phone-GPS workout capture with paired-wearable heart rate → month-capped history + analytics →
AI progress summary → share to named social platforms → full profile/settings cluster.

- 📍 **Where we are / what's next:** [docs/STATUS.md](docs/STATUS.md)
- 🏃 **Run & demo it** (setup, walkthroughs, test accounts): [docs/prototype-demo-guide.md](docs/prototype-demo-guide.md)
- 📋 **Requirements coverage** (all 64 user stories + build status): [docs/requirements/user-stories.md](docs/requirements/user-stories.md)
- 🐛 **Bug log:** [docs/testing/bug-log.md](docs/testing/bug-log.md)
- 🧭 **Docs index:** [docs/README.md](docs/README.md) · agent guidance: [CLAUDE.md](CLAUDE.md)

## Quick start

```bash
flutter pub get
dart run build_runner build          # freezed / json_serializable codegen
flutter run -d <device>              # device ids from `flutter devices`

flutter analyze                      # should report "No issues found!"
flutter test                         # 107 tests, all green
```

The app connects to the hosted Supabase project out of the box (publishable key in
`lib/core/config/env.dart`; safe in the client — everything is RLS-enforced). Demo accounts and
seeding: see the demo guide §3/§7.

## Layout

```
lib/
  entities/                freezed domain models (TDM §8 ERD) + data-owned rules
  controls/                one Riverpod control per use case
  boundaries/ui/           screens (actor-facing boundaries)
  boundaries/gateways/     Supabase / sensor / AI / share adapters (system-facing boundaries)
supabase/                  migrations · Edge Functions · seeds   (see supabase/README.md)
docs/                      requirements · architecture · screen specs · deliverables · QA
```

The architectural rule, graded as part of the FYP: `Actor ─ Boundary ─ Control ─ Entity` —
screens never touch entities or the database directly. Details: [docs/architecture/bce-design.md](docs/architecture/bce-design.md).
