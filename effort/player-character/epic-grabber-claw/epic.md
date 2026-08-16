---
xid: EPI-CHARACTER-GRABBER-CLAW
parent: ../design.md
kind: epic
effort: character
status: open
date: 2026-08-16
bd-id: delve-py1c
---

# The Grabber remastered: it is a claw

## Summary

> "lets remaster the graber get rid of all of the stuff for the graber
> (controols) and make the hands like grabers in a claw macicean (the
> claw) and make it so the player can press e or q depoeding on which
> one it one of the closes or opens" — operator, 2026-08-16

The Grabber stops being a character with four abilities and becomes
**one thing done well**: a pair of claw-machine claws.

**Q works the left hand. E works the right.** Each key opens and shuts
its own claw. That is the entire control scheme.

## What is being REMOVED

Confirmed by the operator on 2026-08-16, answering "how much goes?"
with **all of it**:

| gone | was |
|---|---|
| **zip** | Q — grapple to where you aim (STO-CHARACTER-025) |
| **throw** | hurl what you are holding (STO-CHARACTER-026) |
| **pull** | yank an enemy toward you (STO-CHARACTER-027) |
| **piston** | F — the chargeable ram (STO-CHARACTER-067 to 073) |
| **block** | C — guard and parry (STO-CHARACTER-028) |
| **punch mode** | momentum punches and shockwaves (EPI-CHARACTER-PUNCH-MODE) |

That is a lot of finished work, so: **the stories are marked removed,
not deleted.** They keep their reasoning, their measurements and their
bugs-found, exactly as the Guardian and Builder characters were kept
when they were dropped. Nothing is lost; it is set down.

**The fingers stay.** Five procedural fingers that wrap around what you
hold (EPI-CHARACTER-FINGERS) is not "stuff for the Grabber" — it is
what the claw is MADE of, and a claw machine's claw is exactly a set of
prongs that closes on a thing.

## Why this is a good trade

Four abilities on one character is four things to explain, four keys to
remember, and four half-built systems — the piston alone has **seven**
stories and is still unfinished after three attempts at what it even
is.

A claw is one idea a child can describe in a sentence, and everyone
already knows how it feels: it opens, it closes, it usually drops what
it is holding. That last part is a gift — a grabber that is genuinely
unreliable is funnier and more interesting than one that is not.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 083 | strip-the-grabber | M | ✅ Abilities and their keys removed. |
| 086 | hands-clean-slate | M | ✅ The hands do nothing at all. |
| 084 | claw-open-shut | M | Q works the left claw, E works the right. |
| 085 | claw-holds-things | L | Shut on something and it comes with you. |

Built in that order: the old controls have to be out of the way before
the new ones can have their keys, and the claw has to open and shut
before holding anything means anything.

## Definition of Done

- [x] The Grabber has no zip, throw, pull, piston, block or punch mode.
- [x] The hands themselves do nothing either — a blank page.
- [ ] Q opens and shuts the LEFT claw; E opens and shuts the RIGHT.
- [ ] A shut claw holds what it closed on.
- [ ] The removed stories are marked removed, with their reasoning
      intact.
- [ ] Nothing that other characters use is broken by the removal —
      block, dodge and the rest belong to more than the Grabber in
      places.
- [ ] Proven by headless tests, including that the removed keys really
      do nothing now.

## Out of scope

- Other characters losing anything. This is the Grabber's remaster.
- The claw being good at fighting. It grabs; what that is worth is a
  separate question.
