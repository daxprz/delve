---
xid: STO-ENEMIES-048
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-14
depends-on: [STO-ENEMIES-030]
bd-id: delve-i8ih
---

# The arms reach out for you when it gets close

## Summary

> "make the spiders arms reach out twoards (with prosijal genoration) you
> when its close to you" — operator, 2026-08-14

Today the pincer arms just weave about in front of the spider, doing the
same thing whether you are across the map or standing under it. This
story makes them **notice you**.

When it gets near, the arms stop idling and **stretch out toward where
you are**, tracking you as you move. The jaws open. Then you know it is
about to try.

That is the whole job of this story: **warning**. Being grabbed out of
nowhere is unfair. Watching two long arms unfold and come for you, and
having a second to run, is frightening — which is what this creature is
for.

## Procedurally generated, not an animation

The operator asked for this "with prosijal genoration", and that matches
how the rest of the spider already works. There is **no recorded reach
animation**. The arms are aimed at your actual position every frame, the
same way the legs already work out where to put a foot.

That means it reaches correctly no matter where you stand — above it,
behind it, off to one side — with nobody having to animate those cases.
It also means it keeps working when the spider is a different size,
because the arms are already sized from the body height.

The **floppiness stays on** (STO-ENEMIES-039). The arms should not snap
to you like a robot; they should swing out and settle, still whipping
and trailing. Reaching is the gait's *target* changing, not the springs
being switched off.

## How close is close?

Derived, not typed in — rule 1 of this creature. The arms start reaching
when you are within their **own reach** (~3.8 m today) plus a little,
read off the arms at runtime. A bigger spider then starts reaching from
further away with nothing re-tuned.

## Definition of Done

- [ ] Far away, the arms idle exactly as they do now.
- [ ] Inside reach, both arms extend toward the player's actual position
      and follow them as they move.
- [ ] The jaws open as it reaches.
- [ ] It works for a player standing to the side or behind, not just
      dead ahead.
- [ ] The arms still look floppy while reaching — they swing out and
      settle, they do not snap.
- [ ] The trigger distance is **read off the arms**, not a typed-in
      number.
- [ ] Proven by a headless test that measures the angle between an arm
      and the direction to the player: **large** when far, **small**
      when close. A test that only checks "the reach code ran" does not
      count.

## Out of scope

- Actually catching hold of you — that is STO-ENEMIES-034.
- Reaching around corners and through gaps — that is STO-ENEMIES-032.
- Damage — that is STO-ENEMIES-031.
