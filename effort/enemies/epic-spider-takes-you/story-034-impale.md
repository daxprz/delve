---
xid: STO-ENEMIES-034
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-14
depends-on: [STO-ENEMIES-030, STO-ENEMIES-033]
bd-id: delve-gwv3
---

# The spider grabs you and impales you on a spike

## Summary

The spider catches you in its pincers, hauls you off, and puts you on
something sharp. You do not die. You are **stuck there, alive**, and it
walks away.

## How you are carried (operator, 2026-08-14)

**DRAGGED ALONG THE GROUND.** Not snatched off your feet, not lifted
into the air, not dangling.

It catches you and hauls you behind it. You **stay on the floor**, and
you can **still see and still struggle** the whole way.

That choice was made against two alternatives — being lifted into the
air (more frightening) and being able to break free by struggling
(more fair). Dragging keeps you conscious and watching, which is what
the rest of this story depends on: you have to be able to see where you
are being taken, and see whether anyone is coming for you.

## What you can still do while impaled (operator, 2026-08-14)

This is the important part, and it was decided precisely:

- **You can look around.** You are not frozen. You watch it leave and
  you watch your friends arrive.
- **You can struggle** by mashing **Space**. Every mash takes **0.01**
  off the timer before it comes back for you.
- **You can fight back** — but **sometimes your attacks do nothing.**
  You are pinned and flailing, not fighting properly.
- **Movement attacks do nothing at all.** The Runner's dash, the pounce,
  anything that gets its power from how fast you are going — all dead,
  because you are not going anywhere. Momentum of zero is momentum of
  zero.

That last rule is the honest one. delve already says the Runner's claws
do damage *entirely* from speed (STO-CHARACTER-070). A player nailed to
a spike has no speed, so those attacks doing nothing is not a special
case written for this story — it is the rule we already have, applied
where it hurts.

## Definition of Done

- [ ] The spider's pincers can catch a player (or the dummy).
- [ ] It **drags them along the ground** behind it — not lifted, not
      dangling. They stay on the floor.
- [ ] They can see and turn the whole way there.
- [ ] It finds a spike and leaves them on it.
- [ ] Impaled, you can still turn and look.
- [ ] Mashing Space takes 0.01 off the return timer per press.
- [ ] Struggling alone is **not enough** to free you. Someone must come.
- [ ] Attacks sometimes do nothing while pinned.
- [ ] Momentum-based attacks *always* do nothing while pinned.
- [ ] Proven by a headless test.

## Out of scope

- Being dragged to a nest or a web. The nearest spike will do.
- Being lifted into the air. Explicitly rejected — see above.
- The rescue itself — that is STO-ENEMIES-035.
- Being eaten — that is STO-ENEMIES-036.
