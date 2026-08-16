---
xid: STO-TOOLS-016
parent: ./epic.md
kind: story
effort: tools
size: M
status: draft
date: 2026-08-16
depends-on: [STO-TOOLS-011]
bd-id: delve-74ma
---

# See your change without restarting the game

## Summary

The loop after STO-TOOLS-011 is: edit in Godot → save → **quit the
game → relaunch → get back into a match → find a Grabber → look at
the claw**. That tail is the expensive part, and it is what turns
"try ten small tweaks" into "try two".

Shortening it is the difference between adjusting a shape and
*sculpting* one.

Two ways in, both cheap given delve already has RCON:

- `part reload claw` over RCON (port 9999) — rebuilds the claw on
  every live Grabber from the file on disk.
- A key in-game, so the operator does not need a terminal.

The second matters more. The whole epic is about the operator working
alone, and "open a terminal and type a netcat command" is a worse
barrier than the one being removed.

## The thing that will go wrong

Rebuilding a hand mid-animation. The curl driver holds references into
`Fingers`, and a claw that is *holding something* has state that a
naive rebuild would drop on the floor — possibly literally.

So: reload must either preserve what the claw was holding, or refuse
while it is holding something and say so. Either is fine; silently
dropping the prize is not.

## Definition of Done

- [ ] `part reload <name>` over RCON rebuilds that part on live
      characters.
- [ ] A key does the same in-game, with a message confirming it.
- [ ] Reloading while the claw is open, shut, and mid-travel all leave
      it in a sane state.
- [ ] Reloading while holding something either keeps the hold or
      refuses out loud.
- [ ] A test reloads a deliberately-changed file and checks the live
      claw changed.

## Out of scope

- Watching the file and reloading automatically. Nice, but a
  half-saved file reloading mid-write is a confusing failure, and an
  explicit key never surprises anyone.
