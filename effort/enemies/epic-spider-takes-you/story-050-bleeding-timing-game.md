---
xid: STO-ENEMIES-050
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-14
depends-on: [STO-ENEMIES-034]
bd-id: delve-kuq1
---

# Bleeding out on the spike, and the timing game that slows it

## Summary

> "you have to do a timing game to slow down your bleeding to try to
> maximize the timer while the player can still fight back kinda but
> movement doesnt do any thing and the more the player trys to fight the
> more they bleed out and slowly die" — operator, 2026-08-14

Stuck on the spike, you are **bleeding**, and the bleeding is a clock.
When it runs out you die — or the spider comes back and eats you
(STO-ENEMIES-036), whichever happens first.

You cannot stop the bleeding. You can only **slow it down**, by playing
a small **timing game**: hit the button at the right moment and you
bleed slower for a while. Miss it and you do not.

So the whole time you are pinned, you are doing one thing: **stretching
out how long you last**, buying time for your friends to reach you.

## The idea underneath it, which is the good bit

**Everything you do to save yourself kills you faster. Only staying calm
buys you time. And only someone else can actually free you.**

That is why fighting makes you bleed more. Thrashing about on a spike
should make it worse — that is true, and it is also the most frightening
rule in the game, because it means the panicky, natural thing to do is
the wrong thing. The player who survives longest is the one who stops
struggling and concentrates.

It gives you a real decision every second you are up there, and it never
lets you win alone.

## What you can do while pinned

| You do this | What happens |
|---|---|
| **The timing game** — hit it on time | you bleed **slower** for a while |
| **The timing game** — miss | nothing gained; the bleeding carries on |
| **Fight / attack** | you bleed **faster** |
| **Struggle** (mash Space) | you bleed **faster** |
| **Look around** | free — always allowed |
| **Move** | nothing at all. You are nailed to a spike. |

Fighting is **not banned**. It is allowed, it just costs you — some
attacks land, some do nothing (STO-ENEMIES-034), and every attempt
speeds up the clock. That is a much better rule than taking the button
away, because it is *your* choice to spend life on it.

## ⚠️ One thing that needs settling

STO-ENEMIES-034 already says mashing **Space** takes **0.01 off the
timer**, decided on 2026-08-14. This story says struggling makes you
bleed **faster**.

These two agree only if "0.01 off the timer" means **off your own life**
— you are shortening your own clock by thrashing. Read that way, both
rules say the same thing and the design is clean.

They disagree if it meant 0.01 off the *spider's return* timer as a
reward for struggling.

**Nothing gets built here until the operator says which.** Written down
rather than guessed, because a guess here would quietly invert the whole
point of the story.

## Definition of Done

- [ ] Pinned, a bleed clock runs down, and reaching zero kills you.
- [ ] A timing game appears and can be hit or missed.
- [ ] Hitting it on time measurably slows the bleeding for a period.
- [ ] Missing costs nothing extra — the punishment is the time lost.
- [ ] Attacking measurably speeds the bleeding up.
- [ ] Struggling measurably speeds the bleeding up.
- [ ] Movement does nothing whatsoever.
- [ ] Looking around is never restricted.
- [ ] A perfect player lasts **noticeably** longer than one doing
      nothing, and a thrashing player dies **noticeably** sooner. Proven
      by a headless test running all three and printing the three
      survival times.
- [ ] Being rescued (STO-ENEMIES-035) stops the bleeding at once.
- [ ] The operator plays it and agrees it feels tense rather than fiddly.

## Out of scope

- Bleeding anywhere except on the spike. This is not a wounds system.
- Healing back up. You slow it; you never reverse it.
- What the timing game looks like — that is picked when it is built, and
  it must be readable through the red screen (STO-ENEMIES-049).
