---
xid: STO-CHARACTER-079
parent: ./epic.md
kind: story
effort: player-character
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-c2ne
---

# From outside he looks paper-thin

## Summary

> "from the out side it looks like he becomes 2d"

The other half of the trick: **everybody else sees a paper-thin man**.

Watching a teammate flatten and slide edge-on through a crack you
cannot follow him into is the whole reason to build the outside view at
all. It is also what tells other players the ability happened — without
it, the Mage would simply vanish into a wall and read as a bug.

## Definition of Done

- [x] While flat, the Mage really is a paper-thin figure. Measured off
      his own joints: **0.520 m thick → 0.021 m**.
- [x] He is FLAT, not small — still **full width across** the plane
      (0.086 → 0.084 m) and **full height** (1.655 → 1.658 m). A
      uniform shrink would have passed a thickness check alone and been
      completely wrong.
- [x] The flattening belongs to the PLANE: turned round while flat, he
      is still thin the same way (**0.012 m**).
- [x] He returns to full thickness when he comes back (0.520 m) with no
      squash left on him.
- [ ] It works over the network — remote copies flatten too. **Not
      built.** The flatten is decided locally and nothing replicates it,
      so other players would still see him solid. Not ticked.
- [x] Proven by `tests/smoke_mage_flat_look.gd`, measured from the real
      world positions of his joints — a `thinness()` getter returning
      0.04 proves a number changed, not that anything on screen moved.

## Built (2026-08-14), and what it cost

The squash is one line of geometry — flattening space along a unit
normal n is `S = I - (1-t)·n⊗n` — applied in world space so he keeps
facing where he faces and keeps animating. He is a flattened man, not a
differently-posed one. It is deliberately NOT applied to his collider:
what he can squeeze through is STO-CHARACTER-077, a separate story with
a separate rule.

**Three things escaped it, and each looked like the whole feature was
broken:**

1. Hanging the body off a squash node made `body.gd` treat that node as
   "the player", because it took `get_parent()`. It now walks up to the
   nearest `CharacterBody3D`, so nesting can never break it again.
2. The legs are placed with `global_transform`, which overrides the
   entire parent chain — so they opted out of the squash every frame.
   He came out flat from the waist up and solid from the waist down.
3. The FEET are placed separately again ("keep the foot flat on the
   ground"), and were missed on the first pass — leaving a flat man
   standing on two full-width feet.

All three now go through one `_place()` that expresses the IK result
**relative to the character** and lets the ancestors do what they like
to it. With no squash it is identical to the old behaviour.

⚠️ **Every character's legs now go through `_place()`.** Verified
against `smoke_body_anim`, `smoke_crawler` and the Mage's own tests,
but `smoke_body`, `smoke_player` and `smoke_walljump` need port 7777
and could not run — the game was being played. **Run those before
trusting this.**

## Out of scope

- His own view — that is 078.
- Making him hard to see. He is thin, not invisible.
