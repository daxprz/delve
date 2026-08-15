---
xid: STO-ENEMIES-033
parent: ./epic.md
kind: story
effort: enemies
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-c8um
---

# Sharp spikes in the world

## Summary

> "(add a sharp thing to the map for the spider to put the player on)"
> — operator, twice: 2026-08-14 and again 2026-08-14

There is something **sharp** standing in the world — a spike, a stake, a
pointed stick — and it is there for one reason: the spider needs
somewhere to put you.

The operator has now asked for this twice, in both descriptions of the
grab, which makes it the piece the whole taking sequence rests on. No
spike, no impaling, and STO-ENEMIES-034 has nowhere to end.

## What it needs to be

- **Findable by the spider.** It goes in a group the spider can search,
  so "take them to the nearest spike" is one lookup and never a typed-in
  coordinate. Add a second spike later and it works for free.
- **Visible to a player.** You should be able to spot it across the room
  and think *do not get carried over there.* Knowing where it is before
  it matters is what makes it a threat rather than a surprise.
- **Solid.** It is a real object in the world, not a marker.

Start with **one**, near enough to spawn that it can actually be reached
in a test, and far enough that being dragged there takes long enough to
be frightening.

## Definition of Done

- [ ] At least one sharp thing stands in the world and is visible.
- [ ] It is in a group, and a query returns the nearest one to any point.
- [ ] It is solid — you cannot walk through it.
- [ ] Adding a second one needs no code change.
- [ ] Proven by a headless test that finds the nearest spike from two
      different positions and gets the right answer for each.

## Out of scope

- The spike hurting you by itself. Walking into it is not a trap; only
  the spider puts you on it. Being impaled is STO-ENEMIES-034.
- A whole nest or lair full of them. One is enough to build against.
- Prettiness. It needs to read as *sharp*, nothing more.
