---
xid: STO-ENEMIES-030
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-4hbn
---

# The spider grows pincer arms

## Summary

Two arms on the front of the spider, each ending in a **pincer** that
opens and closes. Not legs — the spider already has four of those and
they are for walking. These are for **reaching out and taking hold of
you**.

They are generated procedurally like everything else about this
creature, seeded from its name, so the pincers on your spider are its
own.

## Why arms and not just longer legs

The spider is already frightening to look at. What it cannot do is
*act* on you — every story after this one needs a part of the creature
that can hold a player, and legs are busy holding the spider up.

Giving it dedicated arms also makes the threat **readable**. You can
see the pincers weaving before it reaches, which is the difference
between a monster that is scary and a monster that is unfair.

## What this story does and does not do

This story is the **arms themselves**: they exist, they are attached,
they move, they open and shut. Deliberately nothing else.

- Damage is **STO-ENEMIES-031**.
- Reaching around and through cover is **STO-ENEMIES-032**.
- Grabbing and carrying you is **STO-ENEMIES-034**.

Each of those is easier to get right against arms that already work,
and impossible to judge if the arms are being invented at the same
time.

## Definition of Done

- [x] The spider has two arms on the front of its body.
- [x] Each arm ends in a pincer of two halves that can open and close.
- [x] They are built procedurally and vary with the spider's seed.
- [x] They reach **further than the body is wide** — an arm that cannot
      out-reach the creature it is attached to is decoration.
- [x] They move on their own: weaving while it walks, not frozen.
- [x] The pincer opens and closes on demand, and something can ask
      where its tip is.
- [x] Walkers do not grow arms — this is the spider's.
- [x] The spider still walks, clambers and ragdolls exactly as before.
- [x] Proven by a headless test.

## What it took (2026-08-14)

Built as their own node rather than more code inside the gait: the legs
are about carrying the creature, the arms are about reaching for you,
and every story left in this epic touches the arms while none of them
touch the walk.

Everything is derived from the body it is bolted to — arm length is a
fraction of how high the block rides — so a bigger spider gets
proportionally bigger arms with nothing to re-tune. Same rule the legs
and the clamber-reach already follow.

Measured on a real spider: **arms 3.13 m, reach 3.82 m against a body
0.37 m wide** — better than ten times the body, and the two tips sit
2.69 m apart.

### The test that would have passed with the arms welded solid

The DoD says the arms move on their own, so the test measured how far a
pincer tip travelled while idle. It reported **1.318 m** and passed.

That number was nonsense. Tip position was being read in **world
space**, and the spider walks — so the tips move metres per second
whether the arms do anything at all. The check would have passed on a
creature with its arms frozen stiff, which is exactly the failure it
existed to catch.

Now measured **relative to the creature**: 0.453 m of genuine weave.

### Teeth

Verified by freezing `_process` entirely:

| | |
|---|---|
| arms frozen | **3 failures**, weave 0.000 m |
| real code | PASS, weave 0.453 m |

The jaw checks caught it independently of the weave check, which is the
useful kind of redundancy — the jaws stuck at their built rest value of
0.30 and never reached either 1.0 or 0.0.

Full suite: **pass=51 fail=0**, 24 skipped for the port.

## Out of scope

- Hurting anybody. That is the very next story.
- Aiming at a target, or any decision about *when* to reach.
- The pincers colliding with the world.
