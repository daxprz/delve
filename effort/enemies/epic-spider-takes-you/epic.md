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
- [ ] The spider can grab you, carry you, and leave you impaled.
- [ ] Impaled, you cannot free yourself, but a friend can free you.
- [ ] If nobody comes in time, it eats you and leaves limbs behind.
- [ ] Every one of the above proven by a headless test.

## Stories

| # | Slug | Size | Notes |
|---|------|------|-------|
| 029 | practice-dummy | M | **First.** Nothing else is testable alone without it. |
| 030 | pincer-arms | M | Procedural arms on the spider, long reach. |
| 031 | pincers-hurt | S | A lot of damage. Being caught must scare you. |
| 032 | pincers-reach | M | Around corners and through gaps. Cover is not safe. |
| 033 | map-spikes | S | Something sharp to be put on. |
| 034 | impale | L | The grab, the carry, the spike. The heart of the epic. |
| 035 | rescue | M | You cannot save yourself. A friend can. |
| 036 | eaten | M | The timer runs out. Limbs are left over. |

## Out of scope

- The spider dragging you somewhere clever, like a nest or a web. It
  puts you on the nearest spike; that is enough.
- Other enemies learning to do this. It is the spider's trick.
