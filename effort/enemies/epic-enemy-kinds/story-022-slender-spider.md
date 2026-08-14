---
xid: STO-ENEMIES-022
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-18i
---

# Slender, seeded proportions with one long reaching leg

## Summary

The spider gets thinner and better proportioned: the **two joints near
the body are small**, and the **last segment is far the longest** — a
long thin reach down to the floor.

And its build is **generated per spider**: each one's segment lengths
and angles are jittered from its seed, so no two have the same shape.

## Definition of Done

- [x] Legs are visibly thinner (0.30 -> 0.155) and the body smaller.
- [x] The last segment is longer than the other two **combined**
      (3.37 against 0.84 + 1.16).
- [x] Segment lengths and angles vary per spider from its seed.
- [x] Feet still reach the ground; it still towers over the player.
- [x] Diagonal-pair walking and ragdolling still hold.

## Verification notes (2026-08-14)

Two spiders from different seeds came out **0.55/0.78/2.41** and
**0.84/1.16/3.37** — different builds, not one shape scaled.

The jittered fractions are **renormalised** so they still sum to the
whole leg. Without that, a spider that rolled three high numbers would
simply have *longer* legs rather than *differently proportioned* ones,
which is scaling wearing a disguise.

Overall leg length had to come DOWN (7.4 -> 4.3) even though the legs
look longer. The long third segment now does nearly all the lifting,
so at 7.4 the body ended up **5.71 m** in the air — a building rather
than a creature.

### A test assertion that had to change

STO-ENEMIES-019 checked that every knee rises **above** the body. That
was right for equal-ish segments, and is wrong now: with the upper two
joints deliberately small, the knee sits near the body instead. The
check was replaced with "knees sit OUT beyond the body", which is what
actually has to hold for the splayed silhouette. The down-up-down
profile is still checked separately.

Recorded because it is a **requirement change, not a test being bent**
— the shape changed on purpose.
