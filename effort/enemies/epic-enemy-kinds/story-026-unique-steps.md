---
xid: STO-ENEMIES-026
parent: ./epic.md
kind: story
effort: enemies
size: S
status: shipped
date: 2026-08-14
shipped: 2026-08-14
depends-on: [STO-ENEMIES-023]
---

# Every step the spider takes is different

## Summary

No two strides are the same. Each step varies in how high the leg
lifts, how far it reaches, and how long it stays planted — so the
spider walks rather than replaying one animation forever.

A perfectly regular gait is what makes procedural walking read as a
LOOP. Real legs never place twice the same.

## Definition of Done

- [x] Consecutive steps differ (6 distinct out of 6 sampled).
- [x] Lift height, stride length AND the planted/swinging split all
      vary.
- [x] The same step is **repeatable**, so every machine shows the same
      spider.
- [x] Diagonal partners still take the SAME step as each other.
- [x] Diagonal-pair walking, feet on the ground and ragdolling all
      still pass.

## Verification notes (2026-08-14)

**Not `randf()`.** The gait runs in `_process` on every peer
independently, so a random number would give each machine a
differently-walking spider. The variation is hashed from *(this
spider's seed, which diagonal, which step number)* — three inputs that
are the same everywhere, so the walk is unrepeating but identical
across the network.

**Jitter had to move from per-LEG to per-PAIR.** Varying each leg
separately immediately broke the diagonal-pair check — and that
pairing is the whole reason the spider is never left unsupported.
Partners now take the same varied step. The test caught it on the
first run.

A good example of a test protecting a property that is easy to forget
you depend on: "every step is different" and "diagonal legs move
together" pull in opposite directions, and only one of them is
obvious.
