---
xid: STO-ENEMIES-016
parent: ./epic.md
kind: story
effort: enemies
size: S
status: shipped
date: 2026-08-07
depends-on: []
bd-id: delve-0b3
shipped: 2026-08-07
tasks: 6
complete: 6
---

# Dead bodies stay so you can still push them around

## Summary

A defeated enemy leaves its body on the floor, and you can still grab,
punch, whip and shove it.

It used to do the exact opposite:

```gdscript
if _health <= 0.0:
        _ragdoll.queue_free()   # the ragdoll is deleted
        queue_free()            # ...and so is the enemy
```

The enemy **and** its ragdoll were deleted the instant it died, so
bodies popped out of existence mid-fight and everything delve had
built for physical fighting stopped working the moment a thing died.

## Definition of Done

- [x] A defeated enemy leaves its ragdoll behind instead of vanishing.
- [x] The body can still be shoved around.
- [x] A corpse takes no more damage and cannot be killed twice.
- [x] A corpse never chases, attacks, or gets back up.
- [x] Bodies do not pile up forever — capped at 8, oldest reaped.
- [x] Proven by a headless test (14 checks).

## Out of scope

- Bodies decaying or sinking into the floor.

## Verification notes (2026-08-07)

`tests/smoke_enemy_corpse.gd`, 14 checks.

The test kills the enemy **while it is still standing** — the harder
case, because there is no ragdoll yet to keep, so `die()` has to build
one purely to leave a body.

A corpse keeps its place in the `enemies` group on purpose, so the
tail and the Grabber's arms can still knock it about, but its own
collision layer is cleared so it stops being something to walk into.
`_downed` is set to infinity, which is what stops it ever standing
back up.

The cap matters more than it sounds: each body is **11 rigid
bodies**, so an uncapped graveyard would quietly strangle the frame
rate over a long fight.

## A test this broke shipped before it was noticed

`smoke_enemy_health` required that lethal damage **removes** the
enemy — the exact behaviour this story reverses. Like `smoke_health`,
it needs to host, so it did not run while the operator was playing,
and v0.1.9 shipped with it failing.

Now inverted: it asserts the enemy is still there AND reports itself
dead. Written that way round deliberately, so "deleted" fails with a
message naming this story rather than a bare mismatch.

## Notes

Found by the operator while playing, not by reading code. It looks
like "the enemy died" and reads like "the enemy was deleted", and only
one of those is what anyone wanted.
