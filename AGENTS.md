# Repository Guidelines

## Project Structure & Module Organization
This repository has three main areas: `app/` for the Flutter mobile app, `web/` for the Vue 3 marketing/admin site, and `docs/` for project and testing documentation. In `app/lib/`, follow the BCE split: `boundaries/` for UI and adapters, `controls/` for use cases, and `entities/` for domain rules. In `web/src/`, keep UI in `boundary/ui/`, data access in `boundary/gateways/`, and feature logic in `controller/`. Tests live in `app/test/` and `web/test/`; Supabase work lives under `app/supabase/`.

## Architecture & Key References
Read `CLAUDE.md` for repository-wide conventions and locked architecture decisions. Start with `docs/STATUS.md` when resuming work, use `docs/README.md` as the docs index, and check `app/supabase/README.md` before changing schema, RLS, or seed data.

## Build, Test, and Development Commands
Mobile app:
- `cd app && flutter pub get` installs Dart and Flutter dependencies.
- `cd app && dart run build_runner build` regenerates `freezed` and JSON code.
- `cd app && flutter analyze` runs static analysis.
- `cd app && flutter test` runs the app test suite.

Web app:
- `cd web && npm install` installs frontend dependencies.
- `cd web && npm run dev -- --host 127.0.0.1` starts the local Vite server.
- `cd web && npm run test` runs Vitest.
- `cd web && npm run verify` runs the BCE check, tests, and production build.

## Coding Style & Naming Conventions
Use the BCE rule consistently: screens/components should not call the database or entities directly. Follow Flutter lints in `app/analysis_options.yaml`; keep Dart filenames in `snake_case` like `generate_plan_test.dart`. Match existing TypeScript/Vue naming with clear verb-based controller names such as `registerUser` or `submitContactMessage`. Keep shared seed or fallback data under `web/src/boundary/gateways/seed/`.

## Testing Guidelines
Add tests beside the appropriate layer focus: entity, control, gateway, or widget tests in `app/test/`, and feature-oriented Vitest files in `web/test/`. Use `*_test.dart` for Flutter and `*.test.ts` for web. Run `flutter test` and `npm run verify` before opening a PR.

## Commit & Pull Request Guidelines
Recent history uses concise conventional commits such as `fix(web): ...`, `refactor(app): ...`, and `docs: ...`; keep that format and scope by surface when helpful. PRs should include a short summary, linked issue or requirement, test evidence, and screenshots or screen recordings for UI changes. Call out Supabase schema or seed-data changes explicitly so both app and web reviewers can validate them.
