---
xid: EPI-ENEMIES-SPIDER-TAKES-YOU
parent: ../design.md
kind: epic
effort: enemies
status: open
date: 2026-08-14
bd-id: delve-3s7p
---

# The spider takes you, and your friends have to come get you

## Summary

Right now the spider is *big*. This epic makes it **terrifying**, and
the difference between those two words is the whole point.

Big is a health bar. Terrifying is what happens when it grabs you,
carries you off, and **spikes you on something sharp** — and you are
stuck there, alive, watching it walk away. You cannot save yourself.
Someone has to come for you. And if nobody does, it comes back and
**eats you**, and all that is left is a few limbs on the floor.

That last part is what makes it work. A monster that kills you is a
fight. A monster that takes you away and leaves your friends a *choice*
— go and get him, or stay safe — is a story that happens differently
every time.

## Why it is built in this order

The dummy comes **first**, before any of the scary parts. It is not the
exciting story, but every other story in this epic ends with "and then
someone rescues you" — and with one person at the keyboard there is
nobody to *be* rescued and nobody to *do* the rescuing. Without the
dummy, seven stories can be built and none of them can be tried.

Then the spider gets its arms, then something to spike you on, then the
taking, then the rescue, and only last the eating. Each one is playable
on its own; none of them needs the one after it.

## Definition of Done

- [ ] A dummy stands in the world and can be hurt, grabbed and rescued
      exactly like a real player.
- [ ] The spider has pincer arms that reach much further than its legs.
- [ ] The pincers hurt badly enough that being caught is frightening.
- [ ] They can reach around and through things — cover is not safe.
- [ ] There are sharp spikes somewhere in the world.
- [ ] The arms reach out for you as it closes in, so you get a warning.
- [ ] The spider can grab you, smash you down, drag you, and leave you
      impaled.
- [ ] The screen dims while you are dragged and reddens on the spike,
      and you can see the room throughout.
- [ ] Impaled, you bleed on a clock you can only slow, never stop.
- [ ] Impaled, you cannot free yourself, but a friend can free you.
- [ ] If nobody comes in time, it eats you and leaves limbs behind.
- [ ] Every one of the above proven by a headless test.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 029 | practice-dummy | M | ✅ **First.** Nothing else is testable alone without it. |
| 030 | pincer-arms | M | ✅ Procedural arms on the spider, long reach. |
| 048 | arms-reach-for-you | M | The arms unfold and come for you. Your warning. |
| 031 | pincers-hurt | S | A lot of damage. Being caught must scare you. |
| 032 | pincers-reach | M | Around corners and through gaps. Cover is not safe. |
| 033 | map-spikes | M | Something sharp to be put on. |
| 034 | impale | L | Catch, **smash**, drag, spike. The heart of the epic. |
| 049 | screen-tells-you | M | Dim while dragged, red on the spike. You can always see. |
| 050 | bleeding-timing-game | L | The clock, and the timing game that slows it. |
| 035 | rescue | M | You cannot save yourself. A friend can. |
| 036 | eaten | M | The timer runs out. Limbs are left over. |

Stories **048, 049 and 050** were added on 2026-08-14 when the operator
described the taking in full for the first time — the arms reaching out
beforehand, the smash into the ground, the screen going dim and then
red, and the bleeding you can only ever slow down.

## Out of scope

- The spider dragging you somewhere clever, like a nest or a web. It
  puts you on the nearest spike; that is enough.
- Other enemies learning to do this. It is the spider's trick.
