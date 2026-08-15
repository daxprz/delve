---
xid: STO-CHARACTER-081
parent: ./epic.md
kind: story
effort: player-character
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-ynb4
---

# The world behind, faded into background art

## Summary

> "hes able to se the backround but its faded out into a backround like
> art stlye"

Flat, the Mage still sees the rest of the world — but **faded, like
background art** rather than like a place he is in.

That distinction is the point. He is not blind to the world he left,
and he is not still standing in it either. Everything off his plane
reads as scenery: there, visible, and clearly not where he is.

It is also the honest way to show the rule from 080. If an enemy off
the line cannot touch him, it should not LOOK like it can.

## ⚠️ The operator CHANGED this (2026-08-14)

The original ask was that he could still see the world, faded:

> "hes able to se the backround but its faded out into a backround like
> art stlye"

The later ask is stronger, and it is the one that was built:

> "make it so the mage can only see the line there on insted of being
> able to see everything around"

**He now sees his own plane and nothing else.** Not faded — absent.

These two are genuinely different games and the second replaced the
first, so it is written down that way rather than quietly blended. If
the faded-background version was what was wanted after all, this is the
line to come back to.

## How it is done

The camera looks straight ALONG the plane normal, which means the
camera's depth axis and the plane's normal are the same line. So
clipping the view to a thin slab centred on the plane shows him his own
plane and nothing else.

Geometry does all the work. Nothing is hidden object by object, so it
costs nothing, it cannot miss anything, and it stays correct for things
that move in and out of the plane by themselves — which is exactly the
rule STO-CHARACTER-080 needs.

## Definition of Done

- [x] Flat, he sees a **1.80 m** slice of the world instead of all
      4000 m of it.
- [x] The slice is centred on his own plane — not in front of it or
      behind it.
- [x] Things on the plane are drawn completely normally.
- [x] It closes in as part of the glide rather than snapping, or the
      world would vanish in a single frame partway through the turn.
- [x] It all returns to normal when he comes back — the full view is
      back.
- [x] Proven by `tests/smoke_mage_camera.gd`.
- [ ] ~~Faded background art.~~ Superseded — see above. Nothing off the
      plane is drawn at all now.

## Out of scope

- Changing the art style of the whole game.
- Fading anything for anyone except the Mage.
