---
xid: EPI-ENEMIES-PULL-IT-APART
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-15
bd-id: delve-efhm
---

# Pull the spider apart, together

## Summary

> "make the spiders arms colidable like the legs so the player (using
> the graber as an example) can smack the out of the way to do damge and
> make it so body parts can just be pulled away make them stick to
> eachother making a way of team work for one person to hold it down
> while some one pulls it limbs off (the spiders limbs should be able to
> come off)" — operator, 2026-08-15

The spider stops being a creature you damage and becomes a creature you
**take apart**. Its limbs are real, they can be **hit out of the way**,
and they can be **pulled off** — but pulling one off is more than one
person can manage alone.

## Why this is the best idea yet for this creature

Everything the spider does so far happens **to** you: it takes you, it
spikes you, your friends come and get you. This is the first thing that
makes the fight itself a **team** activity — and it answers a question
that has been open since the very first epic.

The spider was built to be *terrifying*, and terrifying things need to
be beatable in a way that feels earned. **"Fighting it" is one of the
three empty topics** in the whole design, and this fills it: you do not
out-damage a giant spider, you **dismantle** it, and you cannot do that
on your own.

One player holds a limb still. Another pulls. That is a shape of
gameplay delve does not have anywhere else.

## What has to be built

| # | | |
|---|---|---|
| 058 | ✅ The arms are physics too | done — 12 bones became 16 |
| 059 | Hitting a limb hurts it | smack an arm aside and it costs the creature something |
| 060 | Limbs are attached, and come off | they hold on until pulled hard enough |
| 061 | It takes two | one holds it down, one pulls — alone is not enough |

Built in that order: an arm has to be real before it can be hit, and it
has to be hittable before coming off means anything.

## The rule that makes 061 work

The rescue (STO-ENEMIES-035) already proved this shape: **struggling
alone must never be enough**. There, you cannot free yourself and
someone has to come. Here, one player cannot dismantle a spider and
someone has to help.

Making both of delve's cooperative moments run on the same rule is
deliberate. It is how the game says what it is about.

## Definition of Done

- [x] The pincer arms collide with the world and with the player, like
      the legs do.
- [ ] Hitting a limb hurts the creature and shoves the limb aside.
- [ ] Limbs stay attached until pulled hard enough.
- [ ] A limb really comes off, and the spider is worse without it.
- [ ] One player cannot do it alone. Two can.
- [ ] Every one proven by a headless test, and the "alone is not
      enough" case tested as a NEGATIVE — otherwise a limb that falls
      off for anybody would pass.

## Out of scope

- Other creatures coming apart. Walkers already lose limbs their own
  way (EPI-ENEMIES-ENEMY-LIMBS).
- Putting limbs back on.
- The spider reacting cleverly to losing one. It copes badly, and
  STO-ENEMIES-044 owns making that better.
