---
xid: STO-ENEMIES-050
parent: ./epic.md
kind: story
effort: enemies
size: L
status: done
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

## SETTLED: which timer (operator, 2026-08-14)

STO-ENEMIES-034 says mashing **Space** takes **0.01 off the timer**. It
was not written down *which* timer, and this story said struggling makes
you bleed faster — so it mattered.

**It is 0.01 off YOUR OWN LIFE.** Confirmed by the operator. Every mash
shortens your own clock. Struggling is never a reward and never buys you
anything; it is one more way of bleeding out.

That collapses two rules into one, which is why it is the right answer:

> **Struggling, fighting and thrashing all bleed you out faster. There
> is no exception. The only thing that buys time is the timing game, and
> the only thing that frees you is somebody else.**

## Definition of Done

- [x] Pinned, a bleed clock runs down at **3.0 hp/s**, and reaching zero
      kills you.
- [x] A timing game appears and can be hit or missed. A marker sweeps a
      1.5 s cycle; the good window is the middle 16%.
- [x] Hitting it on time measurably slows the bleeding — to **35%** for
      2.2 s.
- [x] Missing costs nothing extra — the punishment is the time lost.
- [x] Attacking measurably speeds the bleeding up (+0.18 to the
      multiplier, permanently).
- [x] Struggling measurably speeds the bleeding up, **and** takes 0.01
      off your own life. Measured: 140.000 → 139.990 hp, rate
      3.00 → 3.54.
- [x] Movement does nothing whatsoever — the taken state returns before
      any movement code runs.
- [x] Looking around is never restricted.
- [x] A perfect player lasts **noticeably** longer and a thrashing
      player dies **noticeably** sooner — `tests/smoke_bleeding.gd`
      runs all three and prints the times.
- [x] Being rescued stops the bleeding at once (rate → 0.00).
- [ ] **The operator plays it and agrees it feels tense rather than
      fiddly.** Not done — only you can close this one.

## Built (2026-08-14) — the three survival times

Run on a sliver of health so the test finishes quickly; the proportions
are what matter.

| how you play | how long you last |
|---|---|
| **calm** — timing game hit every time | **10.3 s** |
| **nothing at all** | **4.0 s** |
| **thrashing** — struggling every tick | **0.8 s** |

Playing well bought **2.6×** the time. Fighting cost **80%** of it.

## Out of scope

- Bleeding anywhere except on the spike. This is not a wounds system.
- Healing back up. You slow it; you never reverse it.
- What the timing game looks like — that is picked when it is built, and
  it must be readable through the red screen (STO-ENEMIES-049).
