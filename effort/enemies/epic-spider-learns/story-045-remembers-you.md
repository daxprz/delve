---
xid: STO-ENEMIES-045
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: []
bd-id: delve-hg1z
---

# It remembers you between games

## Summary

> "Yes — remembers forever" — operator, 2026-08-14

What the spider learns about you is **saved to a file**. Close the game,
come back tomorrow, and it already knows how you move.

This is the story that turns everything else in the epic from a
five-minute novelty into a thing that builds. A spider that forgets you
at every restart never gets past knowing you slightly.

## Definition of Done

- [x] What it has learned is written to `user://spider_memory.json`.
- [x] It is loaded the moment a spider is built, before its first
      frame — forever has to start before the first minute of every
      session is amnesia.
- [x] A spider that has never met you starts blank: asserted at **0**
      observations.
- [x] A missing file is survivable — it starts blank rather than
      crashing. Corrupt JSON is handled the same way.
- [x] Proven by `tests/smoke_spider_mind.gd`: saved, thrown away,
      reloaded, **320 observations** and the break bias intact.

## Out of scope

- Sharing memories between spiders, or between machines.
- Ever forgetting. The operator asked for forever.
