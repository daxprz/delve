---
xid: STO-ENEMIES-051
parent: ./epic.md
kind: story
effort: enemies
size: L
status: done
date: 2026-08-14
depends-on: [STO-ENEMIES-034]
bd-id: delve-iqxo
---

# It holds you by one leg and you go limp

## Summary

> "when some ones chought make it so it grabs them by one leg and there
> ragdolled" — operator, 2026-08-14

Caught, you do not get carried along politely upright. The spider takes
hold of **one leg** and everything else about you **goes limp**. You are
hauled across the floor head-down, arms trailing, bumping over whatever
is in the way.

This is the detail that makes being taken *humiliating* rather than
merely damaging, and humiliating is a much better fit for what this
creature is for.

## ⚠️ This breaks delve's oldest rule about players, on purpose

`player.gd` says it outright today:

> *"ragdolled, a PLAYER is launched and keeps full control."*

Enemies ragdoll. Players never do. Every knockback, piston launch and
dive impact in delve was written to move you around **without** taking
your body away from you, because losing control of your character is
the most annoying thing a game can do.

Being caught by the spider is the **one** exception, and it earns it:

- It only happens when you are **already caught**, which is already a
  state where you have lost.
- You still **keep your camera**. You look around the whole way. The
  thing you lose is your body, not your eyes — and watching your own
  limp body being dragged off is the point.
- Nothing else in the game may use it. If a second thing ever ragdolls
  a player, this rule has stopped meaning anything.

## By ONE leg

Not by the middle, not by the shoulders. **One leg**, and the rest of
you hangs off it.

That is why it reads as a spider carrying prey rather than a piggyback:
everything below the grip swings, drags and catches on the floor. It
also means the **rest of you is loose** — which is what makes the
rescue (STO-ENEMIES-035) feel like pulling someone out of something.

The held leg follows the pincer. Everything else is real physics.

## Definition of Done

- [x] Caught, the player's body becomes a real ragdoll — eleven rigid
      parts with cone-twist joints, built from their actual body.
- [x] The spider holds it by **one leg** (`ShinL` or `ShinR`, picked
      from a hash of their name), and that leg stays at the pincer —
      measured **0.00 m** off where it is put.
- [x] The rest of the body genuinely dangles: head measured **0.92 m
      BELOW** the held leg. A ragdoll standing neatly upright would
      satisfy "a ragdoll exists" and fail this.
- [x] It still stays on the ground — dragged at ankle height, the head
      sits at y=0.69.
- [x] You can still look around the whole time. The camera rides the
      player node, which follows its own ragdoll's pelvis.
- [x] Put on the spike, you are solid again.
- [x] Freed, you get your body back, upright and controllable, with
      **0** ragdolls left behind in the world.
- [x] Nothing else in delve ragdolls a player. The test asserts a fresh
      player is **not** limp, so anything that started ragdolling
      players generally would trip it.
- [x] Proven by `tests/smoke_held_by_leg.gd`.

## Confirmed by the operator (2026-08-14)

Asked whether any big hit should ragdoll a player, the answer was
**"only ever the spider"**. The exception stays an exception.

## Out of scope

- Ragdolling a player for any other reason. See above — that is the
  whole safeguard.
- Limbs coming off while you are dragged. That is STO-ENEMIES-036,
  and it happens when you are *eaten*, not while you are alive.
