---
xid: STO-ENEMIES-016
parent: ./epic.md
kind: story
effort: enemies
size: S
status: draft
date: 2026-08-07
depends-on: []
bd-id: delve-0b3
---

# Dead bodies stay so you can still push them around

## Summary

When an enemy dies its body should stay on the floor, and you should
still be able to grab it, punch it, whip it and shove it about.

Right now it does the opposite. In `enemy.gd`:

```gdscript
if _health <= 0.0:
        _ragdoll.queue_free()   # the ragdoll is deleted
        queue_free()            # ...and so is the enemy
```

The moment an enemy dies, the enemy **and** its ragdoll are deleted,
so the body pops out of existence mid-fight. Everything delve has
built for physical fighting — the Grabber's arms, the Runner's tail,
throwing, dragging — stops working the instant a thing dies.

## Definition of Done

- [ ] A defeated enemy leaves its ragdoll behind instead of vanishing.
- [ ] The body can still be grabbed, punched, whipped and pushed.
- [ ] A corpse takes no more damage and cannot be "killed" twice.
- [ ] A corpse does not chase, attack, or get back up.
- [ ] Bodies do not pile up forever and slow the game down — there is
      some limit on how many are kept.
- [ ] Every peer sees the same body in multiplayer.
- [ ] Proven by a headless test.

## Out of scope

- Bodies decaying, sinking into the floor, or being cleaned up on a
  timer — a simple limit is enough to start.

## Notes

Found by the operator while playing, not by reading code. Worth
remembering: it looks like "the enemy died" and reads like "the enemy
was deleted", and only one of those is what anyone wanted.
