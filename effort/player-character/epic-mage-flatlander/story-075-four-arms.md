---
xid: STO-CHARACTER-075
parent: ./epic.md
kind: story
effort: player-character
size: M
status: draft
date: 2026-08-14
depends-on: []
bd-id: delve-1f1t
---

# He has four arms

## Summary

> "a mage with 4 arms" — operator, 2026-08-14

**Four** arms, not two. Generated in code like every other body part in
delve, so no two mages have quite the same ones.

Four is the readable number: it is instantly obviously wrong for a
person, without becoming a mass of limbs you cannot count. It also
says *magic* before he has cast anything — you know what he is the
moment you see him.

## Definition of Done

- [ ] The Mage has four arms, and they are visible.
- [ ] They are procedurally generated and seeded, like the rest of
      delve's bodies — same seed, same mage, on every machine.
- [ ] They are arranged so all four are visible and countable, not
      overlapping into a blur.
- [ ] They move with him rather than hanging rigid.
- [ ] Nobody else grows extra arms.
- [ ] Proven by a headless test that counts them and checks they are in
      four DIFFERENT places — "four arm nodes exist" would pass with
      all four inside each other.

## Out of scope

- The arms doing anything. This is what he looks like, not what he
  does.
- Reusing the Grabber's mechanical arms. Those are a machine; these are
  his own.
