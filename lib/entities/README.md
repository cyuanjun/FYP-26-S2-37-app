# ENTITY layer

Freezed + json_serializable models of the ~26 TDM §8 ERD entities, plus
data-owned rules (XP/level/streak). See docs/reference/database-v1.md.

An Entity never depends on a Boundary or a Control. Rule:
`Actor ─ Boundary ─ Control ─ Entity`.

Generate one with: `dart run build_runner build --delete-conflicting-outputs`.
