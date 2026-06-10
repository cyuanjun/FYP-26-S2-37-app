---
screen: 01-splash
role: free
group: auth
status: draft
---

# 1. Splash

**Purpose:** Branded loader shown the moment the app opens, while the client checks session validity and first-run state. Auto-advances — no user input.

## UI elements

- *Top half:* breathing space
- *Centre:* `Logo` mark (`/img/logo.png` — lime W over white M) at **120 px**, above the `Wordmark` at size `lg` (**Large Title** 36 px display) reading **WISE WORKOUT** — WISE in `ink`, WORKOUT in `accent`, uppercase font-black tracking-tight
- *Below wordmark:* tagline in **Subheadline** (15 px, `muted`) — *"Train smart. Move better."*
- *Bottom third:* subtle loading indicator (three pulsing dots, 8 px each) in `accent`
- *Background:* `bg` flat — soft `surface` blur behind the logo for depth
- *Status bar:* light icons on dark — handled by `PhoneFrame`
- No buttons, no nav.

Colours from [../../palette.md](../../palette.md), type sizes from [../../typography.md](../../typography.md). Logo + wordmark are reusable: `app/src/components/Logo.tsx`, `app/src/components/Wordmark.tsx`.

## Edges

- **From:** app launch (entry node — no incoming screen)
- **To (auto, after ~1.5 s):**
  - → **Login** — no valid `Session`
  - → **Onboarding (post-login)** — valid session AND `User.OnboardingCompletedAt IS NULL` (first time after signing up)
  - → **Dashboard** — valid session AND onboarding already completed

On the canvas: three outgoing arrows, each labelled with its condition. In play mode (v2), default branch is `no session → Login`; debug toggle picks the others.

## Data touched

See [../../database-v1.md](../../database-v1.md) for the entity definitions.

- **Reads:** `Session` (by token), `User.Role`, `User.OnboardingCompletedAt`
- **Writes:** `User.LastLoginAt` on successful resume
