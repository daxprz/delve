---
xid: STO-CHARACTER-010
parent: ./epic.md
kind: story
effort: character
size: M
status: shipped
date: 2026-08-03
depends-on: []
bd-id: delve-4qt
tasks: 3
complete: 3
---

# The Runner has a long physics tail that wags

## Summary

The Runner gets a **long physics tail** (~3.6 m, 12 tapered segments)
attached at its lower back. It's a Verlet chain: gravity + momentum make
it **drag and sway** as the Runner moves, and a gentle built-in sideways
motion makes it **wag slowly** even when standing still.

## Definition of Done

- [x] The Runner spawns with a long tail; the Grabber does not.
- [x] The tail is a stable physics chain (never explodes) that hangs
      under gravity and drags behind.
- [x] The tail wags slowly on its own.

## Verification notes (2026-08-03)

- `scripts/tail.gd` (`Tail`): a Verlet chain (12 segments, tapered
  boxes), base pinned to the player's lower back, gravity + damping +
  segment-length constraints, floor clamp, plus a slow sinusoidal
  sideways sway (`WAG_SPEED` / `WAG_STRENGTH`) that's stronger toward
  the tip. Built by `player.gd` when the character def has `tail: true`
  (Runner only).
- `tests/smoke_tail.gd`: **RESULT: PASS** — Runner has a 12-segment
  tail (Grabber has none), the chain stays finite, hangs 0.82 m below
  its base, and the tip wags 0.80 m sideways on its own.

### Change 2026-08-03 — tail stays behind the character

- [x] Operator wanted the tail to **stay behind** the character (it was
      just hanging straight down when standing). Added a gentle
      "rest-behind" bias: each frame the tail eases toward a resting
      pose that trails **backward + down** from the base (using the
      player's back vector), with the slow **wag baked into that target**
      so it still sways while staying behind. Turning the player swings
      the tail around to stay behind.
- `tests/smoke_tail.gd` now also checks this: **RESULT: PASS** — in the
  player's local space the tip rests **3.0 m behind** the base and still
  wags 1.84 m side-to-side.

### Change 2026-08-03 — bigger + floppier (more ragdoll)

- [x] Operator wanted it **bigger** and to stay **partly a ragdoll**.
      Grew it (13 segments × 0.40 m ≈ **5.2 m**, thicker 0.38 m) and made
      it floppier: weaker "stay-behind" pull (`BEHIND_PULL` 0.1 → 0.045)
      and more retained momentum (`DAMPING` 0.985 → 0.99), so it swings
      like a ragdoll while still gently trending behind.
- `tests/smoke_tail.gd`: **RESULT: PASS** — still stable, hangs, rests
  4.4 m behind, and wags 2.05 m.

### Change 2026-08-03 — floppier

- [x] Operator wanted it floppier. Raised `DAMPING` (0.99 → 0.995, keeps
      more momentum) and lowered `BEHIND_PULL` (0.045 → 0.028), so the
      tail swings looser and more ragdoll-like while still trending
      behind. `tests/smoke_tail.gd`: **RESULT: PASS** (still stable,
      rests 4.1 m behind, wags 2.3 m).

### Tune 2026-08-03 — droops down and trails behind

- [x] Operator wanted a clear **down-and-back droop** (the very-floppy
      version let gravity pull it mostly straight down). Set the resting
      direction to ~45° (`REST_DOWN` 0.7 → 1.0) and firmed the pull a
      touch (`BEHIND_PULL` 0.028 → 0.05) so it clearly droops down AND
      trails behind while staying floppy. `tests/smoke_tail.gd`:
      **RESULT: PASS** — droops 0.99 m, trails 3.7 m behind, wags 2.4 m.

### Tune 2026-08-03 (2) — way floppier ragdoll

- [x] Operator wanted it WAY floppier — a ragdoll, not straight. Dropped
      the stiffness right down (`BEHIND_PULL` 0.05 → 0.012) and raised
      `DAMPING` (0.995 → 0.998), so gravity + momentum dominate and the
      tail sags and swings loosely instead of pointing straight. The test
      now checks it **curves/sags** (not straight): `tests/smoke_tail.gd`
      **RESULT: PASS** — 0.50 m of curve off the straight line, wags
      2.6 m.

### Tune 2026-08-03 (3) — drags behind the player

- [x] Operator wanted it to **drag behind** the player. Pointed the
      resting direction more backward (`REST_DOWN` 1.4 → 0.6) and added a
      touch of drag (`DAMPING` 0.998 → 0.99) so the loose tail trails/lags
      behind the body when moving, while staying floppy. `smoke_tail.gd`
      now also checks this: **RESULT: PASS** — moving forward, the tail
      trails 4.1 m behind (and still curves 0.45 m / wags 2.3 m).

### Tune 2026-08-03 (4) — full ragdoll + collides with the player

- [x] Operator wanted it fully ragdoll and to **clip (collide) with the
      player**. Dropped the pose bias further (`BEHIND_PULL` 0.025 →
      0.014) so gravity + momentum do almost everything, and the tail's
      per-segment collision now **includes the player's body** (segments
      3+; the first two at the attachment still ignore the player so the
      base doesn't fight the capsule). So the tail flops against the
      player instead of passing through. `tests/smoke_tail.gd`: **RESULT:
      PASS** (stable, floppy, drags behind).

### Tune 2026-08-03 (5) — FULLY ragdoll

- [x] Operator: make it FULLY ragdoll. Set `BEHIND_PULL` to **0** — no
      scripted pose or wag at all; only gravity + momentum + collisions
      drive the tail. It hangs at rest and swings/drags purely from
      physics. `tests/smoke_tail.gd` rewritten to check ragdoll behaviour
      via motion: **RESULT: PASS** — while moving it drags 4.9 m behind
      and flexes 0.42 m (curves from physics), still stable.

## Out of scope

- The tail reacting to being hit / pushing things.
