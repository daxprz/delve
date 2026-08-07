---
xid: STO-ENEMIES-003
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-eh2
shipped: 2026-08-06
tasks: 5
complete: 5
---

# Enemies get procedurally-generated humanoid bodies

## Summary

Enemies get the same procedural jointed humanoid body as players
(`scripts/body.gd`), with procedural GENERATION on top: `Body` gains a
`variation_seed` that varies leg/arm/torso/head/bulk proportions
(±15–30%) plus a per-enemy red-tint jitter, seeded deterministically
from the enemy's node name so every peer renders the same individual.
The gait animation (procedural stepping, 2-bone leg IK, arm swing)
comes free — it's driven by parent movement. Body also gains
`base_color`, `use_fade` (enemies stay solid up close) and
`set_base_color()` (damage flash retints the whole body).

## Definition of Done

- [x] Enemies build a full humanoid Body (pelvis/torso/neck/head,
      arms, IK legs) instead of the capsule mesh; eyes keep a visible
      "front"; collision capsule unchanged.
- [x] Proportions vary between enemies (procedural generation) but
      are deterministic per name (MP-consistent).
- [x] Player bodies are untouched: seed 0 = exact canonical
      proportions; fade shader still owner-only.
- [x] Damage flash retints the body white and restores the enemy's
      own tint.
- [x] `tests/smoke_enemy_body.gd` passes headless (13 checks, no
      networking required).

## Out of scope

- Collision capsule scaling with body variation.
- Enemy walk-style variation (gait params per seed) — future story.

## Verification notes (2026-08-06)

- `smoke_enemy_body`: 13/13 PASS — structure, variation, determinism
  (same name in different parents → identical scales), no fade
  shader, eyes present, flash + restore.
- Gotcha (new): `preload()` in a `-s` main-loop test script compiles
  dependencies BEFORE autoloads register — enemy.gd references
  DebugOverlay and failed to compile. Runtime `load()` on first tick
  instead.
- Hosting regressions (smoke_enemy, smoke_body*) pending — game port
  7777 held by the operator's live play session; run when free.
