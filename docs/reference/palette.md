# Wise Workout — Colour Palette

Colour-only extract from [resources/FYP-26-S2-37_brand-kit.html](resources/FYP-26-S2-37_brand-kit.html). Everything else in that file (logo mark, typography, feature naming, taglines, copy, nav structure) is mock content and should be **ignored**. Only these hex values are normative.

Use this as the single source of truth for any colour referenced in the per-screen files under [screens/](screens/) (indexed by [screens-v1.md](screens-v1.md)). Pair with [typography.md](typography.md) for the type scale.

---

## Core palette

| Token | Hex | Role |
|---|---|---|
| `bg` | `#111210` | Primary background (deepest layer) |
| `surface` | `#1E1F1B` | Cards, surfaces, raised elements |
| `surface-2` | `#252620` | Higher-elevation surfaces / hover states |
| `ink` | `#EEEEE8` | Primary text, headings on dark |
| `muted` | `#8A8A84` | Secondary text (passes WCAG AA on `surface`) |
| `faint` | `#333330` | Dividers, decorative only — **never use for text** |
| `accent` | `#B8FF00` | Primary action / CTA / brand accent |
| `accent-dim` | `#8CC400` | Hover / pressed state for accent |
| `danger` | `#FF2D55` | Errors, destructive actions, alerts |
| `info` | `#00B4FF` | Info states, secondary CTA, "rest / recovery" feel |
| `gold` | `#FFD700` | Reserved for #1 rank only |

## Tint scales (use sparingly)

**Accent tint scale:** `#F2FFB3` `#E0FF66` `#CBFF1A` `#B8FF00` `#8CC400` `#608A00` `#345000` `#1A2800` `#0A1000`

**Dark surface scale:** `#EEEEE8` `#888880` `#444440` `#333330` `#252620` `#1E1F1B` `#181916` `#141512` `#111210`

## Usage rules

- **Dark-mode app.** Pair `ink` text on `bg` / `surface` / `surface-2`. Never pure `#000000` — `bg` is intentionally not black.
- **Accent on accent text is illegal.** When `accent` (#B8FF00) is the background, text on it must be `bg` (#111210), never white.
- **One accent per screen surface.** Use `accent` for the primary CTA. Anything else competing for attention demotes to `surface-2` or `info`.
- **Danger and info are semantic.** `danger` only for errors / destructive intent. `info` only for informational alerts, share actions, or recovery states.
- **Gold is sacred.** Only ever paint the #1 spot on a leaderboard; nowhere else.

## Tailwind config snippet (for when we scaffold the app)

```js
// tailwind.config.js → theme.extend.colors
{
  bg:         '#111210',
  surface:    '#1E1F1B',
  'surface-2':'#252620',
  ink:        '#EEEEE8',
  muted:      '#8A8A84',
  faint:      '#333330',
  accent:     '#B8FF00',
  'accent-dim':'#8CC400',
  danger:     '#FF2D55',
  info:       '#00B4FF',
  gold:       '#FFD700',
}
```
