---
xid: STO-ENEMIES-007
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-06
depends-on: []
bd-id: delve-05k
shipped: 2026-08-06
tasks: 6
complete: 6
---

# Stronger stance + tiered reactions: shove / stumble / ragdoll, no flash

## Summary

Enemies get a STRONGER stance and three clean reaction tiers, judged
on delivered dv (impulse/mass) against each build's stability:
WEAK (< 3.0×stab) — a shove: shifts a little, barely reacts, keeps
coming. MEDIUM (< 7.5×stab) — a stumble: loses steering for 0.6 s and
the body lurches in the push direction (0 → peak → upright arc), but
stays on its feet. HARD (≥ 7.5×stab, up from 5.0) — the real ragdoll.
The white damage flash is REMOVED — the physical reaction is the hit
feedback; bodies keep their tint. Also adds per-tick velocity caps on
ragdoll parts (22 m/s / 18 rad/s): wall-corner contacts could spike
parts into the hundreds of rad/s — real physics, but a visual
freak-out.

## Definition of Done

- [x] Weak hits: velocity nudge only — no stumble, no stagger, no
      ragdoll, no tint change.
- [x] Medium hits: visible stumble lurch, steering lost briefly,
      recovers upright; never falls.
- [x] Hard hits: ragdoll, with the threshold raised 5.0 → 7.5
      (stronger stance).
- [x] No white flash anywhere (asserted in smoke_enemy_body).
- [x] Ragdoll parts velocity-capped; physics-sanity numbers stay in
      range even when tumbling into walls.
- [x] `tests/smoke_enemy_reactions.gd` (18 checks) and
      `tests/smoke_enemy_body.gd` (12 checks) pass headless.

## Out of scope

- Damage scaling by hit strength (attacks own their damage numbers;
  the tail already scales with swipe speed).
- Directional stumble step animation (the lurch is a body lean; the
  gait IK's scrambling feet sell the rest).

## Verification notes (2026-08-06)

- smoke_enemy_reactions 18/18: tier thresholds hold across the build
  variance envelope (thresholds chosen against stability bounds
  [0.85, 1.25]); stumble lurch peaks and recovers to 0.00 rad;
  ragdoll tier unchanged. With caps: max pelvis angular 19.9 rad/s,
  carry 11.6 m (an uncapped run that tumbled into the procmap walls
  hit 843 rad/s / 54 m — the caps exist for exactly that).
- smoke_enemy_body 12/12 including the new no-flash assertion.
