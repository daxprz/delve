---
xid: STO-ENEMIES-044
parent: ./epic.md
kind: story
effort: enemies
size: M
status: in-progress
date: 2026-08-14
depends-on: []
bd-id: delve-qxmw
---

# It copes when hurt or blocked

## Summary

Hurt it, or block its way, and it **finds another way** instead of
failing.

Today a spider that loses a leg keeps trying to walk exactly as it did
with four, and a spider that meets something it cannot get past keeps
pushing into it. Both read as a broken machine rather than a creature.

After this it notices when things are not working and changes what it
is doing: slower and wider when it is damaged, and a different route
when the one it picked keeps not working.

## Definition of Done

- [x] Getting nowhere repeatedly makes it take a different line rather
      than grinding on.
- [x] It notices from what actually happens to it — distance covered
      AFTER move_and_slide, so walls count and intentions do not.
- [x] It still behaves sensibly when nothing is wrong: a spider that IS
      getting somewhere carries straight on.
- [x] **Standing still on purpose is not being stuck.** Added after it
      wandered off mid-grab: holding a victim still to smash them into
      the ground looks exactly like failing to move. Asserted.
- [ ] Losing a leg changes how it moves, not just how fast. `caution()`
      exists and is derived from legs remaining, but nothing consumes
      it yet — **not built, not ticked**.
- [x] Proven by `tests/smoke_spider_mind.gd`.

## Out of scope

- Healing. Coping is not recovering.
- Re-planning routes properly. This is "try something else", not
  pathfinding.
