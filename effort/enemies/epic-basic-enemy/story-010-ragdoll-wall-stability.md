---
xid: STO-ENEMIES-010
parent: ./epic.md
kind: story
effort: enemies
size: M
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-jqq
shipped: 2026-08-07
tasks: 5
complete: 5
---

# Ragdolls hit thin walls like the floor (no tunnelling or spaz)

## Summary

**Bug:** ragdolls spazzed out when they hit a wall, but behaved fine
on the floor.

**Cause:** the floor is a 1 m thick slab; procmap walls are **0.3 m**
(`WALL_T`). A ragdoll part moving 20+ m/s covers >0.33 m in one 60 Hz
tick — further than a wall is thick — so discrete collision let it
land *inside* the wall, and the solver then ejected it violently while
the joints dragged the rest of the body along.

**Fix — two parts, in this order (order matters):**
1. `scripts/ragdoll_part.gd`: each part clamps its own linear/angular
   velocity in `_integrate_forces`, i.e. INSIDE the physics step, and
   bleeds energy on deep contacts. The previous caps ran in
   `_physics_process` — after the step — which was too late: the part
   had already been ejected and the joints already yanked past their
   limits.
2. With velocities bounded, `continuous_cd` on the parts is finally
   stable, so they sweep against thin geometry instead of teleporting
   into it.

Also applied `continuous_cd` to the playground's movable box, which
the Grabber throws at ~22 m/s and which had the identical tunnelling
risk.

## Definition of Done

- [x] No ragdoll part tunnels through a 0.3 m wall.
- [x] No violent ejection or spin freak-out on wall impact.
- [x] The ragdoll settles after hitting a wall.
- [x] Thrown objects get the same treatment.
- [x] `tests/smoke_ragdoll_wall.gd` passes headless; the existing
      ragdoll/reaction tests still pass.

## Out of scope

- Thickening the procmap walls (they should stay 0.3 m visually; this
  is a physics-integration problem, not a level-geometry one).
- Player/enemy character controllers (move_and_slide already sweeps).

## Verification notes (2026-08-07)

- Reproduced first, headless, before any fix: part tunnelled through,
  peak ejection **28.0 m/s**, peak spin **140.6 rad/s**.
- **CCD alone made it far worse** (313 m/s, 2613 rad/s) — sweeping
  fought the joints while velocities were unbounded. This is why the
  in-step clamp had to land first; the ordering is the fix.
- After both: no tunnelling, peak 18.0 m/s, peak 14.0 rad/s, settles
  to 0.0 m/s.
- In the REAL map, `smoke_enemy_reactions` peak pelvis spin dropped
  from **843 rad/s to 14.0 rad/s**, still carrying 9.7 m.
- smoke_playground / smoke_grab_box unrun: port 7777 held by the
  operator's play session.
