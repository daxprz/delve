---
xid: STO-TOOLS-015
parent: ./epic.md
kind: story
effort: tools
size: S
status: draft
date: 2026-08-16
depends-on: [STO-TOOLS-011]
bd-id: delve-tvix
---

# A guide to modelling a part, written for you

## Summary

The point of this epic is that the operator can change a shape
**without an agent in the loop**. A tool that needs someone to explain
it each time has not achieved that — it has just moved where the
asking happens.

So: a short guide, written for the operator, that gets them from
"I want the prongs longer" to a changed game, alone.

It must answer, in this order, the questions that actually stop
someone:

1. **How do I open it?** Which program, which file, what it looks like
   when it worked.
2. **What am I looking at?** What `J0`, `Seg` and `End` are, in plain
   words — the base joint, the block you can see, and the spot where
   the next piece starts.
3. **How do I make it longer / fatter / bent more?** The three changes
   most likely to be wanted first, each as a concrete click-by-click.
4. **What must I not rename?** The short list of names the code needs
   — and a pointer to STO-TOOLS-013's message, so a mistake here is
   recoverable rather than mysterious.
5. **How do I see it in the game?** Save, then how to look at it.
6. **How do I undo a mess?** Ctrl+Z, and how to get the original claw
   back from git if it goes badly wrong.

Point 6 is not padding. Knowing you can always get back is what makes
someone brave enough to experiment, and experimenting is the entire
purpose of the epic.

Lives at `knowledge/modelling-a-part.md`, next to the other guides.

## Definition of Done

- [ ] The guide exists and covers all six questions above.
- [ ] It uses the operator's words for things, not the code's — "the
      block you can see", not "the MeshInstance3D".
- [ ] It has at least one worked example done start to finish: make
      the prongs longer.
- [ ] **The real test: the operator makes a change to the claw using
      only the guide, with no agent help.** Only they can tick this.

## Out of scope

- Teaching Godot generally. This is a guide to *one file*, on purpose.
  A tour of the editor is a different and much longer document, and
  the surest way to make this one go unread.
