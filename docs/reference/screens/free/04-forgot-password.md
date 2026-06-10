---
screen: 04-forgot-password
role: free
group: auth
status: draft
---

# 4. Forgot password

**Purpose:** Let an existing user request a password-reset link by email. The reset email is sent server-side; the screen then shows a confirmation card and offers a 60-second resend cooldown.

## UI elements

- *Top:* `Eyebrow` "ACCOUNT RECOVERY" in **Caption 2** (11 px `accent`, uppercase, tracking 0.2em) with a 24 px lime leading line
- *Page title:* "FORGOT PASSWORD." in display 48 px (`text-5xl`, font-black, uppercase, tracking-tight, leading 0.95) — wraps to two lines naturally. The trailing period is intentional brand punctuation.
- *Description:* **Subheadline** (15 px `muted`) — *"Enter your registered email — we'll send a secure reset link valid for 30 minutes."*
- *Form:*
  - **Email input** — `Input` component. Label "EMAIL" in **Caption 2** (11 px uppercase `muted`); value in **Body** (17 px `ink`); type=email
- *Primary CTA:* "SEND RESET LINK" — full-width `accent` background, `bg`-coloured text, **Body** (17 px) font-black uppercase tracking-wider, rounded-2xl, subtle accent glow shadow
- *Secondary text link* (centred below primary): 14 × 14 px left-arrow icon followed by "Back to log in" — **Subheadline** (15 px `muted`, sentence case, font-semibold). No background, no border. Hover goes `ink` for both icon and label (the icon uses `currentColor`). Standard iOS auth pattern: the smaller, lower-weight treatment makes the primary CTA visually dominant.
- *Background:* `bg`

Post-send confirmation (toast or inline state showing "check your inbox" + 60-second resend countdown) is deferred — the rate-limit and `UsedAt` columns on `PasswordResetToken` are still in the DB for when it lands.

Colours from [../../palette.md](../../palette.md), type sizes from [../../typography.md](../../typography.md). Reuses: `Eyebrow`, `Input` from `app/src/components/`.

## Edges

- **From:** Login (tap "Forgot password?" link)
- **To:**
  - → Login (tap "Back to log in" button) — explicit return path
  - → *server* (tap "Send reset link") — issues a `PasswordResetToken` and emails the user; screen stays on Forgot password with the "Already sent" card visible. From there the user leaves the app, opens their email, taps the reset link, and lands on a reset-password screen (web-served, out of scope for the mobile app v1).

In play mode (v2), "Send reset link" defaults to staying on this screen (showing the sent card). "Back to log in" returns to Login.

## Data touched

See [../../database-v1.md](../../database-v1.md).

- **Reads:** `User` by `Email` (silently succeed even if no match — never reveal whether an email exists to avoid user enumeration)
- **Writes:** new `PasswordResetToken` row on each send (`ExpiresAt = now + 30 min`, `UsedAt = null`)
- **Resend rate-limit:** server rejects creating a new token if a `PasswordResetToken` for this user was created in the last 60 seconds — no new column needed

## Notes / non-obvious

- **Silent failure on unknown email** is deliberate. The screen always shows the "Already sent" card regardless of whether the email matched a `User` — this prevents an attacker from probing which emails are registered.
- **Reset-password screen** (where the user lands from the email link) is web-served, not part of this app — out of scope for the Free-user inventory.
- The trailing **period** on "FORGOT PASSWORD." is brand styling, intentional. Mirror it on other display-titled screens (e.g. "WELCOME BACK.", "YOUR PROGRESS.").
