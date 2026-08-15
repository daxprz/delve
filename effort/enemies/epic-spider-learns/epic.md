---
xid: EPI-ENEMIES-SPIDER-LEARNS
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-14
bd-id: delve-lrn1
---

# The spider learns, and learns you

## Summary

The spider stops being a thing that always does the same. It **works
on its own walk**, it **copes with whatever happens to it**, and — the
part that matters — it **watches you** and gets better at killing you
the more you play.

It remembers **forever**. Come back tomorrow and it already knows how
you move.

## The honest limit, written down first

**This is not a brain.** A creature that starts knowing nothing and
discovers walking would take neural networks and thousands of training
runs, and that does not fit in delve.

What this epic builds is a spider that **keeps score and adapts**: it
notices what you tend to do, notices what has worked on you, and
changes accordingly. Played against, that feels like learning, because
it genuinely does get harder the longer you play. But it is bookkeeping
and rules underneath, and pretending otherwise would set up a
disappointment later.

## The operator's insight, which makes this buildable

Asked whether the spider should work out walking from scratch, the
operator said (2026-08-14):

> "give it basic knowlge of walking so it seems like its already
> existed before the player was there so it still needs to learn
> without having to go through hundreds of genorations"

That is the whole design, and it is a good one. The spider **starts
already knowing roughly how to walk** — because it existed before you
turned up — and improves from there. It never learns from zero, so it
never needs hundreds of generations, and it is still genuinely learning
rather than replaying a fixed animation.

The same principle carries the rest of the epic: start from something
that works, then refine with what you observe.

## What it learns about you

All of it, per the operator:

| | |
|---|---|
| **Which way you run** | You always break left — so it stops chasing and starts cutting you off. |
| **Your dodge and block timing** | It waits out your dodge, or feints to make you spend it early. |
| **Where you hide** | It checks your favourite spots first. |
| **Which character you play** | The Runner dashes, the Grabber grapples. It plans differently for each. |

## It makes mistakes

Chosen deliberately: it is **smart, but wrong sometimes**. It guesses,
it overcommits, it can be baited. Without that there is no way to
outplay it — only to out-twitch it — and being outplayed by a monster
you cannot fool is not frightening, it is unfair.

## Stories

| # | Slug | Notes |
|---|------|-------|
| 043 | tunes-its-walk | Starts knowing how to walk, then improves it. |
| 044 | copes-when-hurt | Lose a leg, meet rough ground — it finds a way. |
| 045 | remembers-you | Saved to a file. It knows you tomorrow. |
| 046 | learns-your-moves | Your running, dodging, hiding, character. |
| 047 | picks-strategies | Chooses a plan, and sometimes the wrong one. |

## Definition of Done

- [ ] The spider improves its own walk while playing, from a gait that
      already worked.
- [ ] It adapts when hurt or blocked instead of failing.
- [ ] What it learns survives closing the game.
- [ ] It changes what it does based on how you have played.
- [ ] It can be baited into a mistake.
- [ ] Every one of these proven by a headless test, and each one
      measured against a spider that has NOT learned, so "it did
      something" cannot pass for "it learned something".

## Out of scope

- Real machine learning. See the honest limit above.
- Other enemies learning. This is the spider's.
- Spiders teaching each other.
