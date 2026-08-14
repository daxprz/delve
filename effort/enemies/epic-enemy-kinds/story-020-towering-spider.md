---
xid: STO-ENEMIES-020
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-lhe
---

# The spider towers over the player

## Summary

The spider's legs get **much** longer, so its body rides **above head
height** and you walk underneath it. Right now its block sits at about
knee height — a big beetle rather than something that looms.

## The geometry problem this runs into

Making the legs longer does **not** by itself raise the body. The legs
splay out and UP, then fold back down; the body's height is whatever
is left over after that fold. With two equal segments, the fold eats
almost all the extra length — the legs just splay wider and the body
stays low.

Real spiders solve it with **unequal segments**: a shorter femur out
to the side, then a long tibia running down to the ground. That is
what lifts the body up.

So the body's height has to be **derived from the leg geometry**, not
picked. Otherwise the feet float above the floor or sink through it.

## Definition of Done

- [x] Its body rides at **2.70 m** against the player's 1.60 m eye
      height — measured against the real camera, not a guess.
- [x] Lowest foot sits at y **0.01** — on the floor.
- [x] Legs 4.80 long (femur 1.63, tibia 3.17).
- [x] Its hitbox grew to **2.97 m** tall to match.
- [x] Still seeded.
- [x] Diagonal-pair walking, ragdolling and chasing all still pass.

## Verification notes (2026-08-14)

**Longer legs alone did nothing.** With two equal segments the fold
eats the extra length: the spider just splayed wider while its body
stayed at knee height. Splitting the leg into a short femur (34%) and
a long tibia (66%) is what lifts it — the same reason a real spider is
built that way.

The body's height is **derived** from the leg angles rather than
picked, or the feet float above the floor. Getting that formula wrong
was instant and obvious: it computed a body height of **-3.14 m**,
because I summed the segments' vertical contributions without noticing
the tibia's is negative.

## Out of scope

- The spider stepping OVER the player, or the player walking under it
  without being hit.
