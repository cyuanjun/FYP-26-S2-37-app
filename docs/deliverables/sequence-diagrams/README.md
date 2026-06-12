# Sequence diagrams — one per user story (US07–US64)

**59 simplified BCE sequence diagrams** — one per SRS user story (US18 split into
**US18a** basic AI summary + **US18b** basic AI plan), generated/maintained 12 Jun 2026.
A story-by-story review with the team is **in progress** — resume it with the
`/seq-diagrams` skill (`.claude/skills/seq-diagrams/SKILL.md`), which tracks which
diagrams are user-confirmed vs not yet reviewed.
These **replace TDM §6** (the v5 diagrams are wrong — reconciliation log A3) and are the
source for the **PTD §16** sequence-diagram figures. US01–US06 (marketing website) have no
app flow, matching the TDM's own scope.

## Format

Mirrors the **sample PTD convention**: the story's actor + exactly three lifelines —
«Boundary» screen → «Control» use case → «Entity» domain object — with `alt` frames for
normal/alternate flow. The gateway/Supabase persistence path appears as a small note under
the Entity (gateways are system-facing Boundaries in BCE; the note keeps the diagrams
faithful to the as-built architecture without breaking the sample's three-box format). Names are the **as-built/as-designed** classes
from [bce-design.md](../../architecture/bce-design.md) §2 (built stories use shipped
class names; unbuilt stories use the §2.4 design inventory).

- `USnn-<slug>.png` — drop straight into Word (2× scale, white background)
- `src/USnn-<slug>.mmd` — Mermaid sources; edit + re-render to change a diagram

## Regenerate

```bash
cd docs/deliverables/sequence-diagrams
npx -y @mermaid-js/mermaid-cli -i src/US07-log-in.mmd -o US07-log-in.png -b white -s 2
```

(Avoid semicolons in message labels — Mermaid treats them as statement separators.)

## Known TBDs reflected in the diagrams

- **US21** carries a note: rest-alert tier is unresolved (SRS says Free, WBS says Premium).
- **US30 / US48** carry a note: expert-content scope may narrow to services-only.
- The seven detailed (non-simplified) diagrams for the built vertical slice remain in
  [bce-design.md](../../architecture/bce-design.md) §5.
