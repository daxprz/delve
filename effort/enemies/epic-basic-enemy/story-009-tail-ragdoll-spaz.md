---
xid: STO-ENEMIES-009
parent: ./epic.md
kind: story
effort: enemies
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-192
shipped: 2026-08-07
tasks: 4
complete: 4
---

# Fix: tail inside a ragdolling enemy caused a feedback loop (crash)

## Summary

**Bug:** a tail sitting inside an enemy while it ragdolled made both
spaz out (and, reproduced headless, **segfaulted the engine**).

**Cause — a feedback loop with two halves:**
1. Ragdoll parts live on physics layer 2, but the tail's world rays
   used the DEFAULT mask (all layers), so they hit tumbling parts.
   Each hit snapped a tail point onto a fast-moving surface and reset
   its previous position, so the next frame's implied velocity was
   enormous.
2. `_hit_enemies` reads that same implied velocity. The fake spikes
   sailed past `TAIL_TRIP_SPEED`, registering phantom tail "hits" on
   an enemy that was ALREADY ragdolling — each one calling `trip()`
   -> `_knockdown()` -> `shove()`, re-launching the parts, which
   snapped the tail harder. Round and round until the solver blew up.

**Fix:** the tail's rays now mask to layer 1 (world + standing
bodies), ignoring ragdoll parts entirely — consistent with the
ragdoll's own world-only design; and the tail skips hit processing
for enemies that are already downed (you can't sweep someone who is
already on the floor).

## Definition of Done

- [x] Tail rays exclude the ragdoll layer (named `RAGDOLL_LAYER`).
- [x] Tail does not re-trip an already-downed enemy.
- [x] With tail points jammed into ragdoll parts: point speeds stay
      sane, the chain stays finite, and the ragdoll DECAYS instead of
      being re-shoved.
- [x] `tests/smoke_tail_ragdoll.gd` passes headless.

## Out of scope

- Letting the player deliberately whack a downed enemy around (the
  tail now ignores them entirely; a dedicated "finisher" is a
  separate design question).

## Verification notes (2026-08-07)

- 4/4 PASS with the fix: peak tail point speed 38.9 m/s (no snap
  spikes), chain finite, ragdoll pelvis peaked at 9.5 m/s and decayed
  to 0.1 m/s.
- **Test proven to have teeth:** with both fixes reverted, the same
  test does not merely fail — the engine exits 139 (SIGSEGV) right
  after the tail points are jammed in. Restoring the fix returns a
  clean pass.
