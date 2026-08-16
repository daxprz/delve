---
xid: STO-CHARACTER-088
parent: ./epic.md
kind: story
effort: character
size: M
status: done
date: 2026-08-16
depends-on: []
bd-id: delve-bwoz
---

# Prongs: two slim blocks, pointing inward, each with collision

## Summary

> "make it so they all point towrds the middle and are only two blocks
> one as the base shorter and the top will be longer and both the same
> size width and highte and make them slim so it looks like it can grab
> onto something and give every peice colishion exepet for the parts in
> conects to" — operator, 2026-08-16

Five things, and they are separable:

| # | |
|---|---|
| 1 | Every prong **points toward the middle** |
| 2 | **Two blocks** each, not three |
| 3 | The **base is shorter**, the **top is longer** |
| 4 | Same **width and height**, and **slim** |
| 5 | Every piece has **collision**, except against the pieces it joins |

## Why slim and inward matters

A fat prong pointing outward is a bollard. A slim one angled inward is
something that could close on a thing and hold it — the shape says what
it does before it moves.

"Same width and height" also means the blocks stop tapering. The
current prongs narrow toward the tip, which reads as a **spike**; a
constant-section bar with a bend in it reads as a **grabber**.

## The collision rule is one delve already learned

> "except for the parts it connects to"

That is exactly the rule the spider's physics bones needed
(STO-ENEMIES-055). Adjacent segments **share a joint**, so their shapes
always overlap — by construction, every frame. Left to fight, the
solver shoved them apart harder and harder until the whole skeleton
flew **335 m across the map**.

So: each piece collides with the world, and each piece is excepted from
its own neighbours. The operator arrived at the same rule from the
other direction, which is a good sign it is the right one.

## Definition of Done

- [x] **Two** blocks per prong.
- [x] The base is **shorter**: 0.231 m against the top's 0.429 m.
- [x] Same width and height on both — **0.0558 × 0.0558**, no taper.
- [x] **Slim** — 0.056 m across, down from 0.145 m.
- [x] Every prong points **inward**: the flare was reversed, so the
      four tips converge instead of splaying.
- [x] They sit on the **edges** of the palm — 0.496 m across, out from
      0.110 m — and the arrangement is **wider across than up**
      (0.496 vs 0.304), measured as a ratio so it cannot pass for a
      square.
- [x] Each block has its own collision — **16 pieces** (4 prongs × 2
      blocks × 2 hands).
- [x] A block cannot fight the block it joins to. See below.
- [x] The claw still opens, shuts and catches — every earlier check in
      `smoke_claw` still passes, including the 0.100 m elbow.
- [x] Proven by `tests/smoke_claw.gd`.

## Amended (2026-08-16): on the edges, and wider across

> "they should all be on the edges and pointing towrds the middle and
> make it wider on the sides" — operator

The prongs were planted near the middle of the palm and in a square.
Now they sit **at the rim**, and the four of them make a **wide
rectangle** rather than a square.

| | before | after |
|---|---|---|
| across | 0.110 m | **0.496 m** |
| up and down | 0.110 m | **0.304 m** |

Wider than tall is not arbitrary: a claw that is wider than it is tall
reads as something that closes on a thing **sideways**, which is how an
arcade claw actually grabs.

Both numbers are derived from the palm's own width (`FIST_TH`) rather
than typed in, so a bigger Grabber gets a proportionally bigger claw
with nothing re-tuned — rule 1 of every procedural body in delve.

## Built (2026-08-16)

### "Except the parts it connects to" — solved by not being solid

The pieces are **Area3D**, not solid bodies. A prong is carried about
by an animated chain, and a solid body dragged through the world by an
animation fights the solver instead of obeying it — which is precisely
how the spider's bones ended up 335 m away.

An area detects what it has closed around, which is what a claw
actually needs to know, and the neighbour rule then falls out for free:
`monitorable = false` means no other area can see them, and
`pieces_touching()` only ever asks for overlapping **bodies**. Two
sibling areas sitting inside each other cannot notice or push one
another.

Finding that out was worth the detour: the first attempt called
`add_collision_exception_with` on an Area3D, which does not exist. That
error is the proof these are not solid bodies fighting a solver — if
they were, the exception list would have been necessary.

## Out of scope

- Collision between the two hands.
- The prongs pushing the player about.
