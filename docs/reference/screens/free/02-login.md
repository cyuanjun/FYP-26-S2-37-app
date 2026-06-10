---
screen: 02-login
role: free
group: auth
status: draft
---

# 2. Login

**Purpose:** Authenticate an existing user. Signup is **external** — there is no in-app signup; users register on the marketing website (`fyp-26-s2-37-website.vercel.app`) and only log in inside the app.

## UI elements

- *Top third:* `Logo` (**140 px**) centred above `Wordmark` size `lg` (**Large Title** 36 px) — "WISE WORKOUT" with WISE in `ink`, WORKOUT in `accent`
- *Spacer:* large empty band so the form sits in the bottom half
- *Form (bottom half):*
  - **Email input** — `Input` component. Label "EMAIL" in **Caption 2** (11 px uppercase `muted`); value in **Body** (17 px `ink`); type=email
  - **Password input** — same as Email; type=password (dots)
  - **Row:** `Toggle` defaultOn with label "Remember me" in **Subheadline** (15 px `ink`) on left · "Forgot password?" link in **Subheadline** (15 px `accent`) on right
  - **CTA button** — full-width `accent` background, "LOG IN" in **Body** (17 px) `bg`-coloured font-black uppercase tracking-wider, rounded-2xl, subtle accent glow shadow
  - **Footer line** — "No account? Sign up at **fyp-26-s2-37-website.vercel.app**" in **Footnote** (13 px `muted`) with the URL as `accent` link (opens external marketing site)
- *Background:* `bg`

Colours from [../../palette.md](../../palette.md), type sizes from [../../typography.md](../../typography.md). Reuses: `Logo`, `Wordmark`, `Input`, `Toggle` from `app/src/components/`.

## Edges

- **From:** Splash (no valid session)
- **To:**
  - → **Onboarding (post-login)** — credentials valid AND `User.OnboardingCompletedAt IS NULL` (first time)
  - → **Dashboard** — credentials valid AND onboarding already completed
  - → **Forgot password** — tap the "Forgot password?" link
  - → *External:* marketing site — tap the signup URL (leaves the app)

In play mode (v2), default tap of LOG IN goes to `Dashboard` (skipping onboarding); debug toggle picks the first-time branch.

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** `User` by `Email` → compare `PasswordHash`
- **Writes:** new `Session` row on success (`ExpiresAt` long when Remember me is ON, short otherwise); update `User.LastLoginAt`
- **No writes** on failed auth — just show inline error in the form (red state on the inputs)

## Notes / non-obvious

- "Remember me" controls **session lifetime** at issue time, not a stored preference. ON → e.g. 30-day `ExpiresAt`; OFF → e.g. 24-hour `ExpiresAt`. The toggle itself is not persisted to `User`.
- The signup-is-external decision means the project description's "marketing website" deliverable is on the critical path for the login flow to actually work — without that website, new users can't get accounts.
