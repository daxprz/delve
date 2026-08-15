---
xid: STO-ENEMIES-054
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-8zvp
---

# It learns to swing along, letting go and catching

## Summary

> "being able to learn how to swing with letting go and grabing"
> — operator, 2026-08-14

The spider **moves by its arms**: hold on with one, let go with the
other, reach for the next hold, catch it, repeat. And it **learns to do
it better**.

This is the most ambitious thing asked for in the whole project, and it
is worth being clear about why it is buildable: it is the **walk story
again** (STO-ENEMIES-043), applied to arms instead of legs.

## It starts already half-able, and improves

The operator's founding rule for the spider's mind applies here exactly
as it does to walking:

> "give it basic knowlge of walking so it seems like its already
> existed before the player was there so it still needs to learn
> without having to go through hundreds of genorations"

So it does not discover swinging from nothing. It begins with a crude
swing that just about works — let go too early, catch too late, lose a
lot of height — and **hill-climbs** the timing: when to release, how
far to reach, when to grab. Judged on distance actually covered, the
same honest measure the walk already uses.

That is what makes "learning to swing" a few numbers being tuned rather
than a research project, while still genuinely getting better in front
of you.

## Why it is frightening

A spider that walks at you can be outrun and can be blocked by a wall
it cannot climb (STO-ENEMIES-027). A spider that can **haul itself
across a ceiling** cannot. It turns the whole room into floor.

## Definition of Done

- [ ] It can hold with one arm and let go with the other.
- [ ] Released and reaching, it looks for a new hold and takes it.
- [ ] Chained, this moves it along — measurably, in metres.
- [ ] It starts from a swing that already half-works, never from
      nothing.
- [ ] It **improves**: after practising, it covers more ground per
      swing than it did at the start.
- [ ] It never tunes itself into being unable to swing — floors and
      ceilings on every number.
- [ ] Falling is allowed. A missed catch should drop it, not teleport
      it back.
- [ ] Proven by a headless test comparing a practised spider against a
      fresh one over the same route — "it moved" is not "it learned".

## Out of scope

- Swinging on web or rope.
- Swinging while carrying a victim. One impossible thing at a time.
- Other creatures swinging.
