---
xid: STO-ENEMIES-060
parent: ./epic.md
kind: story
effort: enemies
size: L
status: draft
date: 2026-08-15
depends-on: []
bd-id: delve-30d2
---

# Limbs are attached until they are pulled off

## Summary

> "make it so body parts can just be pulled away make them stick to
> eachother ... (the spiders limbs should be able to come off)"

Limbs **stick to each other** — they hold on — until something pulls
hard enough, and then they **come away**.

Enemies can already lose limbs (STO-ENEMIES-012), but only by being
struck hard while ragdolled, and only on the humanoid skeleton. This is
different: a limb you can take hold of and **pull**.

## "Stick to each other" is the important phrase

The operator did not ask for limbs that fall off at a damage threshold.
They asked for limbs that are **attached** — held on by something that
can be overcome. That is a joint with a breaking strain, not a hit
point total, and it is why 061 can exist at all: a thing held on by
force can be pulled by force, and two forces are more than one.

Build it as a real attachment with a limit, not as a counter that
reaches zero.

## Definition of Done

- [ ] Each limb is attached by something with a breaking strain.
- [ ] Pulling harder than that strain detaches it.
- [ ] Below it, the limb stays on however long you pull.
- [ ] A detached limb is a real object left in the world.
- [ ] The spider is worse off without it — measurably slower or weaker.
- [ ] It cannot be reattached.
- [ ] Proven by a headless test that pulls below the strain and gets
      nothing, then above it and gets a limb. Both halves required.

## Out of scope

- Limbs coming off from damage alone.
- Putting them back.
- What you can do with a limb once you have one — STO-COMBAT-007 has
  ideas about crushing it.
