---
xid: STO-ENEMIES-047
parent: ./epic.md
kind: story
effort: enemies
size: M
status: in-progress
date: 2026-08-14
depends-on: []
bd-id: delve-6mvh
---

# It picks strategies, and sometimes gets them wrong

## Summary

It **chooses a plan**, keeps score of which plans have worked on you,
and leans towards the ones that have — and **sometimes picks the wrong
one on purpose**.

> "Smart, but makes mistakes" — operator, 2026-08-14

That last part is not a compromise, it is the design. A monster you
cannot fool is not frightening, it is unfair. It has to be possible to
bait it, overcommit it, and get away with something — otherwise there
is no way to outplay it, only to out-twitch it.

## Definition of Done

- [x] Four plans: charge, cut off, wait, check your hideout.
- [x] It keeps score per player and prefers what has worked.
- [x] It sometimes picks a worse plan anyway — **65 real mistakes in
      400 choices**.
- [x] Occasional, not constant.
- [x] Over 400 choices it picked the winning plan **86%** of the time,
      against **26%** for a spider that has never met you. Preferred,
      never guaranteed.
- [x] Proven by `tests/smoke_spider_mind.gd` over 400 choices — one
      choice can never show a preference.
- [ ] The plans are **chosen and scored but not yet acted on
      differently**: "cut_off" and "wait" do not yet change how it
      moves. Choosing is built; behaving differently per plan is not.

## Out of scope

- Plans that need pathfinding or teamwork.
- Being unbeatable. See above — that is the opposite of the goal.
