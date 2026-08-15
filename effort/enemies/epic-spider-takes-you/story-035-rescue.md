---
xid: STO-ENEMIES-035
parent: ./epic.md
kind: story
effort: enemies
size: M
status: done
date: 2026-08-14
depends-on: [STO-ENEMIES-034]
bd-id: delve-3k0y
---

# Your friends pull you free

## Summary

You are on the spike, bleeding, and you **cannot get yourself off it**.
Someone has to come.

A teammate walks up and **holds a key** to pull you off. It takes a
couple of seconds — long enough that they have to commit, and long
enough that the spider coming back matters.

## Why this is the most important story in the epic

Everything else built so far is a punishment. This is the part that
makes it a **story instead of a death**.

Right now, being taken is fatal every single time: the bleed clock runs
out and that is that. The whole reason the operator wanted the spider to
take people away rather than kill them was so the other players get a
**choice** — go and get him, or stay safe. Without the rescue there is
no choice, and the spike is just a slower way of dying.

## The rules

- **You cannot free yourself.** Nothing you can do while pinned frees
  you — struggling and fighting only bleed you faster
  (STO-ENEMIES-050). This is not a difficulty setting; it is the point.
- **A rescuer must be close and must commit.** Holding **E** for
  **1.5 s** while standing next to you. Let go and the progress is
  lost, so it is a real decision to stand still next to a spike.
- **Then they have to DRAG YOU BACK** (operator, 2026-08-14). Coming
  off the spike is not the end of it: you come off **limp**, and they
  have to haul you away while still holding the key. Let go and they
  set you down wherever you happen to be. Pulling you off is the start
  of the rescue, not the whole of it.
- **Rescue stops the bleeding at once**, and gives you your body back
  (STO-ENEMIES-051).
- **The dummy can be rescued too**, so this can be tried by one person
  at the keyboard. That is exactly why the dummy was built first
  (STO-ENEMIES-029).

## Definition of Done

- [x] A free player standing near an impaled one holds **E** to free
      them.
- [x] It takes about 1.5 s — measured **1.53 s** — and letting go loses
      the progress.
- [x] Out of range, nothing happens however long you hold it. Measured:
      held from **40 m for 5 seconds**, progress **0.00**.
- [x] Freed, the bleeding stops at once (rate → 0.00).
- [x] They come off **limp** and must be **dragged back**. Measured
      **6.9 m** hauled away from the spike.
- [x] Let go and they are set down, standing, moving, not bleeding.
- [x] An impaled player cannot rescue anyone, including themselves. The
      key is held globally in the test, so the victim was mashing it
      for the whole five seconds too.
- [x] The dummy can be rescued the same way — it answers the same calls.
- [x] Proven by `tests/smoke_rescue.gd`, negative case first.

## Built (2026-08-14)

The first version of the test called `hold_rescue()` directly and
failed, because the player's own input handling saw the key was not
held and cancelled the pull on the same frame. **Driving the function
is not driving the feature** — the test now presses the real key.

## Out of scope

- Healing the person you rescued. They come off the spike hurt.
- Fighting the spider off. Rescuing is its own act; whether you can
  survive doing it is up to you.
- Reviving someone who has already bled out.
